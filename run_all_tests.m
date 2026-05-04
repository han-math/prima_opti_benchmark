function run_all_tests()
%RUN_ALL_TESTS Master script to run all tests for PRIMA and OptiProfiler benchmarking.
%
% This script:
%   Task 1: Installs and tests PRIMA, then solves the n-dimensional Rosenbrock
%           function under four constraint scenarios.
%   Task 2: Installs and tests OptiProfiler, then runs precision benchmarks
%           comparing double vs single and double vs quadruple precision.
%
% Output:
%   - Console output with test results.
%   - Figures and data saved to the `results/` directory.
%   - A summary JSON file `results/summary.json`.
%
% Dependencies: PRIMA, OptiProfiler (included in this project).
%
% Author: Han Peiqi (22344049), Sun Yat-sen University

    clc;
    fprintf('=============================================================\n');
    fprintf('  PRIMA & OptiProfiler -- Comprehensive Test Suite\n');
    fprintf('  Author: Han Peiqi (22344049), Sun Yat-sen University\n');
    fprintf('  Date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf('=============================================================\n');

    % Add paths
    addpath(genpath(fullfile(pwd, 'prima')));
    addpath(genpath(fullfile(pwd, 'optiprofiler')));

    diary_file = fullfile('results', sprintf('test_log_%s.txt', datestr(now, 'yyyymmdd_HHMMSS')));
    diary(diary_file);
    diary on;

    results_summary = struct();

    % --------------------------------------------------------------------
    %  TASK 1: PRIMA Installation and Testing
    % --------------------------------------------------------------------
    fprintf('\n\n');
    fprintf('#############################################################\n');
    fprintf('#  TASK 1: PRIMA Installation and Testing\n');
    fprintf('#############################################################\n');

    task1 = struct();

    % --- 1.1 Compile and install PRIMA ---
    fprintf('\n>>> Task 1.1: Compiling and installing PRIMA ...\n');
    try
        cd(fullfile(pwd, 'prima'));
        options_prima.debug = true;
        options_prima.single = true;
        options_prima.quadruple = true;
        setup(options_prima);
        fprintf('    [PASS] PRIMA setup completed successfully.\n');
        task1.install = 'PASS';
    catch ME
        fprintf('    [FAIL] PRIMA setup failed: %s\n', ME.message);
        task1.install = 'FAIL';
        cd(fullfile(pwd, '..'));
        return;
    end

    % --- 1.1 (continued): Run testprima ---
    fprintf('\n>>> Task 1.1 (continued): Running testprima ...\n');
    try
        testprima(false);  % false = non-release mode (more verbose)
        fprintf('    [PASS] testprima passed.\n');
        task1.testprima = 'PASS';
    catch ME
        fprintf('    [FAIL] testprima failed: %s\n', ME.message);
        task1.testprima = 'FAIL';
    end

    % --- 1.2 Extended tests ---
    fprintf('\n>>> Task 1.2: Running extended tests (testprima_ex) ...\n');
    cd(fullfile(pwd, 'matlab', 'tests'));
    try
        testprima_ex();
        fprintf('    [PASS] testprima_ex passed.\n');
        task1.testprima_ex = 'PASS';
    catch ME
        fprintf('    [WARN] testprima_ex encountered issues: %s\n', ME.message);
        task1.testprima_ex = 'FAIL';
    end
    cd(fullfile(pwd, '..', '..', '..', '..'));

    % --- 1.3 Rosenbrock function tests ---
    fprintf('\n>>> Task 1.3: Rosenbrock function tests ...\n');
    task1.rosenbrock = test_rosenbrock();

    results_summary.task1 = task1;

    % --------------------------------------------------------------------
    %  TASK 2: OptiProfiler Installation and Testing
    % --------------------------------------------------------------------
    fprintf('\n\n');
    fprintf('#############################################################\n');
    fprintf('#  TASK 2: OptiProfiler Installation and Testing\n');
    fprintf('#############################################################\n');

    task2 = struct();

    % --- 2.1 Install OptiProfiler ---
    fprintf('\n>>> Task 2.1: Installing OptiProfiler ...\n');
    cd(fullfile(pwd, 'optiprofiler'));
    try
        setup();
        fprintf('    [PASS] OptiProfiler setup completed.\n');
        task2.install = 'PASS';
    catch ME
        fprintf('    [FAIL] OptiProfiler setup failed: %s\n', ME.message);
        task2.install = 'FAIL';
        cd(fullfile(pwd, '..'));
        return;
    end

    % --- 2.2 Basic examples ---
    fprintf('\n>>> Task 2.2: Running OptiProfiler examples ...\n');
    cd(fullfile(pwd, 'matlab', 'examples'));
    examples_status = struct();

    for i = 1:4
        example_name = sprintf('example%d', i);
        fprintf('    Running %s ...\n', example_name);
        try
            eval([example_name, '();']);
            fprintf('    [PASS] %s passed.\n', example_name);
            examples_status.(example_name) = 'PASS';
        catch ME
            fprintf('    [FAIL] %s failed: %s\n', example_name, ME.message);
            examples_status.(example_name) = 'FAIL';
        end
        close all;
    end
    cd(fullfile(pwd, '..', '..', '..', '..'));
    task2.examples = examples_status;

    % --- 2.3 PRIMA performance benchmarks ---
    fprintf('\n>>> Task 2.3: Running PRIMA precision benchmarks ...\n');
    cd(fullfile(pwd, 'optiprofiler', 'matlab', 'examples'));

    % Test Group A: double vs single
    fprintf('\n    --- Test Group A: Double vs Single precision ---\n');
    task2.benchmark_double_vs_single = run_precision_benchmark('double', 'single');

    % Test Group B: double vs quadruple
    fprintf('\n    --- Test Group B: Double vs Quadruple precision ---\n');
    task2.benchmark_double_vs_quadruple = run_precision_benchmark('double', 'quadruple');

    cd(fullfile(pwd, '..', '..', '..', '..'));

    results_summary.task2 = task2;

    % --------------------------------------------------------------------
    %  Save results summary
    % --------------------------------------------------------------------
    save(fullfile('results', 'summary.mat'), 'results_summary');

    % Write a human-readable JSON-like summary
    fid = fopen(fullfile('results', 'summary.txt'), 'w');
    fprintf(fid, 'PRIMA & OptiProfiler Test Summary\n');
    fprintf(fid, '=================================\n');
    fprintf(fid, 'Date: %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, 'Task 1.1 (PRIMA install):    %s\n', task1.install);
    fprintf(fid, 'Task 1.1 (testprima):        %s\n', task1.testprima);
    fprintf(fid, 'Task 1.2 (testprima_ex):     %s\n', task1.testprima_ex);
    fprintf(fid, 'Task 1.3 (Rosenbrock):       see rosenbrock_results/\n\n');
    fprintf(fid, 'Task 2.1 (OptiProfiler install): %s\n', task2.install);
    fprintf(fid, 'Task 2.2 (examples):\n');
    for f = fieldnames(task2.examples)'
        fprintf(fid, '  %s: %s\n', f{1}, task2.examples.(f{1}));
    end
    fprintf(fid, 'Task 2.3 (benchmarks):       see benchmark_results/\n');
    fclose(fid);

    % --------------------------------------------------------------------
    %  Final summary
    % --------------------------------------------------------------------
    fprintf('\n\n');
    fprintf('=============================================================\n');
    fprintf('  ALL TESTS COMPLETED\n');
    fprintf('=============================================================\n');
    fprintf('  Task 1.1 (PRIMA install):    %s\n', task1.install);
    fprintf('  Task 1.1 (testprima):        %s\n', task1.testprima);
    fprintf('  Task 1.2 (testprima_ex):     %s\n', task1.testprima_ex);
    fprintf('  Task 1.3 (Rosenbrock):       completed\n');
    fprintf('  Task 2.1 (OptiProfiler install): %s\n', task2.install);
    fprintf('  Task 2.2 (examples):         completed\n');
    fprintf('  Task 2.3 (benchmarks):       completed\n');
    fprintf('\n  Full log saved to: %s\n', diary_file);
    fprintf('=============================================================\n');

    diary off;

end

% =========================================================================
%  Helper: Rosenbrock function tests (Task 1.3)
% =========================================================================
function rosenbrock_results = test_rosenbrock()
    % Test the n-dimensional Rosenbrock function under four constraint types.

    dims = [2, 5, 10, 20];
    x0_func = @(n) -ones(n, 1);  % Initial point: [-1, -1, ..., -1]

    % Create results directory
    out_dir = fullfile(pwd, 'results', 'rosenbrock_results');
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end

    rosenbrock_results = struct();
    rosenbrock_results.dimensions = dims;

    for n = dims
        fprintf('    Testing n = %d ...\n', n);
        x0 = x0_func(n);

        dim_result = struct();
        dim_result.n = n;
        dim_result.x0 = x0;

        % --- Case 1: Unconstrained ---
        fprintf('      Case 1: Unconstrained\n');
        try
            [x_unc, fx_unc, exitflag_unc, output_unc] = prima(@(x) chrosen(x), x0);
            dim_result.unconstrained = struct('x', x_unc, 'fx', fx_unc, ...
                'exitflag', exitflag_unc, 'funcCount', output_unc.funcCount, ...
                'nf', output_unc.nf, 'message', output_unc.message);
            fprintf('        fx = %.6e, funcCount = %d\n', fx_unc, output_unc.funcCount);
        catch ME
            fprintf('        [FAIL] %s\n', ME.message);
            dim_result.unconstrained = struct('error', ME.message);
        end

        % --- Case 2: Bound constraints x <= 0 ---
        fprintf('      Case 2: Bound constraints (x <= 0)\n');
        try
            ub = zeros(n, 1);
            [x_bnd, fx_bnd, exitflag_bnd, output_bnd] = ...
                prima(@(x) chrosen(x), x0, [], [], [], [], [], ub);
            dim_result.bound_constrained = struct('x', x_bnd, 'fx', fx_bnd, ...
                'exitflag', exitflag_bnd, 'funcCount', output_bnd.funcCount, ...
                'nf', output_bnd.nf, 'message', output_bnd.message);
            fprintf('        fx = %.6e, funcCount = %d\n', fx_bnd, output_bnd.funcCount);
        catch ME
            fprintf('        [FAIL] %s\n', ME.message);
            dim_result.bound_constrained = struct('error', ME.message);
        end

        % --- Case 3: Linear constraints sum(x) <= 1, x >= 0 ---
        fprintf('      Case 3: Linear constraints (sum(x) <= 1, x >= 0)\n');
        try
            A = ones(1, n);
            b = 1;
            lb = zeros(n, 1);
            [x_lin, fx_lin, exitflag_lin, output_lin] = ...
                prima(@(x) chrosen(x), x0, A, b, [], [], lb, []);
            dim_result.linear_constrained = struct('x', x_lin, 'fx', fx_lin, ...
                'exitflag', exitflag_lin, 'funcCount', output_lin.funcCount, ...
                'nf', output_lin.nf, 'message', output_lin.message);
            fprintf('        fx = %.6e, funcCount = %d\n', fx_lin, output_lin.funcCount);
        catch ME
            fprintf('        [FAIL] %s\n', ME.message);
            dim_result.linear_constrained = struct('error', ME.message);
        end

        % --- Case 4: Nonlinear constraints sum(x^2) <= 1, x >= 0 ---
        fprintf('      Case 4: Nonlinear constraints (sum(x^2) <= 1, x >= 0)\n');
        try
            lb = zeros(n, 1);
            nonlcon = @(x) deal(x'*x - 1, []);  % cineq = x'*x - 1 <= 0, ceq = []
            [x_nlc, fx_nlc, exitflag_nlc, output_nlc] = ...
                prima(@(x) chrosen(x), x0, [], [], [], [], lb, [], nonlcon);
            dim_result.nonlinear_constrained = struct('x', x_nlc, 'fx', fx_nlc, ...
                'exitflag', exitflag_nlc, 'funcCount', output_nlc.funcCount, ...
                'nf', output_nlc.nf, 'message', output_nlc.message);
            fprintf('        fx = %.6e, funcCount = %d\n', fx_nlc, output_nlc.funcCount);
        catch ME
            fprintf('        [FAIL] %s\n', ME.message);
            dim_result.nonlinear_constrained = struct('error', ME.message);
        end

        rosenbrock_results.(sprintf('n%d', n)) = dim_result;
    end

    % Save results
    save(fullfile(out_dir, 'rosenbrock_results.mat'), 'rosenbrock_results');

    % Generate a summary table
    fid = fopen(fullfile(out_dir, 'rosenbrock_summary.txt'), 'w');
    fprintf(fid, 'Rosenbrock Function Test Summary\n');
    fprintf(fid, '=================================\n\n');
    fprintf(fid, '%-5s %-25s %-16s %-10s %-12s\n', 'n', 'Constraint Type', 'fx', 'nf', 'ExitFlag');
    fprintf(fid, '%-5s %-25s %-16s %-10s %-12s\n', '---', '---------------', '--', '--', '--------');
    for n = dims
        dn = rosenbrock_results.(sprintf('n%d', n));
        cases = {'unconstrained', 'bound_constrained', 'linear_constrained', 'nonlinear_constrained'};
        case_labels = {'Unconstrained', 'Bound (x<=0)', 'Linear sum<=1', 'Nonlinear ||x||^2<=1'};
        for k = 1:4
            c = cases{k};
            if isfield(dn, c) && isfield(dn.(c), 'fx')
                fprintf(fid, '%-5d %-25s %-16.6e %-10d %-12d\n', ...
                    n, case_labels{k}, dn.(c).fx, dn.(c).nf, dn.(c).exitflag);
            else
                fprintf(fid, '%-5d %-25s %-16s %-10s %-12s\n', ...
                    n, case_labels{k}, 'FAILED', '-', '-');
            end
        end
        fprintf(fid, '\n');
    end
    fclose(fid);

    % Create convergence plots
    plot_rosenbrock_convergence(rosenbrock_results, out_dir);
end

% =========================================================================
%  Helper: Rosenbrock objective function
% =========================================================================
function f = chrosen(x)
    alpha = 4;
    f = sum((x(1:end-1) - 1).^2 + alpha * (x(2:end) - x(1:end-1).^2).^2);
end

% =========================================================================
%  Helper: Convergence plots for Rosenbrock
% =========================================================================
function plot_rosenbrock_convergence(rosenbrock_results, out_dir)
    figure('Position', [100, 100, 1200, 800]);

    dims = [2, 5, 10, 20];
    case_labels = {'Unconstrained', 'Bound (x<=0)', 'Linear sum<=1', 'Nonlinear ||x||^2<=1'};
    cases = {'unconstrained', 'bound_constrained', 'linear_constrained', 'nonlinear_constrained'};
    colors = lines(4);

    % Subplot: fx vs dimension for each case (log scale)
    for k = 1:4
        subplot(2, 2, k);
        fx_vals = [];
        valid_dims = [];
        for n = dims
            dn = rosenbrock_results.(sprintf('n%d', n));
            if isfield(dn, cases{k}) && isfield(dn.(cases{k}), 'fx')
                fx_vals = [fx_vals; dn.(cases{k}).fx];
                valid_dims = [valid_dims; n];
            end
        end
        if ~isempty(valid_dims)
            semilogy(valid_dims, fx_vals, 'o-', 'Color', colors(k,:), 'LineWidth', 2, 'MarkerSize', 8);
        end
        xlabel('Dimension n');
        ylabel('f(x^*) (log scale)');
        title(sprintf('Rosenbrock -- %s', case_labels{k}));
        grid on;
    end

    sgtitle('Rosenbrock Function Optimization Results', 'FontSize', 14);
    saveas(gcf, fullfile(out_dir, 'rosenbrock_fx_vs_dim.png'));
    close(gcf);

    % Subplot: function evaluations vs dimension
    figure('Position', [100, 100, 1200, 800]);
    for k = 1:4
        subplot(2, 2, k);
        nf_vals = [];
        valid_dims = [];
        for n = dims
            dn = rosenbrock_results.(sprintf('n%d', n));
            if isfield(dn, cases{k}) && isfield(dn.(cases{k}), 'nf')
                nf_vals = [nf_vals; dn.(cases{k}).nf];
                valid_dims = [valid_dims; n];
            end
        end
        if ~isempty(valid_dims)
            plot(valid_dims, nf_vals, 's-', 'Color', colors(k,:), 'LineWidth', 2, 'MarkerSize', 8);
        end
        xlabel('Dimension n');
        ylabel('Function evaluations');
        title(sprintf('Function Evaluations -- %s', case_labels{k}));
        grid on;
    end
    sgtitle('PRIMA Function Evaluations for Rosenbrock Problem', 'FontSize', 14);
    saveas(gcf, fullfile(out_dir, 'rosenbrock_nf_vs_dim.png'));
    close(gcf);
end

% =========================================================================
%  Helper: Precision benchmark (Task 2.3)
% =========================================================================
function bm_result = run_precision_benchmark(precision1, precision2)
    % Run OptiProfiler benchmark comparing two PRIMA precision settings.

    % Create parameterized solver wrappers with full constraint signatures.
    % OptiProfiler calls solvers with different numbers of arguments depending
    % on the problem type (unconstrained, bound, linear, nonlinear).
    solver1 = @(varargin) prima_wrapper(precision1, varargin{:});
    solver2 = @(varargin) prima_wrapper(precision2, varargin{:});

    solver_names = {sprintf('prima_%s', precision1), sprintf('prima_%s', precision2)};

    % Benchmark options
    options.ptype = 'ubln';            % All problem types: unconstrained, bound, linear, nonlinear
    options.mindim = 2;                % Minimum dimension
    options.maxdim = 20;               % Maximum dimension
    options.solver_names = solver_names;

    bm_result = struct();

    % --- Test with 'plain' feature ---
    fprintf('      Benchmark with feature = ''plain'' ...\n');
    options.feature_name = 'plain';
    try
        scores_plain = benchmark({solver1, solver2}, options);
        bm_result.plain = scores_plain;
        fprintf('      [PASS] plain benchmark completed.\n');
    catch ME
        fprintf('      [FAIL] plain benchmark: %s\n', ME.message);
        bm_result.plain = struct('error', ME.message);
    end

    % --- Test with 'noisy' feature ---
    fprintf('      Benchmark with feature = ''noisy'' ...\n');
    options.feature_name = 'noisy';
    try
        scores_noisy = benchmark({solver1, solver2}, options);
        bm_result.noisy = scores_noisy;
        fprintf('      [PASS] noisy benchmark completed.\n');
    catch ME
        fprintf('      [FAIL] noisy benchmark: %s\n', ME.message);
        bm_result.noisy = struct('error', ME.message);
    end

    % Save individual benchmark results
    bm_dir = fullfile(pwd, 'results', 'benchmark_results');
    if ~exist(bm_dir, 'dir')
        mkdir(bm_dir);
    end
    bm_filename = sprintf('benchmark_%s_vs_%s.mat', precision1, precision2);
    save(fullfile(bm_dir, bm_filename), 'bm_result');
end

% =========================================================================
%  Helper: PRIMA wrapper with full signature support for OptiProfiler
% =========================================================================
function x = prima_wrapper(precision, varargin)
    % Wrapper for PRIMA that supports all OptiProfiler constraint signatures.
    %
    % OptiProfiler calls solvers with these signatures:
    %   Unconstrained:     solver(fun, x0)
    %   Bound:             solver(fun, x0, xl, xu)
    %   Linear:            solver(fun, x0, xl, xu, aub, bub, aeq, beq)
    %   Nonlinear:         solver(fun, x0, xl, xu, aub, bub, aeq, beq, cub, ceq)
    %
    % Map to PRIMA: prima(fun, x0, A, b, Aeq, beq, lb, ub, nonlcon, options)

    narg = nargin - 1;  % number of args after precision

    fun = varargin{1};
    x0  = varargin{2};

    % Set up constraint arguments with defaults
    A   = [];
    b   = [];
    Aeq = [];
    beq = [];
    lb  = [];
    ub  = [];
    nonlcon = [];

    switch narg
        case 2
            % Unconstrained
        case 4
            % Bound-constrained: (fun, x0, xl, xu)
            lb = varargin{3};
            ub = varargin{4};
        case 8
            % Linearly-constrained: (fun, x0, xl, xu, aub, bub, aeq, beq)
            lb  = varargin{3};
            ub  = varargin{4};
            A   = varargin{5};
            b   = varargin{6};
            Aeq = varargin{7};
            beq = varargin{8};
        case 10
            % Nonlinearly-constrained: (fun, x0, xl, xu, aub, bub, aeq, beq, cub, ceq)
            lb  = varargin{3};
            ub  = varargin{4};
            A   = varargin{5};
            b   = varargin{6};
            Aeq = varargin{7};
            beq = varargin{8};
            % Combine cub and ceq into a single nonlcon for PRIMA
            cub = varargin{9};
            ceq = varargin{10};
            nonlcon = @(x) constraint_wrapper(x, cub, ceq);
    end

    options_prima.precision = precision;
    options_prima.quiet = true;

    try
        [x, ~] = prima(fun, x0, A, b, Aeq, beq, lb, ub, nonlcon, options_prima);
    catch
        % Retry without precision option
        try
            [x, ~] = prima(fun, x0, A, b, Aeq, beq, lb, ub, nonlcon);
        catch
            x = x0;  % Return initial point on failure
        end
    end
end

function varargout = constraint_wrapper(x, cub, ceq)
    % Wrapper to match PRIMA's nonlcon signature [cineq, ceq] = nonlcon(x)
    varargout{1} = cub(x);
    varargout{2} = ceq(x);
end
