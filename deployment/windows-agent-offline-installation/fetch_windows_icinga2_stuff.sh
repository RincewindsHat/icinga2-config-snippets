#!/usr/bin/bash


set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Script description here.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-f, --flag      Some flag description
-p, --param     Some param description
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}


setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

parse_params() {
  # default values of variables set from params
  directory=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    --no-color) NO_COLOR=1 ;;
    -d | --directory)
      directory="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done


  # check required params and arguments
  [[ -z "${directory-}" ]] && die "Missing required parameter: directory"

  return 0
}

checkmark () {
	msg "${GREEN}[x]${NOFORMAT}"
}

parse_params "$@"
setup_colors

#msg "${RED}Read parameters:${NOFORMAT}"
#msg "- directory: ${directory}"

if [ ! -d "$directory" ]; then
	die "${RED}Failure: $directory is not a directory"
fi


echo -n "Downloading Kickstart script: "
FILENAME="icinga-powershell-kickstart.ps1"
if (curl -s "https://raw.githubusercontent.com/Icinga/icinga-powershell-kickstart/master/script/$FILENAME" --output "$directory/icinga-powershell-kickstart.ps1"); then
	checkmark
else
	msg "{RED}failed${NOFORMAT}"
fi


PS_FRAMEWORK_VERSION=$(curl "https://github.com/Icinga/icinga-powershell-framework/releases/latest"  2> /dev/null   | sed 's/.\+tag\///' | sed 's/".\+//')
echo -n "Framework version: $PS_FRAMEWORK_VERSION: "
mkdir "$directory/Powershell_framework"
if (curl -s "https://github.com/Icinga/icinga-powershell-framework/archive/$PS_FRAMEWORK_VERSION.zip" --output "$directory/Powershell_framework/$PS_FRAMEWORK_VERSION"); then
	checkmark
else
	msg "{RED}failed${NOFORMAT}"
fi


PS_PLUGINS_VERSION=$(curl "https://github.com/Icinga/icinga-powershell-plugins/releases/latest"  2> /dev/null   | sed 's/.\+tag\///' | sed 's/".\+//')
echo -n "Plugins version: $PS_PLUGINS_VERSION: "
mkdir "$directory/Powershell_plugins"
if (curl -s "https://github.com/Icinga/icinga-powershell-plugins/archive/$PS_PLUGINS_VERSION.zip" --output "$directory/Powershell_plugins/$PS_PLUGINS_VERSION"); then
	checkmark
else
	msg "{RED}failed${NOFORMAT}"
fi


PS_SERVICE_VERSION=$(curl "https://github.com/Icinga/icinga-powershell-service/releases/latest"  2> /dev/null   | sed 's/.\+tag\///' | sed 's/".\+//')
echo -n "Service version: $PS_SERVICE_VERSION: "
mkdir "$directory/Powershell_service"
# https://github.com/Icinga/icinga-powershell-service/releases/download/v1.1.0/icinga-service-v1.1.0.zip
if (curl -s  "https://github.com/Icinga/icinga-powershell-service/releases/download/$PS_SERVICE_VERSION/icinga-service-$PS_SERVICE_VERSION.zip" --output "$directory/Powershell_service/$PS_SERVICE_VERSION"); then
	checkmark
else
	msg "{RED}failed${NOFORMAT}"
fi

# TODO Get version dynamically
ICINGA2_VERSION=$(curl -s "https://packages.icinga.com/windows/" | grep 'Icinga2.\+64.msi' | grep -v snapshot | sed 's/^.\+Icinga2-//' | sed 's/\-x86_64.msi.\+$//' | sort | head -n 1)
echo -n "Icinga Agent for Windows $ICINGA2_VERSION: "
if (curl -s "https://packages.icinga.com/windows/Icinga2-$ICINGA2_VERSION-x86_64.msi" --output "$directory/Icinga2-$ICINGA2_VERSION-x86_64.msi"); then
	checkmark
else
	msg "{RED}failed${NOFORMAT}"
fi
