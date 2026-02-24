#!/usr/bin/env python3
"""
Run all V850 benchmarks and generate comparison reports.

Usage: python run_benchmarks.py [options]

Options:
    --llvm-only     Only compile with LLVM
    --ccrh-only     Only compile with CCRH
    --opt-level     Optimization level (0, 1, 2, 3, s, z) [default: 2]
    --cpu           Target CPU [default: v850e2m]
    --output-dir    Output directory [default: results]
"""

import argparse
import json
import os
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

SCRIPT_DIR = Path(__file__).parent
BENCHMARK_DIR = SCRIPT_DIR.parent / "benchmarks"
RESULTS_DIR = SCRIPT_DIR.parent / "results"


@dataclass
class BenchmarkResult:
    """Results from compiling a single benchmark."""

    name: str
    source_file: str
    compiler: str
    opt_level: str
    cpu: str
    success: bool
    asm_file: Optional[str]
    obj_file: Optional[str]
    size_bytes: int
    error_message: str


def find_benchmarks(benchmark_dir: Path) -> List[Path]:
    """Find all benchmark C files."""
    benchmarks = []
    for category in ["micro", "kernels", "apps"]:
        cat_dir = benchmark_dir / category
        if cat_dir.exists():
            benchmarks.extend(sorted(cat_dir.glob("*.c")))
    return benchmarks


def run_llvm_compile(
    source: Path, opt_level: str, cpu: str, output_dir: Path
) -> BenchmarkResult:
    """Compile a benchmark with LLVM."""
    name = source.stem
    asm_file = output_dir / f"{name}_llvm.s"
    obj_file = output_dir / f"{name}_llvm.o"

    compile_script = SCRIPT_DIR / "compile_llvm.sh"

    # Generate assembly
    cmd_asm = [
        str(compile_script),
        f"-O{opt_level}",
        f"-mcpu={cpu}",
        "-S",
        "-o",
        str(asm_file),
        str(source),
    ]

    # Generate object
    cmd_obj = [
        str(compile_script),
        f"-O{opt_level}",
        f"-mcpu={cpu}",
        "-c",
        "-o",
        str(obj_file),
        str(source),
    ]

    try:
        subprocess.run(cmd_asm, check=True, capture_output=True, text=True)
        subprocess.run(cmd_obj, check=True, capture_output=True, text=True)

        size = obj_file.stat().st_size if obj_file.exists() else 0

        return BenchmarkResult(
            name=name,
            source_file=str(source),
            compiler="llvm",
            opt_level=opt_level,
            cpu=cpu,
            success=True,
            asm_file=str(asm_file),
            obj_file=str(obj_file),
            size_bytes=size,
            error_message="",
        )
    except subprocess.CalledProcessError as e:
        return BenchmarkResult(
            name=name,
            source_file=str(source),
            compiler="llvm",
            opt_level=opt_level,
            cpu=cpu,
            success=False,
            asm_file=None,
            obj_file=None,
            size_bytes=0,
            error_message=e.stderr or str(e),
        )


def run_ccrh_compile(
    source: Path, opt_level: str, cpu: str, output_dir: Path
) -> BenchmarkResult:
    """Compile a benchmark with CCRH."""
    name = source.stem
    asm_file = output_dir / f"{name}_ccrh.s"
    obj_file = output_dir / f"{name}_ccrh.o"

    compile_script = SCRIPT_DIR / "compile_ccrh.sh"

    # Check if CCRH is available
    if not os.environ.get("CCRH_PATH"):
        return BenchmarkResult(
            name=name,
            source_file=str(source),
            compiler="ccrh",
            opt_level=opt_level,
            cpu=cpu,
            success=False,
            asm_file=None,
            obj_file=None,
            size_bytes=0,
            error_message="CCRH_PATH not set",
        )

    cmd_asm = [
        "docker",
        "run",
        "--rm",
        "-u",
        "1000:1000",
        "-e",
        f"CCRH_PATH={os.environ.get('CCRH_PATH')}",
        "-v",
        f"{SCRIPT_DIR.parent.parent.parent}:{SCRIPT_DIR.parent.parent.parent}",
        "-t",
        "dev:latest",
        str(compile_script),
        f"-O{opt_level}",
        f"-Xcpu={cpu}",
        "-S",
        "-o",
        str(asm_file),
        str(source),
    ]

    cmd_obj = [
        "docker",
        "run",
        "--rm",
        "-u",
        "1000:1000",
        "-e",
        f"CCRH_PATH={os.environ.get('CCRH_PATH')}",
        "-v",
        f"{SCRIPT_DIR.parent.parent.parent}:{SCRIPT_DIR.parent.parent.parent}",
        "-t",
        "dev:latest",
        str(compile_script),
        f"-O{opt_level}",
        f"-Xcpu={cpu}",
        "-c",
        "-o",
        str(obj_file),
        str(source),
    ]

    try:
        subprocess.run(cmd_asm, check=True, capture_output=True, text=True)
        subprocess.run(cmd_obj, check=True, capture_output=True, text=True)

        size = obj_file.stat().st_size if obj_file.exists() else 0

        return BenchmarkResult(
            name=name,
            source_file=str(source),
            compiler="ccrh",
            opt_level=opt_level,
            cpu=cpu,
            success=True,
            asm_file=str(asm_file),
            obj_file=str(obj_file),
            size_bytes=size,
            error_message="",
        )
    except subprocess.CalledProcessError as e:
        return BenchmarkResult(
            name=name,
            source_file=str(source),
            compiler="ccrh",
            opt_level=opt_level,
            cpu=cpu,
            success=False,
            asm_file=None,
            obj_file=None,
            size_bytes=0,
            error_message=e.stderr or str(e),
        )


