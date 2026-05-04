% Precision benchmark: double vs single and double vs quadruple
% Uses OptiProfiler with PRIMA solvers
function run_precision_benchmarks()

    % --- Add paths ---
    addpath('/Users/xiaohan/Downloads/prima_opti_benchmark/prima/matlab/interfaces');
    addpath('/Users/xiaohan/Downloads/prima_opti_benchmark/optiprofiler/matlab/optiprofiler/src');
    addpath('/Users/xiaohan/Downloads/prima_opti_benchmark/optiprofiler/matlab/optiprofiler/problem_libs/s2mpj');

    % --- Output directory ---
    out_dir = '/Users/xiaohan/Downloads/prima_opti_benchmark/results/benchmark_results';
    if ~exist(out_dir, 'dir'), mkdir(out_dir); end

    diary(fullfile(out_dir, 'benchmark_log.txt'));
    diary on;
    fprintf('Benchmark started: %s\n', datestr(now));

    % --- Create PRIMA wrappers for each precision ---
    solver_double = @(varargin) prima_wrapper('double', varargin{:});
    solver_single = @(varargin) prima_wrapper('single', varargin{:});
    solver_quadruple = @(varargin) prima_wrapper('quadruple', varargin{:});

    % --- Common benchmark options ---
    opts.ptype = 'ubln';       % all types: u,b,l,n
    opts.mindim = 2;
    opts.maxdim = 20;
    opts.silent = false;       % show progress
    opts.n_jobs = 1;           % single-thread to avoid parallel pool crash
    opts.score_only = true;    % skip figures (avoids display issues)
    opts.n_runs = 2;           % 2 runs per problem (speed vs statistical power)
    opts.max_eval_factor = 200; % limit evaluations

    % =====================================================================
    % Test A: double vs single, 'plain' feature
    % =====================================================================
    fprintf('\n>>> Benchmark A1: double vs single, feature=plain\n');
    opts.feature_name = 'plain';
    opts.solver_names = {'prima_double', 'prima_single'};
    try
        scores_A1 = benchmark({solver_double, solver_single}, opts);
        save(fullfile(out_dir, 'benchmark_double_vs_single_plain.mat'), 'scores_A1');
        fprintf('  [PASS] double vs single plain: scores saved.\n');
    catch ME
        fprintf('  [FAIL] %s\n', ME.message);
        save(fullfile(out_dir, 'benchmark_double_vs_single_plain_error.mat'), 'ME');
    end

    fprintf('\n>>> Benchmark A2: double vs single, feature=noisy\n');
    opts.feature_name = 'noisy';
    opts.solver_names = {'prima_double', 'prima_single'};
    try
        scores_A2 = benchmark({solver_double, solver_single}, opts);
        save(fullfile(out_dir, 'benchmark_double_vs_single_noisy.mat'), 'scores_A2');
        fprintf('  [PASS] double vs single noisy: scores saved.\n');
    catch ME
        fprintf('  [FAIL] %s\n', ME.message);
        save(fullfile(out_dir, 'benchmark_double_vs_single_noisy_error.mat'), 'ME');
    end

    % =====================================================================
    % Test B: double vs quadruple, 'plain' feature
    % =====================================================================
    fprintf('\n>>> Benchmark B1: double vs quadruple, feature=plain\n');
    opts.feature_name = 'plain';
    opts.solver_names = {'prima_double', 'prima_quadruple'};
    try
        scores_B1 = benchmark({solver_double, solver_quadruple}, opts);
        save(fullfile(out_dir, 'benchmark_double_vs_quadruple_plain.mat'), 'scores_B1');
        fprintf('  [PASS] double vs quadruple plain: scores saved.\n');
    catch ME
        fprintf('  [FAIL] %s\n', ME.message);
        save(fullfile(out_dir, 'benchmark_double_vs_quadruple_plain_error.mat'), 'ME');
    end

    fprintf('\n>>> Benchmark B2: double vs quadruple, feature=noisy\n');
    opts.feature_name = 'noisy';
    opts.solver_names = {'prima_double', 'prima_quadruple'};
    try
        scores_B2 = benchmark({solver_double, solver_quadruple}, opts);
        save(fullfile(out_dir, 'benchmark_double_vs_quadruple_noisy.mat'), 'scores_B2');
        fprintf('  [PASS] double vs quadruple noisy: scores saved.\n');
    catch ME
        fprintf('  [FAIL] %s\n', ME.message);
        save(fullfile(out_dir, 'benchmark_double_vs_quadruple_noisy_error.mat'), 'ME');
    end

    fprintf('\n=== All benchmarks completed ===\n');
    diary off;
    disp('Done.');
end

% =========================================================================
function x = prima_wrapper(precision, varargin)
    % Map OptiProfiler signatures to PRIMA's fmincon-style interface

    narg = nargin - 1;
    fun = varargin{1};
    x0  = varargin{2};

    A   = []; b = []; Aeq = []; beq = []; lb = []; ub = []; nonlcon = [];

    switch narg
        case 2  % Unconstrained
        case 4  % Bound
            lb = varargin{3}; ub = varargin{4};
        case 8  % Linear
            lb  = varargin{3}; ub = varargin{4};
            A   = varargin{5};  b = varargin{6};
            Aeq = varargin{7}; beq = varargin{8};
        case 10 % Nonlinear
            lb  = varargin{3}; ub = varargin{4};
            A   = varargin{5};  b = varargin{6};
            Aeq = varargin{7}; beq = varargin{8};
            cub = varargin{9}; ceq = varargin{10};
            nonlcon = @(x) constraint_wrapper(x, cub, ceq);
    end

    opts.precision = precision;
    opts.quiet = true;

    try
        [x, ~] = prima(fun, x0, A, b, Aeq, beq, lb, ub, nonlcon, opts);
    catch
        try
            [x, ~] = prima(fun, x0, A, b, Aeq, beq, lb, ub, nonlcon);
        catch
            x = x0;
        end
    end
end

function varargout = constraint_wrapper(x, cub, ceq)
    varargout{1} = cub(x);
    varargout{2} = ceq(x);
end
