classdef ThorPolCam < handle
    % CS505MUP1 Polarization Monochrome Camera
    % This can serve as a template for other thorlabs cameras using the
    % .NET interface

    properties (Constant, Hidden)
                PATH = 'C:\Users\sreekar\Documents\MATLAB\acquisition_utils\camera\thorcam';
    end

    properties (Hidden)
        tlCameraSDK
        polarizationProcessorSDK
    end

    properties
        tlCamera
        polarizationProcessor
        polarPhase
        maxPixelValue
        defaultprocess = 'intensity';
    end

    methods
        function h = ThorPolCam(exposureTime)
            h.loaddlls();

            currdir = pwd;
            cd(ThorPolCam.PATH); % needed it to be in the directory of the dll for just this command to work
            h.tlCameraSDK = Thorlabs.TSI.TLCamera.TLCameraSDK.OpenTLCameraSDK;
            cd(currdir);

            serialNumbers = h.tlCameraSDK.DiscoverAvailableCameras;
            disp([num2str(serialNumbers.Count), ' camera was discovered.']);


            if (serialNumbers.Count > 0)
                % Open the first TLCamera using the serial number.
                disp('Opening the first camera')
                h.tlCamera = h.tlCameraSDK.OpenCamera(serialNumbers.Item(0), false);
                h.polarPhase = h.tlCamera.PolarPhase;

                % Check if the camera is Polarization camera.
                cameraSensorType = h.tlCamera.CameraSensorType;
                if(cameraSensorType ~= Thorlabs.TSI.TLCameraInterfaces.CameraSensorType.MonochromePolarized)
                    error('First camera is not a monochrome polarization camera');
                end
            else
                error('No Thorlabs cameras found');
            end

            h.polarizationProcessorSDK = Thorlabs.TSI.PolarizationProcessor.PolarizationProcessorSDK;
            h.polarizationProcessor = h.polarizationProcessorSDK.CreatePolarizationProcessor;

             % Set exposure time and gain of the camera.
             h.setExposure(exposureTime)

            % Check if the camera supports setting "Gain"
            gainRange = h.tlCamera.GainRange;
            if (gainRange.Maximum > 0)
            h.tlCamera.Gain = 0;
            end

            h.tlCamera.MaximumNumberOfFramesToQueue = 1; % get only the most recent frame
            disp('Max Number of frames in queue set to 1. Only latest frame will be held and returned (dropping others if any)');

            h.start();
            warning('Always use delete() to close camera object to properly cleanup');
        end

        function setExposure(h, exposureTime)
            rearm = false;
            if(h.tlCamera.IsArmed)
                rearm = true;
                h.stop;
            end
            h.tlCamera.ExposureTime_us = exposureTime;
            if(rearm)
                h.start;
            end
        end

        function setROI(h, roi)
            % ROI specified as [originx originy width, height]
            rearm = false;
            if(h.tlCamera.IsArmed)
                rearm = true;
                h.stop;
            end
            disp('Setting ROI');
            h.tlCamera.ROIAndBin.ROIOriginX_pixels = roi(1);
            h.tlCamera.ROIAndBin.ROIOriginY_pixels = roi(2);
            h.tlCamera.ROIAndBin.ROIWidth_pixels = roi(3);
            h.tlCamera.ROIAndBin.ROIHeight_pixels = roi(4);
            if(rearm)
                h.start;
            end
        end

        function roi = ROIPosition(h)
            % mirroring the function header for videoinput objects
            roi = [h.tlCamera.ROIAndBin.ROIOriginX_pixels,...
                h.tlCamera.ROIAndBin.ROIOriginY_pixels,...
                h.tlCamera.ROIAndBin.ROIWidth_pixels,...
                h.tlCamera.ROIAndBin.ROIHeight_pixels];
        end

        function resetROI(h)
                h.setROI([h.tlCamera.ROIOriginXRange.Minimum, ...
                h.tlCamera.ROIOriginYRange.Minimum, ...
                h.tlCamera.SensorWidth_pixels, ...
                h.tlCamera.SensorHeight_pixels]);
        end

        function start(h)
            % Start continuous image acquisition
            disp('Starting continuous image acquisition.');
            h.tlCamera.OperationMode = Thorlabs.TSI.TLCameraInterfaces.OperationMode.SoftwareTriggered;
            h.tlCamera.FramesPerTrigger_zeroForUnlimited = 0;
            h.tlCamera.Arm;
            h.tlCamera.IssueSoftwareTrigger;
            
            h.maxPixelValue = double(2^h.tlCamera.BitDepth - 1);
        end

        function avlbl = frames_available(h)
            avlbl = (h.tlCamera.NumberOfQueuedFrames > 0);
        end

        function exposureTime = getExposureTime(hobj)
            exposureTime = hobj.tlCamera.ExposureTime_us;
        end

        function [outImage,image2DRaw] = getsnapshot(hobj, varargin)
            exptimeSec = hobj.tlCamera.ExposureTime_us * 1e-6;
            pause(exptimeSec * 1.1); % wait for capture time

            if(nargin>1)
                process = char(varargin{1});
            else
                process = hobj.defaultprocess;
            end

            if(~hobj.frames_available)
                waittime = 5 * hobj.tlCamera.ExposureTime_us * 1e-6;
                waittime = max(waittime,1);
                 warning('No frame available. waiting for 5x exposuretime : %g s', waittime)
                 pause(waittime);
            end

            if(hobj.frames_available)
                 imageFrame = hobj.tlCamera.GetPendingFrameOrNull;
