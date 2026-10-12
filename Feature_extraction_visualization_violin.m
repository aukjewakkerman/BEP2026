%% Generate_SummaryTable_Morphology

clear; close all; clc;

%% USER INPUT

inputfolder = "C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\Cellpose\train\try_run\try_run_masks";
outputfolder = ""
pixelSize = 0.33; % um/pixel

%% Find mask files

files = dir(fullfile(inputfolder,"**","*mask*.*"));

if isempty(files)
    warning("No mask files found.");
    return
end

%% Initialize tables

summaryTable = table();
singleCellTable = table();

%% Loop through mask images

for k = 1:numel(files)

    filePath = fullfile(files(k).folder,files(k).name);

    fprintf("Processing %d/%d: %s\n", ...
        k,numel(files),files(k).name);

    %% Extract well

    wellToken = regexp(files(k).name,...
        "Point([A-Z]\d+)",...
        "tokens","once");

    well = string(wellToken{1});

    %% Extract replicate

    rToken = regexp(files(k).name,...
        "R(\d+)",...
        "tokens","once");

    replicate = sprintf("R%02d",...
        str2double(rToken{1}));

    %% Load mask

    mask = imread(filePath);

    %% Cell count

    CellCount = numel(unique(mask(mask>0)));

    %% Morphology measurements

    stats = regionprops(mask,...
        "Area",...
        "MajorAxisLength",...
        "MinorAxisLength",...
        "Circularity",...
        "Eccentricity");

    if isempty(stats)
        warning("No cells found in %s",files(k).name);
        continue
    end

    %% Convert to table

    statsTable = struct2table(stats);

    statsTable.Area_um2 = ...
        statsTable.Area .* pixelSize.^2;

    statsTable.Major_um = ...
        statsTable.MajorAxisLength .* pixelSize;

    statsTable.Minor_um = ...
        statsTable.MinorAxisLength .* pixelSize;

    statsTable.AspectRatio = ...
        statsTable.Major_um ./ statsTable.Minor_um;

    %% Store single-cell data

    nCells = height(statsTable);

    cellTable = table();

    cellTable.Well = repmat(well,nCells,1);
    cellTable.Replicate = repmat(string(replicate),nCells,1);
    cellTable.CellID = (1:nCells)';

    cellTable.Area_um2 = statsTable.Area_um2;
    cellTable.Major_um = statsTable.Major_um;
    cellTable.Minor_um = statsTable.Minor_um;
    cellTable.AspectRatio = statsTable.AspectRatio;
    cellTable.Circularity = statsTable.Circularity;
    cellTable.Eccentricity = statsTable.Eccentricity;

    singleCellTable = [singleCellTable; cellTable];

    %% Replicate statistics

    meanArea = mean(statsTable.Area_um2);
    stdArea = std(statsTable.Area_um2);
    semArea = stdArea/sqrt(nCells);

    meanMajor = mean(statsTable.Major_um);
    stdMajor = std(statsTable.Major_um);
    semMajor = stdMajor/sqrt(nCells);

    meanMinor = mean(statsTable.Minor_um);
    stdMinor = std(statsTable.Minor_um);
    semMinor = stdMinor/sqrt(nCells);

    meanAR = mean(statsTable.AspectRatio);
    stdAR = std(statsTable.AspectRatio);
    semAR = stdAR/sqrt(nCells);

    meanCirc = mean(statsTable.Circularity);
    stdCirc = std(statsTable.Circularity);
    semCirc = stdCirc/sqrt(nCells);

    meanEcc = mean(statsTable.Eccentricity);
    stdEcc = std(statsTable.Eccentricity);
    semEcc = stdEcc/sqrt(nCells);

    %% Add replicate row

    newRow = table(...
        well,...
        string(replicate),...
        CellCount,...
        meanArea,stdArea,semArea,...
        meanMajor,stdMajor,semMajor,...
        meanMinor,stdMinor,semMinor,...
        meanAR,stdAR,semAR,...
        meanCirc,stdCirc,semCirc,...
        meanEcc,stdEcc,semEcc,...
        'VariableNames',{...
        'Well','Replicate',...
        'CellCount',...
        'MeanArea_um2','StdArea_um2','SEMArea_um2',...
        'MeanMajor_um','StdMajor_um','SEMMajor_um',...
        'MeanMinor_um','StdMinor_um','SEMMinor_um',...
        'MeanAspectRatio','StdAspectRatio','SEMAspectRatio',...
        'MeanCircularity','StdCircularity','SEMCircularity',...
        'MeanEccentricity','StdEccentricity','SEMEccentricity'});

    summaryTable = [summaryTable; newRow];