def compare_results(
    llvm_result: BenchmarkResult, ccrh_result: BenchmarkResult, output_dir: Path
) -> Optional[Path]:
    """Compare LLVM and CCRH results for a benchmark."""
    if not llvm_result.success or not ccrh_result.success:
        return None

    if not llvm_result.asm_file or not ccrh_result.asm_file:
        return None

    compare_script = SCRIPT_DIR / "compare_asm.py"
    report_file = output_dir / f"{llvm_result.name}_comparison.txt"

    cmd = [
        "docker",
        "run",
        "--rm",
        "-u",
        "1000:1000",
        "-e",
        f"CCRH_PATH={os.environ.get('CCRH_PATH')}",
        "-v",
        f"{SCRIPT_DIR.parent.parent.parent}:{SCRIPT_DIR.parent.parent.parent}",
        "-t",
        "dev:latest",
        sys.executable,
        str(compare_script),
        llvm_result.asm_file,
        ccrh_result.asm_file,
        "-o",
        str(report_file),
    ]

    try:
        subprocess.run(cmd, check=True, capture_output=True)
        return report_file
    except subprocess.CalledProcessError:
        return None


def generate_summary(results: List[BenchmarkResult], output_file: Path):
    """Generate a summary report of all benchmark results."""
    lines = []
    lines.append("=" * 80)
    lines.append("V850 Benchmark Summary")
    lines.append(f"Generated: {datetime.now().isoformat()}")
    lines.append("=" * 80)
    lines.append("")

    # Group by compiler
    llvm_results = [r for r in results if r.compiler == "llvm"]
    ccrh_results = [r for r in results if r.compiler == "ccrh"]

    # LLVM summary
    llvm_success = sum(1 for r in llvm_results if r.success)
    llvm_total_size = sum(r.size_bytes for r in llvm_results if r.success)
    lines.append(f"LLVM Results: {llvm_success}/{len(llvm_results)} succeeded")
    lines.append(f"  Total object size: {llvm_total_size} bytes")
    lines.append("")

    # CCRH summary
    ccrh_success = sum(1 for r in ccrh_results if r.success)
    ccrh_total_size = sum(r.size_bytes for r in ccrh_results if r.success)
    lines.append(f"CCRH Results: {ccrh_success}/{len(ccrh_results)} succeeded")
    lines.append(f"  Total object size: {ccrh_total_size} bytes")
    lines.append("")

    # Comparison table
    lines.append("Per-Benchmark Comparison")
    lines.append("-" * 60)
    lines.append(
        f"{'Benchmark':<25} {'LLVM (bytes)':>12} {'CCRH (bytes)':>12} {'Diff':>10}"
    )
    lines.append("-" * 60)

    llvm_dict = {r.name: r for r in llvm_results}
    ccrh_dict = {r.name: r for r in ccrh_results}
    all_names = sorted(set(llvm_dict.keys()) | set(ccrh_dict.keys()))

    for name in all_names:
        llvm_r = llvm_dict.get(name)
        ccrh_r = ccrh_dict.get(name)

        llvm_size = llvm_r.size_bytes if llvm_r and llvm_r.success else 0
        ccrh_size = ccrh_r.size_bytes if ccrh_r and ccrh_r.success else 0

        llvm_str = str(llvm_size) if llvm_size else "FAIL"
        ccrh_str = str(ccrh_size) if ccrh_size else "FAIL"

        diff = llvm_size - ccrh_size if llvm_size and ccrh_size else 0
        diff_str = f"{diff:+d}" if diff else "-"

        lines.append(f"{name:<25} {llvm_str:>12} {ccrh_str:>12} {diff_str:>10}")

    lines.append("-" * 60)
    if llvm_total_size and ccrh_total_size:
        total_diff = llvm_total_size - ccrh_total_size
        ratio = llvm_total_size / ccrh_total_size
        lines.append(
            f"{'TOTAL':<25} {llvm_total_size:>12} {ccrh_total_size:>12} {total_diff:>+10}"
        )
        lines.append(f"Size ratio (LLVM/CCRH): {ratio:.3f}")
    lines.append("")

    # Failed benchmarks
    failed = [r for r in results if not r.success]
    if failed:
        lines.append("Failed Benchmarks:")
        for r in failed:
            lines.append(f"  {r.name} ({r.compiler}): {r.error_message[:50]}...")

    with open(output_file, "w") as f:
        f.write("\n".join(lines))

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Run V850 benchmarks")
    parser.add_argument(
        "--llvm-only", action="store_true", help="Only compile with LLVM"
    )
    parser.add_argument(
        "--ccrh-only", action="store_true", help="Only compile with CCRH"
    )
    parser.add_argument("--opt-level", "-O", default="2", help="Optimization level")
    parser.add_argument("--cpu", default="rh850g3m", help="Target CPU")
    parser.add_argument(
        "--output-dir", "-o", type=Path, default=RESULTS_DIR, help="Output directory"
    )
    args = parser.parse_args()

    # Create output directories
    args.output_dir.mkdir(parents=True, exist_ok=True)
    asm_dir = args.output_dir / "asm"
    asm_dir.mkdir(exist_ok=True)
    obj_dir = args.output_dir / "obj"
    obj_dir.mkdir(exist_ok=True)
    reports_dir = args.output_dir / "reports"
    reports_dir.mkdir(exist_ok=True)

    # Find benchmarks
    benchmarks = find_benchmarks(BENCHMARK_DIR)
    print(f"Found {len(benchmarks)} benchmarks")

    results = []

    # Compile with LLVM
    if not args.ccrh_only:
        print("\nCompiling with LLVM...")
        for bench in benchmarks:
            print(f"  {bench.name}...", end=" ", flush=True)
            result = run_llvm_compile(bench, args.opt_level, args.cpu, asm_dir)
            results.append(result)
            print("OK" if result.success else f"FAIL: {result.error_message[:30]}")

    # Compile with CCRH
    if not args.llvm_only:
        print("\nCompiling with CCRH...")
        for bench in benchmarks:
            print(f"  {bench.name}...", end=" ", flush=True)
            result = run_ccrh_compile(bench, args.opt_level, args.cpu, asm_dir)
            results.append(result)
            print("OK" if result.success else f"FAIL: {result.error_message[:30]}")

    # Generate comparisons
    if not args.llvm_only and not args.ccrh_only:
        print("\nGenerating comparisons...")
        llvm_results = {r.name: r for r in results if r.compiler == "llvm"}
        ccrh_results = {r.name: r for r in results if r.compiler == "ccrh"}

        for name in llvm_results:
            if name in ccrh_results:
                print(f"  {name}...", end=" ", flush=True)
                report = compare_results(
                    llvm_results[name], ccrh_results[name], reports_dir
                )
                print("OK" if report else "SKIP")

    # Generate summary
    print("\nGenerating summary...")
    summary_file = args.output_dir / "summary.txt"
    summary = generate_summary(results, summary_file)
    print(summary)

    # Save raw results as JSON
    json_file = args.output_dir / "results.json"
    json_results = [
        {
            "name": r.name,
            "source_file": r.source_file,
            "compiler": r.compiler,
            "opt_level": r.opt_level,
            "cpu": r.cpu,
            "success": r.success,
            "size_bytes": r.size_bytes,
            "error_message": r.error_message,
        }
        for r in results
    ]
    with open(json_file, "w") as f:
        json.dump(json_results, f, indent=2)

    print(f"\nResults saved to: {args.output_dir}")


if __name__ == "__main__":
    main()
