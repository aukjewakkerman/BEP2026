%% USER INPUT

folderPath = "C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\MATLAB\test_data";
pixelSize = 0.33; % um/pixel

%% Find mask files recursively
files = dir(fullfile(folderPath,"**","*mask*.*"));

if isempty(files)
    warning("No mask files found.");
    return
end

%% Initialize output table
summaryTable = table();

%% Loop through all mask images
for k = 1:numel(files)

    filePath = fullfile(files(k).folder,files(k).name);

    fprintf("Processing %d/%d: %s\n", ...
        k,numel(files),files(k).name);

    %% Extract metadata    
    % Extract Well
    wellToken = regexp(files(k).name,"Point([A-Z]\d+)","tokens","once");
    well = string(wellToken{1});
    
    % Extract Replicate
    rToken = regexp(files(k).name,"R(\d+)","tokens","once");
    replicate = sprintf("R%02d", str2double(rToken{1}));
    
    %% Load mask
    mask = imread(filePath);
    
    %% Cell count
    labels = unique(mask);
    CellCount = sum(labels > 0);
    
    %% Morphology
    stats = regionprops(mask, "Area", "MajorAxisLength", "MinorAxisLength", "Circularity", "Eccentricity");
    
    %% Empty image
    if isempty(stats)
        warning("No cells found in %s", files(k).name);
        continue
    end
    
    %% Convert to table
    statsTable = struct2table(stats);
    statsTable.Area_um2 = statsTable.Area .* pixelSize.^2;
    statsTable.Major_um = statsTable.MajorAxisLength .* pixelSize;
    statsTable.Minor_um = statsTable.MinorAxisLength .* pixelSize;
    statsTable.AspectRatio = statsTable.Major_um ./ statsTable.Minor_um;
    
    %% Statistics
    meanArea = mean(statsTable.Area_um2,'omitnan');
    stdArea  = std(statsTable.Area_um2,0,'omitnan');
    semArea  = stdArea/sqrt(height(statsTable));
    
    meanMajor = mean(statsTable.Major_um,'omitnan');
    stdMajor  = std(statsTable.Major_um,0,'omitnan');
    semMajor  = stdMajor/sqrt(height(statsTable));
    
    meanMinor = mean(statsTable.Minor_um,'omitnan');
    stdMinor  = std(statsTable.Minor_um,0,'omitnan');
    semMinor  = stdMinor/sqrt(height(statsTable));
    
    meanAR = mean(statsTable.AspectRatio,'omitnan');
    stdAR  = std(statsTable.AspectRatio,0,'omitnan');
    semAR  = stdAR/sqrt(height(statsTable));
    
    meanCirc = mean(statsTable.Circularity,'omitnan');
    stdCirc  = std(statsTable.Circularity,0,'omitnan');
    semCirc  = stdCirc/sqrt(height(statsTable));
    
    meanEcc = mean(statsTable.Eccentricity,'omitnan');
    stdEcc  = std(statsTable.Eccentricity,0,'omitnan');
    semEcc  = stdEcc/sqrt(height(statsTable));
    
    %% Add row
    newRow = table(string(well),...
        string(replicate),...
        CellCount,...
        meanArea,stdArea,semArea,...
        meanMajor,stdMajor,semMajor,...
        meanMinor,stdMinor,semMinor,...
        meanAR,stdAR,semAR,...
        meanCirc,stdCirc,semCirc,...
        meanEcc,stdEcc,semEcc,...
        'VariableNames',{'Well','Replicate',...
        'CellCount',...
        'MeanArea_um2','StdArea_um2','SemArea_um2',...
        'MeanMajor_um','StdMajor_um','SemMajor_um',...
        'MeanMinor_um','StdMinor_um','SemMinor_um',...
        'MeanAspectRatio','StdAspectRatio','SemAspectRatio',...
        'MeanCircularity','StdCircularity','SemCircularity',...
        'MeanEccentricity','StdEccentricity','SemEccentricity'});
    
    summaryTable = [summaryTable; newRow];

end

summaryTable = sortrows(summaryTable,{'Well','Replicate'});

%% Calculate summary per well
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
    rows = summaryTable(summaryTable.Well == currentWell,:);
    newRow = table(currentWell,'VariableNames',{'Well'});
    newRow.N_Replicates = height(rows);

    for f = 1:numel(features)
        feature = features{f};
        newRow.(sprintf('Mean_%s',feature)) = mean(rows.(feature),'omitnan');
        newRow.(sprintf('Std_%s',feature)) = std(rows.(feature),0,'omitnan');

    end

    wellSummary = [wellSummary; newRow];

end

%% Save
save(fullfile(folderPath,'summaryTable.mat'),'summaryTable');
save(fullfile(folderPath, 'wellSummary.mat'), 'wellSummary')
disp(summaryTable)
fprintf("%d images processed.\n",height(summaryTable));

disp(wellSummary)
fprintf("Finished. %d wells processed.\n", height(wellSummary))