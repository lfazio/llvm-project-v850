#!/usr/bin/env python3
"""
V850 Cycle Estimation Tool

Analyzes V850 assembly and estimates execution cycles based on
instruction timing data from V850CycleTimings.md.

Usage:
    ./estimate_cycles.py <assembly_file> [--cpu=v850e2m]
"""

import re
import sys
import argparse
from dataclasses import dataclass
from typing import Dict, List, Tuple, Optional

@dataclass
class InsnTiming:
    """Instruction timing: issue-repeat-latency cycles"""
    issue: int
    repeat: int
    latency: int

    def __str__(self):
        return f"{self.issue}-{self.repeat}-{self.latency}"

# Timing tables for V850E2M (most common target)
# Format: instruction pattern -> (issue, repeat, latency)
V850E2M_TIMINGS = {
    # Load instructions (latency depends on cache/memory)
    r'ld\.b': InsnTiming(1, 1, 3),
    r'ld\.h': InsnTiming(1, 1, 3),
    r'ld\.w': InsnTiming(1, 1, 3),
    r'ld\.bu': InsnTiming(1, 1, 3),
    r'ld\.hu': InsnTiming(1, 1, 3),
    r'sld\.b': InsnTiming(1, 1, 3),
    r'sld\.h': InsnTiming(1, 1, 3),
    r'sld\.w': InsnTiming(1, 1, 3),
    r'sld\.bu': InsnTiming(1, 1, 3),
    r'sld\.hu': InsnTiming(1, 1, 3),

    # Store instructions
    r'st\.b': InsnTiming(1, 1, 1),
    r'st\.h': InsnTiming(1, 1, 1),
    r'st\.w': InsnTiming(1, 1, 1),
    r'sst\.b': InsnTiming(1, 1, 1),
    r'sst\.h': InsnTiming(1, 1, 1),
    r'sst\.w': InsnTiming(1, 1, 1),

    # Arithmetic/Move
    r'add\s': InsnTiming(1, 1, 1),
    r'addi\s': InsnTiming(1, 1, 1),
    r'sub\s': InsnTiming(1, 1, 1),
    r'subr\s': InsnTiming(1, 1, 1),
    r'cmp\s': InsnTiming(1, 1, 1),
    r'mov\s': InsnTiming(1, 1, 1),
    r'movea\s': InsnTiming(1, 1, 1),
    r'movhi\s': InsnTiming(1, 1, 1),
    r'setf\s': InsnTiming(1, 1, 1),
    r'sasf\s': InsnTiming(1, 1, 1),
    r'cmov\s': InsnTiming(1, 1, 1),
    r'adf\s': InsnTiming(1, 1, 1),
    r'sbf\s': InsnTiming(1, 1, 1),

    # Saturating arithmetic
    r'satadd\s': InsnTiming(1, 1, 1),
    r'satsub\s': InsnTiming(1, 1, 1),
    r'satsubi\s': InsnTiming(1, 1, 1),
    r'satsubr\s': InsnTiming(1, 1, 1),

    # Logical
    r'and\s': InsnTiming(1, 1, 1),
    r'andi\s': InsnTiming(1, 1, 1),
    r'or\s': InsnTiming(1, 1, 1),
    r'ori\s': InsnTiming(1, 1, 1),
    r'xor\s': InsnTiming(1, 1, 1),
    r'xori\s': InsnTiming(1, 1, 1),
    r'not\s': InsnTiming(1, 1, 1),
    r'tst\s': InsnTiming(1, 1, 1),

    # Shift
    r'shr\s': InsnTiming(1, 1, 1),
    r'sar\s': InsnTiming(1, 1, 1),
    r'shl\s': InsnTiming(1, 1, 1),

    # Data manipulation
    r'bsh\s': InsnTiming(1, 1, 1),
    r'bsw\s': InsnTiming(1, 1, 1),
    r'hsh\s': InsnTiming(1, 1, 1),
    r'hsw\s': InsnTiming(1, 1, 1),
    r'sxb\s': InsnTiming(1, 1, 1),
    r'sxh\s': InsnTiming(1, 1, 1),
    r'zxb\s': InsnTiming(1, 1, 1),
    r'zxh\s': InsnTiming(1, 1, 1),

    # Bit search
    r'sch0l\s': InsnTiming(1, 1, 1),
    r'sch0r\s': InsnTiming(1, 1, 1),
    r'sch1l\s': InsnTiming(1, 1, 1),
    r'sch1r\s': InsnTiming(1, 1, 1),

    # Multiply
    r'mulh\s': InsnTiming(1, 1, 3),
    r'mulhi\s': InsnTiming(1, 1, 3),
    r'mul\s': InsnTiming(1, 1, 3),
    r'mulu\s': InsnTiming(1, 1, 3),
    r'mac\s': InsnTiming(1, 1, 3),
    r'macu\s': InsnTiming(1, 1, 3),

    # Divide (expensive!)
    r'divh\s': InsnTiming(36, 36, 36),
    r'div\s': InsnTiming(36, 36, 36),
    r'divu\s': InsnTiming(35, 35, 35),
    r'divhu\s': InsnTiming(35, 35, 35),
    r'divq\s': InsnTiming(10, 10, 10),  # Average case
    r'divqu\s': InsnTiming(10, 10, 10),

    # Branch (assume 50% taken for estimation)
    r'b[a-z]+\s': InsnTiming(2, 2, 2),  # Average of taken/not taken
    r'b[a-z]+9\s': InsnTiming(2, 2, 2),  # CCRH short branch (9-bit displacement)
    r'jmp\s': InsnTiming(4, 4, 4),
    r'jr\s': InsnTiming(4, 4, 4),
    r'jr22\s': InsnTiming(4, 4, 4),  # CCRH format
    r'jr32\s': InsnTiming(5, 5, 5),  # CCRH format
    r'jarl\s': InsnTiming(4, 4, 4),
    r'jarl22\s': InsnTiming(4, 4, 4),  # CCRH format
    r'jarl32\s': InsnTiming(5, 5, 5),  # CCRH format

    # Bit manipulation (memory access)
    r'set1\s': InsnTiming(4, 4, 4),
    r'clr1\s': InsnTiming(4, 4, 4),
    r'not1\s': InsnTiming(4, 4, 4),
    r'tst1\s': InsnTiming(4, 4, 4),

    # Special
    r'nop': InsnTiming(1, 1, 1),
    r'di': InsnTiming(2, 2, 2),
    r'ei': InsnTiming(2, 2, 2),
    r'halt': InsnTiming(1, 1, 1),
    r'ldsr\s': InsnTiming(2, 2, 4),  # Varies by register
    r'stsr\s': InsnTiming(1, 1, 1),
    r'trap\s': InsnTiming(7, 7, 7),
    r'reti': InsnTiming(7, 7, 7),
    r'prepare\s': InsnTiming(4, 4, 4),  # Varies with register count
    r'dispose\s': InsnTiming(4, 4, 4),
    r'switch\s': InsnTiming(8, 8, 8),
    r'callt\s': InsnTiming(10, 10, 10),
    r'ctret': InsnTiming(7, 7, 7),
    r'syscall\s': InsnTiming(10, 10, 10),
    r'syncp': InsnTiming(1, 1, 1),
    r'syncm': InsnTiming(1, 1, 1),
    r'synce': InsnTiming(1, 1, 1),
}

