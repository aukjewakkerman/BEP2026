%% Input/output folders
inputfolder = 'C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\Cellpose\train';
outputfolder = 'C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\MATLAB\Feature_extraction_2\Feature extraction train_images';
sarcfolder = 'C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\Images_from_NIS_viewer\live_images\20260904_CM-cFB-maturation0\Plate1\8bit_luts_applied';

if ~exist(outputfolder,'dir')
    mkdir(outputfolder);
end

%% Find all CellPose masks
maskFiles = dir(fullfile(inputfolder,'*_masks.png'));
number_of_files = numel(maskFiles);
fprintf('Found %d mask files\n',number_of_files);

% Overall statistics
total_removed_masks = 0;
total_number_of_masks = 0;

% Co-culture: A1 + A4
co_removed = 0;
co_total = 0;
co_images = 0;

% Monoculture: A2 + A5
mono_removed = 0;
mono_total = 0;
mono_images = 0;

for i = 1:number_of_files
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

    nremoved = ntotal - nKept;
    total_removed_masks = total_removed_masks + nremoved;
    total_number_of_masks = total_number_of_masks + ntotal;

    % Determine condition from token
    if contains(token,'PointA1') || contains(token,'PointA4')
    
        co_removed = co_removed + nremoved;
        co_total = co_total + ntotal;
        co_images = co_images + 1;
    
    elseif contains(token,'PointA2') || contains(token,'PointA5')
    
        mono_removed = mono_removed + nremoved;
        mono_total = mono_total + ntotal;
        mono_images = mono_images + 1;
    
    end

    fprintf('Total masks   : %d\n',ntotal);
    fprintf('Retained %d/%d masks\n',nKept,numel(labels));
    fprintf('Removed masks: %d\n', nremoved);

    outputName = [maskName '_CM_only.tif'];

    imwrite(uint16(CMmask_labels), ...
        fullfile(outputfolder,outputName));

    fprintf('Saved: %s\n',outputName);

end

%% Overall statistics
mean_removed_masks = total_removed_masks / number_of_files;
mean_masks = total_number_of_masks / number_of_files;

fprintf('\n=====================================\n');
fprintf('OVERALL\n');
fprintf('Mean ROIs/image       : %.1f\n', mean_masks);
fprintf('Mean removed/image    : %.1f\n', mean_removed_masks);
fprintf('Removed fraction      : %.4f\n', ...
    total_removed_masks/total_number_of_masks);
fprintf('Removed percentage    : %.2f %%\n', ...
    100*total_removed_masks/total_number_of_masks);

%% Co-culture statistics
co_mean_rois = co_total / co_images;
co_mean_removed = co_removed / co_images;
co_fraction = co_removed / co_total;

fprintf('\nCO-CULTURE (A1 + A4)\n');
fprintf('Images               : %d\n', co_images);
fprintf('Mean ROIs/image      : %.1f\n', co_mean_rois);
fprintf('Mean removed/image   : %.1f\n', co_mean_removed);
fprintf('Removed fraction     : %.4f\n', co_fraction);
fprintf('Removed percentage   : %.2f %%\n', ...
    100*co_fraction);

%% Monoculture statistics
mono_mean_rois = mono_total / mono_images;
mono_mean_removed = mono_removed / mono_images;
mono_fraction = mono_removed / mono_total;

fprintf('\nMONOCULTURE (A2 + A5)\n');
fprintf('Images               : %d\n', mono_images);
fprintf('Mean ROIs/image      : %.1f\n', mono_mean_rois);
fprintf('Mean removed/image   : %.1f\n', mono_mean_removed);
fprintf('Removed fraction     : %.4f\n', mono_fraction);
fprintf('Removed percentage   : %.2f %%\n', ...
    100*mono_fraction);

fprintf('\n=====================================\n');
fprintf('Finished processing all images.\n');