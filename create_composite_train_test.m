%% Select folders
inputFolder = 'C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\MATLAB\Appliing_luts_and_composite\8bit_luts_test';
outputFolder = 'C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\MATLAB\Appliing_luts_and_composite\8bit_luts_test\composites';

%% Find DAPI files
dapiFiles = dir(fullfile(inputFolder,'*ChannelDapi*.tif'));

fprintf('Found %d DAPI files.\n',numel(dapiFiles));

for k = 1:numel(dapiFiles)

    dapiName = dapiFiles(k).name;

    % Extract prefix before channel name
    token = extractBefore(dapiName,'ChannelDapi');
    
    % Find matching PC image
    pcMatch = dir(fullfile(inputFolder,[token '*ChannelPC*.tif']));
    
    if isempty(pcMatch)
    warning('No matching PC file found for %s',dapiName);
    continue
    end

    %% Read images
    dapi = imread(fullfile(dapiFiles(k).folder,dapiName));
    pc   = imread(fullfile(pcMatch(1).folder,pcMatch(1).name));

    %% Convert to double
    dapi = im2double(dapi);
    pc = im2double(pc);

    %% Create RGB composite
    rgb = zeros(size(dapi,1),size(dapi,2),3);

    rgb(:,:,1) = pc;     % Red = PC
    rgb(:,:,2) = 0;      % Green = empty
    rgb(:,:,3) = dapi;   % Blue = DAPI

    %% Output filename
    compName = strrep(dapiName,'ChannelDapi','Composite_PC_DAPI');

    %% Save
    imwrite(rgb,fullfile(outputFolder,compName));

    fprintf('Saved: %s\n',compName);

end

disp('Done.');