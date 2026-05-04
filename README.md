# PRIMA & OptiProfiler -- Benchmark Test Suite

Comprehensive installation, testing, and performance benchmarking of
[PRIMA](https://github.com/libprima/prima) and
[OptiProfiler](https://github.com/optiprofiler/optiprofiler) in MATLAB.


---

## Project Structure

```
prima_opti_benchmark/
├── README.md                       # This file
├── report.tex                      # LaTeX test report
├── report.pdf                      # Compiled test report
├── test_rosenbrock_run.m           # Task 1: Rosenbrock function tests
├── precision_benchmark.m           # Task 2: Precision benchmark
├── generate_figures.m              # Generate all figures from .mat results
├── mex_config/                     # MEX compiler configuration (reference)
│   ├── gfortran.xml                #   MATLAB MEX config for GNU Fortran
│   └── gfortran-wrapper            #   NAG-to-gfortran flag translation
├── prima/                          # PRIMA library (clone from GitHub)
├── optiprofiler/                   # OptiProfiler library
├── results/
│   ├── rosenbrock_results/         # Rosenbrock test results
│   │   ├── rosenbrock_results.mat
│   │   └── rosenbrock_log.txt
│   ├── benchmark_results/          # Precision benchmark results
│   │   ├── precision_results.mat
│   │   ├── precision_summary.txt
│   │   └── precision_benchmark_log.txt
│   └── figures/                    # Generated figures (PDF)
└── .gitignore
```

---

## Requirements

- **MATLAB R2020b or later** (tested on R2025b)
- **Fortran MEX compiler** for PRIMA's Fortran gateways
  - On macOS Apple Silicon: `gfortran` via Homebrew (`brew install gcc`)
  - Custom MEX configuration (`gfortran.xml`) + wrapper script for flag translation
- **Git** (for cloning repositories)
- **LaTeX** (for compiling the report)

---

## Quick Start

### 1. Clone dependencies

```bash
git clone <this-repo-url>
cd prima_opti_benchmark
git clone https://github.com/libprima/prima.git prima
```

Download OptiProfiler from https://github.com/optiprofiler/optiprofiler
and place it under `prima_opti_benchmark/optiprofiler/`.

### 2. Compile PRIMA

```matlab
cd prima
options.single = true;
options.quadruple = true;
options.verbose = true;
setup(options);
```

### 3. Run Rosenbrock tests

```matlab
run('test_rosenbrock_run.m')
```

### 4. Run precision benchmarks

```matlab
run('precision_benchmark.m')
```

### 5. Compile the report

```bash
pdflatex report.tex
pdflatex report.tex   # run twice for ToC
```

---

## Tasks Summary

### Task 1: PRIMA Rosenbrock Function Tests

Test the $n$-dimensional Chained Rosenbrock function:

$$f(x) = \sum_{i=1}^{n-1} \left[ (x_i - 1)^2 + 100(x_{i+1} - x_i^2)^2 \right]$$

Initial point: $x_0 = (-1, -1, \ldots, -1)^T$ for all dimensions.

**Results:**

| n  | Constraint Type       | f(x*)      | #f-evals | Solver  |
|----|----------------------|------------|----------|---------|
| 2  | Unconstrained        | 2.00e-17   | 75       | UOBYQA  |
| 2  | Bound (x ≤ 0)        | 1.00e+00   | 31       | BOBYQA  |
| 2  | Linear (Σx≤1, x≥0)   | 1.46e-01   | 47       | LINCOA  |
| 2  | Nonlinear (‖x‖²≤1, x≥0)| 4.57e-02 | 572      | COBYLA  |
| 5  | Unconstrained        | 3.71e-15   | 344      | UOBYQA  |
| 5  | Bound (x ≤ 0)        | 4.00e+00   | 83       | BOBYQA  |
| 5  | Linear (Σx≤1, x≥0)   | 2.43e+00   | 71       | LINCOA  |
| 5  | Nonlinear (‖x‖²≤1, x≥0)| 1.50e+00 | 405      | COBYLA  |
| 10 | Unconstrained        | 2.23e-11   | 944      | NEWUOA  |
| 10 | Bound (x ≤ 0)        | 9.00e+00   | 173      | BOBYQA  |
| 10 | Linear (Σx≤1, x≥0)   | 7.43e+00   | 169      | LINCOA  |
| 10 | Nonlinear (‖x‖²≤1, x≥0)| 6.43e+00 | 860      | COBYLA  |
| 15 | Unconstrained        | 3.99e+00   | 1714     | NEWUOA  |
| 15 | Bound (x ≤ 0)        | 1.40e+01   | 308      | BOBYQA  |
| 15 | Linear (Σx≤1, x≥0)   | 1.24e+01   | 252      | LINCOA  |
| 15 | Nonlinear (‖x‖²≤1, x≥0)| 1.14e+01 | 1231     | COBYLA  |
| 20 | Unconstrained        | 1.59e-10   | 2796     | NEWUOA  |
| 20 | Bound (x ≤ 0)        | 1.90e+01   | 538      | BOBYQA  |
| 20 | Linear (Σx≤1, x≥0)   | 1.74e+01   | 320      | LINCOA  |
| 20 | Nonlinear (‖x‖²≤1, x≥0)| 1.63e+01 | 1722     | COBYLA  |

- **Unconstrained**: Global min at x=(1,...,1), f*=0, recovered to machine precision for most n. Interesting anomaly at n=15 where solver hit evaluation budget before full convergence (f*≈3.99).
- **Bound (x≤0)**: Optimum at x=(0,...,0), f*=n-1. Confirmed exactly for all n=2,...,20.
- **Linear/Nonlinear**: Optimum lies on constraint boundary. Adding x≥0 significantly reduces nf (e.g., n=20 linear: 787→320). Full n=2:20 sweep shown in figures.

### Task 2: Precision Benchmarks

152 problems, 3 precisions, 2 features, 1368 solver calls. Full dimension sweep n=2:20.

**Double vs Single:**

| Metric               | Plain | Noisy (10⁻⁶) |
|---------------------|-------|-------------|
| Problems             | 152   | 304         |
| Median f ratio (d/s) | 1.000 | 1.000       |
| Median nf ratio (d/s)| 0.945 | 1.000       |

**Double vs Quadruple:**

| Metric               | Plain | Noisy (10⁻⁶) |
|---------------------|-------|-------------|
| Problems             | 152   | 304         |
| Median f ratio (d/q) | 1.000 | 1.000       |
| Median nf ratio (d/q)| 1.000 | 1.000       |
| Speed overhead       | ~25×  | ~23×        |

**Key findings:**
- All three precisions achieve identical median solution quality (median ratio = 1.0) across 152 problems.
- Single precision is viable for well-conditioned problems; double precision outperforms on ill-conditioned cases (Rosenbrock α=100).
- Quadruple precision incurs ~25× overhead with no median accuracy benefit over double.
- Under noise (10⁻⁶), precision choice becomes largely irrelevant — noise dominates numerical error.
- Bound-constrained optimum is independent of α (confirmed f*=n-1 for all n=2,...,20).

---

## Environment

| Component            | Specification                          |
|---------------------|----------------------------------------|
| OS                  | macOS 26.0.1 (Apple Silicon, arm64)    |
| MATLAB              | R2025b (25.2.0.2998904)               |
| Fortran Compiler    | GNU Fortran 15.2.0 (Homebrew)         |
| MEX Config          | Custom gfortran.xml + wrapper script   |

---

## Troubleshooting

### MEX compilation fails
- Verify Fortran compiler: `mex -setup FORTRAN`
- Check the custom `gfortran.xml` is placed in MATLAB's mexopts directory
- Ensure the wrapper script at `~/.local/nagfor-wrapper/gfortran-wrapper` handles
  NAG-to-gfortran flag translation (-i8 → -fdefault-integer-8, -fpp → -cpp, etc.)

### MATLAB segfault on exit
- Known issue with MATLAB R2025b on macOS 26.0.1.
- Computation completes correctly; crash occurs in license logger/threadpool cleanup.
- Use flags: `-nodesktop -nojvm -nodisplay -nosplash`

### Path issues
- PRIMA MEX files are in `prima/matlab/interfaces/private/`
- Add `prima/matlab/interfaces/` to MATLAB path (not the private directory)

---

## License

This project is for academic use. PRIMA and OptiProfiler are distributed under
their respective open-source licenses. See their repositories for details.
