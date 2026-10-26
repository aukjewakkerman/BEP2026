%% Input/output folders
inputfolder = 'C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\Cellpose\austen_ran_on_m1_plate1';
outputfolder = 'C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\MATLAB\cm_only\visualization_all_steps';
sarcfolder = 'C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\Images_from_NIS_viewer\live_images\20260911_CM-cFB-maturation1\Plate2\8bit_luts_applied';

if ~exist(outputfolder,'dir')
    mkdir(outputfolder);
end

%% Find all CellPose masks
maskFiles = dir(fullfile(inputfolder,'*_masks.tif'));
number_of_files = numel(maskFiles);
fprintf('Found %d mask files\n',number_of_files);
total_removed_masks = 0;

%for i = 1:number_of_files
for i = 1:2
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

    %% Remove masks without enough pixels and mCherry signal
    minFrac = 0.005;
    %minPixels = 1000;

    labels = unique(cellimg);
    labels(labels==0) = [];
    
    ntotal = numel(labels);
    CMmask_labels = zeros(size(cellimg),'like',cellimg);
    nKept = 0;
    minArea = 1000;
    
    for k = 1:ntotal
        label = labels(k);
        idx = (cellimg == label);
    
        maskArea = nnz(idx);
        sarcPixels = sum(sarcclosed(idx));
        fracSarc = sarcPixels / maskArea;
    
        if fracSarc > minFrac && maskArea > minArea
            CMmask_labels(idx) = label;
            nKept = nKept + 1;
        end
    end

    imwrite(uint16(CMmask_labels), fullfile(outputfolder, [token '_CM_filtered.tif']));

    nremoved = ntotal - nKept;
    total_removed_masks = total_removed_masks + nremoved;

    fprintf('Total masks   : %d\n',ntotal);
    fprintf('Retained %d/%d masks\n',nKept,numel(labels));
    fprintf('Removed masks: %d\n', nremoved);

    % Binary masks for visualization
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

mean_removed_masks = round(total_removed_masks/number_of_files);
fprintf('Mean removed masks   : %d\n',mean_removed_masks);

fprintf('\nFinished processing all images.\n');