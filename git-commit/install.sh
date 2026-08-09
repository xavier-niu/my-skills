#!/usr/bin/env bash

set -euo pipefail

SKILL_SOURCE="local"
SKILL_NAME="git-commit"
DEPENDENCIES=()

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd -P)
SKILL_DIR="$SCRIPT_DIR"

# shellcheck source=../scripts/local-skill-install.sh
source "$PROJECT_ROOT/scripts/local-skill-install.sh"
run_local_skill_installer "$@"
