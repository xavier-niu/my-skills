#!/usr/bin/env bash

set -euo pipefail

SKILL_SOURCE="remote"
SKILL_NAME="qu-ai-wei"
REMOTE_URL="https://github.com/LifelongLazyLearner/qu-ai-wei.git"
REMOTE_REF="main"
REMOTE_PATH="."
REMOTE_INCLUDE_PATHS=("SKILL.md" "agents" "references" "LICENSE")
REMOTE_ROOT_PATHS=()
DEPENDENCIES=()

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd -P)
SKILL_DIR="$SCRIPT_DIR"

# shellcheck source=../scripts/remote-skill-install.sh
source "$PROJECT_ROOT/scripts/remote-skill-install.sh"
run_remote_skill_installer "$@"
