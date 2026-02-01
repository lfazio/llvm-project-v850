#!/usr/bin/env python3
"""
Compare assembly output from LLVM and CCRH compilers.

Usage: python compare_asm.py <llvm_asm> <ccrh_asm> [--output <report>]
"""

import argparse
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple


@dataclass
class Function:
    """Represents a function in assembly."""
    name: str
    start_line: int
    end_line: int
    instructions: List[str]
    instruction_count: int
    size_bytes: int
    labels: List[str]


@dataclass
class Instruction:
    """Parsed assembly instruction."""
    mnemonic: str
    operands: str
    raw: str
    size: int  # Estimated size in bytes


def parse_v850_instruction(line: str) -> Optional[Instruction]:
    """Parse a V850 assembly instruction line."""
    # Skip empty lines, comments, directives, labels
    line = line.strip()
    if not line or line.startswith('#') or line.startswith(';'):
        return None
    if line.startswith('.') and not line.startswith('.word'):
        return None
    if line.endswith(':'):
        return None

    # Handle common instruction patterns
    # Format: mnemonic [operands]
    parts = line.split(None, 1)
    if not parts:
        return None

    mnemonic = parts[0].lower()
    operands = parts[1] if len(parts) > 1 else ""

    # Estimate instruction size (simplified)
    size = estimate_instruction_size(mnemonic, operands)

    return Instruction(mnemonic=mnemonic, operands=operands, raw=line, size=size)


def estimate_instruction_size(mnemonic: str, operands: str) -> int:
    """Estimate V850 instruction size in bytes."""
    # 16-bit instructions (common)
    short_insns = {
        'nop', 'mov', 'not', 'shl', 'shr', 'sar', 'add', 'sub', 'cmp',
        'and', 'or', 'xor', 'tst', 'br', 'jmp'
    }

    # 32-bit instructions
    long_insns = {
        'movhi', 'movea', 'addi', 'andi', 'ori', 'xori', 'mulhi',
        'ld.b', 'ld.h', 'ld.w', 'st.b', 'st.h', 'st.w',
        'jarl', 'jr', 'prepare', 'dispose', 'div', 'divu', 'mul', 'mulu'
    }

    # 48-bit instructions (V850E2+)
    extra_long = {'jr32', 'jarl32'}

    base = mnemonic.split('.')[0]  # Handle ld.w -> ld

    if base in extra_long:
        return 6
    elif base in long_insns or mnemonic in long_insns:
        return 4
    elif base in short_insns:
        return 2
    else:
        return 4  # Default to 32-bit


def parse_asm_file(filepath: Path, compiler: str) -> Dict[str, Function]:
    """Parse an assembly file and extract functions."""
    functions = {}
    current_func = None
    current_instrs = []
    func_start = 0

    with open(filepath) as f:
        lines = f.readlines()

    for i, line in enumerate(lines):
        line = line.rstrip()

        # Detect function start (label followed by code)
        # LLVM: func_name:
        # CCRH: _func_name: or func_name:
        label_match = re.match(r'^(_?[a-zA-Z_][a-zA-Z0-9_]*):', line)
        if label_match:
            # Save previous function
            if current_func:
                size = sum(inst.size for inst in current_instrs)
                functions[current_func] = Function(
                    name=current_func,
                    start_line=func_start,
                    end_line=i - 1,
                    instructions=[inst.raw for inst in current_instrs],
                    instruction_count=len(current_instrs),
                    size_bytes=size,
                    labels=[]
                )

            # Start new function
            name = label_match.group(1)
            # Normalize: remove leading underscore (CCRH convention)
            if name.startswith('_') and compiler == 'ccrh':
                name = name[1:]
            current_func = name
            current_instrs = []
            func_start = i
            continue

        # Parse instruction
        if current_func:
            inst = parse_v850_instruction(line)
            if inst:
                current_instrs.append(inst)

    # Save last function
    if current_func:
        size = sum(inst.size for inst in current_instrs)
        functions[current_func] = Function(
            name=current_func,
            start_line=func_start,
            end_line=len(lines) - 1,
            instructions=[inst.raw for inst in current_instrs],
            instruction_count=len(current_instrs),
            size_bytes=size,
            labels=[]
        )

    return functions


