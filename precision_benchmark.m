% PRIMA Precision Benchmark
% Compares double vs single and double vs quadruple precision
% on standard test problems (unconstrained, bound, linear, nonlinear)
function precision_benchmark()

    addpath('/Users/xiaohan/Downloads/prima_opti_benchmark/prima/matlab/interfaces');

    out_dir = '/Users/xiaohan/Downloads/prima_opti_benchmark/results/benchmark_results';
    if ~exist(out_dir, 'dir'), mkdir(out_dir); end

    diary(fullfile(out_dir, 'precision_benchmark_log.txt'));
    diary on;
    fprintf('Precision Benchmark started: %s\n', datestr(now));

    % =====================================================================
    % Define test problems covering all constraint types and dimensions
    % =====================================================================
    problems = define_problems();
    precisions = {'single', 'double', 'quadruple'};
    n_runs = 3;  % runs per problem (with different noise seeds)

    fprintf('Testing %d problems with %d precisions, %d runs each\n', ...
        length(problems), length(precisions), n_runs);
    fprintf('Total: %d solver calls\n\n', length(problems) * length(precisions) * n_runs);

    results = struct();
    summary = [];

    for ip = 1:length(problems)
        prob = problems{ip};
        fprintf('--- Problem %d/%d: %s (n=%d, type=%s) ---\n', ...
            ip, length(problems), prob.name, prob.n, prob.ptype);

        for irun = 1:n_runs
            rng(irun * 100 + ip);  % reproducible noise

            if irun == 1
                noise_level = 0;  % plain (no noise)
                feat_label = 'plain';
            else
                noise_level = 1e-6;  % noisy
                feat_label = 'noisy';
            end

            for iprec = 1:length(precisions)
                prec = precisions{iprec};
                prima_opts.precision = prec;
                prima_opts.quiet = true;
                prima_opts.maxfun = min(500 * prob.n, 10000);

                % Create objective with optional noise
                fun_noisy = @(x) prob.fun(x) * (1 + noise_level * randn());

                tic;
                try
                    [x, fx, exitflag, output] = prima(fun_noisy, prob.x0, ...
                        prob.A, prob.b, prob.Aeq, prob.beq, ...
                        prob.lb, prob.ub, prob.nonlcon, prima_opts);
                    t = toc;
                    success = true;
                catch ME
                    t = toc;
                    fx = NaN; exitflag = -1; success = false;
                    output.funcCount = NaN;
                    output.algorithm = 'fail';
                end

                r = struct('problem', prob.name, 'n', prob.n, 'ptype', prob.ptype, ...
                    'precision', prec, 'feature', feat_label, 'run', irun, ...
                    'fx', fx, 'funcCount', output.funcCount, ...
                    'time', t, 'exitflag', exitflag, 'success', success);

                if success
                    fprintf('  [%s][%s] fx=%.4e  nf=%5d  t=%.2fs  [%s]\n', ...
                        prec, feat_label, fx, output.funcCount, t, output.algorithm);
                else
                    fprintf('  [%s][%s] FAILED\n', prec, feat_label);
                end

                summary = [summary; r];
            end
        end

        % Save intermediate results
        save(fullfile(out_dir, 'precision_results.mat'), 'results', 'summary');
    end

    % =====================================================================
    % Generate summary statistics
    % =====================================================================
    fprintf('\n\n========================================\n');
    fprintf('  PRECISION COMPARISON SUMMARY\n');
    fprintf('========================================\n');

    generate_summary(summary, out_dir);

    fprintf('\nBenchmark completed: %s\n', datestr(now));
    diary off;
end

