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

# libceru relies on the script that sources
# it to set the following environment variables:
#     CMD_NAME USAGE

set -u

# ======== INTERNAL STATE ========
SUBCMDS="$PWD/subcmds" # XXX: TODO: don't hardcode as relative
CMD_ABS="$SUBCMDS" # (initial value) CMD_ABS stores the current cmd's absolute path
CMD_MAJ="$THIS"    # (initial value) CMD_MAJ stores the current cmd's parent's name
CMD_MIN=""         # (initial value) CMD_MIN stores the current cmd's name
# ======== INTERNAL STATE ========

# ANSI Coloring
BLACK='\033[30m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
DEFCOL='\033[39m' # default colour

# ANSI Styling
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
BLINKSLOW='\033[5m'
BLINKFAST='\033[6m'
REVERSE='\033[7m'
INVISIBLE='\033[8m'

# Error Messages
function perr            { echo -e "${BOLD}${RED}error:${WHITE} $@\n${BOLD}${GREEN}[+]${WHITE} Try ${GREEN}'--help'${WHITE} for more information." >&2; }
function perr-usage      { echo -e "$USAGE\n" >&2; }
function perr-badflag    { perr "unrecognised flag ${BOLD}${MAGENTA}'$1'${RESET}"; }
function perr-noflagval  { perr "flag ${BOLD}${MAGENTA}'$1'${RESET} requires ${BOLD}${MAGENTA}${2}${RESET} argument(s), but only ${BOLD}${MAGENTA}${3}${RESET} were given"; }
function perr-badarg     { perr "unrecognised arg ${BOLD}${MAGENTA}'$1'${RESET}"; }
function perr-noarg      { perr "required argument ${BOLD}${MAGENTA}'$1'${RESET} is missing"; }
function perr-badval     { perr "value ${MAGENTA}\"$1\"${WHITE} is not valid for flag ${CYAN}$2${RESET}"; }
# Failures
function throw           { echo -e "${@:2}" >&2; if [[ "$1" -ge 0 ]]; then exit "$1"; fi; }
function throw-usage     { throw "$1" "$(perr-usage               2>&1)\n"; }
function throw-badflag   { throw "$1" "$(perr-badflag   "${@:2}"  2>&1)"; }
function throw-noflagval { throw "$1" "$(perr-noflagval "${@:2}"  2>&1)"; }
function throw-badarg    { throw "$1" "$(perr-badarg    "${@:2}"  2>&1)"; }
function throw-noarg     { throw "$1" "$(perr-noarg     "${@:2}"  2>&1)"; }
function throw-badval    { throw "$1" "$(perr-badval "$2" "$3"    2>&1)"; }
# Parsing/Validation
function required { [[ -n "$1" ]] || throw-noarg 1 "${@:2}"; }

# Other
function confirm-action {
  local CHAR
  while :; do
    echo -e "$1"
    read -n1 CHAR
    case $CHAR in
      [yY])
        return 0 ;;
      [nN])
        return 1 ;;
    esac
  done
}
function confirm { confirm-action ":: Proceed? [Y/n]  "; }

function confirm-file-overwrite {
  local OVERWRITE=false
  local ARG
  for ARG in "$@"; do
    if [[ -f "$ARG" ]]; then
      # write info (initial) lines on first overwritable file found
      if [[ "$OVERWRITE" = false ]]; then
        echo -e "${BOLD}${UNDERLINE}${BLINKFAST}${RED}WARNING!${RESET} ${YELLOW}The following files will be overwritten:${RESET}"
        OVERWRITE=true
      fi
      # list all files that require overwriting
      echo -e "${BOLD}	• ${GREEN}${ARG}${RESET}"
    fi
  done 
	[[ "$OVERWRITE" = false ]] || confirm
}

function isnumeric { [[ "$1" =~ ^[0-9]+$ ]]; }

# ====== Core ======
function run-subcmd {
  # if CMD_MIN is empty, then CMD_MAJ is the root cmd (ie ceru)
  # and hence CMD_MAJ shouldn't yet be overridden
  if [[ ! "$CMD_MIN" = "" ]]; then
    CMD_MAJ="$CMD_MIN" # swapsies!
  fi
  # we shift here so $@ is passed correctly when we `source "$TARGET"`
  CMD_MIN="$1"; shift

  # ensure the current command can take subcommands
  if [[ -f "$CMD_ABS" ]]; then
    # XXX: INTERNAL ERROR
    throw 2 "Subcommand \"$CMD_MIN\" cannot exist, as $CMD_MAJ has no subcommands!"
  fi

  CMD_ABS="$CMD_ABS/$CMD_MIN"

  # attempt to find the script corresponding to CMD_ABS
  TARGET="$CMD_ABS"
  if [[ -d "$CMD_ABS" ]]; then
    TARGET="$TARGET/default.sh"
  elif [[ ! -f "$CMD_ABS" ]]; then
      throw 1 "Command \"$CMD_MAJ\" does not provide subcommand \"$CMD_MIN\"!"
  fi
  source "$TARGET"
}