end

%% Sort replicate table

summaryTable = sortrows(summaryTable,...
    {'Well','Replicate'});

%% Well summary

features = {...
    'CellCount',...
    'MeanArea_um2',...
    'MeanMajor_um',...
    'MeanMinor_um',...
    'MeanAspectRatio',...
    'MeanCircularity',...
    'MeanEccentricity'};

wells = unique(summaryTable.Well);

wellSummary = table();

for w = 1:numel(wells)

    currentWell = wells(w);

    rows = summaryTable(...
        summaryTable.Well == currentWell,:);

    newRow = table(currentWell,...
        'VariableNames',{'Well'});

    newRow.N_Replicates = height(rows);

    for f = 1:numel(features)

        feature = features{f};

        newRow.(sprintf('Mean_%s',feature)) = ...
            mean(rows.(feature),'omitnan');

        newRow.(sprintf('Std_%s',feature)) = ...
            std(rows.(feature),0,'omitnan');

    end

    wellSummary = [wellSummary; newRow];

end

wellSummary = sortrows(wellSummary,'Well');

%% Save tables

save(fullfile(outputfolder,...
    'summaryTable.mat'),'summaryTable');

save(fullfile(outputfolder,...
    'wellSummary.mat'),'wellSummary');

save(fullfile(folderPath,...
    'singleCellTable.mat'),'singleCellTable');

writetable(summaryTable,...
    fullfile(folderPath,...
    'summaryTable.csv'));

writetable(wellSummary,...
    fullfile(folderPath,...
    'wellSummary.csv'));

writetable(singleCellTable,...
    fullfile(folderPath,...
    'singleCellTable.csv'));

%% ==========================================================
%% PLOT 1: SINGLE-CELL DISTRIBUTIONS
%% ==========================================================

cellFeatures = {...
    'Area_um2',...
    'Major_um',...
    'Minor_um',...
    'AspectRatio',...
    'Circularity',...
    'Eccentricity'};

for i = 1:numel(cellFeatures)

    figure

    boxchart( ...
        categorical(singleCellTable.Well),...
        singleCellTable.(cellFeatures{i}));

    title(['Single Cell Distribution: ',...
        cellFeatures{i}])

    xlabel('Well')
    ylabel(cellFeatures{i})

    grid on

end

%% ==========================================================
%% PLOT 2: REPLICATE MEANS
%% ==========================================================

repFeatures = {...
    'MeanArea_um2',...
    'MeanMajor_um',...
    'MeanMinor_um',...
    'MeanAspectRatio',...
    'MeanCircularity',...
    'MeanEccentricity'};

for i = 1:numel(repFeatures)

    figure

    boxchart( ...
        categorical(summaryTable.Well),...
        summaryTable.(repFeatures{i}));

    hold on

    swarmchart( ...
        categorical(summaryTable.Well),...
        summaryTable.(repFeatures{i}),...
        80,...
        'filled');

    title(['Replicate Means: ',...
        repFeatures{i}])

    xlabel('Well')
    ylabel(repFeatures{i})

    grid on

end

%% ==========================================================
%% PLOT 3: WELL MEAN ± SD
%% ==========================================================

wellFeatures = {...
    'CellCount',...
    'MeanArea_um2',...
    'MeanMajor_um',...
    'MeanMinor_um',...
    'MeanAspectRatio',...
    'MeanCircularity',...
    'MeanEccentricity'};

for i = 1:numel(wellFeatures)

    figure

    errorbar( ...
        1:height(wellSummary),...
        wellSummary.(sprintf('Mean_%s',wellFeatures{i})),...
        wellSummary.(sprintf('Std_%s',wellFeatures{i})),...
        'o-',...
        'LineWidth',1.5,...
        'MarkerSize',8);

    xticks(1:height(wellSummary))
    xticklabels(wellSummary.Well)

    xlabel('Well')
    ylabel(wellFeatures{i})

    title(['Well Mean ± SD: ',...
        wellFeatures{i}])

    grid on

end

%% Display

disp(summaryTable)
disp(wellSummary)

fprintf("%d images processed.\n",...
    height(summaryTable));

fprintf("%d wells processed.\n",...
    height(wellSummary));