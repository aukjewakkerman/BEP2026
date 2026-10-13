%% Input folder containing mCherry images
sarcfolder = 'C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\Images_from_NIS_viewer\live_images\20260904_CM-cFB-maturation0\Plate1\8bit_luts_applied';

%% Find mCherry images
mCherryFiles = dir(fullfile(sarcfolder,'*mCherry*.tif'));

%% Choose image to inspect
imgIdx = 1;   % change if desired

sarcimg = im2double(imread(fullfile( ...
    mCherryFiles(imgIdx).folder,...
    mCherryFiles(imgIdx).name)));

%% Threshold sensitivities to test
sensitivities = [0.1 0.2 0.3 0.4 0.5 0.6];

figure('Name',mCherryFiles(imgIdx).name);

% Original image
subplot(2,4,1)
imshow(sarcimg,[])
title('Original mCherry')

for i = 1:numel(sensitivities)

    s = sensitivities(i);

    bw = imbinarize( ...
        imadjust(sarcimg), ...
        'adaptive', ...
        'Sensitivity',s);

    subplot(2,4,i+1)
    imshow(bw)
    title(sprintf('Sens = %.1f',s))

end