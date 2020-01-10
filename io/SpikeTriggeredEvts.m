function signals = bz_SpikeTriggeredEvts(basepath,markers,wdw,varargin)
% [signals] = bz_SpikeTriggeredEvts(basePath) Get the waveforms associated 
% with the timestamps specified by 'markers' in a window of +/- wdw seconds 
% around each marker for all channels of a recording.
% 
% INPUT
%   basePath        directory: '/whatevetPath/baseName/'
%   markers         nmarkers x 1 vector: timestamps of events to be
%                   events to be extracted (e.g. spiketimes).
%   wdw             double: time window (+/-) around each marker to be
%                   extracted
%   (optional)      
%   channelgroups   cell array: groups of channels to be coloured
%   groupcolors     cell array: colors for the groups specified above.
%
% Output: nchannels x 2*wdw+1 x nMarkers matrix containing the peri-marker
% recording traces.
%
% Useful to retrieve waveforms of a given unit, but also to observe its
% direct effect on the signatures of neighboring shanks (e.g. synaptic
% potentials, etc.).
%
% Thomas Hainmueller, 2019
%% inputs and defaults
p = inputParser;
addParameter(p,'channelgroups',{},@iscell);
addParameter(p,'groupcolors',{},@islogical);
parse(p,varargin{:})
noPrompts = p.Results.channelgroups;
editGUI = p.Results.groupcolors;

if ~exist('basePath','var')
    basePath = pwd;
end
baseName = bz_BasenameFromBasepath(basePath);

%% Iterate through binary file
sessionInfo = bz_getSessionInfo(basepath,'noPrompts',true);
nChannels = sessionInfo.nChannels;

for n=length(markers):-1:1
    signals(:,:,n) = LoadBinary([baseName,'.dat'],'start',markers(n)-wdw,...
        'duration',2*wdw,'nChannels',nChannels,'channels',1:nChannels);
end
end
    