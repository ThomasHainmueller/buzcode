function [h] = layoutplot(matrix,sessionInfo,varargin)
% layoutplot(matrix,sessionInfo). Plot data in 'matrix' according to the
% probe layout specified in 'sessionInfo'
%
% INPUTS
%   matrix          nchannels x ndatapoints matrix of data acquired from the
%                   respective channel (e.g. LFP fragments or similar).
%   sessionInfo     For the respective recording session.
%   
%   (optional)      
%   colorgroups     channels x 2 vector: specifying channel number and
%                   corresponding color group.
%   xValues         vector of length ndatapoints specifying x-axis values.
%   Position        Figure size and location
%   yrange          Amplitude range to plot in, in microvolt

% Thomas Hainmueller 2019
%% inputs and defaults
p = inputParser;
addParameter(p,'colorgroups',single.empty(2,1,0),@isnumeric);
addParameter(p,'xValues',[],@isnumeric);
addParameter(p,'Position',[50 50 800 920],@isnumeric);
addParameter(p,'traces',[],@isnumeric);
addParameter(p,'traceImg',true,@islogical);
addParameter(p,'yrange','auto',@isnumeric);

parse(p,varargin{:})
colorgroups = p.Results.colorgroups;
xValues = p.Results.xValues;
Position = p.Results.Position;
traces = p.Results.traces;
traceImg = p.Results.traceImg;
yrange = p.Results.yrange;

if ~exist('sessionInfo')
    sessionInfo = bz_GetSessionInfo();
end

% IntanConversion = 0.000050354; %Conversion factor for signal amplitude (voltage).
%% Plotting
ncols = length(sessionInfo.SpkGrps);
nrows = length(sessionInfo.SpkGrps(1).Channels); % Assumes equal numbers of groups per channel

h = figure; h.Renderer = 'Painter';
for pos = 1:ncols*nrows
    % Indices on the plot
    icol = mod(pos-1,8)+1;
    irow = ceil(pos/8);
    
    % corresponding channel
    index = sessionInfo.SpkGrps(icol).Channels(irow)+1; % Cave: 1-based indexing
    
    if traceImg
        subplot(ncols,nrows*2,pos*2-1);
    else
        subplot(ncols,nrows,pos);
    end
 
    % Color fields according to groups specified
    if any(colorgroups(1,:)==(index-1)) %Cave: Channels passed in color groups are 0-based
        thisgroup = colorgroups(2,colorgroups(1,:)==(index-1));
        %cval = .5+.5*thisgroup/(max(colorgroups(2,:)+1));
        %set(subplot(ncols,nrows,pos),'Color',[cval,cval,cval]);
        cval = .5*thisgroup(1)/(max(colorgroups(2,:)+1)); %Index one in case both cells are in same channel
        color = [1 cval cval];
    else
        color = [0 0 0];
    end
    
    % Create whatever here, e.g. imagesc or as desired
    if ~isempty(xValues)
        if ~isempty(traces) && traceImg
            subplot(ncols,nrows*2,pos*2);
            imagesc(xValues,1:size(traces,3),squeeze(traces(:,index,:))'); 
            caxis(yrange);
            ax = gca; ax.FontSize = 3; 
            subplot(ncols,nrows*2,pos*2-1);
        elseif ~isempty(traces)
            hold on
            for t = 1:size(traces,3)
                plot(xValues,traces(:,index,t),'color',[.3 [t/size(traces,3)] 1],'LineWidth',.001);
            end
        end
        %plot(xValues,matrix(:,index),'color',[0 0 0]);
        plot(xValues,matrix(:,index),'color',color);
        ylim(yrange);
    else
        if ~isempty(traces) && traceImg
            subplot(ncols,nrows*2,pos*2);
            imagesc(squeeze(traces(:,index,:))');
            caxis(yrange);
            ax = gca; ax.FontSize = 3; 
            subplot(ncols,nrows*2,pos*2-1);
        elseif ~isempty(traces)
            hold on
            for t = 1:size(traces,3)
                plot(traces(:,index,t),'color',[.3 [t/size(traces,3)] 1],'LineWidth',.001);
            end
        end
        %plot(matrix(:,index),'color',[0 0 0]);
        plot(matrix(:,index),'color',color);
        ylim(yrange);
    end
    ax = gca;
    ax.FontSize = 3; 
end

set(gcf,'Position',Position);
end
