%% Input and output folders

inputFolder = "C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\Images_from_NIS_viewer\live_images\20260904_CM-cFB-maturation0\Plate1\train_test_copy";
outputFolder = "C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\Images_from_NIS_viewer\live_images\20260904_CM-cFB-maturation0\Plate1\train_test_copy\8bit_luts_train_test";

if ~exist(outputFolder,'dir')
    mkdir(outputFolder);
end

%% LUT limits (adapt to your data)

PC_low  = 400;
PC_high = 4000;

DAPI_low  = 150;
DAPI_high = 2000;

mCherry_low  = 0;
mCherry_high = 300;

%% Get all tif files

files = dir(fullfile(inputFolder,"*.tif"));

for k = 1:length(files)

    fileName = files(k).name;
    fullName = fullfile(files(k).folder,fileName);

    img = imread(fullName);

    %% Select LUT based on channel

    if contains(fileName,'ChannelPC','IgnoreCase',true)

        low = PC_low;
        high = PC_high;

    elseif contains(fileName,'ChannelDAPI','IgnoreCase',true)

        low = DAPI_low;
        high = DAPI_high;

    elseif contains(fileName,'ChannelmCherry','IgnoreCase',true)

        low = mCherry_low;
        high = mCherry_high;

    else
        warning('Unknown channel: %s',fileName)
        continue
    end

    %% Apply LUT

    img_luts = imadjust(img,[low high]/65536,[0 1]); %65536 because 12bit in unit16 exported from NIS

    %% Convert to 8-bit

    img_8bit = im2uint8(img_luts);

    %% Save
    [~,base,ext] = fileparts(fileName);
    outName = fullfile(outputFolder, base + "_8bit" + ext);

    imwrite(img_8bit,outName);

end

disp('Done!')
