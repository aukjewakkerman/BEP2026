%%code for choosing LUTs limits

img = imread("PointA1_R01_im_ChannelPC,Dapi,GFP,mCherry,Cy5_Seq0000_Cy5.tif");

figure;
histogram(double(img(:)),1000);
xlim([0 10000])
