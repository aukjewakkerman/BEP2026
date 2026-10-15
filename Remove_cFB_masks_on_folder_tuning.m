%% Input/output folders
inputfolder = 'C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\Cellpose\austen_ran_on_m0_plate1';
outputfolder = 'C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\MATLAB\cm_only\visualization_all_steps';
sarcfolder = 'C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\Images_from_NIS_viewer\live_images\20260904_CM-cFB-maturation0\Plate1\8bit_luts_applied';

if ~exist(outputfolder,'dir')
    mkdir(outputfolder);
end

%% Find all CellPose masks
maskFiles = dir(fullfile(inputfolder,'*_masks.tif'));

fprintf('Found %d mask files\n',numel(maskFiles));

%for i = 1:numel(maskFiles)
for i = 1

    fprintf('\nProcessing %s (%d/%d)\n', ...
        maskFiles(i).name, i, numel(maskFiles));

    %% Load CellPose mask
    maskFile = fullfile(maskFiles(i).folder, maskFiles(i).name);
    cellimg = imread(maskFile);

    %% Locate matching mCherry image
    
    maskName = maskFiles(i).name;
    
    % Extract identifier, e.g. PointA1_R03_im
    token = regexp(maskName,...
        'Point[A-Z0-9]+_R\d+_im',...
        'match','once');
    
    if isempty(token)
        warning('Could not extract point name from %s',maskName);
        continue
    end
    
    % Find matching mCherry image
    sarcCandidates = dir(fullfile(sarcfolder,...
        ['*' token '*mCherry*.tif']));
    
    if isempty(sarcCandidates)
        warning('No matching mCherry image found for %s',token);
        continue
    elseif numel(sarcCandidates) > 1
        warning('Multiple mCherry images found for %s. Using first match.',token);
    end
    
    sarcFile = fullfile( ...
        sarcCandidates(1).folder, ...
        sarcCandidates(1).name);
    
    fprintf('Matched mCherry image: %s\n', ...
        sarcCandidates(1).name);

    %% Load mCherry image
    sarcimg = im2double(imread(sarcFile));

    %% Sarcomere segmentation
    sarcbin_thresholded = imbinarize(imadjust(sarcimg), ...
        'adaptive','Sensitivity',0.7);

    sarcbin = bwareaopen(sarcbin_thresholded,350);

    sarcdil = imclose(sarcbin,strel('disk',20));

    sarcclosed = ~bwareaopen(~sarcdil,20000);

    %% Remove masks without enough mCherry signal
    minFrac = 0.005;
    minPixels = 1000;

    labels = unique(cellimg);
    labels(labels==0) = [];
    
    ntotal = numel(labels);

    CMmask_labels = zeros(size(cellimg),'like',cellimg);

    nKept = 0;

    for k = 1:ntotal

        label = labels(k);

        idx = (cellimg == label);

        sarcPixels = sum(sarcclosed(idx));

        fracSarc = sarcPixels / nnz(idx);

        if fracSarc > minFrac && sarcPixels > minPixels
            CMmask_labels(idx) = label;
            nKept = nKept + 1;
        end

    end

    nremoved = ntotal - nKept;

    fprintf('Total masks   : %d\n',ntotal);
    fprintf('Retained %d/%d masks\n',nKept,numel(labels));
    fprintf('Removed masks: %d\n', nremoved);

    %% Binary masks for visualization
    CMmask = CMmask_labels > 0;
    cellmask = cellimg > 0;
    sarcmask = sarcclosed;
    
    %% Original CellPose masks
    fig = figure;
    imshow(cellmask);
    title(sprintf('Original CellPose mask (%d ROIs)', ntotal));
    
    exportgraphics(fig, fullfile(outputfolder,...
        [token '_01_CellPoseMask.png']), 'Resolution',300);

    
    %% Original sarcomere image
    fig = figure;
    imshow(sarcimg,[]);
    title('Original mCherry');
    
    exportgraphics(fig, fullfile(outputfolder,...
        [token '_02_mCherryImage.png']), 'Resolution',300);
    
    %% Sarcomere mask thresholded
    fig = figure;
    imshow(sarcbin_thresholded,[]);
    title('mCherry-derived sarcomere mask');
    
    exportgraphics(fig, fullfile(outputfolder,...
        [token '_03_ThresholdedSarcomereMask.png']), 'Resolution',300);
    
    %% Sarcomere mask after morphology
    fig = figure;
    imshow(sarcmask);
    title('mCherry-derived sarcomere mask with morphological operations');
    
    exportgraphics(fig, fullfile(outputfolder,...
        [token '_04_MorphologySarcomereMask.png']), 'Resolution',300);
    
    %% Final CM-only mask
    fig = figure;
    imshow(CMmask);
    title(sprintf('Filtered CM mask (%d masks removed)', nremoved));
    
    exportgraphics(fig, fullfile(outputfolder,...
        [token '_05_CMOnlyMask.png']), 'Resolution',300);
    
    %% RGB overlay
    removedMask = cellmask & ~CMmask;
    
    % Maak RGB-afbeelding vanuit mCherry beeld
    rgb = repmat(mat2gray(sarcimg),1,1,3);
    
    % Retained masks groen
    rgb(:,:,2) = max(rgb(:,:,2), CMmask);
    
    % Removed masks rood (overschrijft groen)
    rgb(:,:,1) = max(rgb(:,:,1), removedMask);
    rgb(:,:,2) = rgb(:,:,2).*(~removedMask);
    rgb(:,:,3) = rgb(:,:,3).*(~removedMask);
    
    fig = figure;
    imshow(rgb);
    
    title(sprintf('Retained masks (green), removed masks (red)'));
    
    exportgraphics(fig, fullfile(outputfolder,...
        [token '_06_Overlay.png']), 'Resolution',300);

end

fprintf('\nFinished processing all images.\n');