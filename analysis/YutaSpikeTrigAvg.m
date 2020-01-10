function data = YutaSpikeTrigAvg(UnitFeatureCell,varargin)
% Extracting spike triggered averages from raw data for all identified GC,
% MC and CA3 units plus the postsynaptic targets of GCs. Aim is to identify 
% extracellular signatures of MF-bouton activity.
%
% Thomas Hainmueller 2019

%% inputs and defaults
p = inputParser;
addParameter(p,'basepath',pwd,@isstr);
addParameter(p,'psthwdw',.005,@isnumeric);
addParameter(p,'nsamples',100,@isnumeric);
addParameter(p,'saveoutput',true,@islogical);
addParameter(p,'filename','_WholeProbeWaveforms.mat',@ischar);
addParameter(p,'applyfilter',true,@islogical);
addParameter(p,'DS12separation',true,@islogical);

parse(p,varargin{:})

basepath = p.Results.basepath;
psthwdw = p.Results.psthwdw; %Window in ms for perispike histograms
nsamples = p.Results.nsamples; %Number of spikes used for triggered averages
saveoutput = p.Results.saveoutput;
outfilename = p.Results.filename;
applyfilter = p.Results.applyfilter;
DS12sep = p.Results.DS12separation;

%IntanConversion = 0.000050354; %Conversion factor for signal amplitude (voltage).
IntanConversion = 0.195; %To microvolts, see http://intantech.com/files/Intan_RHD2000_data_file_formats.pdf

%% Load relevant indexing data
cd(basepath);
baseName = bz_BasenameFromBasepath(basepath);

try 
    spikes = bz_GetSpikes('noPrompts',true);
catch
    warning('Could not load spikes, aborting...');
    return
end

try
    sessionInfo = bz_getSessionInfo(basepath,'noPrompts',true);
catch
    warning('Could not load SessionInfo, aborting...');
    return
end

try 
    conn = dir('*MonoSynConvClick.mat');
    conn = load(conn.name,'FinalExcMonoSynID');
    conn = conn.FinalExcMonoSynID;
catch
    warning('Connection matrix (MonoSynConvClick.mat) not found, aborting');
    return
end

if DS12sep
    % Make sure these files exist in preprocessing!
    DS1fn = ls('*DS1.ch*.evt');
    DS1 = LoadEvents(DS1fn(1,:));
    DS1 = [DS1.time(1:3:end),DS1.time(3:3:end)]; %Convert to list form
    DS2fn = ls('*DS2.ch*.evt');
    DS2 = LoadEvents(DS2fn(1,:));
    DS2 = [DS2.time(1:3:end),DS2.time(3:3:end)];
end

% Get global IDs for the units in this session
unitIDs = [];
for n=1:size(UnitFeatureCell.fname,1)
    if strcmp(baseName,UnitFeatureCell.fname(n,:))
        unitIDs = [unitIDs,n];
    end
end

%% Find out who is who
% Granule cells
GCindexGlobal = UnitFeatureCell.unitID(and(and(...
    max(UnitFeatureCell.unitID == unitIDs,[],2),...
    UnitFeatureCell.fineCellType == 1),...
    UnitFeatureCell.region == 4));
GCindexSession = UnitFeatureCell.unitIDsession(GCindexGlobal);


% Mossy Cells
MCindexGlobal = UnitFeatureCell.unitID(and(...
    max(UnitFeatureCell.unitID == unitIDs,[],2),...
    UnitFeatureCell.fineCellType == 2));
MCindexSession = UnitFeatureCell.unitIDsession(MCindexGlobal);

% CA3 pyramidal cells
CA3pyrindexGlobal = UnitFeatureCell.unitID(and(and(...
    max(UnitFeatureCell.unitID == unitIDs,[],2),...
    UnitFeatureCell.fineCellType == 1),...
    UnitFeatureCell.region == 3));
CA3pyrindexSession = UnitFeatureCell.unitIDsession(CA3pyrindexGlobal);