# FPU timings for V850E2M
FPU_TIMINGS = {
    r'addf\.s': InsnTiming(1, 1, 4),
    r'subf\.s': InsnTiming(1, 1, 4),
    r'mulf\.s': InsnTiming(1, 1, 4),
    r'divf\.s': InsnTiming(1, 17, 17),
    r'cmpf\.s': InsnTiming(1, 1, 2),
    r'absf\.s': InsnTiming(1, 1, 1),
    r'negf\.s': InsnTiming(1, 1, 1),
    r'sqrtf\.s': InsnTiming(1, 17, 17),
    r'maddf\.s': InsnTiming(1, 1, 4),
    r'msubf\.s': InsnTiming(1, 1, 4),
    r'nmaddf\.s': InsnTiming(1, 1, 4),
    r'nmsubf\.s': InsnTiming(1, 1, 4),
    r'minf\.s': InsnTiming(1, 1, 2),
    r'maxf\.s': InsnTiming(1, 1, 2),
    r'cvtf\.': InsnTiming(1, 1, 4),
    r'trncf\.': InsnTiming(1, 1, 4),
    r'ceilf\.': InsnTiming(1, 1, 4),
    r'floorf\.': InsnTiming(1, 1, 4),
    r'roundf\.': InsnTiming(1, 1, 4),

    # Double precision (slower)
    r'addf\.d': InsnTiming(1, 1, 5),
    r'subf\.d': InsnTiming(1, 1, 5),
    r'mulf\.d': InsnTiming(1, 1, 5),
    r'divf\.d': InsnTiming(1, 33, 33),
    r'sqrtf\.d': InsnTiming(1, 33, 33),
}