%                   frameCount = frameCount + 1;
                % For color images, the image data is in BGR format.
                if(numel(imageFrame)==0)
                    disp('Null Frame')
                    outImage = nan;
                    image2DRaw = nan;
                    return
                end
                try

                    imageData = imageFrame.ImageData.ImageData_monoOrBGR;
                catch
%                     disp('imageFrame')
                    disp(class(imageFrame));
%                     error('Something wrong with this statement (dot indexing not supported error')
                end
                
%                 disp(['Image frame number: ' num2str(imageFrame.FrameNumber)]);
                
                % custom image processinrg code goes here
                imageHeight = imageFrame.ImageData.Height_pixels;
                imageWidth = imageFrame.ImageData.Width_pixels;
                bitDepth = imageFrame.ImageData.BitDepth;
                maxOutput = uint16(2^bitDepth - 1);
                    
                % Allocate memory for processed Intensity image output.
                outputData = NET.createArray('System.UInt16',imageHeight * imageWidth);

                % return raw data as well if requested
                if(strcmpi(process(1:3),'qua') || strcmpi(process,'raw')|| nargout > 1)
                    image2DRaw = reshape(uint16(imageData), [imageWidth, imageHeight])';
                end

                if(strcmpi(process,'raw'))
                    outImage = image2DRaw;
                elseif(strcmpi(process, 'intensity'))
                    % Calculate the Intensity image.
                    hobj.polarizationProcessor.TransformToIntensity(hobj.polarPhase, imageData, int32(0), int32(0), imageWidth, imageHeight, ...
                        bitDepth, maxOutput, outputData);
                    % Reshape to 2D
                    outImage = reshape(uint16(outputData), [imageWidth, imageHeight])';
                    
                elseif(strcmpi(process, 'DoLP'))
                    % Calculate degree of linear polarization (DoLP)
                    hobj.polarizationProcessor.TransformToDoLP(hobj.polarPhase, imageData, int32(0), int32(0), imageWidth, imageHeight, ...
                                            bitDepth, maxOutput, outputData);
                    imageDoLPData = double(outputData) / double(maxOutput) * 100;
                    
                    % Display the DoLP image
                    outImage = reshape(imageDoLPData, [imageWidth, imageHeight])';
                    
                elseif(strcmpi(process,'azimuth'))
                    hobj.polarizationProcessor.TransformToAzimuth(hobj.polarPhase, imageData, int32(0), int32(0), imageWidth, imageHeight, ...
                    bitDepth, maxOutput, outputData);
                                        
                    % Convert the angle data to degrees (-90 to 90 degrees)
                    imageAngleData = double(outputData) / double(maxOutput) * 180 - 90;
                    % Display the Azimuth image
                    outImage = reshape(imageAngleData, [imageWidth, imageHeight])';

                elseif(strcmpi(process(1:3),'qua'))
                    if(strcmpi(process,'quad0'))
                        outImage =  image2DRaw(1:2:end,1:2:end);
                    elseif(strcmpi(process,'quad1'))
                        outImage =  image2DRaw(2:2:end,1:2:end);
                    elseif(strcmpi(process,'quad2'))                        
                        outImage =   image2DRaw(1:2:end,2:2:end);
                    elseif(strcmpi(process,'quad3'))                        
                        outImage =   image2DRaw(2:2:end,2:2:end);
                    else                    
                        outImage = zeros([imageHeight/2 imageWidth/2 4],'uint16');
                        outImage(:,:,1) = image2DRaw(1:2:end,1:2:end);
                        outImage(:,:,2) = image2DRaw(2:2:end,1:2:end);
                        outImage(:,:,3) = image2DRaw(1:2:end,2:2:end);
                        outImage(:,:,4) = image2DRaw(2:2:end,2:2:end);
                    end
                else
                    error('Unknown process "%s" specified', process)
                end
                
                % Release the image frame
                delete(imageFrame);
            else
                warning('No frame available even after waiting for 5x exposure.');
                outImage = nan;                    
                image2DRaw = nan;
                return
             end

        end

        function stop(h)
             % Stop continuous image acquisition
            disp('Stopping continuous image acquisition.');
            h.tlCamera.Disarm;
        end

        function delete(h) 
           h.stop(); % Stop im acq
            
            % Release the TLCamera
            disp('Releasing the camera, processors and SDK');
            h.tlCamera.Dispose;
            delete(h.tlCamera);
            h.polarizationProcessor.Dispose;
            delete(h.polarizationProcessor);
            h.polarizationProcessorSDK.Dispose;
            delete(h.polarizationProcessorSDK);
            h.tlCameraSDK.Dispose;
            delete(h.tlCameraSDK);
        end
    end

     methods (Static)
        function loaddlls()
            if(~exist('Thorlabs.TSI.TLCamera.TLCameraSDK','class'))
                NET.addAssembly([ThorPolCam.PATH, '\Thorlabs.TSI.TLCamera.dll']);
                disp('Dot NET assembly for TL cameras loaded.');
            end
            if(~exist('Thorlabs.TSI.PolarizationProcessor.PolarizationProcessorSDK','class'))
                NET.addAssembly([ThorPolCam.PATH, '\Thorlabs.TSI.PolarizationProcessor.dll']);
                disp('Dot NET assembly for pol processing loaded')
            end
        end

     end

end