#!/bin/bash

# MIT License Copyright (c) 2018 TKF144 https://github.com/tkf144/basic-arch-installer

resources=(
	"install.sh"
	"configure.sh"
	"settings.ini"
	"workman.map"
)

function main()
{
	resourcesUrl="$1"
	resourcesPath=$(pwd)"/installationResources"
	log=$(pwd)"/log.txt"

	touch $log > /dev/null
	logMessage $? "Created log file '${log}'"

	mkdir ${resourcesPath} >> $log 2>&1
	logMessage $? "Created resources path '${resourcesPath}'"

	for resource in "${resources[@]}"; do
		wget -qO "${resourcesPath}/${resource}" "${resourcesUrl}/${resource}" >> $log 2>&1
		logMessage $? "Retrieved '${resourcesUrl}/${resource}'" || return 1
	done

	chmod 755 ${resourcesPath}/*.sh >> $log 2>&1
	logMessage $? "Set resource files executable"

	successMessage "Bootstrap complete; retrieved resources and handed off to install.sh\n"

	. "${resourcesPath}/install.sh" "${resourcesPath}" "${log}"
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
	echo -n -e "[      ] ${1}.."

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

main "$@"