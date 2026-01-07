#!/usr/bin/env bash
set -euo pipefail
USAGE="${BOLD}${UNDERLINE}${RED}Usage${RESET}
	${BOLD}${GREEN}$THIS new [option...] subcommand${RESET}

${BOLD}${UNDERLINE}${RED}Options${RESET}
	${BOLD}${MAGENTA}-h, --help${RESET}               Show this message (^_^)

${BOLD}${UNDERLINE}${RED}Subcommands${RESET}
	${BOLD}${CYAN}key${RESET}                      Generate a new binary-cache signing keypair"

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
