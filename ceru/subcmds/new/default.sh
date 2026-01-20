#!/usr/bin/env bash
# Copyright 2025 Emile Clark-Boman
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

USAGE="${BOLD}${UNDERLINE}${RED}Usage${RESET}
	${BOLD}${GREEN}$THIS new [option...] subcommand${RESET}

${BOLD}${UNDERLINE}${RED}Options${RESET}
	${BOLD}${MAGENTA}-h, --help${RESET}               Show this message (^_^)

${BOLD}${UNDERLINE}${RED}Subcommands${RESET}
	${BOLD}${CYAN}cache-key${RESET}                      Generate a new binary-cache signing keypair
	${BOLD}${CYAN}ssh-key${RESET}                        Generate a new SSH RSA-4096 keypair"

# parse all args
SUBCMD=false # where a subcommand was specified
while [[ $# -gt 0 ]]; do
	ARG=$1
	case $ARG in
		-h|--help)
			throw-usage 0 ;;
		-*)
			echo "[!] Unknown option \"$ARG\""
			exit 1 ;;
		*)
			SUBCMD=true
			break ;;
	esac
done; unset -v ARG

# invalid usage occurs if no args or subcommand given
if [[ $# = 0 || "$SUBCMD" = false ]]; then
	throw-usage 1
fi; unset -v SUBCMD

# run provided subcommand
run-subcmd "$@"
