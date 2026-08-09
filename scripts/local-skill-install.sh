#!/usr/bin/env bash

# Shared implementation for project-owned local skill installers.
# The calling install.sh must define all configuration variables before sourcing
# this file, then call run_local_skill_installer "$@".

local_skill_fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

local_skill_read_name() {
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

local_skill_validate() {
  local declared_name

  [[ -f $SKILL_DIR/SKILL.md ]] ||
    local_skill_fail "missing $SKILL_NAME/SKILL.md"
  declared_name=$(local_skill_read_name "$SKILL_DIR/SKILL.md")
  [[ $declared_name == "$SKILL_NAME" ]] ||
    local_skill_fail \
      "local skill name '$declared_name' does not match '$SKILL_NAME'"
}

local_skill_install_dependency() {
  local dependency=$1
  shift
  local installer

  [[ $dependency =~ ^[a-z0-9][a-z0-9-]*$ ]] ||
    local_skill_fail "invalid dependency name: $dependency"
  installer="$PROJECT_ROOT/$dependency/install.sh"
  [[ -x $installer ]] ||
    local_skill_fail "missing executable dependency installer: $installer"

  printf 'Installing dependency %s for %s...\n' "$dependency" "$SKILL_NAME"
  "$installer" "$@"
}

local_skill_install_link() {
  local agent_name=$1
  local executable=$2
  local skill_root=$3
  local target="$skill_root/$SKILL_NAME"
  local resolved

  if ! command -v "$executable" >/dev/null 2>&1; then
    printf 'Skipped %s: executable %s is absent.\n' \
      "$agent_name" "$executable"
    LOCAL_SKILL_SKIPPED=$((LOCAL_SKILL_SKIPPED + 1))
    return
  fi

  mkdir -p "$skill_root"
  if [[ -L $target ]]; then
    resolved=$(readlink -f -- "$target" 2>/dev/null || true)
    if [[ $resolved == "$SKILL_DIR" ]]; then
      printf 'Installed %s: %s already points to this skill.\n' \
        "$agent_name" "$target"
      LOCAL_SKILL_INSTALLED=$((LOCAL_SKILL_INSTALLED + 1))
      return
    fi
    printf 'Conflict for %s: %s points elsewhere; left unchanged.\n' \
      "$agent_name" "$target" >&2
    LOCAL_SKILL_CONFLICTS=$((LOCAL_SKILL_CONFLICTS + 1))
    return
  fi

  if [[ -e $target ]]; then
    printf 'Conflict for %s: %s already exists; left unchanged.\n' \
      "$agent_name" "$target" >&2
    LOCAL_SKILL_CONFLICTS=$((LOCAL_SKILL_CONFLICTS + 1))
    return
  fi

  ln -s "$SKILL_DIR" "$target"
  printf 'Installed %s: %s -> %s\n' "$agent_name" "$target" "$SKILL_DIR"
  LOCAL_SKILL_INSTALLED=$((LOCAL_SKILL_INSTALLED + 1))
}

run_local_skill_installer() {
  local dependency
  local -a dependency_args=()

  while (( $# > 0 )); do
    case "$1" in
      --force|--skip-update) dependency_args+=("$1") ;;
      -h|--help)
        printf 'Usage: %s [--force] [--skip-update]\n' "${0##*/}"
        return
        ;;
      *) local_skill_fail "unknown argument: $1" ;;
    esac
    shift
  done

  [[ ${SKILL_SOURCE:-} == local ]] ||
    local_skill_fail "SKILL_SOURCE must be local"
  [[ -n ${SKILL_NAME:-} ]] ||
    local_skill_fail "local installer configuration is incomplete"
  declare -p DEPENDENCIES >/dev/null 2>&1 ||
    local_skill_fail "DEPENDENCIES array is missing"

  case ":${MY_SKILLS_INSTALL_STACK:-}:" in
    *":$SKILL_NAME:"*)
      local_skill_fail \
        "dependency cycle detected: ${MY_SKILLS_INSTALL_STACK:-}:$SKILL_NAME"
      ;;
  esac

  if [[ -z ${MY_SKILLS_INSTALL_STATE:-} ]]; then
    MY_SKILLS_INSTALL_STATE=$(mktemp)
    export MY_SKILLS_INSTALL_STATE
    LOCAL_SKILL_ROOT_INVOCATION=1
  else
    LOCAL_SKILL_ROOT_INVOCATION=0
  fi
  [[ -f $MY_SKILLS_INSTALL_STATE ]] ||
    local_skill_fail "dependency state file is missing"

  if grep -Fxq -- "$SKILL_NAME" "$MY_SKILLS_INSTALL_STATE"; then
    printf 'Dependency %s was already installed in this run.\n' "$SKILL_NAME"
    return
  fi

  export MY_SKILLS_INSTALL_STACK="${MY_SKILLS_INSTALL_STACK:+$MY_SKILLS_INSTALL_STACK:}$SKILL_NAME"
  LOCAL_SKILL_INSTALLED=0
  LOCAL_SKILL_SKIPPED=0
  LOCAL_SKILL_CONFLICTS=0

  local_skill_cleanup() {
    if (( LOCAL_SKILL_ROOT_INVOCATION == 1 )) &&
      [[ -n ${MY_SKILLS_INSTALL_STATE:-} && -f $MY_SKILLS_INSTALL_STATE ]]; then
      rm -f -- "$MY_SKILLS_INSTALL_STATE"
    fi
  }
  trap local_skill_cleanup EXIT

  local_skill_validate
  for dependency in "${DEPENDENCIES[@]}"; do
    local_skill_install_dependency "$dependency" "${dependency_args[@]}"
  done

  local_skill_install_link "Codex" "codex" "$HOME/.agents/skills"
  local_skill_install_link "Claude Code" "claude" "$HOME/.claude/skills"

  printf '%s\n' "$SKILL_NAME" >>"$MY_SKILLS_INSTALL_STATE"
  printf 'Summary: source=local skill=%s dependencies=%d installed=%d skipped=%d conflicts=%d\n' \
    "$SKILL_NAME" "${#DEPENDENCIES[@]}" "$LOCAL_SKILL_INSTALLED" \
    "$LOCAL_SKILL_SKIPPED" "$LOCAL_SKILL_CONFLICTS"

  (( LOCAL_SKILL_CONFLICTS == 0 )) || return 1
}
