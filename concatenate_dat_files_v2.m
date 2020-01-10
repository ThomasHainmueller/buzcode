function concatenate_dat_files_v2(datapath,recordings)
% Creates a concatenated dat file, optionally with analog channels as well
%
% Inputs:
% datapath: path to the files (e.g.: 'G:\IntanData\' )
% recordings: name of recordings (e.g.: {'Peter_160831_182631','Peter_160831_182631'} )
% combine_amp_analog: further combines amplifier.dat with analogin.dat
% add_empty_space : Adds empty space between recordings
% 
% By Peter Petersen
% petersen.peter@gmail.com

% datapath = 'Z:\peterp03\IntanData\MS13\'
% recordings = {'Peter_MS13_171206_132039','Peter_MS13_171206_164117','Peter_MS13_171206_171703'}
% combine_amp_analog = 0
% add_empty_space = 0

% Creating concatenation folder
if ~exist(fullfile(datapath, [recordings{1},'_concat\']))
    mkdir(fullfile(datapath, [recordings{1},'_concat\']))
end
recording_dir_path = fullfile(datapath, recordings{1});
recording_dir_out = fullfile(datapath, [recordings{1},'_concat']);

% Copying xml, nrs and info.rhd to the new folder
if exist(fullfile(recording_dir_path, [recordings{1}, '.xml']))== 0
    disp('No xml file found in the source folder')
else
    disp('Copying .xml file to concatenated folder')
    copyfile(fullfile(recording_dir_path, [recordings{1}, '.xml']),fullfile(recording_dir_out, [recordings{1}, '_concat.xml']))
end
if exist(fullfile(recording_dir_path, [recordings{1}, '.nrs']))~= 0
    disp('Copying .nrs file to concatenated folder')
    copyfile(fullfile(recording_dir_path, [recordings{1}, '.nrs']),fullfile(recording_dir_out, [recordings{1}, '_concat.nrs']))
end
disp('Copying info.rhd file to concatenated folder')
copyfile(fullfile(recording_dir_path, 'info.rhd'),fullfile(recording_dir_out, 'info.rhd'))

disp('Creating dat file in concatenated folder')
command = ['copy /b '];
for i = 1:length(recordings)-1
    command = [command fullfile(datapath,recordings{i},[recordings{i},'.dat']),'+'];
end
command = [command fullfile(datapath,recordings{end},[recordings{end},'.dat']),' ', fullfile(recording_dir_out,[recordings{1},'_concat.dat'])];
status = system(command);


fname_concat2 = fullfile(recording_dir_out, 'analogin.dat');
h2 = fopen(fname_concat2,'W');
disp('Concatenating digital channels...')
for i = 1:length(recordings)
    disp(['Loading digital channels from ' recordings{i}])
    m = memmapfile(fullfile(datapath, recordings{i}, 'analogin.dat'),'Format','uint16','writable',false);
    fwrite(h2,m.Data,'uint16');
end
fclose(h2);
disp('Finished concatenating digital channels')

fname_concat3 = fullfile(recording_dir_out, 'digitalin.dat');
h3 = fopen(fname_concat3,'W');
disp('Concatenating digital channels...')
for i = 1:length(recordings)
    disp(['Loading digital channels from ' recordings{i}])
    m = memmapfile(fullfile(datapath, recordings{i}, 'digitalin.dat'),'Format','uint16','writable',false);
    fwrite(h3,m.Data,'uint16');
end
fclose(h3);
disp('Finished concatenating digital channels')

fname_concat4 = fullfile(recording_dir_out, 'auxiliary.dat');
h4 = fopen(fname_concat4,'W');
disp('Concatenating aux channels...')
for i = 1:length(recordings)
    disp(['Loading aux channels from ' recordings{i}])
    m = memmapfile(fullfile(datapath, recordings{i}, 'auxiliary.dat'),'Format','uint16','writable',false);
    fwrite(h4,m.Data,'uint16');
end
fclose(h4);

fname_concat5 = fullfile(recording_dir_out, 'time.dat');
h5 = fopen(fname_concat5,'W');
disp('Concatenating time files...')
for i = 1:length(recordings)
    disp(['Loading time file from ' recordings{i}])
    m = memmapfile(fullfile(datapath, recordings{i}, 'time.dat'),'Format','int32','writable',false);
    fwrite(h5,m.Data,'int32');
end
fclose(h5);
disp('Finished concatenating aux channels')

% Creating meta file with fileName and nSamples
% Intan_rec_info = read_Intan_RHD2000_file_Peter(fullfile(recording_dir_path));
% fname = [recording.name '.dat'];
% nChannels = size(Intan_rec_info.amplifier_channels,2);
% 
% concat.fileName = recordings;
% concat.nSamples = recordings;
% concat.sr = recordings;

fprintf('\nConcatenated files successfully!\n');
