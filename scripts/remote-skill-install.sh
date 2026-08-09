#!/usr/bin/env bash

# Shared implementation for project-owned remote skill installers.
# The calling install.sh must define all configuration variables before sourcing
# this file, then call run_remote_skill_installer "$@".

remote_skill_fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

remote_skill_read_name() {
  local skill_file=$1

  awk '
    NR == 1 {
      sub(/\r$/, "")
      if ($0 != "---") exit
      frontmatter = 1
      next
    }
    frontmatter && /^---\r?$/ { exit }
    frontmatter && /^name:[[:space:]]*/ {
      sub(/^name:[[:space:]]*/, "")
      sub(/[[:space:]]*\r?$/, "")
      gsub(/^['\''"]|['\''"]$/, "")
      print
      exit
    }
  ' "$skill_file"
}

remote_skill_validate_relative_path() {
  local path=$1
  local allow_dot=${2:-false}

  if [[ $allow_dot == true && $path == . ]]; then
    return
  fi

  [[ -n $path ]] || remote_skill_fail "empty remote path"
  [[ $path != /* ]] || remote_skill_fail "absolute remote path: $path"
  [[ $path != *$'\n'* && $path != *$'\t'* ]] ||
    remote_skill_fail "remote path contains a newline or tab"

  case "/$path/" in
    */../*|*/./*) remote_skill_fail "unsafe remote path: $path" ;;
  esac
}

remote_skill_sha256() {
  local file=$1

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{ print $1 }'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{ print $1 }'
  else
    remote_skill_fail "sha256sum or shasum is required"
  fi
}

remote_skill_write_manifest() {
  local payload=$1
  local output=$2
  local relative
  local hash

  : >"$output"
  while IFS= read -r relative; do
    relative=${relative#./}
    remote_skill_validate_relative_path "$relative"
    case "$relative" in
      install.sh|.upstream-manifest|.upstream-revision)
        remote_skill_fail "upstream payload uses reserved path: $relative"
        ;;
    esac
    hash=$(remote_skill_sha256 "$payload/$relative")
    printf '%s\t%s\n' "$hash" "$relative" >>"$output"
  done < <(cd "$payload" && find . -type f -print | LC_ALL=C sort)

  [[ -s $output ]] || remote_skill_fail "remote payload is empty"
}

remote_skill_manifest_has_path() {
  local manifest=$1
  local wanted=$2

  awk -F '\t' -v wanted="$wanted" '
    $2 == wanted { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$manifest"
}

remote_skill_validate_payload() {
  local payload=$1
  local declared_name

  [[ -f $payload/SKILL.md ]] ||
    remote_skill_fail "remote payload does not contain SKILL.md"

  if find "$payload" -type l -print -quit | grep -q .; then
    remote_skill_fail "remote payload contains a symbolic link"
  fi
  if find "$payload" -mindepth 1 ! -type f ! -type d -print -quit |
    grep -q .; then
    remote_skill_fail "remote payload contains a special file"
  fi

  declared_name=$(remote_skill_read_name "$payload/SKILL.md")
  [[ -n $declared_name ]] ||
    remote_skill_fail "remote SKILL.md has no valid name"
  [[ $declared_name == "$SKILL_NAME" ]] ||
    remote_skill_fail \
      "remote skill name '$declared_name' does not match '$SKILL_NAME'"
}

remote_skill_copy_entry() {
  local source=$1
  local destination=$2

  [[ -e $source ]] || remote_skill_fail "missing upstream path: $source"
  mkdir -p "${destination%/*}"
  cp -a "$source" "$destination"
}

remote_skill_stage_update() {
  local clone_dir
  local source_root
  local entry

  command -v git >/dev/null 2>&1 || remote_skill_fail "git is required"

  REMOTE_SKILL_TEMP=$(mktemp -d)
  clone_dir="$REMOTE_SKILL_TEMP/repository"
  REMOTE_SKILL_PAYLOAD="$REMOTE_SKILL_TEMP/payload"
  REMOTE_SKILL_MANIFEST="$REMOTE_SKILL_TEMP/manifest"
  mkdir -p "$REMOTE_SKILL_PAYLOAD"

  printf 'Fetching %s (%s)...\n' "$REMOTE_URL" "$REMOTE_REF"
  git clone --quiet --depth 1 --branch "$REMOTE_REF" -- "$REMOTE_URL" \
    "$clone_dir"

  remote_skill_validate_relative_path "$REMOTE_PATH" true
  source_root="$clone_dir"
  if [[ $REMOTE_PATH != . ]]; then
    source_root+="/$REMOTE_PATH"
  fi
  [[ -d $source_root ]] ||
    remote_skill_fail "remote skill path does not exist: $REMOTE_PATH"

  for entry in "${REMOTE_INCLUDE_PATHS[@]}"; do
    remote_skill_validate_relative_path "$entry"
    remote_skill_copy_entry "$source_root/$entry" \
      "$REMOTE_SKILL_PAYLOAD/$entry"
  done

  for entry in "${REMOTE_ROOT_PATHS[@]}"; do
    remote_skill_validate_relative_path "$entry"
    remote_skill_copy_entry "$clone_dir/$entry" \
      "$REMOTE_SKILL_PAYLOAD/$entry"
  done

  remote_skill_validate_payload "$REMOTE_SKILL_PAYLOAD"
  remote_skill_write_manifest "$REMOTE_SKILL_PAYLOAD" \
    "$REMOTE_SKILL_MANIFEST"
  REMOTE_SKILL_REVISION=$(git -C "$clone_dir" rev-parse HEAD)
}

remote_skill_check_local_changes() {
  local force=$1
  local old_manifest="$SKILL_DIR/.upstream-manifest"
  local expected
  local relative
  local current

  (( force == 0 )) || return

  if [[ -f $old_manifest ]]; then
    while IFS=$'\t' read -r expected relative; do
      remote_skill_validate_relative_path "$relative"
      [[ -f $SKILL_DIR/$relative ]] ||
        remote_skill_fail \
          "local vendored file is missing: $SKILL_NAME/$relative (use --force to replace)"
      current=$(remote_skill_sha256 "$SKILL_DIR/$relative")
      [[ $current == "$expected" ]] ||
        remote_skill_fail \
          "local vendored file was modified: $SKILL_NAME/$relative (use --force to replace)"
    done <"$old_manifest"
  fi

  while IFS=$'\t' read -r expected relative; do
    [[ -e $SKILL_DIR/$relative ]] || continue
    if [[ -f $old_manifest ]] &&
      remote_skill_manifest_has_path "$old_manifest" "$relative"; then
      continue
    fi
    current=$(remote_skill_sha256 "$SKILL_DIR/$relative")
    [[ $current == "$expected" ]] ||
      remote_skill_fail \
        "upstream path conflicts with local file: $SKILL_NAME/$relative (use --force to replace)"
  done <"$REMOTE_SKILL_MANIFEST"
}

remote_skill_prune_empty_parents() {
  local relative=$1
  local parent=${relative%/*}

  while [[ $parent != "$relative" && $parent != . && -n $parent ]]; do
    rmdir "$SKILL_DIR/$parent" 2>/dev/null || break
    relative=$parent
    parent=${relative%/*}
  done
}

remote_skill_sync_payload() {
  local old_manifest="$SKILL_DIR/.upstream-manifest"
  local ignored_hash
  local relative
  local parent

  if [[ -f $old_manifest ]]; then
    while IFS=$'\t' read -r ignored_hash relative; do
      remote_skill_validate_relative_path "$relative"
      if ! remote_skill_manifest_has_path "$REMOTE_SKILL_MANIFEST" \
        "$relative"; then
        rm -f -- "$SKILL_DIR/$relative"
        remote_skill_prune_empty_parents "$relative"
      fi
    done <"$old_manifest"
  fi

  while IFS=$'\t' read -r ignored_hash relative; do
    remote_skill_validate_relative_path "$relative"
    parent=${relative%/*}
    if [[ $parent != "$relative" ]]; then
      mkdir -p "$SKILL_DIR/$parent"
    fi
    cp -p "$REMOTE_SKILL_PAYLOAD/$relative" "$SKILL_DIR/$relative"
  done <"$REMOTE_SKILL_MANIFEST"

  cp "$REMOTE_SKILL_MANIFEST" "$SKILL_DIR/.upstream-manifest"
  printf '%s\n' "$REMOTE_SKILL_REVISION" >"$SKILL_DIR/.upstream-revision"
}

remote_skill_validate_current() {
  local declared_name

  [[ -f $SKILL_DIR/SKILL.md ]] ||
    remote_skill_fail "missing $SKILL_NAME/SKILL.md"
  declared_name=$(remote_skill_read_name "$SKILL_DIR/SKILL.md")
  [[ $declared_name == "$SKILL_NAME" ]] ||
    remote_skill_fail \
      "local skill name '$declared_name' does not match '$SKILL_NAME'"
}

remote_skill_install_dependency() {
  local dependency=$1
  shift
  local installer

  [[ $dependency =~ ^[a-z0-9][a-z0-9-]*$ ]] ||
    remote_skill_fail "invalid dependency name: $dependency"
  installer="$PROJECT_ROOT/$dependency/install.sh"
  [[ -x $installer ]] ||
    remote_skill_fail "missing executable dependency installer: $installer"

  printf 'Installing dependency %s for %s...\n' "$dependency" "$SKILL_NAME"
  "$installer" "$@"
}

remote_skill_install_link() {
  local agent_name=$1
  local executable=$2
  local skill_root=$3
  local target="$skill_root/$SKILL_NAME"
  local resolved

  if ! command -v "$executable" >/dev/null 2>&1; then
    printf 'Skipped %s: executable %s is absent.\n' \
      "$agent_name" "$executable"
    REMOTE_SKILL_SKIPPED=$((REMOTE_SKILL_SKIPPED + 1))
    return
  fi

  mkdir -p "$skill_root"
  if [[ -L $target ]]; then
    resolved=$(readlink -f -- "$target" 2>/dev/null || true)
    if [[ $resolved == "$SKILL_DIR" ]]; then
      printf 'Installed %s: %s already points to this skill.\n' \
        "$agent_name" "$target"
      REMOTE_SKILL_INSTALLED=$((REMOTE_SKILL_INSTALLED + 1))
      return
    fi
    printf 'Conflict for %s: %s points elsewhere; left unchanged.\n' \
      "$agent_name" "$target" >&2
    REMOTE_SKILL_CONFLICTS=$((REMOTE_SKILL_CONFLICTS + 1))
    return
  fi

  if [[ -e $target ]]; then
    printf 'Conflict for %s: %s already exists; left unchanged.\n' \
      "$agent_name" "$target" >&2
    REMOTE_SKILL_CONFLICTS=$((REMOTE_SKILL_CONFLICTS + 1))
    return
  fi

  ln -s "$SKILL_DIR" "$target"
  printf 'Installed %s: %s -> %s\n' "$agent_name" "$target" "$SKILL_DIR"
  REMOTE_SKILL_INSTALLED=$((REMOTE_SKILL_INSTALLED + 1))
}

run_remote_skill_installer() {
  local force=0
  local skip_update=0
  local dependency
  local -a dependency_args=()

  while (( $# > 0 )); do
    case "$1" in
      --force) force=1 ;;
      --skip-update) skip_update=1 ;;
      -h|--help)
        printf 'Usage: %s [--force] [--skip-update]\n' "${0##*/}"
        return
        ;;
      *) remote_skill_fail "unknown argument: $1" ;;
    esac
    shift
  done

  [[ ${SKILL_SOURCE:-} == remote ]] ||
    remote_skill_fail "SKILL_SOURCE must be remote"
  [[ -n ${SKILL_NAME:-} && -n ${REMOTE_URL:-} &&
     -n ${REMOTE_REF:-} && -n ${REMOTE_PATH:-} ]] ||
    remote_skill_fail "remote installer configuration is incomplete"
  declare -p DEPENDENCIES REMOTE_INCLUDE_PATHS REMOTE_ROOT_PATHS \
    >/dev/null 2>&1 || remote_skill_fail "remote installer arrays are missing"

  case ":${MY_SKILLS_INSTALL_STACK:-}:" in
    *":$SKILL_NAME:"*)
      remote_skill_fail \
        "dependency cycle detected: ${MY_SKILLS_INSTALL_STACK:-}:$SKILL_NAME"
      ;;
  esac

  if [[ -z ${MY_SKILLS_INSTALL_STATE:-} ]]; then
    MY_SKILLS_INSTALL_STATE=$(mktemp)
    export MY_SKILLS_INSTALL_STATE
    REMOTE_SKILL_ROOT_INVOCATION=1
  else
    REMOTE_SKILL_ROOT_INVOCATION=0
  fi
  [[ -f $MY_SKILLS_INSTALL_STATE ]] ||
    remote_skill_fail "dependency state file is missing"

  if grep -Fxq -- "$SKILL_NAME" "$MY_SKILLS_INSTALL_STATE"; then
    printf 'Dependency %s was already installed in this run.\n' "$SKILL_NAME"
    return
  fi

  export MY_SKILLS_INSTALL_STACK="${MY_SKILLS_INSTALL_STACK:+$MY_SKILLS_INSTALL_STACK:}$SKILL_NAME"
  REMOTE_SKILL_TEMP=""
  REMOTE_SKILL_PAYLOAD=""
  REMOTE_SKILL_MANIFEST=""
  REMOTE_SKILL_REVISION=""
  REMOTE_SKILL_INSTALLED=0
  REMOTE_SKILL_SKIPPED=0
  REMOTE_SKILL_CONFLICTS=0

  remote_skill_cleanup() {
    if [[ -n $REMOTE_SKILL_TEMP && -d $REMOTE_SKILL_TEMP ]]; then
      rm -rf -- "$REMOTE_SKILL_TEMP"
    fi
    if (( REMOTE_SKILL_ROOT_INVOCATION == 1 )) &&
      [[ -n ${MY_SKILLS_INSTALL_STATE:-} && -f $MY_SKILLS_INSTALL_STATE ]]; then
      rm -f -- "$MY_SKILLS_INSTALL_STATE"
    fi
  }
  trap remote_skill_cleanup EXIT

  if (( force == 1 )); then
    dependency_args+=(--force)
  fi
  if (( skip_update == 1 )); then
    dependency_args+=(--skip-update)
  else
    remote_skill_stage_update
    remote_skill_check_local_changes "$force"
  fi

  for dependency in "${DEPENDENCIES[@]}"; do
    remote_skill_install_dependency "$dependency" "${dependency_args[@]}"
  done

  if (( skip_update == 0 )); then
    remote_skill_sync_payload
  fi
  remote_skill_validate_current

  remote_skill_install_link "Codex" "codex" "$HOME/.agents/skills"
  remote_skill_install_link "Claude Code" "claude" "$HOME/.claude/skills"

  if [[ -z $REMOTE_SKILL_REVISION && -f $SKILL_DIR/.upstream-revision ]]; then
    REMOTE_SKILL_REVISION=$(<"$SKILL_DIR/.upstream-revision")
  fi
  printf '%s\n' "$SKILL_NAME" >>"$MY_SKILLS_INSTALL_STATE"
  printf 'Summary: source=remote skill=%s revision=%s dependencies=%d installed=%d skipped=%d conflicts=%d\n' \
    "$SKILL_NAME" "${REMOTE_SKILL_REVISION:-unknown}" \
    "${#DEPENDENCIES[@]}" "$REMOTE_SKILL_INSTALLED" \
    "$REMOTE_SKILL_SKIPPED" "$REMOTE_SKILL_CONFLICTS"

  (( REMOTE_SKILL_CONFLICTS == 0 )) || return 1
}
