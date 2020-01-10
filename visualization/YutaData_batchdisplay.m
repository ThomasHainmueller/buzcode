%% Convenience code for displaying results from Yuta spike-triggered averages
% Iterate through all pairs
for n=1:length(data.GCs)
    if isfield(data.GCs{n},'targets')
        for t=1:length(data.GCs{n}.targets)
            layoutplot(data.GCs{n}.signals,sessionInfo,'colorgroups',...
                [data.GCs{n}.maxWaveformCh;1],'Position',[10 1100 650 650]);
            %title('Presynaptic GC')
            layoutplot(data.GCs{n}.targets{t}.transmitted,sessionInfo,'colorgroups',...
                [[data.GCs{n}.maxWaveformCh,data.GCs{n}.targets{t}.maxWaveformCh];[2,1]],...
                'Position',[10+650*1 1100 650 650]);
            %title('Transmitted spikes')
            layoutplot(data.GCs{n}.targets{t}.nontransmitted,sessionInfo,'colorgroups',...
                [[data.GCs{n}.maxWaveformCh,data.GCs{n}.targets{t}.maxWaveformCh];[2,1]],...
                'Position',[10+650*2 1100 650 650]);
            %title('Non transmitted spikes')
            input('Press Enter to continue to next pair');
            close all
        end
    end
end

%% Iterate through all GCs
for n=1:length(data.GCs)
    layoutplot(data.GCs{n}.signals,sessionInfo,'colorgroups',...
        [data.GCs{n}.maxWaveformCh;1],'Position',[30 900 1600 950]);
    input('Press Enter to continue to next GC');
    close all
end

%% Iterate through all MCs
for n=1:length(data.MCs)
    layoutplot(data.MCs{n}.signals,sessionInfo,'colorgroups',...
        [data.MCs{n}.maxWaveformCh;1],'Position',[30 900 1600 950]);
    input('Press Enter to continue to next MC');
    close all
end

%% Iterate through all CA3 PYR
for n=1:length(data.PCs)
    layoutplot(data.PCs{n}.signals,sessionInfo,'colorgroups',...
        [data.PCs{n}.maxWaveformCh;1],'Position',[30 900 1600 950]);
    input('Press Enter to continue to next CA3 pyramidal cell');
    close all
end