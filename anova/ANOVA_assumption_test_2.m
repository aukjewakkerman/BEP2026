%% Load data
T = readtable('imageTable.csv');

%% Convert to categorical
T.Maturity = categorical(T.Maturity);
T.Culture  = categorical(T.Culture);

%% Parameters to test
features = {'Area','Circularity','AspectRatio'};

for k = 1:numel(features)

    feature = features{k};

    fprintf('\n====================================\n');
    fprintf('%s\n',feature);
    fprintf('====================================\n');

    %% Two-way ANOVA model
    mdl = fitlm(T,...
        sprintf('%s ~ Maturity*Culture',feature));

    y         = T.(feature);
    residuals = mdl.Residuals.Raw;
    fitted    = mdl.Fitted;

    %% Group labels
    group = strcat(string(T.Maturity),"_",string(T.Culture));
    
    group = categorical(group,...
        ["m0_Mono","m0_Co","m1_Mono","m1_Co"],...
        ["M0 Mono","M0 Co","M1 Mono","M1 Co"]);
    %% -------------------------
    %% 1. Normality
    %% -------------------------
    [h_norm,p_norm] = lillietest(residuals);

    fprintf('Normality test (Lilliefors)\n');
    fprintf('p = %.4g\n',p_norm);

    if h_norm==0
        fprintf('PASS: residuals approximately normal\n');
    else
        fprintf('FAIL: residuals deviate from normality\n');
    end

    %% -------------------------
    %% 2. Homogeneity of variance
    %% -------------------------
    p_levene = vartestn(y,group,...
        'TestType','LeveneAbsolute',...
        'Display','off');

    fprintf('\nLevene test\n');
    fprintf('p = %.4g\n',p_levene);

    if p_levene > 0.05
        fprintf('PASS: equal variances\n');
    else
        fprintf('FAIL: unequal variances\n');
    end

    %% -------------------------
    %% 3. Outlier detection
    %% -------------------------
    zres = residuals/std(residuals);

    nOut = sum(abs(zres) > 3);

    fprintf('\nOutliers (|standardized residual| > 3)\n');
    fprintf('N = %d\n',nOut);

    %% -------------------------
    %% Plots
    %% -------------------------
    figure('Name',feature);

    subplot(2,2,1)
    qqplot(residuals)
    xlabel('Theoretical Normal Quantiles')
    ylabel('Residual Quantiles')
    title('Normal Q-Q Plot')

    subplot(2,2,2)
    histogram(residuals,20)
    title('Residual Distribution')

    subplot(2,2,3)
    scatter(fitted,residuals,'filled')
    yline(0,'r--')
    xlabel('Fitted')
    ylabel('Residuals')
    title('Residuals vs. Fitted Values')

    subplot(2,2,4)
    boxplot(y,group)
    ylabel(feature)
    title('Group Distributions')

    sgtitle(sprintf('%s ANOVA Assumption Checks',feature), ...
        'FontSize',10,'FontWeight','bold')

    exportgraphics(gcf,[feature '_assumption_plots.png'],'Resolution',300)

end