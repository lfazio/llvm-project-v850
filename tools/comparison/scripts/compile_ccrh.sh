#!/bin/bash
#
# Compile V850 benchmarks with Renesas CC-RH (CCRH)
#
# Usage: ./compile_ccrh.sh [options] <source_file>
#
# Options:
#   -O<level>    Optimization level (0, 1, 2, 3, s)
#   -mcpu=<cpu>  Target CPU (v850, v850e1, v850e2, v850e2m, rh850g3m)
#   -S           Output assembly only
#   -c           Output object file only
#   -o <file>    Output file name
#
# Environment variables:
#   CCRH_PATH    Path to CC-RH installation (default: searches common locations)
#

set -e

# Default settings
OPT_LEVEL="2"
CPU="g3m"
OUTPUT_TYPE="obj"  # asm, obj
OUTPUT_FILE=""
EXTRA_FLAGS=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LLVM_BUILD="${SCRIPT_DIR}/../../../build-v850"
LLVM_OBJDUMP="${LLVM_OBJDUMP:-${LLVM_BUILD}/bin/llvm-objdump}"

# Find CC-RH compiler
find_ccrh() {
    # Check environment variable first
    if [ -n "$CCRH_PATH" ] && [ -x "$CCRH_PATH/ccrh" ]; then
        echo "$CCRH_PATH/ccrh"
        return 0
    fi

    # Common installation paths (Windows paths via WSL or Wine)
    local SEARCH_PATHS=(
        "/opt/renesas/ccrh"
        "/opt/ccrh"
        "$HOME/ccrh"
        "/mnt/c/Program Files (x86)/Renesas Electronics/CS+"
        "/mnt/c/Renesas/CS+"
    )

    for path in "${SEARCH_PATHS[@]}"; do
        if [ -d "$path" ]; then
            local CCRH=$(find "$path" -name "ccrh" -o -name "ccrh.exe" 2>/dev/null | head -1)
            if [ -n "$CCRH" ] && [ -x "$CCRH" ]; then
                echo "$CCRH"
                return 0
            fi
        fi
    done

    return 1
}

CCRH=$(find_ccrh) || {
    echo "Error: CC-RH compiler not found."
    echo "Please set CCRH_PATH environment variable to CC-RH installation directory."
    echo "Example: export CCRH_PATH=/usr/local/Renesas/CC-RH/V2.07.00/bin"
    exit 1
}
echo "Using CC-RH: $CCRH"

# Map CPU names between LLVM and CCRH conventions
map_cpu() {
    case $1 in
        v850)     echo "-Xcpu=g3m" ;;
        v850e1)   echo "-Xcpu=g3m" ;;
        v850e2)   echo "-Xcpu=g3m" ;;
        v850e2m)  echo "-Xcpu=g3m" ;;
        g3m)      echo "-Xcpu=g3m" ;;
        g3mh)     echo "-Xcpu=g3mh" ;;
        rh850g3m) echo "-Xcpu=g3m" ;;
        rh850g3mh) echo "-Xcpu=g3mh" ;;
        rh850g4m) echo "-Xcpu=g4m" ;;
        rh850g4mh) echo "-Xcpu=g4mh" ;;
        *)        echo "-Xcpu=$1" ;;
    esac
}

# Map optimization levels
map_opt() {
    case $1 in
        0)  echo "-Onothing" ;;
        1)  echo "-Odefault" ;;
        2)  echo "-Ospeed" ;;
        3)  echo "-Ospeed" ;;
        s)  echo "-Osize" ;;
        z)  echo "-Osize" ;;
        *)  echo "-Odefault" ;;
    esac
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -O*)
            OPT_LEVEL="${1#-O}"
            shift
            ;;
        -Xcpu=*)
            CPU="${1#-Xcpu=}"
            shift
            ;;
        -S)
            OUTPUT_TYPE="asm"
            shift
            ;;
        -c)
            OUTPUT_TYPE="obj"
            shift
            ;;
        -o)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -*)
            EXTRA_FLAGS="$EXTRA_FLAGS $1"
            shift
            ;;
        *)
            SOURCE_FILE="$1"
            shift
            ;;
    esac
done

if [ -z "$SOURCE_FILE" ]; then
    echo "Usage: $0 [options] <source_file>"
    exit 1
fi

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Source file not found: $SOURCE_FILE"
    exit 1
fi

# Determine output file name
BASENAME=$(basename "$SOURCE_FILE" .c)
if [ -z "$OUTPUT_FILE" ]; then
    if [ "$OUTPUT_TYPE" = "asm" ]; then
        OUTPUT_FILE="${BASENAME}_ccrh.s"
    else
        OUTPUT_FILE="${BASENAME}_ccrh.o"
    fi
fi

# Map options to CC-RH format
CPU_FLAG=$(map_cpu "$CPU")
OPT_FLAG=$(map_opt "$OPT_LEVEL")

# Common CC-RH flags
# -Xcommon=rh850 : Use RH850 common object format
# -g : Debug info (useful for analysis)
# -Xasm : Output assembly listing
COMMON_FLAGS="$CPU_FLAG $OPT_FLAG"
COMMON_FLAGS="$COMMON_FLAGS -Xcommon=rh850 -lang=c99 "
COMMON_FLAGS="$COMMON_FLAGS $EXTRA_FLAGS"
COMMON_FLAGS="$COMMON_FLAGS -I$CCRH_PATH/../inc"

echo "Compiling: $SOURCE_FILE"
echo "  Target: $CPU"
echo "  Optimization: -O$OPT_LEVEL ($OPT_FLAG)"
echo "  Output: $OUTPUT_FILE"

if [ "$OUTPUT_TYPE" = "asm" ]; then
    # Generate assembly listing
    $CCRH $COMMON_FLAGS -S "$SOURCE_FILE" -o"${OUTPUT_FILE%.asm}"
    # Move/rename the .asm file if generated differently
    if [ -f "${BASENAME}.asm" ]; then
        mv "${BASENAME}.asm" "$OUTPUT_FILE"
    fi
else
    $CCRH $COMMON_FLAGS -c "$SOURCE_FILE" -o"$OUTPUT_FILE"
fi

echo "Done."
