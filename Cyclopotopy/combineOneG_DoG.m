function [rmFileOneG, rmFileDoG, CombinedModelName] = combineOneG_DoG(rmFileOneG, rmFileDoG)

if notDefined('rmFileOneG'),
        dlgStr='Choose one-gaussian retinotopic model file';
        rmFileOneG = getPathStrDialog(pwd,dlgStr,'*.mat');
        drawnow;
        fprintf(1,'[%s]:One gaussian pRF model:%s\n',mfilename,rmFileOneG);
end
if notDefined('rmFileDoG'),
        dlgStr='Choose difference of gaussian retinotopic model file';
        rmFileDoG = getPathStrDialog(pwd,dlgStr,'*.mat');
        drawnow;
        fprintf(1,'[%s]:Difference of gaussian pRF model:%s\n',mfilename,rmFileDoG);
end

CombinedModelName=strcat(rmFileDoG(1:end-4), '-combined.mat');

rmDataOneG=load(rmFileOneG);
rmDataCombined=load(rmFileDoG);

%Determine variance explained for each model, and find which is greater for
%each voxel
veDoG = 1 - (rmDataCombined.model{1}.rss ./ rmDataCombined.model{1}.rawrss);
veDoG(~isfinite(veDoG)) = 0;
veDoG = max(veDoG, 0);
veDoG = min(veDoG, 1);

veOneG = 1 - (rmDataOneG.model{1}.rss ./ rmDataOneG.model{1}.rawrss);
veOneG(~isfinite(veOneG)) = 0;
veOneG = max(veOneG, 0);
veOneG = min(veOneG, 1);

betterOneG=veOneG>veDoG;
            
%rmDataCombined.model{1}.description=strcat(rmDataCombined.model{1}.description,' combined with OneG model for voxels with better variance explained');
rmDataCombined.model{1}.x0(betterOneG)=rmDataOneG.model{1}.x0(betterOneG);
rmDataCombined.model{1}.y0(betterOneG)=rmDataOneG.model{1}.y0(betterOneG);
rmDataCombined.model{1}.rawrss(betterOneG)=rmDataOneG.model{1}.rawrss(betterOneG);
rmDataCombined.model{1}.rss(betterOneG)=rmDataOneG.model{1}.rss(betterOneG);
rmDataCombined.model{1}.rawrss(betterOneG)=rmDataOneG.model{1}.rawrss(betterOneG);

rmDataCombined.model{1}.rsspos(betterOneG)=rmDataOneG.model{1}.rss(betterOneG);
rmDataCombined.model{1}.rssneg(betterOneG)=0;
rmDataCombined.model{1}.rss2(betterOneG)=0;

rmDataCombined.model{1}.sigma.major(betterOneG)=rmDataOneG.model{1}.sigma.major(betterOneG);
rmDataCombined.model{1}.sigma.minor(betterOneG)=rmDataOneG.model{1}.sigma.minor(betterOneG);
rmDataCombined.model{1}.sigma.theta(betterOneG)=rmDataOneG.model{1}.sigma.theta(betterOneG);
rmDataCombined.model{1}.sigma2.major(betterOneG)=eps('single');
rmDataCombined.model{1}.sigma2.minor(betterOneG)=eps('single');
rmDataCombined.model{1}.sigma2.theta(betterOneG)=0;

rmDataCombined.model{1}.beta(1,betterOneG,1)=rmDataOneG.model{1}.beta(1,betterOneG,1);
rmDataCombined.model{1}.beta(1,betterOneG,2)=0;
rmDataCombined.model{1}.beta(1,betterOneG,3:9)=rmDataOneG.model{1}.beta(1,betterOneG,2:8);

model=rmDataCombined.model;
params=rmDataCombined.params;
save(CombinedModelName, 'model', 'params')

end

