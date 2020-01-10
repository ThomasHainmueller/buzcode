function plotCCGWaveForm(fname,ref_unit,targ_unit,ch,nch,epoch)

% plots -pre to +post ms on ch at each spike time of ref_unit
% plot waveforms from targ_unit in red
% if user submits dat file, then it will be hipass filtered

%fname = dat/fil filename
%ref_unit = [ch cluster] or pre-synaptic cell
%targ_unit = [ch cluster] or post-synaptic cell
%ch = channel(base 1) to plot
%nch = number of channels in the dat/fil
%epochs(optional) = [Nx2] start/stop ts pairs (s)

%eg. plotCCGWaveForm(fname,[2 5],[2 15],35,64,[0 1000]);
%requires FMAtoolbox

hh = [];
idx = 1;



if nargin <6
    epoch = [0 inf];
end



%sampling rate of dat/fil file
Fs = 20000;
IntanConversion = 0.000050354; %Conversion factor for signal amplitude (voltage).
%upsample
upVal = 4;

%time before and after (s)
pre = .003;
post = .005;
ts = -pre:1/(Fs*upVal):post;




warning off
%how many ref waveforms to plot
numWave = 400;

if exist([fname(1:end-3) 'xml'],'file') ==2
    SetCurrentSession([fname(1:end-3) 'xml'])
else
    disp('ERROR: Missing XML')
    return;
end

if  ~(strcmp(fname(end-2:end),'fil') || strcmp(fname(end-2:end),'dat'))
    disp('ERROR: Must be a fil or dat file')
    return;
end

if ~exist([fname],'file') ==2
    
    disp('ERROR: Missing data file')
    return;
end

units = GetUnits;

if ~ismember(ref_unit,units,'rows')
    disp('ERROR: Cell not part of data set')
    return;
end


%get timestamps
unit_ts = GetSpikeTimes(ref_unit,'output','numbered');
unit_ts  = unit_ts(:,1);

cnt = kspike(unit_ts,1,.01);

unit_ts = unit_ts(cnt==2);

targ_ts = GetSpikeTimes(targ_unit,'output','numbered');
targ_ts = targ_ts(:,1);

%only keep waveforms in epoch
in = InIntervals(unit_ts,epoch);
unit_ts = unit_ts(in);

if isempty(unit_ts)
    disp('ERROR: No spikes')
    return;
    
end
%only keep numWave ref spike times
if length(unit_ts)>numWave
    kp = randsample(1:length(unit_ts),numWave);
    unit_ts = unit_ts(kp);
else
    numWave = length(unit_ts);
end



%%
%plot it
figure

plot([0 0],[-.07 .07],'color',[.7 .7 .7])
hold on

for i = 1:numWave
    
    %get relevant target waveforms
    t = targ_ts(targ_ts>unit_ts(i)-pre & targ_ts < unit_ts(i)+post);
    
    
    %get raw dat/fil data +/ ref spike
    
    
    fil_data = LoadBinary(fname,'nChannels',nch,'channels',ch,'start',unit_ts(i)-pre,'duration',pre+post);
    fil_data = double(fil_data)*IntanConversion;
    %if dat file is loaded, filter
    if  strcmp(fname(end-2:end),'dat')
        fil_data = BandpassFilter(fil_data,20000,[100 10000]);
    end
    
    %up sample raw data by upVal
    fil_data = interp1(-pre:1/(Fs):post - 1/Fs,fil_data,ts,'cubic');
    
    
    patchline(ts,fil_data,'edgecolor','k','linewidth',.5,'edgealpha',0.1)
    
    
    for j = 1:length(t)
        
        %find indices of +/- .0006s around each target spike (clip to window)
        targ_spki = round((t(j)-unit_ts(i)-.0006+pre)*(Fs*upVal)):round((t(j)-unit_ts(i)+.0006+pre)*(Fs*upVal));
        targ_spki(targ_spki>length(ts)) = length(ts);
        targ_spki(targ_spki<1) = 1;
        hh(idx) =  patchline(ts(targ_spki),fil_data(targ_spki),'edgecolor','r','linewidth',1.3,'edgealpha',0.07);
        idx = idx+1;
    end
    
    
end


%put on target wike waveforms on top
for j = 1:length(hh)
    
    uistack(hh(j), 'top')
end
xlim([-.003 .005])
xlabel('time (s)')
ylabel('V')
ylim([-.07 .07])
title([num2str(ref_unit) ' to ' num2str(targ_unit)])
end

function signal_filtered = BandpassFilter(signal, Fs, Fpass)

Wn_theta = [Fpass(1)/(Fs/2) Fpass(2)/(Fs/2)]; % normalized by the nyquist frequency

[btheta,atheta] = butter(3,Wn_theta);

signal_filtered = filtfilt(btheta,atheta,signal);
end