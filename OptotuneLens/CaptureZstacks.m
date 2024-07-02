%% This is a Matlab scipt for Z-stack image acquisition using Optotune tunable lens EL-16-40-TC and Lemunera camera Lt425.
% 2020/4/14 copy right by Jun Liao (ginoliao@tencent.com)
% To conotrol the tunable lensEL-16-40-TC, I made a few modification on the
% basis of R. Spesyvtsev's code: (http://www.st-andrews.ac.uk/~photon/manipulation/)
%%
% Initialize com port for the tunable lens
lens = Optotune('COM9');
lens = lens.Open();
lens = lens.getCurrent();
%% here is how to change the focus power of the tunable lens, -293mA to +293mA is acceptable for EL-16-40-TC
currentValue=0;
lens.setCurrent(currentValue)
%% section to turn off lens, run when finished image acquisition
lens = Close(lens)
%% section to turn off camera, run when finished image acquisition
delete(vid)
clear vid
%% Initialize camera
vid = videoinput('winvideo', 1, 'GBRG8_2048x2048');
src = getselectedsource(vid);
vid.FramesPerTrigger = 1;
src.ExposureMode = 'manual';src.Exposure = -9;
src.FrameRate = '90.1770';
src.GainMode = 'manual';src.Gain = 0;
triggerconfig(vid, 'manual');
vid.TriggerRepeat = Inf;start(vid);
% preview(vid);
preview(vid,image( zeros(2048, 2048, 3) ));camroll(-270);
%% initial
sampleNum=88; % change sample num when change slides         
LocNum=12;       % change change location num for each new image view            
%% Capture Z-stack Images under 10X objective lens
close all;clc

InitialPos=120;  %from 120mA : -10mA: -120mA, 0mA is the focus Plane( need optical adjustment)
lens.setCurrent(InitialPos);pause(0.05);
imTempColor=zeros(2048,2048,3,'uint8');
imtemp=zeros(1024,1024,'uint8');
Brenner=zeros(1,25); % use Brenner Gradient to double check the focal plane.
varnameSame = genvarname(['TCT' num2str(sampleNum) '_loc' num2str(LocNum)]);
mkdir(varnameSame);% generate new directory
for i=1:25       % capture 25 images for each Z-stack
    getsnapshot(vid); pause(0.01);
    imTempColor=getsnapshot(vid);pause(0.05);                 % capture image
    lens.setCurrent(InitialPos-i*10);     %change focal position
    imwrite(imTempColor,[varnameSame '/TCT' num2str(sampleNum) '_loc' num2str(LocNum) 'num' num2str(i) '.png']);  
    imtemp=rgb2gray(imTempColor(513:end-512,513:end-512,:));   % use gray image to calc Brenner
    Brenner(i)=Fbrenner(imtemp); 
    pause(0.03); 
end
save([varnameSame '/Brenner_TCT' num2str(sampleNum) '_loc' num2str(LocNum)  '.mat'],'Brenner');
LocNum=LocNum+1;
figure;plot(Brenner);
hold on;plot(Brenner,'r*');
lens.setCurrent(0)