def compare_functions(llvm_funcs: Dict[str, Function],
                     ccrh_funcs: Dict[str, Function]) -> List[dict]:
    """Compare functions between LLVM and CCRH output."""
    results = []

    all_funcs = set(llvm_funcs.keys()) | set(ccrh_funcs.keys())

    for name in sorted(all_funcs):
        llvm_func = llvm_funcs.get(name)
        ccrh_func = ccrh_funcs.get(name)

        result = {
            'name': name,
            'llvm_count': llvm_func.instruction_count if llvm_func else 0,
            'ccrh_count': ccrh_func.instruction_count if ccrh_func else 0,
            'llvm_size': llvm_func.size_bytes if llvm_func else 0,
            'ccrh_size': ccrh_func.size_bytes if ccrh_func else 0,
            'in_llvm': llvm_func is not None,
            'in_ccrh': ccrh_func is not None,
        }

        if llvm_func and ccrh_func:
            result['count_diff'] = llvm_func.instruction_count - ccrh_func.instruction_count
            result['size_diff'] = llvm_func.size_bytes - ccrh_func.size_bytes
            result['count_ratio'] = llvm_func.instruction_count / max(ccrh_func.instruction_count, 1)
            result['size_ratio'] = llvm_func.size_bytes / max(ccrh_func.size_bytes, 1)
        else:
            result['count_diff'] = 0
            result['size_diff'] = 0
            result['count_ratio'] = 0
            result['size_ratio'] = 0

        results.append(result)

    return results


def analyze_instruction_mix(func: Function) -> Dict[str, int]:
    """Analyze instruction type distribution in a function."""
    categories = defaultdict(int)

    for inst_line in func.instructions:
        inst = parse_v850_instruction(inst_line)
        if not inst:
            continue

        mnemonic = inst.mnemonic.split('.')[0]  # ld.w -> ld

        # Categorize instructions
        if mnemonic in ('add', 'addi', 'sub', 'subr', 'mul', 'mulu', 'div', 'divu',
                       'mulh', 'mulhi', 'mac', 'macu'):
            categories['arithmetic'] += 1
        elif mnemonic in ('and', 'andi', 'or', 'ori', 'xor', 'xori', 'not', 'tst'):
            categories['logical'] += 1
        elif mnemonic in ('shl', 'shr', 'sar', 'rotl', 'rotr'):
            categories['shift'] += 1
        elif mnemonic in ('ld', 'st', 'sld', 'sst'):
            categories['memory'] += 1
        elif mnemonic in ('mov', 'movhi', 'movea'):
            categories['move'] += 1
        elif mnemonic in ('br', 'jr', 'jarl', 'jmp', 'bcond', 'bz', 'bnz', 'be', 'bne',
                         'bge', 'bgt', 'ble', 'blt', 'bh', 'bl', 'bnh', 'bnl'):
            categories['branch'] += 1
        elif mnemonic in ('cmp', 'cmov', 'setf', 'sasf'):
            categories['compare'] += 1
        elif mnemonic in ('prepare', 'dispose'):
            categories['prologue_epilogue'] += 1
        else:
            categories['other'] += 1

    return dict(categories)


