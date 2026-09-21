#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'Usage: %s\n' "${0##*/}"
  printf 'List installed agent skills, grouped by declared skill name.\n'
}

if (( $# > 0 )); then
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
fi

: "${HOME:?HOME must be set}"

declare -a AGENT_NAMES=()
declare -a AGENT_ROOTS=()

add_agent_root() {
  local agent_name=$1
  local root=$2
  local index

  for index in ${AGENT_ROOTS[@]+"${!AGENT_ROOTS[@]}"}; do
    if [[ ${AGENT_ROOTS[$index]} == "$root" ]]; then
      return
    fi
  done

  AGENT_NAMES+=("$agent_name")
  AGENT_ROOTS+=("$root")
}

# Current Codex user location, followed by profile/legacy and admin locations.
add_agent_root "Codex" "$HOME/.agents/skills"
if [[ -n ${CODEX_HOME:-} ]]; then
  add_agent_root "Codex" "$CODEX_HOME/skills"
fi
add_agent_root "Codex" "$HOME/.codex/skills"
add_agent_root "Codex" "/etc/codex/skills"

# Other supported coding-agent user locations.
add_agent_root "Claude Code" "$HOME/.claude/skills"

read_skill_name() {
  local skill_file=$1
  local name
  local first
  local last

  name=$(awk '
    NR == 1 {
      sub(/\r$/, "")
      if ($0 != "---") exit
      in_frontmatter = 1
      next
    }
    in_frontmatter && /^---\r?$/ { exit }
    in_frontmatter && /^name:[[:space:]]*/ {
      sub(/^name:[[:space:]]*/, "")
      sub(/\r$/, "")
      print
      exit
    }
  ' "$skill_file")

  name="${name#"${name%%[![:space:]]*}"}"
  name="${name%"${name##*[![:space:]]}"}"

  if (( ${#name} >= 2 )); then
    first=${name:0:1}
    last=${name: -1}
    if [[ ( $first == '"' && $last == '"' ) ||
          ( $first == "'" && $last == "'" ) ]]; then
      name=${name:1:${#name}-2}
    fi
  fi

  name=${name//$'\t'/ }
  printf '%s\n' "$name"
}

# Indexed arrays keep the inventory compatible with macOS Bash 3.2.
declare -a SKILL_NAMES=()
declare -a AGENTS_BY_SKILL=()
declare -a PATHS_BY_SKILL=()
declare -a SEEN_AGENT=()
declare -a SEEN_PATH=()

record_skill() {
  local skill_name=$1
  local agent_name=$2
  local install_path=$3
  local separator=$'\034'
  local agent_key="${skill_name}${separator}${agent_name}"
  local path_key="${skill_name}${separator}${install_path}"
  local index=0
  local key
  local seen=0

  while (( index < ${#SKILL_NAMES[@]} )); do
    [[ ${SKILL_NAMES[$index]} == "$skill_name" ]] && break
    index=$((index + 1))
  done
  if (( index == ${#SKILL_NAMES[@]} )); then
    SKILL_NAMES+=("$skill_name")
    AGENTS_BY_SKILL+=("")
    PATHS_BY_SKILL+=("")
  fi

  for key in ${SEEN_AGENT[@]+"${SEEN_AGENT[@]}"}; do
    [[ $key == "$agent_key" ]] && seen=1
  done
  if (( seen == 0 )); then
    AGENTS_BY_SKILL[$index]+="${AGENTS_BY_SKILL[$index]:+, }$agent_name"
    SEEN_AGENT+=("$agent_key")
  fi

  seen=0
  for key in ${SEEN_PATH[@]+"${SEEN_PATH[@]}"}; do
    [[ $key == "$path_key" ]] && seen=1
  done
  if (( seen == 0 )); then
    PATHS_BY_SKILL[$index]+="${PATHS_BY_SKILL[$index]:+; }$install_path"
    SEEN_PATH+=("$path_key")
  fi
}

for index in ${AGENT_ROOTS[@]+"${!AGENT_ROOTS[@]}"}; do
  root=${AGENT_ROOTS[$index]}
  agent=${AGENT_NAMES[$index]}

  [[ -d $root ]] || continue

  while IFS= read -r -d '' skill_file; do
    install_path=${skill_file%/SKILL.md}
    skill_name=$(read_skill_name "$skill_file")
    if [[ -z $skill_name ]]; then
      skill_name=${install_path##*/}
    fi
    record_skill "$skill_name" "$agent" "$install_path"
  done < <(
    find -L "$root" -mindepth 2 -maxdepth 3 -type f -name SKILL.md -print0 \
      2>/dev/null || true
  )
done

if (( ${#AGENTS_BY_SKILL[@]} == 0 )); then
  printf 'No installed skills found in known coding-agent directories.\n'
  exit 0
fi

name_width=4
agent_width=13

for index in "${!SKILL_NAMES[@]}"; do
  skill_name=${SKILL_NAMES[$index]}
  agents=${AGENTS_BY_SKILL[$index]}
  (( ${#skill_name} > name_width )) && name_width=${#skill_name}
  (( ${#agents} > agent_width )) && agent_width=${#agents}
done

printf '%-*s  %-*s  %s\n' \
  "$name_width" "NAME" "$agent_width" "CODING AGENTS" "INSTALLED PATHS"

while IFS= read -r skill_name; do
  for index in "${!SKILL_NAMES[@]}"; do
    [[ ${SKILL_NAMES[$index]} == "$skill_name" ]] || continue
    printf '%-*s  %-*s  %s\n' \
      "$name_width" "$skill_name" \
      "$agent_width" "${AGENTS_BY_SKILL[$index]}" \
      "${PATHS_BY_SKILL[$index]}"
    break
  done
done < <(printf '%s\n' "${SKILL_NAMES[@]}" | LC_ALL=C sort)
