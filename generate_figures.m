% Generate all figures for the PRIMA & OptiProfiler test report
% Dynamically loads from .mat result files (supports arbitrary dimensions)
function generate_figures()

    out_dir = '/Users/xiaohan/Downloads/prima_opti_benchmark/results/figures';
    if ~exist(out_dir, 'dir'), mkdir(out_dir); end

    fprintf('Generating figures for report...\n');

    colors = [0.0 0.45 0.74; 0.85 0.33 0.10; 0.93 0.69 0.13; 0.49 0.18 0.56];
    case_labels = {'Unconstrained', 'Bound: x <= 0', 'Linear: \Sigma x <= 1', 'Nonlinear: ||x||^2 <= 1'};
    markers = {'o-', 's-', 'd-', '^-'};

    % =====================================================================
    % LOAD DATA
    % =====================================================================
    rb_file = '/Users/xiaohan/Downloads/prima_opti_benchmark/results/rosenbrock_results/rosenbrock_results.mat';
    if ~exist(rb_file, 'file'), error('Rosenbrock results not found'); end
    rb = load(rb_file); rb = rb.results;
    dims = rb.dimensions;  % e.g. 2:20
    nd = length(dims);

    % Extract fx and nf arrays for all dimensions
    fx_data = zeros(nd, 4);
    nf_data = zeros(nd, 4);
    solver_data = cell(nd, 4);
    cases = {'unconstrained', 'bound', 'linear', 'nonlinear'};

    for i = 1:nd
        n = dims(i);
        fn = sprintf('n%d', n);
        for j = 1:4
            s = rb.(fn).(cases{j});
            fx_data(i,j) = abs(s.fx);
            nf_data(i,j) = s.funcCount;
            solver_data{i,j} = s.message;
        end
    end

    % =====================================================================
    % Figure 1: Rosenbrock f(x*) vs n + function evaluations vs n
    % =====================================================================
    fprintf('  Figure 1: Rosenbrock f(x*) vs dimension (n=%d..%d)\n', dims(1), dims(end));

    fig = figure('Visible', 'off', 'Position', [100 100 1000 400]);

    subplot(1,2,1);
    for k = 1:4
        semilogy(dims, fx_data(:,k), markers{k}, 'Color', colors(k,:), ...
            'LineWidth', 2, 'MarkerSize', 7, 'MarkerFaceColor', colors(k,:));
        hold on;
    end
    xlabel('Dimension n', 'FontSize', 12);
    ylabel('f(x^*)  (log scale)', 'FontSize', 12);
    title('Optimal Function Value', 'FontSize', 13, 'FontWeight', 'bold');
    grid on; box on;
    set(gca, 'FontSize', 11);
    set(gca, 'XTick', dims);

    subplot(1,2,2);
    for k = 1:4
        plot(dims, nf_data(:,k), markers{k}, 'Color', colors(k,:), ...
            'LineWidth', 2, 'MarkerSize', 7, 'MarkerFaceColor', colors(k,:));
        hold on;
    end
    xlabel('Dimension n', 'FontSize', 12);
    ylabel('Function Evaluations', 'FontSize', 12);
    title('Function Evaluations', 'FontSize', 13, 'FontWeight', 'bold');
    grid on; box on;
    set(gca, 'FontSize', 11);
    set(gca, 'XTick', dims);

    Lg = legend(case_labels, 'Orientation', 'horizontal', 'FontSize', 9, ...
        'Position', [0.12 0.97 0.76 0.03]);
    Lg.Box = 'off';

    exportgraphics(fig, fullfile(out_dir, 'rosenbrock_results.pdf'), ...
        'ContentType', 'vector', 'BackgroundColor', 'white');
    close(fig);
    fprintf('    -> rosenbrock_results.pdf\n');

    % =====================================================================
    % Figure 2: Solver auto-selection map across dimensions
    % =====================================================================
    fprintf('  Figure 2: Rosenbrock solver auto-selection\n');

    solver_names = {'UOBYQA', 'NEWUOA', 'BOBYQA', 'LINCOA', 'COBYLA'};

    % Build solver index matrix
    solver_idx = zeros(nd, 4);
    for i = 1:nd
        for j = 1:4
            sol = solver_data{i,j};
            [~, idx] = ismember(sol, solver_names);
            if idx == 0, idx = 1; end
            solver_idx(i,j) = idx;
        end
    end

    fig = figure('Visible', 'off', 'Position', [100 100 1000 400]);

    % Left: solver selection heatmap
    subplot(1,2,1);
    imagesc(1:4, dims, solver_idx);
    colormap(gca, [0.0 0.45 0.74; 0.0 0.75 0.75; 0.85 0.33 0.10; 0.93 0.69 0.13; 0.49 0.18 0.56]);
    caxis([1 5]);
    set(gca, 'XTick', 1:4, 'XTickLabel', {'Unc.', 'Bound', 'Linear', 'Nonlin.'}, 'FontSize', 11);
    set(gca, 'YTick', dims);
    ylabel('Dimension n', 'FontSize', 12);
    title('Solver Auto-Selection', 'FontSize', 13, 'FontWeight', 'bold');
    cb = colorbar; cb.Ticks = 1:5; cb.TickLabels = solver_names; cb.FontSize = 9;
    grid on;

    % Right: nf scaled by dimension (efficiency)
    subplot(1,2,2);
    nf_per_dim = nf_data ./ dims';
    for k = 1:4
        plot(dims, nf_per_dim(:,k), markers{k}, 'Color', colors(k,:), ...
            'LineWidth', 2, 'MarkerSize', 7, 'MarkerFaceColor', colors(k,:));
        hold on;
    end
    xlabel('Dimension n', 'FontSize', 12);
    ylabel('Evaluations / Dimension', 'FontSize', 12);
    title('Solver Efficiency', 'FontSize', 13, 'FontWeight', 'bold');
    grid on; box on;
    set(gca, 'XTick', dims);
    set(gca, 'FontSize', 11);

    Lg = legend(case_labels, 'Orientation', 'horizontal', 'FontSize', 9, ...
        'Position', [0.12 0.97 0.76 0.03]);
    Lg.Box = 'off';

    exportgraphics(fig, fullfile(out_dir, 'rosenbrock_bars.pdf'), ...
        'ContentType', 'vector', 'BackgroundColor', 'white');
    close(fig);
    fprintf('    -> rosenbrock_bars.pdf\n');

    % =====================================================================
    % Figure 3: Precision comparison across representative problems (plain feature)
    % =====================================================================
    fprintf('  Figure 3: Precision comparison across problems (plain, no noise)\n');

    data_file = '/Users/xiaohan/Downloads/prima_opti_benchmark/results/benchmark_results/precision_results.mat';
    if exist(data_file, 'file')
        load(data_file, 'summary');
        plain_mask = strcmp({summary.feature}, 'plain');
        plain_data = summary(plain_mask);

        % Select representative problems spanning dimensions and types
        representative = {'Rosenbrock_n2', 'Rosenbrock_n5', 'Rosenbrock_n10', ...
            'Rosenbrock_n20', 'Sphere_n10', 'Sphere_n20', ...
            'Rastrigin_n10', 'Rosenbrock_Bound_n10', 'Rosenbrock_Bound_n20', ...
            'Rosenbrock_Linear_n10', 'Rosenbrock_Nonlinear_n10', ...
            'Sphere_Nonlinear_n10'};

        prob_list = {};
        fx_single = []; fx_double = []; fx_quad = [];
        nf_single = []; nf_double = []; nf_quad = [];
        t_single = []; t_double = []; t_quad = [];

        for i = 1:length(representative)
            p = representative{i};
            idx = find(strcmp({plain_data.problem}, p));
            if ~isempty(idx)
                % Abbreviate problem names: Rosenbrock_n2 -> Ros (n=2), etc.
                short = p;
                short = regexprep(short, 'Rosenbrock_Nonlinear_n(\d+)', 'Ros-Nonlin (n=$1)');
                short = regexprep(short, 'Rosenbrock_Linear_n(\d+)', 'Ros-Lin (n=$1)');
                short = regexprep(short, 'Rosenbrock_Bound_n(\d+)', 'Ros-Bnd (n=$1)');
                short = regexprep(short, 'Rosenbrock_n(\d+)', 'Ros (n=$1)');
                short = regexprep(short, 'Sphere_Nonlinear_n(\d+)', 'Sph-Nonlin (n=$1)');
                short = regexprep(short, 'Sphere_Bound_n(\d+)', 'Sph-Bnd (n=$1)');
                short = regexprep(short, 'Sphere_n(\d+)', 'Sph (n=$1)');
                short = regexprep(short, 'Rastrigin_n(\d+)', 'Ras (n=$1)');
                prob_list{end+1} = short;
                for j = 1:length(idx)
                    d = plain_data(idx(j));
                    switch d.precision
                        case 'single'
                            fx_single(end+1) = abs(d.fx);
                            nf_single(end+1) = d.funcCount;
                            t_single(end+1) = d.time;
                        case 'double'
                            fx_double(end+1) = abs(d.fx);
                            nf_double(end+1) = d.funcCount;
                            t_double(end+1) = d.time;
                        case 'quadruple'
                            fx_quad(end+1) = abs(d.fx);
                            nf_quad(end+1) = d.funcCount;
                            t_quad(end+1) = d.time;
                    end
                end
            end
        end

        n_probs = length(prob_list);

        if n_probs > 0
            fig = figure('Visible', 'off', 'Position', [100 100 1400 500]);
            x = 1:n_probs;

            subplot(1,3,1);
            h = bar(x, [fx_single(:) fx_double(:) fx_quad(:)]);
            h(1).FaceColor = [0.85 0.33 0.10]; h(2).FaceColor = [0.0 0.45 0.74]; h(3).FaceColor = [0.47 0.67 0.19];
            set(gca, 'XTick', x, 'XTickLabel', prob_list, 'FontSize', 8);
            set(gca, 'XTickLabelRotation', 45);
            set(gca, 'YScale', 'log');
            ylabel('|f(x^*)|  (log scale)', 'FontSize', 11);
            title('Solution Quality', 'FontSize', 12, 'FontWeight', 'bold');
            grid on; box on;

            subplot(1,3,2);
            h = bar(x, [nf_single(:) nf_double(:) nf_quad(:)]);
            h(1).FaceColor = [0.85 0.33 0.10]; h(2).FaceColor = [0.0 0.45 0.74]; h(3).FaceColor = [0.47 0.67 0.19];
            set(gca, 'XTick', x, 'XTickLabel', prob_list, 'FontSize', 8);
            set(gca, 'XTickLabelRotation', 45);
            ylabel('Function Evaluations', 'FontSize', 11);
            title('Computational Cost', 'FontSize', 12, 'FontWeight', 'bold');
            grid on; box on;

            subplot(1,3,3);
            h = bar(x, [t_single(:) t_double(:) t_quad(:)]);
            h(1).FaceColor = [0.85 0.33 0.10]; h(2).FaceColor = [0.0 0.45 0.74]; h(3).FaceColor = [0.47 0.67 0.19];
            set(gca, 'XTick', x, 'XTickLabel', prob_list, 'FontSize', 8);
            set(gca, 'XTickLabelRotation', 45);
            ylabel('Time (seconds)', 'FontSize', 11);
            title('Computation Time', 'FontSize', 12, 'FontWeight', 'bold');
            grid on; box on;

            Lg = legend('Single', 'Double', 'Quadruple', ...
                'Orientation', 'horizontal', 'FontSize', 10, ...
                'Position', [0.35 0.97 0.30 0.03]);
            Lg.Box = 'off';

            exportgraphics(fig, fullfile(out_dir, 'precision_problems.pdf'), ...
                'ContentType', 'vector', 'BackgroundColor', 'white');
            close(fig);
            fprintf('    -> precision_problems.pdf\n');
        end
    end

    % =====================================================================
    % Figure 4: Precision summary (per-feature median-based statistics)
    % =====================================================================
    fprintf('  Figure 4: Precision summary comparison\n');

    if exist(data_file, 'file')
        load(data_file, 'summary');
        precs = {'single', 'double', 'quadruple'};
        features = {'plain', 'noisy'};
        pairs = {{'double','single','d/s'}, {'double','quadruple','d/q'}};
        pair_labels = {{'Double / Single', 'Double / Single'}, {'Double / Quad', 'Double / Quad'}};

        fx_vals = zeros(4,1);
        nf_vals = zeros(4,1);
        row = 1;

        for f = 1:2
            feat = features{f};
            for p = 1:2
                prec_a = pairs{p}{1}; prec_b = pairs{p}{2};
                mask_a = strcmp({summary.precision}, prec_a) & strcmp({summary.feature}, feat) & [summary.success];
                mask_b = strcmp({summary.precision}, prec_b) & strcmp({summary.feature}, feat) & [summary.success];
                if sum(mask_a) > 0 && sum(mask_b) > 0
                    n = min(sum(mask_a), sum(mask_b));
                    fx_ratio = median(abs([summary(mask_a).fx]) ./ max(abs([summary(mask_b).fx]), eps));
                    nf_ratio = median([summary(mask_a).funcCount] ./ max([summary(mask_b).funcCount], 1));
                    fx_vals(row) = fx_ratio;
                    nf_vals(row) = nf_ratio;
                end
                row = row + 1;
            end
        end

        fig = figure('Visible', 'off', 'Position', [100 100 1000 400]);

        subplot(1,2,1);
        b = bar(fx_vals);
        b.FaceColor = 'flat';
        b.CData = [0.0 0.45 0.74; 0.0 0.45 0.74; 0.47 0.67 0.19; 0.47 0.67 0.19];
        b.EdgeColor = 'none';
        set(gca, 'XTickLabel', {'Double/Single\nPlain', 'Double/Single\nNoisy', ...
            'Double/Quad\nPlain', 'Double/Quad\nNoisy'}, 'FontSize', 10);
        ylabel('Median f(x*) Ratio', 'FontSize', 12);
        title('Solution Quality Comparison', 'FontSize', 13, 'FontWeight', 'bold');
        hold on; plot(xlim, [1 1], 'r--', 'LineWidth', 1.5);
        for i = 1:4
            text(i, fx_vals(i)+0.06, sprintf('%.2f', fx_vals(i)), ...
                'HorizontalAlign', 'center', 'FontSize', 11, 'FontWeight', 'bold');
        end
        grid on; box on;
        ylim([0 max(fx_vals)*1.25 + 0.1]);

        subplot(1,2,2);
        b = bar(nf_vals);
        b.FaceColor = 'flat';
        b.CData = [0.0 0.45 0.74; 0.0 0.45 0.74; 0.47 0.67 0.19; 0.47 0.67 0.19];
        b.EdgeColor = 'none';
        set(gca, 'XTickLabel', {'Double/Single\nPlain', 'Double/Single\nNoisy', ...
            'Double/Quad\nPlain', 'Double/Quad\nNoisy'}, 'FontSize', 10);
        ylabel('Median Function Evaluation Ratio', 'FontSize', 12);
        title('Computational Cost Comparison', 'FontSize', 13, 'FontWeight', 'bold');
        hold on; plot(xlim, [1 1], 'r--', 'LineWidth', 1.5);
        for i = 1:4
            text(i, nf_vals(i)+0.02, sprintf('%.2f', nf_vals(i)), ...
                'HorizontalAlign', 'center', 'FontSize', 11, 'FontWeight', 'bold');
        end
        grid on; box on;
        ylim([0 max(nf_vals)*1.15 + 0.02]);

        exportgraphics(fig, fullfile(out_dir, 'precision_summary.pdf'), ...
            'ContentType', 'vector', 'BackgroundColor', 'white');
        close(fig);
        fprintf('    -> precision_summary.pdf\n');
    end

    % =====================================================================
    % Figure 5: Computation time comparison
    % =====================================================================
    fprintf('  Figure 5: Quadruple precision time overhead\n');

    if exist(data_file, 'file')
        load(data_file, 'summary');

        % Compute mean time per feature and precision
        time_plain = zeros(1,3);
        time_noisy = zeros(1,3);
        for j = 1:3
            prec = precs{j};
            mp = mean([summary(strcmp({summary.precision}, prec) & strcmp({summary.feature}, 'plain') & [summary.success]).time]);
            mn = mean([summary(strcmp({summary.precision}, prec) & strcmp({summary.feature}, 'noisy') & [summary.success]).time]);
            time_plain(j) = mp;
            time_noisy(j) = mn;
        end
        time_data = [time_plain; time_noisy];

        fig = figure('Visible', 'off', 'Position', [100 100 1000 400]);

        subplot(1,2,1);
        b = bar(time_data);
        b(1).FaceColor = [0.85 0.33 0.10];
        b(2).FaceColor = [0.0 0.45 0.74];
        b(3).FaceColor = [0.47 0.67 0.19];
        set(gca, 'XTickLabel', {'Plain', 'Noisy (10^{-6})'}, 'FontSize', 11);
        ylabel('Mean Time per Solve (s)', 'FontSize', 11);
        title('Time Comparison', 'FontSize', 12, 'FontWeight', 'bold');
        legend('Single', 'Double', 'Quadruple', 'Location', 'best', 'FontSize', 9);
        grid on; box on;
        set(gca, 'YScale', 'log');

        subplot(1,2,2);
        slowdown = [time_data(1,3)/time_data(1,2); time_data(2,3)/time_data(2,2)];
        b2 = bar(slowdown);
        b2.FaceColor = [0.47 0.67 0.19];
        b2.EdgeColor = 'none';
        set(gca, 'XTickLabel', {'Plain', 'Noisy (10^{-6})'}, 'FontSize', 11);
        ylabel('Slowdown Factor (Quadruple / Double)', 'FontSize', 11);
        title('Quadruple Precision Overhead', 'FontSize', 12, 'FontWeight', 'bold');
        grid on; box on;
        ylim([0 max(slowdown)*1.35]);
        for i = 1:2
            text(i, slowdown(i) + 0.5, sprintf('%.0f\\times slower', slowdown(i)), ...
                'HorizontalAlign', 'center', 'FontSize', 11, 'FontWeight', 'bold', ...
                'Color', [0.47 0.67 0.19]);
        end
        hold on; plot(xlim, [1 1], 'r--', 'LineWidth', 1.5);
        text(0.5, 1.3, 'equal speed (ratio=1)', 'Color', 'r', 'FontSize', 9);

        exportgraphics(fig, fullfile(out_dir, 'precision_timing.pdf'), ...
            'ContentType', 'vector', 'BackgroundColor', 'white');
        close(fig);
        fprintf('    -> precision_timing.pdf\n');
    end

    % =====================================================================
    % Figure 6: OptiProfiler-style Performance Profiles
    % =====================================================================
    fprintf('  Figure 6: OptiProfiler performance profiles\n');

    if exist(data_file, 'file')
        load(data_file, 'summary');
        features = {'plain', 'noisy'};
        precs = {'single', 'double', 'quadruple'};
        prec_colors = [0.85 0.33 0.10; 0.0 0.45 0.74; 0.47 0.67 0.19];
        prec_markers = {'s-', 'o-', 'd-'};

        % Get unique problem names
        all_probs = unique({summary.problem});
        all_dims = [summary.n];

        fig = figure('Visible', 'off', 'Position', [100 100 1200 450]);

        for feat_idx = 1:2
            feat = features{feat_idx};
            subplot(1, 2, feat_idx);

            mask_feat = strcmp({summary.feature}, feat);
            max_ratio = 0;

            for prec_idx = 1:3
                prec = precs{prec_idx};

                % For each problem with this feature, get nf for all 3 precisions
                ratios = [];
                for ip = 1:length(all_probs)
                    pname = all_probs{ip};
                    % Get successful runs for all 3 precisions on this problem+feature
                    nf_vals = zeros(1, 3);
                    for j = 1:3
                        mask = strcmp({summary.problem}, pname) & ...
                               strcmp({summary.feature}, feat) & ...
                               strcmp({summary.precision}, precs{j}) & ...
                               [summary.success];
                        if sum(mask) > 0
                            nf_vals(j) = mean([summary(mask).funcCount]);
                        else
                            nf_vals(j) = NaN;
                        end
                    end
                    % Performance ratio: nf_this / min(nf_all)
                    if ~isnan(nf_vals(prec_idx)) && all(~isnan(nf_vals))
                        ratio = nf_vals(prec_idx) / min(nf_vals);
                        ratios = [ratios; ratio];
                    end
                end

                if ~isempty(ratios)
                    % Sort ratios for cumulative distribution (Dolan-Moré profile)
                    ratios = sort(ratios);
                    n_r = length(ratios);
                    y = (1:n_r)' / n_r;
                    % Stair-step: duplicate x and shift y
                    x_stair = [ratios(1); reshape([ratios(1:end-1) ratios(2:end)]', [], 1); ratios(end)];
                    y_stair = [0; reshape([y(1:end-1) y(1:end-1)]', [], 1); y(end)];
                    plot(x_stair, y_stair, prec_markers{prec_idx}, ...
                        'Color', prec_colors(prec_idx, :), ...
                        'LineWidth', 2, 'MarkerSize', 4, ...
                        'MarkerIndices', 1:10:length(x_stair));
                    hold on;
                    max_ratio = max(max_ratio, max(ratios));
                end
            end

            xlabel('Performance ratio \tau', 'FontSize', 12);
            ylabel('Fraction of problems solved', 'FontSize', 12);
            feat_title = sprintf('Performance Profile — %s', feat);
            title(feat_title, 'FontSize', 13, 'FontWeight', 'bold');
            if max_ratio > 20
                set(gca, 'XScale', 'log');
                xlabel('Performance ratio \tau  (log scale)', 'FontSize', 12);
                xlim([1 max_ratio * 1.2]);
            else
                xlim([1 max_ratio * 1.2]);
            end
            ylim([0 1.05]);
            grid on; box on;
            set(gca, 'FontSize', 11);
            legend('Single', 'Double', 'Quadruple', 'Location', 'southeast', 'FontSize', 9);
        end

        % Shared top legend removed (individual legends per subplot due to different scales)
        exportgraphics(fig, fullfile(out_dir, 'performance_profiles.pdf'), ...
            'ContentType', 'vector', 'BackgroundColor', 'white');
        close(fig);
        fprintf('    -> performance_profiles.pdf\n');
    end

    % =====================================================================
    % Figure 7: OptiProfiler-style Data Profiles
    % =====================================================================
    fprintf('  Figure 7: OptiProfiler data profiles\n');

    if exist(data_file, 'file')
        load(data_file, 'summary');
        features = {'plain', 'noisy'};
        precs = {'single', 'double', 'quadruple'};
        prec_colors = [0.85 0.33 0.10; 0.0 0.45 0.74; 0.47 0.67 0.19];
        prec_markers = {'s-', 'o-', 'd-'};

        % Get unique problem-dimension pairs
        all_probs = unique({summary.problem});
        prob_dim_map = containers.Map;
        for ip = 1:length(all_probs)
            mask = strcmp({summary.problem}, all_probs{ip});
            prob_dim_map(all_probs{ip}) = summary(find(mask, 1)).n;
        end

        fig = figure('Visible', 'off', 'Position', [100 100 1200 450]);

        for feat_idx = 1:2
            feat = features{feat_idx};
            subplot(1, 2, feat_idx);

            max_budget = 0;

            for prec_idx = 1:3
                prec = precs{prec_idx};

                % For each problem, compute budget in units of n+1 (one simplex gradient)
                budgets = [];
                for ip = 1:length(all_probs)
                    pname = all_probs{ip};
                    n = prob_dim_map(pname);
                    mask = strcmp({summary.problem}, pname) & ...
                           strcmp({summary.feature}, feat) & ...
                           strcmp({summary.precision}, prec) & ...
                           [summary.success];
                    if sum(mask) > 0
                        nf = mean([summary(mask).funcCount]);
                        budgets = [budgets; nf / (n + 1)];
                    end
                end

                if ~isempty(budgets)
                    budgets = sort(budgets);
                    n_b = length(budgets);
                    y = (1:n_b)' / n_b;
                    x_stair = [budgets(1); reshape([budgets(1:end-1) budgets(2:end)]', [], 1); budgets(end)];
                    y_stair = [0; reshape([y(1:end-1) y(1:end-1)]', [], 1); y(end)];
                    plot(x_stair, y_stair, prec_markers{prec_idx}, ...
                        'Color', prec_colors(prec_idx, :), ...
                        'LineWidth', 2, 'MarkerSize', 4, ...
                        'MarkerIndices', 1:10:length(x_stair));
                    hold on;
                    max_budget = max(max_budget, max(budgets));
                end
            end

            xlabel('Budget (simplex gradients: n_f / (n+1))', 'FontSize', 12);
            ylabel('Fraction of problems solved', 'FontSize', 12);
            feat_title = sprintf('Data Profile — %s', feat);
            title(feat_title, 'FontSize', 13, 'FontWeight', 'bold');
            xlim([0 max_budget * 1.1]);
            ylim([0 1.05]);
            grid on; box on;
            set(gca, 'FontSize', 11);
            legend('Single', 'Double', 'Quadruple', 'Location', 'southeast', 'FontSize', 9);
        end

        exportgraphics(fig, fullfile(out_dir, 'optiprofiler_profiles.pdf'), ...
            'ContentType', 'vector', 'BackgroundColor', 'white');
        close(fig);
        fprintf('    -> optiprofiler_profiles.pdf\n');
    end

    fprintf('\nAll figures generated in %s\n', out_dir);
end