%% Set up datasetructure and get the data
%% Granule cells first, together with all postsynaptic partners
for gc = length(GCindexSession):-1:1
    disp(sprintf('Pulling signals from GC #%d and its targets',GCindexSession(gc)))
    % Information about the unit in question
    data.GCs{gc}.UnitSessionID = GCindexSession(gc);
    data.GCs{gc}.UnitGlobalID = GCindexGlobal(gc);
    data.GCs{gc}.Ccg = UnitFeatureCell.Ccg(...
        data.GCs{gc}.UnitGlobalID,:);
    data.GCs{gc}.maxWaveformCh = spikes.maxWaveformCh(GCindexSession(gc));
    data.GCs{gc}.ShankID = spikes.shankID(GCindexSession(gc));
    data.GCs{gc}.ShankPos = find(sessionInfo.spikeGroups.groups{...
        data.GCs{gc}.ShankID}==data.GCs{gc}.maxWaveformCh);
    
    
    % Get the spike triggered averages; limit sample number for performance
    if length(spikes.times{GCindexSession(gc)})>nsamples
        timestamps = randsample(spikes.times{GCindexSession(gc)},nsamples,false);
    else
        timestamps = spikes.times{GCindexSession(gc)};
    end

    data.GCs{gc}.signals = bz_SpikeTriggeredEvts(basepath,timestamps,psthwdw,...
        'fs',1000000/sessionInfo.SampleTime,'filterFreq',300,'applyfilter',...
        applyfilter)*IntanConversion;
    
    % Now the monosynaptic targets
    targets = conn(conn(:,1)==...
        GCindexSession(gc),2);
    
    for t = length(targets):-1:1
        data.GCs{gc}.targets{t}.UnitSessionID = targets(t);
        data.GCs{gc}.targets{t}.UnitGlobalID = UnitFeatureCell.unitID(...
            and(max(UnitFeatureCell.unitID == unitIDs,[],2),...
            max(UnitFeatureCell.unitIDsession == targets(t),[],2)));
        data.GCs{gc}.targets{t}.Ccg = UnitFeatureCell.Ccg(...
            data.GCs{gc}.targets{t}.UnitGlobalID,:);
        data.GCs{gc}.targets{t}.maxWaveformCh =...
            spikes.maxWaveformCh(targets(t));
        data.GCs{gc}.targets{t}.ShankID = spikes.shankID(targets(t));
        data.GCs{gc}.targets{t}.ShankPos = find(sessionInfo.spikeGroups.groups{...
            data.GCs{gc}.targets{t}.ShankID}==data.GCs{gc}.targets{t}.maxWaveformCh);
        data.GCs{gc}.targets{t}.region = UnitFeatureCell.region(...
            data.GCs{gc}.targets{t}.UnitGlobalID);
        data.GCs{gc}.targets{t}.fineCellType = UnitFeatureCell.fineCellType(...
            data.GCs{gc}.targets{t}.UnitGlobalID);
        
        % Get the spike triggered averages; limit sample number for performance
        Itransmitted = transmittedSpikes(spikes.times{GCindexSession(gc)},...
            spikes.times{targets(t)},.005);
        
        if length(spikes.times{targets(t)})>nsamples
            allspikes = randsample(spikes.times{targets(t)},nsamples,false);
        else
            allspikes = spikes.times{targets(t)};
        end
        
        if length(spikes.times{targets(t)}(Itransmitted))>nsamples
            transmitted = randsample(spikes.times{targets(t)}(Itransmitted),nsamples,false);
        else
            transmitted = spikes.times{targets(t)}(Itransmitted);
        end
        
        if length(spikes.times{targets(t)}(~Itransmitted))>nsamples
            nontransmitted = randsample(spikes.times{targets(t)}(~Itransmitted),nsamples,false);
        else
            nontransmitted = spikes.times{targets(t)}(~Itransmitted);
        end

        
        data.GCs{gc}.targets{t}.allsignals = bz_SpikeTriggeredEvts(...
            basepath,allspikes,psthwdw,...
            'fs',1000000/sessionInfo.SampleTime,'filterFreq',300,'applyfilter',...
            applyfilter)*IntanConversion;
        data.GCs{gc}.targets{t}.transmitted = bz_SpikeTriggeredEvts(...
            basepath,transmitted,psthwdw,...
            'fs',1000000/sessionInfo.SampleTime,'filterFreq',300,'applyfilter',...
            applyfilter)*IntanConversion;
        data.GCs{gc}.targets{t}.nontransmitted = bz_SpikeTriggeredEvts(...
            basepath,nontransmitted,psthwdw,...
            'fs',1000000/sessionInfo.SampleTime,'filterFreq',300,'applyfilter',...
            applyfilter)*IntanConversion;
    end
end

