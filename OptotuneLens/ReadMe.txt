%% This is a Matlab script for Z-stack image acquisition using Optotune tunable lens EL-16-40-TC and Lemunera camera Lt425.
% 2020/4/14 copy right by Jun Liao (ginoliao@tencent.com)
% To conotrol the tunable lensEL-16-40-TC, I made a few modification on the
% basis of R. Spesyvtsev's code: (http://www.st-andrews.ac.uk/~photon/manipulation/)

1. CaptureZstacks.m: code for capturing Z-stack images using Optotune tunable lens EL-16-40-TC and Lemunera camera Lt425.

2. Fbrenner.m : code for calculating the Brenner gradient of an input image.

3.  A matlab class with examples for controlling the electro-tunable lens from the Optotune company (http://www.optotune.com/). The program is written by Roman Spesyvtsev from Optical manipulation group (http://www.st-andrews.ac.uk/~photon/manipulation/).
  Optotune.m - main control class,
  
  append_crc.m  - calculates and appends checksum.

  lens driver V4...excel - consists the command library. 

  Optotune lens driver 4 manual.pdf
( I made some modification on Roman Spesyvtsev's code to successfully control EL-16-40-TC from -293mA to +293mA.)