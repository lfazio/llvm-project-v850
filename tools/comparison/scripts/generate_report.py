#!/usr/bin/env python3
"""
Generate comprehensive V850 LLVM vs CCRH comparison report.

Usage:
    ./generate_report.py [--output=report.md]
"""

import os
import sys
import json
import argparse
from datetime import datetime

# Add the scripts directory to path for estimate_cycles
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def get_file_size(filepath):
    """Get size of assembly file (approximation of code size)."""
    try:
        with open(filepath, 'r') as f:
            # Count non-empty, non-comment, non-directive lines
            insn_count = 0
            for line in f:
                line = line.strip()
                if not line or line.startswith(';') or line.startswith('#'):
                    continue
                if line.startswith('.') or line.startswith('$'):
                    continue
                if line.endswith(':'):
                    continue
                insn_count += 1
            return insn_count
    except:
        return 0

def run_cycle_estimation(filepath):
    """Run cycle estimation on a file."""
    try:
        import subprocess
        result = subprocess.run(
            ['python3', 'scripts/estimate_cycles.py', filepath, '--json'],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode == 0:
            return json.loads(result.stdout)
        return None
    except:
        return None

def main():
    parser = argparse.ArgumentParser(description='Generate comparison report')
    parser.add_argument('--output', default='results/comprehensive_report.md',
                        help='Output file (default: results/comprehensive_report.md)')
    args = parser.parse_args()

    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

    benchmarks = [
        'arithmetic', 'bitwise', 'control_flow', 'crypto',
        'dsp', 'embedded', 'matrix', 'state_machine'
    ]

    report = []
    report.append("# V850 LLVM vs CCRH Comprehensive Comparison Report")
    report.append("")
    report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append("")

    # Collect all data
    data = []
    totals = {'llvm_insns': 0, 'ccrh_insns': 0, 'llvm_cycles': 0, 'ccrh_cycles': 0}

    for bench in benchmarks:
        llvm_file = f"results/asm/{bench}_llvm.s"
        ccrh_file = f"results/asm/{bench}_ccrh.s"

        if not os.path.exists(llvm_file) or not os.path.exists(ccrh_file):
            continue

        llvm_data = run_cycle_estimation(llvm_file)
        ccrh_data = run_cycle_estimation(ccrh_file)

        if llvm_data and ccrh_data:
            llvm_insns = sum(f['insn_count'] for f in llvm_data['functions'])
            ccrh_insns = sum(f['insn_count'] for f in ccrh_data['functions'])
            llvm_cycles = sum(f['issue_cycles'] for f in llvm_data['functions'])
            ccrh_cycles = sum(f['issue_cycles'] for f in ccrh_data['functions'])

            totals['llvm_insns'] += llvm_insns
            totals['ccrh_insns'] += ccrh_insns
            totals['llvm_cycles'] += llvm_cycles
            totals['ccrh_cycles'] += ccrh_cycles

            data.append({
                'name': bench,
                'llvm_insns': llvm_insns,
                'ccrh_insns': ccrh_insns,
                'llvm_cycles': llvm_cycles,
                'ccrh_cycles': ccrh_cycles,
                'insn_ratio': llvm_insns / max(1, ccrh_insns),
                'cycle_ratio': llvm_cycles / max(1, ccrh_cycles),
                'winner': 'LLVM' if llvm_cycles < ccrh_cycles else ('CCRH' if llvm_cycles > ccrh_cycles else 'TIE')
            })

    # Summary
    report.append("## Executive Summary")
    report.append("")
    report.append("| Metric | LLVM | CCRH | LLVM/CCRH |")
    report.append("|--------|------|------|-----------|")
    report.append(f"| Total Instructions | {totals['llvm_insns']} | {totals['ccrh_insns']} | {100*totals['llvm_insns']//totals['ccrh_insns']}% |")
    report.append(f"| Estimated Cycles | {totals['llvm_cycles']} | {totals['ccrh_cycles']} | {100*totals['llvm_cycles']//totals['ccrh_cycles']}% |")
    report.append("")

    llvm_wins = sum(1 for d in data if d['winner'] == 'LLVM')
    ccrh_wins = sum(1 for d in data if d['winner'] == 'CCRH')
    report.append(f"**Overall: LLVM wins {llvm_wins}/{len(data)} benchmarks**")
    report.append("")

    # Detailed comparison
    report.append("## Benchmark Comparison")
    report.append("")
    report.append("| Benchmark | LLVM Insns | CCRH Insns | Insn% | LLVM Cycles | CCRH Cycles | Cycle% | Winner |")
    report.append("|-----------|------------|------------|-------|-------------|-------------|--------|--------|")

    for d in data:
        report.append(f"| {d['name']} | {d['llvm_insns']} | {d['ccrh_insns']} | {100*d['insn_ratio']:.0f}% | {d['llvm_cycles']} | {d['ccrh_cycles']} | {100*d['cycle_ratio']:.0f}% | {d['winner']} |")

    report.append(f"| **TOTAL** | **{totals['llvm_insns']}** | **{totals['ccrh_insns']}** | **{100*totals['llvm_insns']//totals['ccrh_insns']}%** | **{totals['llvm_cycles']}** | **{totals['ccrh_cycles']}** | **{100*totals['llvm_cycles']//totals['ccrh_cycles']}%** | **LLVM** |")
    report.append("")

    # Key findings
    report.append("## Key Findings")
    report.append("")
    report.append("### LLVM Advantages")
    report.append("")
    for d in sorted(data, key=lambda x: x['cycle_ratio']):
        if d['winner'] == 'LLVM' and d['cycle_ratio'] < 0.9:
            report.append(f"- **{d['name']}**: {100*d['cycle_ratio']:.0f}% of CCRH cycles ({d['llvm_cycles']} vs {d['ccrh_cycles']})")

    report.append("")
    report.append("### Areas Where CCRH is Competitive")
    report.append("")
    for d in sorted(data, key=lambda x: x['cycle_ratio'], reverse=True):
        if d['winner'] == 'CCRH' or d['cycle_ratio'] > 0.9:
            report.append(f"- **{d['name']}**: {100*d['cycle_ratio']:.0f}% of CCRH cycles")

    report.append("")
    report.append("---")
    report.append("")
    report.append("*Note: Cycle estimates are based on V850E2M instruction timing. CCRH was compiled with -Ospeed (aggressive speed optimization), LLVM with -O2.*")

    # Write report
    with open(args.output, 'w') as f:
        f.write('\n'.join(report))

    print(f"Report written to {args.output}")
    print(f"\nSummary: LLVM generates {100*totals['llvm_cycles']//totals['ccrh_cycles']}% of CCRH's estimated cycles")

if __name__ == '__main__':
    main()
