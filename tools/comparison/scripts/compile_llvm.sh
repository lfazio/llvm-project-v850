#!/bin/bash
#
# Compile V850 benchmarks with LLVM/Clang
#
# Usage: ./compile_llvm.sh [options] <source_file>
#
# Options:
#   -O<level>    Optimization level (0, 1, 2, 3, s, z)
#   -mcpu=<cpu>  Target CPU (v850, v850e1, v850e2, v850e2m, g3m, g3mh)
#   -S           Output assembly only
#   -c           Output object file only
#   -o <file>    Output file name
#

set -e

# Default settings
OPT_LEVEL="-O2"
CPU="v850e2m"
OUTPUT_TYPE="obj"  # asm, obj
OUTPUT_FILE=""
EXTRA_FLAGS=""

# Find LLVM tools
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LLVM_BUILD="${SCRIPT_DIR}/../../../build-v850"
CLANG="${CLANG:-${LLVM_BUILD}/bin/clang}"
LLC="${LLC:-${LLVM_BUILD}/bin/llc}"
LLVM_OBJDUMP="${LLVM_OBJDUMP:-${LLVM_BUILD}/bin/llvm-objdump}"

echo $LLVM_OBJDUMP

# Check if tools exist
if [ ! -x "$CLANG" ]; then
    # Try system clang with V850 support
    if command -v clang &> /dev/null; then
        CLANG="clang"
    else
        echo "Error: clang not found at $CLANG"
        exit 1
    fi
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -O*)
            OPT_LEVEL="$1"
            shift
            ;;
        -mcpu=*)
            CPU="${1#-mcpu=}"
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
        OUTPUT_FILE="${BASENAME}_llvm.s"
    else
        OUTPUT_FILE="${BASENAME}_llvm.o"
    fi
fi

# Common flags
COMMON_FLAGS="-target v850-unknown-elf -mcpu=$CPU $OPT_LEVEL"
COMMON_FLAGS="$COMMON_FLAGS -ffreestanding -fno-math-errno"
COMMON_FLAGS="$COMMON_FLAGS -Wall -Wextra"
COMMON_FLAGS="$COMMON_FLAGS $EXTRA_FLAGS"

echo "Compiling: $SOURCE_FILE"
echo "  Target: v850-unknown-elf ($CPU)"
echo "  Optimization: $OPT_LEVEL"
echo "  Output: $OUTPUT_FILE"

if [ "$OUTPUT_TYPE" = "asm" ]; then
    $CLANG $COMMON_FLAGS -S "$SOURCE_FILE" -o "$OUTPUT_FILE"
else
    $CLANG $COMMON_FLAGS -c "$SOURCE_FILE" -o "$OUTPUT_FILE"
fi

echo "Done."

# Optionally generate disassembly for object files
if [ "$OUTPUT_TYPE" = "obj" ] && [ -x "$LLVM_OBJDUMP" ]; then
    DISASM_FILE="${OUTPUT_FILE%.o}.dis"
    echo $LLVM_OBJDUMP -mcpu=$CPU -d "$OUTPUT_FILE"
    $LLVM_OBJDUMP --mcpu=$CPU -d "$OUTPUT_FILE" > "$DISASM_FILE" 2>/dev/null || true
    echo "Disassembly: $DISASM_FILE"
fi
