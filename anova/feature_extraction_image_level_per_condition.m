%Feature extraction script.

%% INPUT

inputfolder = "C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\MATLAB\cm_only\cm_only_2\cm_filtered_all_images";
outputfolder = "C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\MATLAB\Feature_extraction_2";

pixelSize = 0.33; % um/pixel

%% FIND FILES

files = dir(fullfile(inputfolder, "*.tif"));

if isempty(files)
    error("No mask files found.");
end

%% TABLE WITH ONE ROW PER IMAGE

imageTable = table();

%% ==========================================================
%% LOOP FILES
%% ==========================================================

for k = 1:numel(files)

    fileName = files(k).name;
    filePath = fullfile(files(k).folder,fileName);

    fprintf("Processing %d/%d: %s\n", ...
        k,numel(files),fileName);

    %% WELL

    wellToken = regexp( ...
        fileName,...
        "Point([A-Z]\d+)",...
        "tokens","once");

    if isempty(wellToken)
        continue
    end

    well = string(wellToken{1});

    %% only A1 A2 A4 A5

    if ~ismember(well,["A1","A2","A4","A5"])
        continue
    end

    %% MATURITY

    conditionToken = regexp( ...
        fileName,...
        "(m\d+)",...
        "tokens","once");

    if isempty(conditionToken)
        continue
    end

    maturity = string(conditionToken{1});

    %% CULTURE

    switch well

        case {"A1","A4"}
            culture = "Co";

        case {"A2","A5"}
            culture = "Mono";

    end

    %% LOAD MASK

    mask = imread(filePath);

    %% REGIONPROPS

    stats = regionprops( ...
        mask,...
        "Area",...
        "MajorAxisLength",...
        "MinorAxisLength",...
        "Circularity");

    if isempty(stats)
        continue
    end

    stats = struct2table(stats);

    %% FEATURES

    area_um2 = stats.Area .* pixelSize.^2;

    major_um = stats.MajorAxisLength .* pixelSize;

    minor_um = stats.MinorAxisLength .* pixelSize;

    aspectRatio = major_um ./ max(minor_um,eps);

    circularity = stats.Circularity;

    %% IMAGE-LEVEL MEDIANS

    newRow = table( ...
        string(fileName),...
        maturity,...
        culture,...
        well,...
        height(stats),...
        median(area_um2),...
        median(circularity),...
        median(aspectRatio),...
        'VariableNames',{ ...
        'Image',...
        'Maturity',...
        'Culture',...
        'Well',...
        'NCells',...
        'Area',...
        'Circularity',...
        'AspectRatio'});

    imageTable = [imageTable; newRow];

end

%% ==========================================================
%% CATEGORICAL VARIABLES
%% ==========================================================

imageTable.Maturity = categorical(imageTable.Maturity);
imageTable.Culture  = categorical(imageTable.Culture);
imageTable.Well     = categorical(imageTable.Well);

%% ==========================================================
%% DISPLAY IMAGE TABLE
%% ==========================================================

disp("==================================================")
disp("IMAGE-LEVEL TABLE")
disp("==================================================")
disp(imageTable)

writetable(...
    imageTable,...
    fullfile(outputfolder,...
    'imageTable.csv'));

save(...
    fullfile(outputfolder,...
    'imageTable.mat'),...
    'imageTable');

%% ==========================================================
%% SUMMARY TABLE
%% ==========================================================

summaryTable = groupsummary( ...
    imageTable,...
    {'Maturity','Culture'},...
    {'mean','median','std'},...
    {'Area','Circularity','AspectRatio'});

disp("==================================================")
disp("SUMMARY TABLE")
disp("==================================================")
disp(summaryTable)

writetable(...
    summaryTable,...
    fullfile(outputfolder,...
    'summaryTable.csv'));

save(...
    fullfile(outputfolder,...
    'summaryTable.mat'),...
    'summaryTable');