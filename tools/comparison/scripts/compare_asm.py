#!/usr/bin/env python3
"""
Compare assembly output from LLVM and CCRH compilers, with optional
disassembly cross-verification.

Usage:
  python compare_asm.py <llvm_asm> <ccrh_asm> [--output <report>]
  python compare_asm.py <llvm_asm> <ccrh_asm> --disasm <llvm_dis> [--mode full]

Modes:
  asm    - Compare LLVM asm vs CCRH asm (default, existing behavior)
  verify - Compare LLVM asm vs LLVM disassembly (encoding round-trip check)
  full   - All comparisons: asm-vs-asm, asm-vs-disasm, disasm-vs-ccrh
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


@dataclass
class DisasmInstruction:
    """Parsed disassembly instruction (from llvm-objdump output)."""
    address: int
    hex_bytes: str
    mnemonic: str
    operands: str
    raw: str
    size: int  # Actual size from hex bytes


@dataclass
class DisasmFunction:
    """Represents a function in disassembly output."""
    name: str
    address: int
    instructions: List[DisasmInstruction]
    size_bytes: int


@dataclass
class EncodingMismatch:
    """Records a mismatch between assembly and disassembly."""
    function: str
    index: int
    category: str  # 'mnemonic', 'operand', 'count', 'extra_nop'
    asm_text: str
    disasm_text: str
    severity: str  # 'critical', 'warning', 'info'


# Register alias map for normalization
REGISTER_ALIASES = {
    'sp': 'r3', 'gp': 'r4', 'tp': 'r5',
    'ep': 'r30', 'lp': 'r31', 'zero': 'r0',
    'fp': 'r29',
}

# Condition code aliases
COND_ALIASES = {
    'bz': 'be', 'bnz': 'bne',
    'bc': 'bl', 'bnc': 'bnl',
}


def normalize_instruction(mnemonic: str, operands: str) -> Tuple[str, str]:
    """Normalize instruction mnemonic and operands for comparison.

    Handles differences between CCRH and LLVM conventions:
    - Register aliases (sp/r3, lp/r31, etc.)
    - Condition code aliases (bz/be, bnz/bne)
    - Leading underscores on labels
    - Whitespace normalization
    """
    mnemonic = mnemonic.lower().strip()
    operands = operands.strip()

    # Normalize condition code aliases
    if mnemonic in COND_ALIASES:
        mnemonic = COND_ALIASES[mnemonic]

    # Normalize register names in operands
    def replace_registers(text: str) -> str:
        for alias, canonical in REGISTER_ALIASES.items():
            # Match word boundaries to avoid partial matches
            text = re.sub(r'\b' + re.escape(alias) + r'\b', canonical, text)
        return text

    operands = replace_registers(operands)

    # Normalize whitespace in operands
    operands = re.sub(r'\s+', ' ', operands).strip()
    # Remove trailing comments
    operands = re.sub(r'\s*[;#].*$', '', operands).strip()
    # Remove leading underscores on labels (CCRH convention)
    operands = re.sub(r'\b_([a-zA-Z_][a-zA-Z0-9_]*)\b', r'\1', operands)

    return mnemonic, operands


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


def parse_disasm_file(filepath: Path) -> Dict[str, DisasmFunction]:
    """Parse an llvm-objdump disassembly file and extract functions.

    Expected format:
        00000000 <func_name>:
               0: c6 39         add  r6, r7
               2: 07 50         mov  r7, r10
    """
    functions = {}
    current_func = None
    current_addr = 0
    current_instrs = []

    with open(filepath) as f:
        lines = f.readlines()

    for line in lines:
        line = line.rstrip()

        # Match function header: "00000000 <func_name>:"
        func_match = re.match(r'^([0-9a-fA-F]+)\s+<([^>]+)>:', line)
        if func_match:
            # Save previous function
            if current_func and current_instrs:
                size = sum(inst.size for inst in current_instrs)
                functions[current_func] = DisasmFunction(
                    name=current_func,
                    address=current_addr,
                    instructions=list(current_instrs),
                    size_bytes=size,
                )

            current_func = func_match.group(2)
            current_addr = int(func_match.group(1), 16)
            current_instrs = []
            continue

        # Match instruction line: "       0: c6 39         add  r6, r7"
        # Also handles: "       0: c6 39        \tadd\tr6, r7"
        inst_match = re.match(
            r'^\s+([0-9a-fA-F]+):\s+([0-9a-fA-F][0-9a-fA-F ]+?)\s{2,}(\S+)\s*(.*?)$',
            line
        )
        if not inst_match:
            # Try tab-separated format
            inst_match = re.match(
                r'^\s+([0-9a-fA-F]+):\s+([0-9a-fA-F][0-9a-fA-F ]+?)\t(\S+)\t?(.*?)$',
                line
            )

        if inst_match and current_func:
            addr = int(inst_match.group(1), 16)
            hex_bytes = inst_match.group(2).strip()
            mnemonic = inst_match.group(3).strip().lower()
            operands = inst_match.group(4).strip() if inst_match.group(4) else ""

            # Calculate actual size from hex bytes
            byte_count = len(hex_bytes.replace(' ', '')) // 2

            current_instrs.append(DisasmInstruction(
                address=addr,
                hex_bytes=hex_bytes,
                mnemonic=mnemonic,
                operands=operands,
                raw=line.strip(),
                size=byte_count,
            ))

    # Save last function
    if current_func and current_instrs:
        size = sum(inst.size for inst in current_instrs)
        functions[current_func] = DisasmFunction(
            name=current_func,
            address=current_addr,
            instructions=list(current_instrs),
            size_bytes=size,
        )

    return functions


def compare_asm_vs_disasm(
    asm_funcs: Dict[str, Function],
    disasm_funcs: Dict[str, DisasmFunction],
) -> List[EncodingMismatch]:
    """Compare LLVM assembly vs LLVM disassembly for encoding verification.

    This catches assembler encoding bugs by checking that what the assembler
    produces (disassembly) matches what was requested (assembly source).
    """
    mismatches = []

    for func_name in sorted(asm_funcs.keys()):
        asm_func = asm_funcs[func_name]
        disasm_func = disasm_funcs.get(func_name)

        if disasm_func is None:
            mismatches.append(EncodingMismatch(
                function=func_name,
                index=-1,
                category='missing',
                asm_text=f'{asm_func.instruction_count} instructions',
                disasm_text='(not found in disassembly)',
                severity='warning',
            ))
            continue

        # Filter out nop padding from disasm for comparison
        disasm_instrs = disasm_func.instructions
        # Keep all instructions including nops for now; we'll handle padding below

        asm_instrs = []
        for raw_line in asm_func.instructions:
            inst = parse_v850_instruction(raw_line)
            if inst:
                asm_instrs.append(inst)

        # Compare instruction by instruction
        asm_idx = 0
        dis_idx = 0

        while asm_idx < len(asm_instrs) and dis_idx < len(disasm_instrs):
            asm_inst = asm_instrs[asm_idx]
            dis_inst = disasm_instrs[dis_idx]

            asm_mn, asm_ops = normalize_instruction(asm_inst.mnemonic, asm_inst.operands)
            dis_mn, dis_ops = normalize_instruction(dis_inst.mnemonic, dis_inst.operands)

            # Check mnemonic match
            if asm_mn != dis_mn:
                # Check if disasm has an extra nop (alignment padding)
                if dis_mn == 'nop':
                    mismatches.append(EncodingMismatch(
                        function=func_name,
                        index=dis_idx,
                        category='extra_nop',
                        asm_text='(no corresponding asm instruction)',
                        disasm_text=dis_inst.raw,
                        severity='info',
                    ))
                    dis_idx += 1
                    continue

                mismatches.append(EncodingMismatch(
                    function=func_name,
                    index=asm_idx,
                    category='mnemonic',
                    asm_text=asm_inst.raw.strip(),
                    disasm_text=dis_inst.raw,
                    severity='critical',
                ))
            elif asm_ops != dis_ops:
                mismatches.append(EncodingMismatch(
                    function=func_name,
                    index=asm_idx,
                    category='operand',
                    asm_text=asm_inst.raw.strip(),
                    disasm_text=dis_inst.raw,
                    severity='critical',
                ))

            asm_idx += 1
            dis_idx += 1

        # Handle remaining disasm instructions (trailing nops)
        while dis_idx < len(disasm_instrs):
            dis_inst = disasm_instrs[dis_idx]
            dis_mn, _ = normalize_instruction(dis_inst.mnemonic, dis_inst.operands)
            if dis_mn == 'nop':
                mismatches.append(EncodingMismatch(
                    function=func_name,
                    index=dis_idx,
                    category='extra_nop',
                    asm_text='(alignment padding)',
                    disasm_text=dis_inst.raw,
                    severity='info',
                ))
            else:
                mismatches.append(EncodingMismatch(
                    function=func_name,
                    index=dis_idx,
                    category='count',
                    asm_text='(no corresponding asm instruction)',
                    disasm_text=dis_inst.raw,
                    severity='warning',
                ))
            dis_idx += 1

        # Handle remaining asm instructions
        while asm_idx < len(asm_instrs):
            asm_inst = asm_instrs[asm_idx]
            mismatches.append(EncodingMismatch(
                function=func_name,
                index=asm_idx,
                category='count',
                asm_text=asm_inst.raw.strip(),
                disasm_text='(no corresponding disasm instruction)',
                severity='warning',
            ))
            asm_idx += 1

    return mismatches


def compare_disasm_vs_ccrh(
    disasm_funcs: Dict[str, DisasmFunction],
    ccrh_funcs: Dict[str, Function],
) -> List[dict]:
    """Compare LLVM disassembly (ground truth) vs CCRH assembly.

    Uses LLVM disassembly as the actual machine code representation
    for comparison against CCRH output.
    """
    results = []

    all_funcs = set(disasm_funcs.keys()) | set(ccrh_funcs.keys())

    for name in sorted(all_funcs):
        disasm_func = disasm_funcs.get(name)
        ccrh_func = ccrh_funcs.get(name)

        result = {
            'name': name,
            'in_disasm': disasm_func is not None,
            'in_ccrh': ccrh_func is not None,
            'disasm_count': len(disasm_func.instructions) if disasm_func else 0,
            'ccrh_count': ccrh_func.instruction_count if ccrh_func else 0,
            'disasm_size': disasm_func.size_bytes if disasm_func else 0,
            'ccrh_size': ccrh_func.size_bytes if ccrh_func else 0,
            'instruction_diffs': [],
        }

        if disasm_func and ccrh_func:
            result['count_diff'] = len(disasm_func.instructions) - ccrh_func.instruction_count
            result['size_diff'] = disasm_func.size_bytes - ccrh_func.size_bytes

            # Instruction-level diff for common functions
            ccrh_instrs = []
            for raw_line in ccrh_func.instructions:
                inst = parse_v850_instruction(raw_line)
                if inst:
                    ccrh_instrs.append(inst)

            # Compare normalized instructions
            max_len = max(len(disasm_func.instructions), len(ccrh_instrs))
            for i in range(max_len):
                if i < len(disasm_func.instructions) and i < len(ccrh_instrs):
                    dis_inst = disasm_func.instructions[i]
                    ccrh_inst = ccrh_instrs[i]

                    dis_mn, dis_ops = normalize_instruction(dis_inst.mnemonic, dis_inst.operands)
                    ccrh_mn, ccrh_ops = normalize_instruction(ccrh_inst.mnemonic, ccrh_inst.operands)

                    if dis_mn != ccrh_mn or dis_ops != ccrh_ops:
                        result['instruction_diffs'].append({
                            'index': i,
                            'disasm': f'{dis_mn} {dis_ops}'.strip(),
                            'ccrh': f'{ccrh_mn} {ccrh_ops}'.strip(),
                        })
                elif i < len(disasm_func.instructions):
                    dis_inst = disasm_func.instructions[i]
                    dis_mn, dis_ops = normalize_instruction(dis_inst.mnemonic, dis_inst.operands)
                    result['instruction_diffs'].append({
                        'index': i,
                        'disasm': f'{dis_mn} {dis_ops}'.strip(),
                        'ccrh': '(missing)',
                    })
                else:
                    ccrh_inst = ccrh_instrs[i]
                    ccrh_mn, ccrh_ops = normalize_instruction(ccrh_inst.mnemonic, ccrh_inst.operands)
                    result['instruction_diffs'].append({
                        'index': i,
                        'disasm': '(missing)',
                        'ccrh': f'{ccrh_mn} {ccrh_ops}'.strip(),
                    })
        else:
            result['count_diff'] = 0
            result['size_diff'] = 0

        results.append(result)

    return results


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


def format_encoding_verification(mismatches: List[EncodingMismatch]) -> List[str]:
    """Format encoding verification results into report lines."""
    lines = []
    lines.append("Encoding Verification (ASM vs Disassembly)")
    lines.append("-" * 80)

    if not mismatches:
        lines.append("  All instructions verified: assembly matches disassembly.")
        lines.append("")
        return lines

    # Group by severity
    critical = [m for m in mismatches if m.severity == 'critical']
    warnings = [m for m in mismatches if m.severity == 'warning']
    info = [m for m in mismatches if m.severity == 'info']

    lines.append(f"  Total mismatches: {len(mismatches)} "
                 f"(critical: {len(critical)}, warning: {len(warnings)}, info: {len(info)})")
    lines.append("")

    if critical:
        lines.append("  CRITICAL - Encoding Bugs:")
        for m in critical:
            lines.append(f"    [{m.function}] insn #{m.index} ({m.category}):")
            lines.append(f"      ASM:    {m.asm_text}")
            lines.append(f"      DISASM: {m.disasm_text}")
        lines.append("")

    if warnings:
        lines.append("  WARNINGS - Instruction Count Mismatches:")
        for m in warnings:
            lines.append(f"    [{m.function}] insn #{m.index} ({m.category}):")
            lines.append(f"      ASM:    {m.asm_text}")
            lines.append(f"      DISASM: {m.disasm_text}")
        lines.append("")

    if info:
        # Summarize info-level (nop padding) by function
        nop_counts = defaultdict(int)
        for m in info:
            nop_counts[m.function] += 1
        lines.append("  INFO - Alignment Padding (nops):")
        for func, count in sorted(nop_counts.items()):
            lines.append(f"    {func}: {count} nop(s)")
        lines.append("")

    return lines


def format_disasm_vs_ccrh(results: List[dict]) -> List[str]:
    """Format disassembly vs CCRH comparison into report lines."""
    lines = []
    lines.append("Disassembly vs CCRH Comparison (Machine Code Ground Truth)")
    lines.append("-" * 80)

    common = [r for r in results if r['in_disasm'] and r['in_ccrh']]
    disasm_only = [r for r in results if r['in_disasm'] and not r['in_ccrh']]
    ccrh_only = [r for r in results if not r['in_disasm'] and r['in_ccrh']]

    lines.append(f"  Common functions: {len(common)}")
    lines.append(f"  LLVM-only functions: {len(disasm_only)}")
    lines.append(f"  CCRH-only functions: {len(ccrh_only)}")
    lines.append("")

    if not common:
        lines.append("  No common functions to compare.")
        lines.append("")
        return lines

    # Summary table
    lines.append(f"  {'Function':<30} {'LLVM':>8} {'CCRH':>8} {'Diff':>8} {'Diffs':>8}")
    lines.append(f"  {'-'*30} {'-'*8} {'-'*8} {'-'*8} {'-'*8}")

    for r in sorted(common, key=lambda x: abs(x.get('count_diff', 0)), reverse=True):
        diff_count = len(r.get('instruction_diffs', []))
        lines.append(f"  {r['name']:<30} {r['disasm_count']:>8} {r['ccrh_count']:>8} "
                     f"{r.get('count_diff', 0):>+8} {diff_count:>8}")

    lines.append("")

    # Detailed diffs for functions with instruction-level differences
    funcs_with_diffs = [r for r in common if r.get('instruction_diffs')]
    if funcs_with_diffs:
        lines.append("  Instruction-Level Differences:")
        for r in funcs_with_diffs[:10]:  # Limit to top 10
            diffs = r['instruction_diffs']
            lines.append(f"    {r['name']} ({len(diffs)} difference(s)):")
            for d in diffs[:5]:  # Show first 5 diffs per function
                lines.append(f"      #{d['index']:>3}: LLVM: {d['disasm']:<30} CCRH: {d['ccrh']}")
            if len(diffs) > 5:
                lines.append(f"      ... and {len(diffs) - 5} more")
        lines.append("")

    return lines


def generate_report(llvm_file: Path, ccrh_file: Path,
                   llvm_funcs: Dict[str, Function],
                   ccrh_funcs: Dict[str, Function],
                   comparison: List[dict],
                   encoding_mismatches: Optional[List[EncodingMismatch]] = None,
                   disasm_vs_ccrh: Optional[List[dict]] = None) -> str:
    """Generate a comparison report."""
    lines = []
    lines.append("=" * 80)
    lines.append("V850 Compiler Comparison Report")
    lines.append("=" * 80)
    lines.append("")
    lines.append(f"LLVM file: {llvm_file}")
    lines.append(f"CCRH file: {ccrh_file}")
    lines.append("")

    # Encoding verification section (if available)
    if encoding_mismatches is not None:
        lines.extend(format_encoding_verification(encoding_mismatches))

    # Disassembly vs CCRH section (if available)
    if disasm_vs_ccrh is not None:
        lines.extend(format_disasm_vs_ccrh(disasm_vs_ccrh))

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
    parser.add_argument("--disasm", type=Path, help="LLVM disassembly file (.dis) for encoding verification")
    parser.add_argument("--mode", choices=['asm', 'verify', 'full'], default='asm',
                        help="Comparison mode: asm (default), verify (asm vs disasm), full (all)")
    args = parser.parse_args()

    # Use stderr for status messages so JSON output on stdout stays clean
    def log(msg: str):
        print(msg, file=sys.stderr)

    if not args.llvm_asm.exists():
        log(f"Error: LLVM file not found: {args.llvm_asm}")
        sys.exit(1)
    if not args.ccrh_asm.exists():
        log(f"Error: CCRH file not found: {args.ccrh_asm}")
        sys.exit(1)

    # Auto-upgrade mode when --disasm is provided
    if args.disasm and args.mode == 'asm':
        args.mode = 'full'

    # Parse assembly files
    log(f"Parsing LLVM assembly: {args.llvm_asm}")
    llvm_funcs = parse_asm_file(args.llvm_asm, 'llvm')
    log(f"  Found {len(llvm_funcs)} functions")

    log(f"Parsing CCRH assembly: {args.ccrh_asm}")
    ccrh_funcs = parse_asm_file(args.ccrh_asm, 'ccrh')
    log(f"  Found {len(ccrh_funcs)} functions")

    # Parse disassembly if provided
    disasm_funcs = None
    encoding_mismatches = None
    disasm_vs_ccrh_results = None

    if args.disasm:
        if not args.disasm.exists():
            log(f"Warning: Disassembly file not found: {args.disasm}")
        else:
            log(f"Parsing LLVM disassembly: {args.disasm}")
            disasm_funcs = parse_disasm_file(args.disasm)
            log(f"  Found {len(disasm_funcs)} functions")

            if args.mode in ('verify', 'full'):
                log("Running encoding verification (asm vs disasm)...")
                encoding_mismatches = compare_asm_vs_disasm(llvm_funcs, disasm_funcs)
                critical = sum(1 for m in encoding_mismatches if m.severity == 'critical')
                log(f"  Found {len(encoding_mismatches)} mismatches ({critical} critical)")

            if args.mode == 'full':
                log("Comparing disassembly vs CCRH...")
                disasm_vs_ccrh_results = compare_disasm_vs_ccrh(disasm_funcs, ccrh_funcs)
                common = sum(1 for r in disasm_vs_ccrh_results if r['in_disasm'] and r['in_ccrh'])
                log(f"  Compared {common} common functions")

    # Compare asm vs asm (always done)
    comparison = compare_functions(llvm_funcs, ccrh_funcs)

    # Generate report
    if args.json:
        import json
        output = {
            'asm_comparison': comparison,
        }
        if encoding_mismatches is not None:
            output['encoding_mismatches'] = [
                {
                    'function': m.function,
                    'index': m.index,
                    'category': m.category,
                    'asm_text': m.asm_text,
                    'disasm_text': m.disasm_text,
                    'severity': m.severity,
                }
                for m in encoding_mismatches
            ]
        if disasm_vs_ccrh_results is not None:
            output['disasm_vs_ccrh'] = disasm_vs_ccrh_results
        report = json.dumps(output, indent=2)
    else:
        report = generate_report(args.llvm_asm, args.ccrh_asm,
                                llvm_funcs, ccrh_funcs, comparison,
                                encoding_mismatches, disasm_vs_ccrh_results)

    if args.output:
        with open(args.output, 'w') as f:
            f.write(report)
        log(f"Report written to: {args.output}")
    else:
        print(report)


if __name__ == "__main__":
    main()
