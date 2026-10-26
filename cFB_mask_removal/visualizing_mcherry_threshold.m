%% Input folder containing mCherry images
sarcfolder = 'C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\Images_from_NIS_viewer\live_images\20260904_CM-cFB-maturation0\Plate1\8bit_luts_applied';

%% Find mCherry images
mCherryFiles = dir(fullfile(sarcfolder,'*mCherry*.tif'));

%% Choose image to inspect
imgIdx = 1;

sarcimg = im2double(imread(fullfile( ...
    mCherryFiles(imgIdx).folder,...
    mCherryFiles(imgIdx).name)));

%% Threshold sensitivities to test
sensitivities = [0.2 0.3 0.4 0.5 0.6 0.7 0.8];

fig = figure('Name',mCherryFiles(imgIdx).name,...
             'Color','w',...
             'Position',[100 100 1400 700]);

t = tiledlayout(2,4,'TileSpacing','compact','Padding','compact');

%% Original image
nexttile
imshow(sarcimg,[])
title('mCherry image')

%% Thresholded images
for i = 1:numel(sensitivities)
    s = sensitivities(i);

    bw = imbinarize( ...
        imadjust(sarcimg), ...
        'adaptive', ...
        'Sensitivity',s);

    nexttile
    imshow(bw)
    title(sprintf('Sensitivity threshold = %.1f',s))
end

%% Save figure
scriptFolder = fileparts(mfilename('fullpath'));

saveName = fullfile(scriptFolder, ...
    [erase(mCherryFiles(imgIdx).name,'.tif') '_threshold_comparison.png']);

exportgraphics(fig,saveName,'Resolution',300);
