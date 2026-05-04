% Standalone Rosenbrock test - saves results before potential MATLAB crash
function test_rosenbrock_run()
    addpath('/Users/xiaohan/Downloads/prima_opti_benchmark/prima/matlab/interfaces');

    out_dir = '/Users/xiaohan/Downloads/prima_opti_benchmark/results/rosenbrock_results';
    if ~exist(out_dir, 'dir'), mkdir(out_dir); end

    dims = 2:20;
    diary(fullfile(out_dir, 'rosenbrock_log.txt'));
    diary on;

    fprintf('Rosenbrock Test Started: %s\n', datestr(now));

    results = struct();
    results.dimensions = dims;

    for n = dims
        fprintf('\n>>> Testing n = %d\n', n);
        x0 = -ones(n, 1);

        % --- Case 1: Unconstrained ---
        fprintf('  Case 1: Unconstrained\n');
        [x, fx, exitflag, output] = prima(@chrosen, x0);
        results.(sprintf('n%d', n)).unconstrained = struct(...
            'n', n, 'x', x, 'fx', fx, 'exitflag', exitflag, ...
            'funcCount', output.funcCount, 'message', output.message);
        fprintf('    fx=%.6e  nf=%d  exitflag=%d\n', fx, output.funcCount, exitflag);
        save(fullfile(out_dir, 'rosenbrock_results.mat'), 'results');

        % --- Case 2: Bound constraints x <= 0 ---
        fprintf('  Case 2: Bound (x <= 0)\n');
        ub = zeros(n, 1);
        [x, fx, exitflag, output] = prima(@chrosen, x0, [], [], [], [], [], ub);
        results.(sprintf('n%d', n)).bound = struct(...
            'n', n, 'x', x, 'fx', fx, 'exitflag', exitflag, ...
            'funcCount', output.funcCount, 'message', output.message);
        fprintf('    fx=%.6e  nf=%d  exitflag=%d\n', fx, output.funcCount, exitflag);
        save(fullfile(out_dir, 'rosenbrock_results.mat'), 'results');

        % --- Case 3: Linear constraints sum(x) <= 1, x >= 0 ---
        fprintf('  Case 3: Linear (sum(x) <= 1, x >= 0)\n');
        A = ones(1, n); b = 1; lb = zeros(n, 1);
        [x, fx, exitflag, output] = prima(@chrosen, x0, A, b, [], [], lb);
        results.(sprintf('n%d', n)).linear = struct(...
            'n', n, 'x', x, 'fx', fx, 'exitflag', exitflag, ...
            'funcCount', output.funcCount, 'message', output.message);
        fprintf('    fx=%.6e  nf=%d  exitflag=%d\n', fx, output.funcCount, exitflag);
        save(fullfile(out_dir, 'rosenbrock_results.mat'), 'results');

        % --- Case 4: Nonlinear constraints ||x||^2 <= 1, x >= 0 ---
        fprintf('  Case 4: Nonlinear (||x||^2 <= 1, x >= 0)\n');
        nonlcon = @(x) deal(x'*x - 1, []); lb = zeros(n, 1);
        [x, fx, exitflag, output] = prima(@chrosen, x0, [], [], [], [], lb, [], nonlcon);
        results.(sprintf('n%d', n)).nonlinear = struct(...
            'n', n, 'x', x, 'fx', fx, 'exitflag', exitflag, ...
            'funcCount', output.funcCount, 'message', output.message);
        fprintf('    fx=%.6e  nf=%d  exitflag=%d\n', fx, output.funcCount, exitflag);
        save(fullfile(out_dir, 'rosenbrock_results.mat'), 'results');
    end

    fprintf('\n=== Rosenbrock Tests Complete ===\n');
    diary off;
    disp('Results saved to rosenbrock_results.mat');
end

function f = chrosen(x)
    alpha = 100;
    f = sum((x(1:end-1) - 1).^2 + alpha * (x(2:end) - x(1:end-1).^2).^2);
end
