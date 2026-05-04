function test_rosenbrock_standalone()
%TEST_ROSENBROCK_STANDALONE Standalone Rosenbrock function optimization tests.
%
% This script solves the n-dimensional Rosenbrock function using PRIMA under
% four constraint scenarios:
%   1. Unconstrained
%   2. Bound constraints: x <= 0
%   3. Linear constraints: sum(x) <= 1, x >= 0
%   4. Nonlinear constraints: sum(x^2) <= 1, x >= 0
%
% The initial point is [-1, -1, ..., -1] for dimensions n = 2, 5, 10, 20.
%
% Dependencies: PRIMA must be set up (run prima/setup.m first).
%
% Author: Han Peiqi (22344049), Sun Yat-sen University

    clc;
    fprintf('=============================================================\n');
    fprintf('  Rosenbrock Function Optimization -- PRIMA Solver\n');
    fprintf('=============================================================\n\n');

    % Ensure PRIMA is on the path
    if exist('prima', 'file') ~= 2
        error('PRIMA not found on MATLAB path. Run prima/setup.m first.');
    end

    % Test dimensions
    dims = [2, 5, 10, 20];

    % Create output directory
    out_dir = fullfile('results', 'rosenbrock_standalone');
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end

    diary(fullfile(out_dir, 'rosenbrock_log.txt'));
    diary on;

    % Store all results
    all_results = struct();

    for idx = 1:length(dims)
        n = dims(idx);
        x0 = -ones(n, 1);  % Initial point: [-1, -1, ..., -1]

        fprintf('\n==========================================\n');
        fprintf('  Dimension n = %d\n', n);
        fprintf('  Initial point: x0 = [-1, -1, ..., -1]\n');
        fprintf('==========================================\n');

        % ---------------------------------------------------------------
        % Case 1: Unconstrained
        % ---------------------------------------------------------------
        fprintf('\n--- Case 1: Unconstrained ---\n');
        tic;
        [x1, fx1, exitflag1, output1] = prima(@chrosen, x0);
        t1 = toc;
        fprintf('  f(x*)  = %.10e\n', fx1);
        fprintf('  ||x*|| = %.6e\n', norm(x1));
        fprintf('  nf     = %d (function evaluations)\n', output1.nf);
        fprintf('  time   = %.4f s\n', t1);
        fprintf('  flag   = %d (%s)\n', exitflag1, output1.message);

        % ---------------------------------------------------------------
        % Case 2: Bound constraints x <= 0
        % ---------------------------------------------------------------
        fprintf('\n--- Case 2: Bound Constraints (x <= 0) ---\n');
        ub = zeros(n, 1);
        tic;
        [x2, fx2, exitflag2, output2] = prima(@chrosen, x0, [], [], [], [], [], ub);
        t2 = toc;
        fprintf('  f(x*)  = %.10e\n', fx2);
        fprintf('  max(x) = %.6e (should be <= 0)\n', max(x2));
        fprintf('  nf     = %d\n', output2.nf);
        fprintf('  time   = %.4f s\n', t2);
        fprintf('  flag   = %d (%s)\n', exitflag2, output2.message);

        % ---------------------------------------------------------------
        % Case 3: Linear constraints sum(x) <= 1, x >= 0
        % ---------------------------------------------------------------
        fprintf('\n--- Case 3: Linear Constraints (sum(x) <= 1, x >= 0) ---\n');
        A = ones(1, n);
        b = 1;
        lb = zeros(n, 1);
        tic;
        [x3, fx3, exitflag3, output3] = prima(@chrosen, x0, A, b, [], [], lb, []);
        t3 = toc;
        fprintf('  f(x*)  = %.10e\n', fx3);
        fprintf('  sum(x) = %.6e (should be <= 1)\n', sum(x3));
        fprintf('  min(x) = %.6e (should be >= 0)\n', min(x3));
        fprintf('  nf     = %d\n', output3.nf);
        fprintf('  time   = %.4f s\n', t3);
        fprintf('  flag   = %d (%s)\n', exitflag3, output3.message);

        % ---------------------------------------------------------------
        % Case 4: Nonlinear constraints sum(x^2) <= 1, x >= 0
        % ---------------------------------------------------------------
        fprintf('\n--- Case 4: Nonlinear Constraints (||x||^2 <= 1, x >= 0) ---\n');
        lb = zeros(n, 1);
        tic;
        [x4, fx4, exitflag4, output4] = prima(@chrosen, x0, [], [], [], [], lb, [], @ballcon);
        t4 = toc;
        fprintf('  f(x*)  = %.10e\n', fx4);
        fprintf('  ||x||^2 = %.6e (should be <= 1)\n', sum(x4.^2));
        fprintf('  min(x) = %.6e (should be >= 0)\n', min(x4));
        fprintf('  nf     = %d\n', output4.nf);
        fprintf('  time   = %.4f s\n', t4);
        fprintf('  flag   = %d (%s)\n', exitflag4, output4.message);

        % Store results
        all_results.(sprintf('n%d', n)) = struct( ...
            'dimension', n, ...
            'x0', x0, ...
            'unconstrained',      struct('x', x1, 'fx', fx1, 'nf', output1.nf, 'time', t1, 'exitflag', exitflag1), ...
            'bound_constrained',  struct('x', x2, 'fx', fx2, 'nf', output2.nf, 'time', t2, 'exitflag', exitflag2), ...
            'linear_constrained', struct('x', x3, 'fx', fx3, 'nf', output3.nf, 'time', t3, 'exitflag', exitflag3), ...
            'nonlinear_constrained', struct('x', x4, 'fx', fx4, 'nf', output4.nf, 'time', t4, 'exitflag', exitflag4) ...
        );
    end

    % Save all results
    save(fullfile(out_dir, 'all_results.mat'), 'all_results');

    % Generate summary table
    fprintf('\n\n=============================================================\n');
    fprintf('  SUMMARY TABLE\n');
    fprintf('=============================================================\n');
    fprintf('%-5s | %-20s | %-16s | %-8s | %-8s | %-10s\n', ...
        'n', 'Constraint', 'f(x*)', 'nf', 'Time(s)', 'ExitFlag');
    fprintf([repmat('-', 1, 76), '\n']);

    case_names = {'unconstrained', 'bound_constrained', 'linear_constrained', 'nonlinear_constrained'};
    case_labels = {'Unconstrained', 'Bound (x<=0)', 'Linear sum<=1', 'Nonlinear ||x||^2<=1'};

    for n = dims
        dn = all_results.(sprintf('n%d', n));
        for k = 1:4
            c = case_names{k};
            d = dn.(c);
            fprintf('%-5d | %-20s | %-16.6e | %-8d | %-8.4f | %-10d\n', ...
                n, case_labels{k}, d.fx, d.nf, d.time, d.exitflag);
        end
        fprintf([repmat('-', 1, 76), '\n']);
    end

    % Create visualization
    plot_rosenbrock_results(all_results, out_dir);

    diary off;
    fprintf('\nResults saved to: %s\n', out_dir);
    fprintf('Done.\n');
