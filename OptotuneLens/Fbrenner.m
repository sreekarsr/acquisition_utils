% function to calculate the Brenner Gradient of an input image
% 2020/4/14 copyright by Jun Liao (ginoliao@tencent.com)
function [ output ] = Fbrenner( im )
% Brenner
yBrenner=int16((im(:,3:end) - im(:,1:end-2)));
 output=sum(sum(yBrenner.^2))./10000000;
end

