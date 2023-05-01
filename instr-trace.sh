#!/bin/bash

readonly G_SCRIPT_NAME="$(basename $(realpath $0))"

function write_gdb_script
{
	local MY_PID="$1"
	local MAX_INSTR="$2"
	local GDB_SCRIPT="$3"
	
echo "set print demangle
set print asm-demangle
set disassembly-flavor intel

set \$i = 0
set \$max_instr = ${MAX_INSTR}

attach ${MY_PID}

while (\$i < \$max_instr)
	x/i \$pc
	stepi
	set \$i = \$i + 1
end

detach
quit" > "${GDB_SCRIPT}"
}

function run_gdb
{
	local GDB_BIN="$1"
	local GDB_SCRIPT="$2"
	local TRACE_FILE="$3"
	
	echo "${G_SCRIPT_NAME}: trace file is ${TRACE_FILE}"
	gdb --batch -x "${GDB_SCRIPT}" 2>/dev/null | grep '^=>' > "${TRACE_FILE}"
}

function cleanup
{
	local GDB_SCRIPT="$1"
	
	rm "${GDB_SCRIPT}"
}

function get_instr_trace
{
	local MY_PID="$1"
	local MAX_INSTR="$2"
	local TRACE_FILE="gdb.${MY_PID}.itrace"
	
	local GDB_BIN=""
	GDB_BIN="$(which gdb)"
	if [ "$?" -ne 0 ]; then
		echo "${G_SCRIPT_NAME}: error: no gdb found on the system" >&2
		exit 1
	fi
	
	local GDB_SCRIPT=""
	GDB_SCRIPT="$(mktemp)"
	if [ "$?" -ne 0 ]; then
		echo "${G_SCRIPT_NAME}: error: could not create temp file" >&2
		exit 1
	fi
	
	write_gdb_script "${MY_PID}" "${MAX_INSTR}" "${GDB_SCRIPT}"
	run_gdb "${GDB_BIN}" "${GDB_SCRIPT}" "${TRACE_FILE}"
	cleanup "${GDB_SCRIPT}"
}

function main
{
	if [ "$#" -ne 2 ]; then
		echo "Use: ${G_SCRIPT_NAME} <pid> <number-of-instrucions>" >&2
		exit 1
	fi
	
	get_instr_trace "$1" "$2"
}

main "$@"