end

% =========================================================================
function f = chrosen(x)
    alpha = 4;
    f = sum((x(1:end-1) - 1).^2 + alpha * (x(2:end) - x(1:end-1).^2).^2);
end

% =========================================================================
function [cineq, ceq] = ballcon(x)
    cineq = x'*x - 1;  % ||x||^2 <= 1
    ceq = [];            % no equality constraints
end

% =========================================================================
function plot_rosenbrock_results(all_results, out_dir)
    dims = [2, 5, 10, 20];
    case_names = {'unconstrained', 'bound_constrained', 'linear_constrained', 'nonlinear_constrained'};
    case_labels = {'Unconstrained', 'Bound (x<=0)', 'Linear sum<=1', 'Nonlinear ||x||^2<=1'};
    colors = lines(4);
    markers = {'o', 's', '^', 'd'};

    % Plot 1: Final f(x*) vs dimension (log)
    figure('Position', [100, 100, 1200, 500]);
    subplot(1,2,1);
    for k = 1:4
        fx_vals = zeros(length(dims), 1);
        for j = 1:length(dims)
            dn = all_results.(sprintf('n%d', dims(j)));
            fx_vals(j) = dn.(case_names{k}).fx;
        end
        semilogy(dims, fx_vals, [markers{k}, '-'], 'Color', colors(k,:), ...
            'LineWidth', 1.5, 'MarkerSize', 8, 'DisplayName', case_labels{k});
        hold on;
    end
    xlabel('Dimension n');
    ylabel('f(x^*) (log scale)');
    title('Optimal Function Value vs Dimension');
    legend('Location', 'northwest');
    grid on;
    hold off;

    % Plot 2: Function evaluations vs dimension
    subplot(1,2,2);
    for k = 1:4
        nf_vals = zeros(length(dims), 1);
        for j = 1:length(dims)
            dn = all_results.(sprintf('n%d', dims(j)));
            nf_vals(j) = dn.(case_names{k}).nf;
        end
        plot(dims, nf_vals, [markers{k}, '-'], 'Color', colors(k,:), ...
            'LineWidth', 1.5, 'MarkerSize', 8, 'DisplayName', case_labels{k});
        hold on;
    end
    xlabel('Dimension n');
    ylabel('Function evaluations');
    title('Function Evaluations vs Dimension');
    legend('Location', 'northwest');
    grid on;
    hold off;

    sgtitle('PRIMA Rosenbrock Function Optimization Results');
    saveas(gcf, fullfile(out_dir, 'rosenbrock_results.png'));
    close(gcf);

    % Plot 3: Computation time vs dimension
    figure('Position', [100, 100, 600, 450]);
    for k = 1:4
        time_vals = zeros(length(dims), 1);
        for j = 1:length(dims)
            dn = all_results.(sprintf('n%d', dims(j)));
            time_vals(j) = dn.(case_names{k}).time;
        end
        plot(dims, time_vals, [markers{k}, '-'], 'Color', colors(k,:), ...
            'LineWidth', 1.5, 'MarkerSize', 8, 'DisplayName', case_labels{k});
        hold on;
    end
    xlabel('Dimension n');
    ylabel('Time (seconds)');
    title('Computation Time vs Dimension');
    legend('Location', 'northwest');
    grid on;
    hold off;
    saveas(gcf, fullfile(out_dir, 'rosenbrock_time.png'));
    close(gcf);
end