function problems = define_problems()
    % Define a diverse set of test problems

    problems = {};

    % --- Unconstrained ---
    % Rosenbrock (n=2, 5, 10)
    for n = 2:20
        problems{end+1} = struct('name', sprintf('Rosenbrock_n%d', n), ...
            'n', n, 'ptype', 'u', ...
            'fun', @(x) sum((x(1:end-1)-1).^2 + 100*(x(2:end)-x(1:end-1).^2).^2), ...
            'x0', -ones(n,1), ...
            'A', [], 'b', [], 'Aeq', [], 'beq', [], 'lb', [], 'ub', [], 'nonlcon', []);
    end

    % Sphere (n=5, 10, 15)
    for n = 2:20
        problems{end+1} = struct('name', sprintf('Sphere_n%d', n), ...
            'n', n, 'ptype', 'u', ...
            'fun', @(x) sum(x.^2), ...
            'x0', 5*ones(n,1), ...
            'A', [], 'b', [], 'Aeq', [], 'beq', [], 'lb', [], 'ub', [], 'nonlcon', []);
    end

    % Rastrigin-like (n=5, 10)
    for n = 2:20
        problems{end+1} = struct('name', sprintf('Rastrigin_n%d', n), ...
            'n', n, 'ptype', 'u', ...
            'fun', @(x) 10*n + sum(x.^2 - 10*cos(2*pi*x)), ...
            'x0', 3*ones(n,1), ...
            'A', [], 'b', [], 'Aeq', [], 'beq', [], 'lb', [], 'ub', [], 'nonlcon', []);
    end

    % --- Bound-constrained ---
    % Rosenbrock with bounds x <= 0 (n=2, 5, 10)
    for n = 2:20
        problems{end+1} = struct('name', sprintf('Rosenbrock_Bound_n%d', n), ...
            'n', n, 'ptype', 'b', ...
            'fun', @(x) sum((x(1:end-1)-1).^2 + 100*(x(2:end)-x(1:end-1).^2).^2), ...
            'x0', -ones(n,1), ...
            'A', [], 'b', [], 'Aeq', [], 'beq', [], ...
            'lb', [], 'ub', zeros(n,1), 'nonlcon', []);
    end

    % Sphere with bound x >= 1 (n=5, 10)
    for n = 2:20
        problems{end+1} = struct('name', sprintf('Sphere_Bound_n%d', n), ...
            'n', n, 'ptype', 'b', ...
            'fun', @(x) sum(x.^2), ...
            'x0', 2*ones(n,1), ...
            'A', [], 'b', [], 'Aeq', [], 'beq', [], ...
            'lb', ones(n,1), 'ub', [], 'nonlcon', []);
    end

    % --- Linearly-constrained ---
    % Rosenbrock with sum(x) <= 1, x >= 0
    for n = 2:20
        problems{end+1} = struct('name', sprintf('Rosenbrock_Linear_n%d', n), ...
            'n', n, 'ptype', 'l', ...
            'fun', @(x) sum((x(1:end-1)-1).^2 + 100*(x(2:end)-x(1:end-1).^2).^2), ...
            'x0', -ones(n,1), ...
            'A', ones(1,n), 'b', 1, 'Aeq', [], 'beq', [], ...
            'lb', zeros(n,1), 'ub', [], 'nonlcon', []);
    end

    % --- Nonlinearly-constrained ---
    % Rosenbrock with ||x||^2 <= 1, x >= 0
    for n = 2:20
        problems{end+1} = struct('name', sprintf('Rosenbrock_Nonlinear_n%d', n), ...
            'n', n, 'ptype', 'n', ...
            'fun', @(x) sum((x(1:end-1)-1).^2 + 100*(x(2:end)-x(1:end-1).^2).^2), ...
            'x0', -ones(n,1), ...
            'A', [], 'b', [], 'Aeq', [], 'beq', [], ...
            'lb', zeros(n,1), 'ub', [], ...
            'nonlcon', @(x) deal(x'*x - 1, []));
    end

    % Sphere with nonlinear constraint ||x||^2 <= 4 (n=5, 10)
    for n = 2:20
        problems{end+1} = struct('name', sprintf('Sphere_Nonlinear_n%d', n), ...
            'n', n, 'ptype', 'n', ...
            'fun', @(x) sum(x.^2), ...
            'x0', 3*ones(n,1), ...
            'A', [], 'b', [], 'Aeq', [], 'beq', [], ...
            'lb', [], 'ub', [], ...
            'nonlcon', @(x) deal(x'*x - 4, []));
    end

    fprintf('Defined %d test problems\n', length(problems));
end

function generate_summary(summary, out_dir)
    % Extract summary statistics

    fid = fopen(fullfile(out_dir, 'precision_summary.txt'), 'w');
    fprintf(fid, 'PRIMA Precision Comparison Summary\n');
    fprintf(fid, '==================================\n\n');

    precs = {'single', 'double', 'quadruple'};
    features = {'plain', 'noisy'};

    for f = 1:2
        feat = features{f};
        fprintf(fid, 'Feature: %s\n', feat);
        fprintf(fid, '----------------------------------\n');

        % Filter data for this feature
        for i = 1:length(precs)
            p = precs{i};
            mask = strcmp({summary.precision}, p) & strcmp({summary.feature}, feat) & [summary.success];
            if sum(mask) > 0
                fx_vals = [summary(mask).fx];
                nf_vals = [summary(mask).funcCount];
                t_vals = [summary(mask).time];
                fprintf(fid, '  %-12s: n=%d  median(fx)=%.4e  mean(nf)=%.1f  mean(t)=%.2fs\n', ...
                    p, sum(mask), median(abs(fx_vals)), mean(nf_vals), mean(t_vals));
            end
        end

        % Double vs Single comparison
        mask_ds_d = strcmp({summary.precision}, 'double') & strcmp({summary.feature}, feat) & [summary.success];
        mask_ds_s = strcmp({summary.precision}, 'single') & strcmp({summary.feature}, feat) & [summary.success];
        if sum(mask_ds_d) > 0 && sum(mask_ds_s) > 0
            n = min(sum(mask_ds_d), sum(mask_ds_s));
            fx_ratio = abs([summary(mask_ds_d).fx]) ./ max(abs([summary(mask_ds_s).fx]), eps);
            nf_ratio = [summary(mask_ds_d).funcCount] ./ max([summary(mask_ds_s).funcCount], 1);
            fprintf(fid, '  Double vs Single:\n');
            fprintf(fid, '    fx ratio: mean=%.4f median=%.4f\n', mean(fx_ratio(1:n)), median(fx_ratio(1:n)));
            fprintf(fid, '    nf ratio: mean=%.4f median=%.4f\n', mean(nf_ratio(1:n)), median(nf_ratio(1:n)));
        end

        % Double vs Quadruple comparison
        mask_dq_d = strcmp({summary.precision}, 'double') & strcmp({summary.feature}, feat) & [summary.success];
        mask_dq_q = strcmp({summary.precision}, 'quadruple') & strcmp({summary.feature}, feat) & [summary.success];
        if sum(mask_dq_d) > 0 && sum(mask_dq_q) > 0
            n = min(sum(mask_dq_d), sum(mask_dq_q));
            fx_ratio = abs([summary(mask_dq_d).fx]) ./ max(abs([summary(mask_dq_q).fx]), eps);
            nf_ratio = [summary(mask_dq_d).funcCount] ./ max([summary(mask_dq_q).funcCount], 1);
            fprintf(fid, '  Double vs Quadruple:\n');
            fprintf(fid, '    fx ratio: mean=%.4f median=%.4f\n', mean(fx_ratio(1:n)), median(fx_ratio(1:n)));
            fprintf(fid, '    nf ratio: mean=%.4f median=%.4f\n', mean(nf_ratio(1:n)), median(nf_ratio(1:n)));
        end

        fprintf(fid, '\n');
    end

    fclose(fid);
    fprintf('\nSummary saved to %s\n', fullfile(out_dir, 'precision_summary.txt'));
end