@dataclass
class FunctionStats:
    """Statistics for a single function"""
    name: str
    insn_count: int
    total_issue: int
    total_latency: int
    load_count: int
    store_count: int
    branch_count: int
    mul_count: int
    div_count: int
    fpu_count: int
    unknown_insns: List[str]

def get_timing(insn: str) -> Optional[InsnTiming]:
    """Get timing for an instruction"""
    insn_lower = insn.lower().strip()

    # Check FPU first
    for pattern, timing in FPU_TIMINGS.items():
        if re.match(pattern, insn_lower):
            return timing

    # Check regular instructions
    for pattern, timing in V850E2M_TIMINGS.items():
        if re.match(pattern, insn_lower):
            return timing

    return None

def is_function_label(line: str, public_symbols: set) -> bool:
    """Check if a line is a function label (not a local label)"""
    if not line.endswith(':'):
        return False

    label = line[:-1]

    # Skip local/internal labels
    if label.startswith('.'):
        return False
    if '.BB.' in label or '.LBB' in label:
        return False

    # Check if it's in the public symbols (for CCRH)
    if public_symbols and label in public_symbols:
        return True

    # For LLVM, check if it's not a local label
    if not public_symbols:
        return True

    return False

def parse_function(lines: List[str], start_idx: int, public_symbols: set = None) -> Tuple[FunctionStats, int]:
    """Parse a single function and return stats"""
    # Get function name from label
    name_match = re.match(r'^(\w+):', lines[start_idx])
    if not name_match:
        name = "unknown"
    else:
        name = name_match.group(1)

    stats = FunctionStats(
        name=name,
        insn_count=0,
        total_issue=0,
        total_latency=0,
        load_count=0,
        store_count=0,
        branch_count=0,
        mul_count=0,
        div_count=0,
        fpu_count=0,
        unknown_insns=[]
    )

    idx = start_idx + 1
    while idx < len(lines):
        line = lines[idx].strip()

        # Skip empty lines and comments
        if not line or line.startswith(';') or line.startswith('#'):
            idx += 1
            continue

        # Skip directives
        if line.startswith('.') or line.startswith('$'):
            # Check for function end
            if '.size' in line and name in line:
                break
            idx += 1
            continue

        # Skip local labels (but not function starts)
        if line.endswith(':'):
            label = line[:-1]
            # Check if this is a new function
            if is_function_label(line, public_symbols):
                break
            idx += 1
            continue

        # New function start (for non-colon matching)
        match = re.match(r'^(\w+):', line)
        if match and is_function_label(line, public_symbols):
            break

        # Parse instruction
        stats.insn_count += 1
        timing = get_timing(line)

        if timing:
            stats.total_issue += timing.issue
            stats.total_latency += timing.latency

            # Categorize
            insn_lower = line.lower()
            if insn_lower.startswith(('ld.', 'sld.')):
                stats.load_count += 1
            elif insn_lower.startswith(('st.', 'sst.')):
                stats.store_count += 1
            elif insn_lower.startswith(('b', 'jmp', 'jr', 'jarl')):
                if not insn_lower.startswith(('bsh', 'bsw')):
                    stats.branch_count += 1
            elif insn_lower.startswith(('mul', 'mac')):
                stats.mul_count += 1
            elif insn_lower.startswith('div'):
                stats.div_count += 1
            elif 'f.' in insn_lower or 'f.s' in insn_lower or 'f.d' in insn_lower:
                stats.fpu_count += 1
        else:
            stats.unknown_insns.append(line)

        idx += 1

    return stats, idx

def analyze_file(filepath: str) -> List[FunctionStats]:
    """Analyze an assembly file and return function statistics"""
    with open(filepath, 'r') as f:
        lines = f.readlines()

    # First pass: collect public symbols (for CCRH format)
    public_symbols = set()
    for line in lines:
        line = line.strip()
        # CCRH format: .public _function_name
        if line.startswith('.public'):
            match = re.match(r'\.public\s+(\w+)', line)
            if match:
                public_symbols.add(match.group(1))
        # LLVM format: .globl function_name
        elif line.startswith('.globl'):
            match = re.match(r'\.globl\s+(\w+)', line)
            if match:
                public_symbols.add(match.group(1))

    functions = []
    idx = 0

    while idx < len(lines):
        line = lines[idx].strip()

        # Look for function start (label followed by instructions)
        if re.match(r'^\w+:', line) and not line.startswith('.'):
            label = line[:-1] if line.endswith(':') else line.split(':')[0]
            # Only parse if it's a public symbol or we have no public symbol info
            if not public_symbols or label in public_symbols:
                stats, idx = parse_function(lines, idx, public_symbols)
                if stats.insn_count > 0:
                    functions.append(stats)
            else:
                idx += 1
        else:
            idx += 1

    return functions

