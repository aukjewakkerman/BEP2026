%% Load data
imageTable = readtable('imageTable');

%% ==========================================================
%% CATEGORICAL VARIABLES
%% ==========================================================

imageTable.Maturity = categorical(imageTable.Maturity);
imageTable.Culture  = categorical(imageTable.Culture);
imageTable.Well     = categorical(imageTable.Well);

%% ==========================================================
%% QUICK VISUALIZATION
%% ==========================================================

figure('Color','w',...
       'Position',[100 100 1200 450]);

subplot(1,3,1)
boxchart(interactionplotlabels(imageTable),imageTable.Area)
ylabel('Median Cell Area (\mum^2)')
title('Cell Area')
xtickangle(30)
set(gca,'FontSize',11,'Box','off')

subplot(1,3,2)
boxchart(interactionplotlabels(imageTable),imageTable.AspectRatio)
ylabel('Median Aspect Ratio')
title('Aspect Ratio')
xtickangle(30)
set(gca,'FontSize',11,'Box','off')

subplot(1,3,3)
boxchart(interactionplotlabels(imageTable),imageTable.Circularity)
ylabel('Median Circularity')
title('Circularity')
xtickangle(30)
set(gca,'FontSize',11,'Box','off')

exportgraphics(gcf,'Image-level morphology.png','Resolution',300)


%% ==========================================================
%% HELPER
%% ==========================================================

function labels = interactionplotlabels(T)

labels = strcat(string(T.Maturity),"_",string(T.Culture));

labels = categorical(labels,...
    ["m0_Mono","m0_Co","m1_Mono","m1_Co"],...
    ["M0 Mono","M0 Co","M1 Mono","M1 Co"]);

end
