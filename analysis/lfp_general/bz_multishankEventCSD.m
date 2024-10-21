%% SEE bz_eventMultishankCSD for this
% function bz_multishankEventCSD(varargin)
% % Create an event-triggered mean and CSD of the LFP.
% % 
% % Thomas Hainmueller, Buzsakilab 2023
% 
% badChanValidation = @(x) any(strcmp(x,{'exclude','interpolate'}));
% shankValidation = @(x) strcmp(x,'all') | isnumeric(x);
% 
% p = inputParser;
% addRequired(p,'events'); % Can be buzcode compatible event structure or vector of timestamps
% addParameter(p,'basepath',pwd,@ischar);
% addParameter(p,'window',[-0.1 0.1],@isnumeric); % Window around each timestamp, in seconds
% addParameter(p,'shanks','all',shankValidation);
% addParameter(p,'sessionInfo',[],@isstruct);
% addParameter(p,'ntraces',0,@isnumeric); % Number of individual traces to show
% addParameter(p,'offset',2,@isnumeric); % Between traces, in mV
% addParameter(p,'IntanConvFact',0.00038,@isnumeric);
% addParameter(p,'skipStaggered',false,@islogical); % Skip every second chan for staggered probes
% addParameter(p,'badChHandling','exclude',badChanValidation);
% 
% parse(p,varargin{:});
% events = p.Results.events;
% shanks = p.Results.shanks;
% basepath = p.Results.basepath;
% window = p.Results.window;
% sessionInfo = p.Results.sessionInfo;
% ntraces = p.Results.ntraces;
% offset = p.Results.offset;
% IntanConvFact = p.Results.IntanConvFact;
% skipStaggered = p.Results.skipStaggered;
% badChHandling = p.Results.badChHandling;
% 
% if isstruct(events)
%     events = events.timestamps(:,1);
% end
% 
% events = events(:); % Force column vector;
% 
% if isempty(sessionInfo)
%     sessionInfo = bz_getSessionInfo(basepath,'noPrompts',true);
% end
% 
% rng(1);
% 
% %% Core
% intervals = [events+window(1) events+window(2)];
% lfp = bz_GetLFP('all','basepath',basepath,'intervals',intervals);
% 
% if ~isempty(sessionInfo.spikeGroups.groups)
%     spkgroups = sessionInfo.spikeGroups.groups;
% else
%     spkgroups = {sessionInfo.AnatGrps.Channels};
% end
% 
% if ~strcmp(shanks,'all')
%     spkgroups = spkgroups(shanks);
% end
% nSpkg = length(spkgroups);
% 
% if isfield(sessionInfo,'badchannels')
%     badchan = sessionInfo.badchannels;
% else
%     badchan = [];
% end
% 
% figure('position',[100 100 200*nSpkg 300]);
% 
% [dsize1,~] = cellfun(@size,{lfp(:).data});
% incomplete = dsize1<median(dsize1);
% 
% data = cat(3,lfp(~incomplete).data);
% timeV = linspace(window(1),window(2),size(data,1));
% 
% for spkg = 1:nSpkg
%     subplot(1,nSpkg,spkg);
%     hold on
%     %chans = sessionInfo.spikeGroups.groups{spkg} + 1;
%     chans = spkgroups{spkg}+1;
%     thesedata = double(data(:,chans,:))*IntanConvFact;
%     
%     % handle bad channels
%     if all(ismember(chans,badchan+1))
%         % skip dead shanks on plot
%         continue
%     elseif strcmp(badChHandling,'exclude')
%         thesedata = thesedata(:,~ismember(chans,badchan+1),:);
%     end
%     
%     if skipStaggered
%         thesedata = thesedata(:,1:2:end,:);
%     end
%     
%     % Plot CSD profile
%     shCSD = -diff(nanmedian(thesedata,3),2,2);
%     shCSD = cat(2,zeros(size(shCSD,1),1), shCSD, zeros(size(shCSD,1),1));
%     
%     cmax = max(max(shCSD));
%     
%     set(gca,'YDir','reverse');
%     contourf(timeV,(0:size(shCSD,2)-1)*offset,shCSD',40,'LineColor','none');
%     colormap jet; 
%     if ~isempty(collims)
%         caxis(collims);
%     else
%         caxis([-cmax cmax]);
%     end
%     xlabel('time (s)');
%     ylabel('amplitude (mV)');
%     
%     for ch=1:size(thesedata,2)
%         thisoffset = offset*(ch-1);
%         
%         % Plot individual traces if selected
%         if ntraces > 0
%             smp = randsample(1:size(thesedata,3),ntraces,true);
%             plot(timeV,(thisoffset - squeeze(thesedata(:,ch,smp)))',...
%                 'color',[0 0 0 .05],'LineWidth',.5); % Flip direction of plot for reverse Y axis!
%         end
%         
%         plot(timeV,thisoffset - nanmedian(thesedata(:,ch,:),3),'k','LineWidth',1);
%         xlabel('Time (s)');
%     end
% end
% 
% end