def print_report(functions: List[FunctionStats], filename: str):
    """Print analysis report"""
    print("=" * 80)
    print(f"V850 Cycle Estimation Report")
    print(f"File: {filename}")
    print("=" * 80)
    print()

    # Summary
    total_insns = sum(f.insn_count for f in functions)
    total_issue = sum(f.total_issue for f in functions)
    total_latency = sum(f.total_latency for f in functions)
    total_loads = sum(f.load_count for f in functions)
    total_stores = sum(f.store_count for f in functions)
    total_branches = sum(f.branch_count for f in functions)
    total_muls = sum(f.mul_count for f in functions)
    total_divs = sum(f.div_count for f in functions)
    total_fpus = sum(f.fpu_count for f in functions)

    print(f"Summary:")
    print(f"  Functions analyzed: {len(functions)}")
    print(f"  Total instructions: {total_insns}")
    print(f"  Estimated issue cycles: {total_issue}")
    print(f"  Estimated latency cycles: {total_latency}")
    print()

    print(f"Instruction Mix:")
    print(f"  Loads:    {total_loads:6d} ({100*total_loads/max(1,total_insns):5.1f}%)")
    print(f"  Stores:   {total_stores:6d} ({100*total_stores/max(1,total_insns):5.1f}%)")
    print(f"  Branches: {total_branches:6d} ({100*total_branches/max(1,total_insns):5.1f}%)")
    print(f"  Multiply: {total_muls:6d} ({100*total_muls/max(1,total_insns):5.1f}%)")
    print(f"  Divide:   {total_divs:6d} ({100*total_divs/max(1,total_insns):5.1f}%)")
    print(f"  FPU:      {total_fpus:6d} ({100*total_fpus/max(1,total_insns):5.1f}%)")
    print()

    # Per-function details
    print("-" * 80)
    print(f"{'Function':<30} {'Insns':>8} {'Issue':>8} {'Latency':>8} {'IPC':>6}")
    print("-" * 80)

    for f in sorted(functions, key=lambda x: x.total_issue, reverse=True):
        ipc = f.insn_count / max(1, f.total_issue)
        print(f"{f.name:<30} {f.insn_count:>8} {f.total_issue:>8} {f.total_latency:>8} {ipc:>6.2f}")

    print("-" * 80)

    # Collect all unknown instructions
    all_unknown = set()
    for f in functions:
        all_unknown.update(f.unknown_insns)

    if all_unknown:
        print()
        print(f"Unknown instructions (timing not available):")
        for insn in sorted(all_unknown)[:20]:
            print(f"  {insn}")
        if len(all_unknown) > 20:
            print(f"  ... and {len(all_unknown) - 20} more")

def main():
    parser = argparse.ArgumentParser(description='V850 Cycle Estimation Tool')
    parser.add_argument('file', help='Assembly file to analyze')
    parser.add_argument('--cpu', default='v850e2m',
                        help='Target CPU (default: v850e2m)')
    parser.add_argument('--json', action='store_true',
                        help='Output in JSON format')

    args = parser.parse_args()

    try:
        functions = analyze_file(args.file)

        if args.json:
            import json
            data = {
                'file': args.file,
                'cpu': args.cpu,
                'functions': [
                    {
                        'name': f.name,
                        'insn_count': f.insn_count,
                        'issue_cycles': f.total_issue,
                        'latency_cycles': f.total_latency,
                        'loads': f.load_count,
                        'stores': f.store_count,
                        'branches': f.branch_count,
                        'multiplies': f.mul_count,
                        'divides': f.div_count,
                        'fpu': f.fpu_count,
                    }
                    for f in functions
                ]
            }
            print(json.dumps(data, indent=2))
        else:
            print_report(functions, args.file)

    except FileNotFoundError:
        print(f"Error: File not found: {args.file}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
