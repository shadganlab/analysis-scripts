% Written by Mahta Khoshnam

% Added by Ali Zaidi
% 14.03.2022

clc
clear
close all

[file,path] = uigetfile('*.tdf', '0001~ac~P01 March 8.tdf:');
filename = fullfile(path, file);
[startTime,frequency,emgMap,labels,emgData] = tdfReadDataEmg(filename);
time = (startTime+1: length(emgData))' * 1/frequency;

emgCalf = emgData(1,:)';
emgQuad = emgData(2,:)';

subplot(2,1,1)
plot(time, emgCalf)
ylabel('Calf')
xlim([0 time(end)])

subplot(2,1,2)
plot(time, emgQuad)
ylabel('Quad')
xlim([0 time(end)])
xlabel('Time (s)')