#!/bin/bash

# MIT License Copyright (c) 2018 TKF144 https://github.com/tkf144/basic-arch-installer

function main()
{
	argPause=false
	argResume=false

	[[ "${#@}" < 1 ]] && printUsage "Too few arguments" && return 1
	[[ "${#@}" > 2 ]] && printUsage "Too many arguments" && return 1

	for arg in "$@"
	do
		case $arg in
			--url=*)
				argUrlPath=${arg#*=}
				[[ -z "$argUrlPath" ]] && printUsage "Invalid --url value '${argUrlPath}'" && return 1
				shift
			;;

			--pause)
				argPause=true
				shift
			;;

			--resume)
				argResume=true
				shift
			;;

			'-?'|--help)
				printUsage && return 0
			;;

			*)
				printUsage && return 1
			;;
		esac
	done

	# Errors: unclear/undefined behaviour
	[[ "${argPause}" = true && "${argResume}" = true ]] && printUsage "Invalid combination of --pause and --resume" && return 1
	[[ "${argPause}" = true && -z "${argUrlPath}" ]] && printUsage "Argument --pause requires --url" && return 1
	[[ "${argResume}" = true && -n "${argUrlPath}" ]] && printUsage "Invalid combination of --url and --resume" && return 1

	# Proceed
	resourcesDir=$(pwd)"/installationresources"
	[[ "$argResume" = false ]] && bootstrap "$argUrlPath" "$resourcesDir" || logMessage $? "Bootstrapped installer" || return 1
	[[ "$argPause" = false ]] && initiate "$resourcesDir"
}

function cleanup()
{
	rm -rf $(pwd)"/installationresources"
	logMessage $? "Removed resources directory"
	rm log.txt "bootstrapped.tmp"
	logMessage $? "Removed log.txt and bootstrapped.tmp flag"
}

function bootstrap()
{
	resources=(
		"main.sh"
		"install.sh"
		"configure.sh"
		"settings.ini"
	)

	resourcesUrl="$1"
	resourcesPath="$2"
	log=$(pwd)"/log.txt"

	[[ -e "bootstrapped.tmp" ]] && failMessage "Bootstrap already initiated. See bootstrap.sh --help." && return 1

	touch "bootstrapped.tmp"

	touch $log > /dev/null
	logMessage $? "Created log file '${log}'" || return 1

	mkdir ${resourcesPath} >> $log 2>&1
	logMessage $? "Created resources directory '${resourcesPath}'" || return 1

	for resource in "${resources[@]}"; do
		wget -qO "${resourcesPath}/${resource}" "${resourcesUrl}/${resource}" >> $log 2>&1
		logMessage $? "Retrieved '${resourcesUrl}/${resource}'" || return 1
	done

	chmod 755 ${resourcesPath}/*.sh >> $log 2>&1
	logMessage $? "Set resource files executable" || return 1


	successMessage "Bootstrap complete"
}

function initiate()
{
	[[ ! -e "bootstrapped.tmp" ]] && printUsage "Cannot resume without first initiating bootstrap" && return 1

	successMessage "Initiating installation"

	resourcesPath="$1"
	. "${resourcesPath}/main.sh" "${resourcesPath}" "${log}"
}


function printUsage()
{
	[[ ! -z "${@}" ]] && echo -e "Error: ${@}\n"

	cat <<"EOF"
Basic Arch Installer - Bootstrap 
Retrieve install resources and initiate installation of Arch Linux

Usage:
	bootstrap.sh --url=RESOURCES_URL
		Download resources from --url and initiate installation

	OR

	bootstrap.sh --url=RESOURCES_URL --pause
		Only download resources from --url
	bootstrap.sh --resume
		Only initiate installation

  --url=<URL>	The URL that bootstrap.sh will retrieve resources from
  --pause 	Pause bootstrap after download; don't initiate installation (requires --url)
  --resume  	Resume bootstrap after pause; only initiate installation
  -?, --help  	Print this usage info

MIT License Copyright (c) 2018 TKF144 https://github.com/tkf144/basic-arch-installer
EOF
}

function logMessage()
{
	if [ $1 -eq 0 ]; then
		successMessage "$2"
	else
		failMessage "$2"
		return 1
	fi
}

function successMessage()
{
	GREEN='\033[0;32m'
	NC='\033[0m'
	WIPE_LINE="\r\033[K"
	echo -n -e "${WIPE_LINE}${NC}[  ${GREEN}OK${NC}  ] "
	echo -e $1

	return 0
}

function failMessage()
{
	RED='\033[1;31m'
	NC='\033[0m'
	WIPE_LINE="\r\033[K"
	echo -n -e "${WIPE_LINE}${NC}[ ${RED}FAIL${NC} ] "
	echo -e $1

	return 0
}

function tentativeMessage()
{
	echo -n -e "[	  ] ${1}.."

	return 0
}

function getSetting()
{
	settingName=$1

	egrep "^\s*${settingName}=" "${resourcesPath}/settings.ini" > /dev/null 2>&1
	if [ ! $? -eq 0 ]; then
		return 1
	fi

	value=$(egrep "^\s*${settingName}=" "${resourcesPath}/settings.ini" | sed -E "s/^\s*${settingName}=//" | tr -d "[:space:]")

	if [ -z "$value" ]; then
		return 1
	fi

	echo $value

	return 0
}

export -f logMessage
export -f successMessage
export -f failMessage
export -f tentativeMessage
export -f getSetting

main "$@" \
	&& successMessage "Bootstrapped and initiated installation" \
	|| { failMessage "Bootstrapped and initiated installation"; cleanup; }