%% Mossy cells
for mc = length(MCindexSession):-1:1
    disp(sprintf('Pulling signals from Mossy cell #%d',MCindexSession(mc)))
    % Information about the unit in question
    data.MCs{mc}.UnitSessionID = MCindexSession(mc);
    data.MCs{mc}.UnitGlobalID = MCindexGlobal(mc);
    data.MCs{mc}.Ccg = UnitFeatureCell.Ccg(...
        data.MCs{mc}.UnitGlobalID,:);
    data.MCs{mc}.maxWaveformCh = spikes.maxWaveformCh(MCindexSession(mc));
    data.MCs{mc}.ShankID = spikes.shankID(MCindexSession(mc));
    data.MCs{mc}.ShankPos = find(sessionInfo.spikeGroups.groups{...
        data.MCs{mc}.ShankID}==data.MCs{mc}.maxWaveformCh);

    if length(spikes.times{MCindexSession(mc)})>nsamples
        timestamps = randsample(spikes.times{MCindexSession(mc)},nsamples,false);
    else
        timestamps = spikes.times{MCindexSession(mc)};
    end

    data.MCs{mc}.signals = bz_SpikeTriggeredEvts(basepath,timestamps,psthwdw,...
        'fs',1000000/sessionInfo.SampleTime,'filterFreq',300,'applyfilter',...
        applyfilter)*IntanConversion;
    
    % Separately store spikes occuring during dentate spikes
    if DS12sep
        DS1spikes = spikes.times{MCindexSession(mc)}(...
            InIntervals(spikes.times{MCindexSession(mc)},DS1));
        DS2spikes = spikes.times{MCindexSession(mc)}(...
            InIntervals(spikes.times{MCindexSession(mc)},DS2));
        if length(DS1spikes)>nsamples
            DS1spikes = randsample(DS1spikes,nsamples);
        end
        if length(DS2spikes)>nsamples
            DS2spikes = randsample(DS2spikes,nsamples);
        end
        
        data.MCs{mc}.ds1spikes = bz_SpikeTriggeredEvts(basepath,DS1spikes,psthwdw,...
            'fs',1000000/sessionInfo.SampleTime,'filterFreq',300,'applyfilter',...
            applyfilter)*IntanConversion;
        
        data.MCs{mc}.ds2spikes = bz_SpikeTriggeredEvts(basepath,DS2spikes,psthwdw,...
            'fs',1000000/sessionInfo.SampleTime,'filterFreq',300,'applyfilter',...
            applyfilter)*IntanConversion;
    end     
end

%% CA3 pyramidal cells
for pc = length(CA3pyrindexSession):-1:1
    disp(sprintf('Pulling signals from CA3 pyramidal cell #%d',CA3pyrindexSession(pc)))
    % Information about the unit in question
    data.PCs{pc}.UnitSessionID = CA3pyrindexSession(pc);
    data.PCs{pc}.UnitGlobalID = CA3pyrindexGlobal(pc);
    data.PCs{pc}.Ccg = UnitFeatureCell.Ccg(...
        data.PCs{pc}.UnitGlobalID,:);
    data.PCs{pc}.maxWaveformCh = spikes.maxWaveformCh(CA3pyrindexSession(pc));
    data.PCs{pc}.ShankID = spikes.shankID(CA3pyrindexSession(pc));
    data.PCs{pc}.ShankPos = find(sessionInfo.spikeGroups.groups{...
        data.PCs{pc}.ShankID}==data.PCs{pc}.maxWaveformCh);
    
    % Get the spike triggered averages; limit sample number for performance
    if length(spikes.times{CA3pyrindexSession(pc)})>nsamples
        timestamps = randsample(spikes.times{CA3pyrindexSession(pc)},nsamples,false);
    else
        timestamps = spikes.times{CA3pyrindexSession(pc)};
    end
    
    data.PCs{pc}.signals = bz_SpikeTriggeredEvts(basepath,timestamps,psthwdw,...
        'fs',1000000/sessionInfo.SampleTime,'filterFreq',300,'applyfilter',...
        applyfilter)*IntanConversion;
    
    % Separately store spikes occuring during dentate spikes
    if DS12sep
        DS1spikes = spikes.times{CA3pyrindexSession(pc)}(...
            InIntervals(spikes.times{CA3pyrindexSession(pc)},DS1));
        DS2spikes = spikes.times{CA3pyrindexSession(pc)}(...
            InIntervals(spikes.times{CA3pyrindexSession(pc)},DS2));
        if length(DS1spikes)>nsamples
            DS1spikes = randsample(DS1spikes,nsamples);
        end
        if length(DS2spikes)>nsamples
            DS2spikes = randsample(DS2spikes,nsamples);
        end
        
        data.PCs{pc}.ds1spikes = bz_SpikeTriggeredEvts(basepath,DS1spikes,psthwdw,...
            'fs',1000000/sessionInfo.SampleTime,'filterFreq',300,'applyfilter',...
            applyfilter)*IntanConversion;
        
        data.PCs{pc}.ds2spikes = bz_SpikeTriggeredEvts(basepath,DS2spikes,psthwdw,...
            'fs',1000000/sessionInfo.SampleTime,'filterFreq',300,'applyfilter',...
            applyfilter)*IntanConversion;
    end
end

%% Save the data
if saveoutput
    save([baseName,outfilename],'data','-v7.3');
end
end

function spikes = transmittedSpikes(ts1,ts2,mininterval)
% Give a logical vector of spikes in ts2 that were preceeded by ts1 in a 5
% millisecond interval indicating pre-post transmission.
if ~exist('mininterval')
    mininterval = 0.005; %Default: 5 milliseconds
end

for n=length(ts2):-1:1
    thisres = ts1(find(ts1<ts2(n),1,'last'));
    if ~isempty(thisres)
        spikes(n)=(ts2(n)-thisres)<mininterval;
    end
end
end
