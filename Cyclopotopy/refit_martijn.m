function refit(vs,roi,model,postfix,refitBeta)
% vs = dataTypes
% sample call: refit([5 6 7 9 10 11],'RightV1','retModel-DoG-fFit') % vs = dataType #s
% sample call: refit([5 6 7 9 10 11],[],[pwd '/Gray/Averages/retModel-DoG-fFit'])
% refit([5 6 7 9 10 11],[],[pwd '/Gray/At fixation and Interleave/retModel-DoG-fFit'])
% refit([9 10 11],[],[pwd '/Gray/At fixation and Interleave Combined/retModel-DoG-fFit-fFit-fFit-combined'])
% refit([5 6 7 9 10 11],[],[pwd '/Gray/At fixation and Interleave Combined/retModel-DoG-fFit-fFit-fFit-combined'])
% refit([5 6 7 9 10 11],[],[pwd '/Gray/At fixation/retModel-DoG-fFit-fFit-fFit-combined'])


% refit op 2 versies van ieder (at fixation, interleave, and far) dataType,
% with the two different image files (image_atFixationBinary and
% image_interleave)

for v = vs
    subRefit(v,roi,model,postfix,refitBeta)
end
return

function subRefit(v,roi,model,postfix,refitBeta)
% sample call: refit(VOLUME{1},'RightV1','retModel-DoG-fFit')
% sample call: refit(5,'RightV1','retModel-DoG-fFit') % 5 = dataType #

% v = viewSet(5,'rmfile',model);
% When loading retModel, fitted hrf is in params.stim.hrfParams
% v = viewSet(v,'rmFile',model)
% hrfParams = viewGet(v,'rmhrf') % Attempt to load fitted hrf (default [5.4000 5.2000 10.8000 7.3500 0.3500])
% Ugly hack that needs to get fixed
temp = load(model);
val1 = temp.params.stim(1).hrfType;
val2 = temp.params.stim(1).hrfParams{2};
hrfParams = {val1 val2};

if ~isstruct(v),
    v = rmInitView([1 v],roi); % 1 = VOLUME #, v = dataType #
end

[junk filename]=fileparts(model);
v = viewSet(v,'rmfile',model);

% v = rmMain(v,[],0,'refine','refit','matfilename',[model '-refit']); %,'dc',true);
% v = rmMain(v,[],0,'refine','refit','matfilename',[filename '-refit']); %,'dc',true);
% v = rmMain(v,['V1-V3'],0,'refine','refit','matfilename',[filename '-refit']); %,'dc',true);
v = rmMain(v,...
    [],...
    0,...
    'cyclo',true,...    
    'refine','refit',...
    'matfilename',[filename '-' postfix],...
    'hrf',hrfParams); 
%'refitbeta',refitBeta,...
    %,'dc',true);
   
return

% 
% % Diagnostics
% onXAxis = 'retModel-DoG-fFit-refitdc-fFit';
% onYAxis = 'retModel-DoG-fFit-shift-refitdc-fFit';
% 
% a = load(onXAxis);
% b = load(onYAxis);
% figure(12);clf;
% 
% % p = 'varexp'; % Get varianced explained by the model
% p = 'sigma'; % Get pRF width
% 
% % plot(log(rmGet(a.model{1},p)),log(rmGet(b.model{1},p)),'.');
% plot(rmGet(a.model{1},p),rmGet(b.model{1},p),'.');
% 
% title(pwd)
% xlabel(onXAxis)
% ylabel(onYAxis)
% 
% % axis([-2 2 -2 2]) % Warning: Cuts off datapoints!
% axis([-1 1 -1 1]) % Warning: Cuts off datapoints!