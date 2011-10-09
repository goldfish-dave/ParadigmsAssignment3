#!/bin/bash
set -e
BUILD_DIR=build

if [ ${#} != 1 ]; then
	echo "Usage: ${0} filename.vpl" >&2
	exit 1
fi

#java -cp antlr-3.1.2.jar org.antlr.Tool -o ${BUILD_DIR} VPL.g

java org.antlr.Tool -o ${BUILD_DIR} VPL.g
touch ${BUILD_DIR}/__init__.py

./vpl2asm.py < ${1} > ${1}.s

cat ${1}.s
#gcc -Wall -W main.c ${1}.s -o my_program