def generate_report(llvm_file: Path, ccrh_file: Path,
                   llvm_funcs: Dict[str, Function],
                   ccrh_funcs: Dict[str, Function],
                   comparison: List[dict]) -> str:
    """Generate a comparison report."""
    lines = []
    lines.append("=" * 80)
    lines.append("V850 Compiler Comparison Report")
    lines.append("=" * 80)
    lines.append("")
    lines.append(f"LLVM file: {llvm_file}")
    lines.append(f"CCRH file: {ccrh_file}")
    lines.append("")

    # Summary statistics
    total_llvm_size = sum(r['llvm_size'] for r in comparison)
    total_ccrh_size = sum(r['ccrh_size'] for r in comparison)
    total_llvm_count = sum(r['llvm_count'] for r in comparison)
    total_ccrh_count = sum(r['ccrh_count'] for r in comparison)

    lines.append("Summary")
    lines.append("-" * 40)
    lines.append(f"{'Metric':<25} {'LLVM':>10} {'CCRH':>10} {'Diff':>10}")
    lines.append("-" * 40)
    lines.append(f"{'Total Code Size (bytes)':<25} {total_llvm_size:>10} {total_ccrh_size:>10} {total_llvm_size - total_ccrh_size:>+10}")
    lines.append(f"{'Total Instructions':<25} {total_llvm_count:>10} {total_ccrh_count:>10} {total_llvm_count - total_ccrh_count:>+10}")
    lines.append(f"{'Functions':<25} {len(llvm_funcs):>10} {len(ccrh_funcs):>10}")

    if total_ccrh_size > 0:
        ratio = total_llvm_size / total_ccrh_size
        lines.append(f"{'Size Ratio (LLVM/CCRH)':<25} {ratio:>10.2f}")
    lines.append("")

    # Per-function comparison
    lines.append("Per-Function Comparison")
    lines.append("-" * 80)
    lines.append(f"{'Function':<30} {'LLVM':>8} {'CCRH':>8} {'Diff':>8} {'Ratio':>8}")
    lines.append("-" * 80)

    # Sort by size difference (worst first)
    sorted_comp = sorted(comparison, key=lambda x: x['size_diff'], reverse=True)

    for result in sorted_comp:
        if not result['in_llvm'] or not result['in_ccrh']:
            status = "(LLVM only)" if result['in_llvm'] else "(CCRH only)"
            lines.append(f"{result['name']:<30} {status}")
            continue

        ratio_str = f"{result['size_ratio']:.2f}" if result['size_ratio'] else "N/A"
        lines.append(f"{result['name']:<30} {result['llvm_size']:>8} {result['ccrh_size']:>8} "
                    f"{result['size_diff']:>+8} {ratio_str:>8}")

    lines.append("")

    # Instruction mix comparison for notable functions
    lines.append("Instruction Mix Analysis (Top 5 Functions by Size)")
    lines.append("-" * 80)

    common_funcs = [r['name'] for r in comparison
                   if r['in_llvm'] and r['in_ccrh']][:5]

    for func_name in common_funcs:
        llvm_func = llvm_funcs.get(func_name)
        ccrh_func = ccrh_funcs.get(func_name)

        if llvm_func and ccrh_func:
            llvm_mix = analyze_instruction_mix(llvm_func)
            ccrh_mix = analyze_instruction_mix(ccrh_func)

            lines.append(f"\n{func_name}:")
            lines.append(f"  {'Category':<20} {'LLVM':>8} {'CCRH':>8}")
            all_cats = set(llvm_mix.keys()) | set(ccrh_mix.keys())
            for cat in sorted(all_cats):
                lines.append(f"  {cat:<20} {llvm_mix.get(cat, 0):>8} {ccrh_mix.get(cat, 0):>8}")

    lines.append("")
    lines.append("=" * 80)

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Compare V850 assembly output")
    parser.add_argument("llvm_asm", type=Path, help="LLVM assembly file")
    parser.add_argument("ccrh_asm", type=Path, help="CCRH assembly file")
    parser.add_argument("--output", "-o", type=Path, help="Output report file")
    parser.add_argument("--json", action="store_true", help="Output JSON format")
    args = parser.parse_args()

    if not args.llvm_asm.exists():
        print(f"Error: LLVM file not found: {args.llvm_asm}")
        sys.exit(1)
    if not args.ccrh_asm.exists():
        print(f"Error: CCRH file not found: {args.ccrh_asm}")
        sys.exit(1)

    # Parse assembly files
    print(f"Parsing LLVM assembly: {args.llvm_asm}")
    llvm_funcs = parse_asm_file(args.llvm_asm, 'llvm')
    print(f"  Found {len(llvm_funcs)} functions")

    print(f"Parsing CCRH assembly: {args.ccrh_asm}")
    ccrh_funcs = parse_asm_file(args.ccrh_asm, 'ccrh')
    print(f"  Found {len(ccrh_funcs)} functions")

    # Compare
    comparison = compare_functions(llvm_funcs, ccrh_funcs)

    # Generate report
    if args.json:
        import json
        report = json.dumps(comparison, indent=2)
    else:
        report = generate_report(args.llvm_asm, args.ccrh_asm,
                                llvm_funcs, ccrh_funcs, comparison)

    if args.output:
        with open(args.output, 'w') as f:
            f.write(report)
        print(f"Report written to: {args.output}")
    else:
        print(report)


if __name__ == "__main__":
    main()
