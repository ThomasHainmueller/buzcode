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
%
% Output: nchannels x 2*wdw+1 x nMarkers matrix containing the peri-marker
% recording traces.
%
% Useful to retrieve waveforms of a given unit, but also to observe its
% direct effect on the signatures of neighboring shanks (e.g. synaptic
% potentials, etc.).
%
% Thomas Hainmueller, 2019
%% Input handling
p = inputParser;
addParameter(p,'applyfilter',true,@islogical);
addParameter(p,'filterFreq',500,@isnumeric);
addParameter(p,'fs',30000,@isnumeric);

parse(p,varargin{:})

applyfilter = p.Results.applyfilter;
filterFreq = p.Results.filterFreq;
fs = p.Results.fs;

if ~exist('basePath','var')
    basePath = pwd;
end
baseName = bz_BasenameFromBasepath(basePath);
filename = fullfile(basepath,[baseName,'.dat']);
%% Iterate through binary file
sessionInfo = bz_getSessionInfo(basepath,'noPrompts',true);
nChannels = sessionInfo.nChannels;

for n=length(markers):-1:1
    signals(:,:,n) = LoadBinary(filename,'start',markers(n)-wdw,...
        'duration',2*wdw,'nChannels',nChannels,'channels',1:nChannels);
end

if applyfilter
    [b,a] = ellip(2,.1,60,2*filterFreq/fs,'high'); %Empirical filter design...
    signals = FiltFiltM(b,a,double(signals));
end
end
    