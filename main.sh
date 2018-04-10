#!/bin/bash

# MIT License Copyright (c) 2018 TKF144 https://github.com/tkf144/basic-arch-installer

function main()
{


	return 0
}

main "$@" \
	&& successMessage "Main complete" \
	|| failMessage "Main failed. See ${2} (tail below)."