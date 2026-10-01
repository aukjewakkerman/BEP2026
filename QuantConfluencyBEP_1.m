%% Load CellPose segmentation

cellimg = imread('PointA1_R01_im_ChannelPC,Dapi,GFP,mCherry,Cy5_Seq0000_Cy5_cp_masks.png');

%% Load raw mCherry image

sarcimg = imread('PointA1_R01_im_ChannelPC,Dapi,GFP,mCherry,Cy5_Seq0000_Cy5.tif');
sarcimg = im2double(sarcimg); %rescale pixel values

%% Sarcomere segmentation pipeline

sarcbin = imbinarize(imadjust(sarcimg),'adaptive','Sensitivity',0.3); %converting to binary image with sacromeres 1 and background 0. Check threshold with ImageJ
sarcbin = bwareaopen(sarcbin,350); %opening: components with less than 350 pixels are removed, so noise is removed
sarcdil = imclose(sarcbin, strel('disk',20)); %closing: fill small gaps, connect nearby sacromere structures
sarcclosed = ~bwareaopen(~sarcdil,20000); %closing: fill large holes > 20000 pixels
sarcmask = sarcclosed;

%% Remove masks without enough mCherry signal
minFrac = 0.01;      % 1% sarcomere coverage
minPixels = 100;     % at least 100 sarcomere pixels, for small masks

% Get all CellPose labels except background (0)
labels = unique(cellimg);
labels(labels==0) = [];
fprintf('Number of CellPose labels: %d\n',numel(labels));

% Output image with retained CM masks
CMmask_labels = zeros(size(cellimg),'like',cellimg);
nKept = 0;

for k = 1:numel(labels)

    label = labels(k);
    
    % Pixels belonging to one CellPose mask
    idx = (cellimg == label);
    
    % Number of sarcomere-positive pixels in this mask
    sarcPixels = sum(sarcclosed(idx));
    
    % Fraction of mask positive for sarcomeres
    fracSarc = sarcPixels / nnz(idx);
    
    % Keep only CM-like masks
    if fracSarc > minFrac && sarcPixels > minPixels
    
        CMmask_labels(idx) = label;
        nKept = nKept + 1;
    end

end

fprintf('Masks retained: %d\n',nKept);
fprintf('Masks removed: %d\n',numel(labels)-nKept);

%% Binary CM-only mask
CMmask = CMmask_labels > 0;

%% Visualizations

figure;
imshow(cellmask);
title(sprintf('Original Cellpose mask (%d ROIs)', numel(labels)))

figure;
imshow(sarcmask);
title('mCherry-derived sarcomere mask')

figure;
imshow(CMmask);
title(sprintf('Filtered CM mask: %d fibroblast-like masks removed', numel(labels)-nKept))

%% RGB overlay

rgb = zeros(size(cellmask,1),size(cellmask,2),3);

rgb(:,:,1) = sarcmask;   % red
rgb(:,:,2) = cellmask;   % green

figure;
imshow(rgb);
title('Cell (green), Sarcomeres (red), Overlap (yellow)');