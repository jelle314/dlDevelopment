function model = rmSearchFit_twoGaussiansDoG_fixed(model,data,params,wProcess,t)
% rmSearchFit_twoGaussiansDoG_fixed - wrapper for 'fine' two DoG Gaussian fit
%
% model = rmSearchFit_twoGaussiansDoG(model,prediction,data,params);
%
% Second gaussian negative only. Fit one beta for DoG.
%
% 2008/01 SOD: split of from rmSearchFit.

% add upper and lower limit:
expandRange    = params.analysis.fmins.expandRange;

% fminsearch options
searchOptions = params.analysis.fmins.options;
vethresh      = params.analysis.fmins.vethresh;

% convert to double just in case
params.analysis.X = double(params.analysis.X);
params.analysis.Y = double(params.analysis.Y);
params.analysis.allstimimages = double(params.analysis.allstimimages);

% amount of negative fits
nNegFit  = 0;
trends   = t.trends;
t_id     = t.dcid+2;

% get starting upper and lower range and reset TolFun 
% (raw rss computation (similar to norm) and TolFun adjustments)
[range TolFun] = rmSearchFit_range(params,model,data);

% initialize
if ~isfield(model,'rss2')
    model.rss2 = zeros(size(model.rss));
end

if ~isfield(model,'rssPos')
    model.rsspos = zeros(size(model.rss));
end

if ~isfield(model,'rssNeg')
    model.rssneg = zeros(size(model.rss));
end

%-----------------------------------
% Go for each voxel
%-----------------------------------
progress = 0;tic;
for ii = 1:numel(wProcess),

    % progress monitor (10 dots)
    if floor(ii./numel(wProcess)*10)>progress,
        % print out estimated time left
        if progress==0,
            esttime = toc.*10;
            if floor(esttime./3600)>0,
                fprintf(1,'[%s]:Estimated processing time: %d voxels: %d hours.\n',...
                    mfilename,numel(wProcess),ceil(esttime./3600));
            else
                fprintf(1,'[%s]:Estimated processing time: %d voxels: %d minutes.\n',...
                    mfilename,numel(wProcess),ceil(esttime./60));
            end;
            fprintf(1,'[%s]:Nonlinear optimization (x,y,sigma):',mfilename);
        end;
        fprintf(1,'.');drawnow;
        progress = progress + 1;
    end;

    % volume index
    vi = wProcess(ii);
    vData = double(data(:,ii));
    

    outParams = range.start(:,vi);

    
    % make predictions
    Xv = params.analysis.X - outParams(1);   % positive x0 moves center right
    Yv = params.analysis.Y - outParams(2);   % positive y0 moves center up
    rf = exp( (Yv.*Yv + Xv.*Xv) ./ (-2.*(outParams(3).^2)) );
    %rf(:,2) = exp( (Yv.*Yv + Xv.*Xv) ./ (-2.*(outParams(4).^2)) );
    
    % make one pRF
    %rf = rf*model.b(1,vi);
        
    X = [params.analysis.allstimimages*rf]; % TODO: Check if params.analysis.allstimimages is the right one
    vData = vData - model.b(2,vi);%mean(model.b(3:4,vi));
    
    if isfield(params.analysis.cyclo,'refitBeta') && params.analysis.cyclo.refitBeta
           b    = pinv(X)*vData;  
           rss  = norm(vData-X*b(1)).^2;
           
           model.b2(:,vi) = model.b(:,vi);
           model.b(1,vi) = b;           
    else
        rss  = norm(vData-X).^2;
    end

    model.rss(vi)  = rss;
        

end;

% end time monitor
et  = toc;
if floor(et/3600)>0,
    fprintf(1,'Done [%d hours].\n',ceil(et/3600));
else
    fprintf(1,'Done [%d minutes].\n',ceil(et/60));
end;
fprintf(1,'[%s]:Removed negative fits: %d (%.1f%%).\n',...
    mfilename,nNegFit,nNegFit./numel(wProcess).*100);

return;

%-----------------------------------
% make sure that the pRF can only be moved "step" away from original
% poisiton "startParams"
% For the two Gaussian model we add the additional constraint that the
% second Gaussian is at least twice as large as the first.
function [C, Ceq]=distanceCon(x,startParams,step,minRatio)
Ceq = [];
dist = x([1 2])-startParams([1 2]);
C(1) = sqrt(dist(1).^2+dist(2).^2) - step;
C(2) = minRatio - 0.001 - x(4)./x(3);
return;
%-----------------------------------

