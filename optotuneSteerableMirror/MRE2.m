classdef MRE2 < handle
    % MRE2 Optotune Fast Steerable Mirror controller
    properties (Constant, Hidden)
		PATHDEFAULT='C:\Users\sreekar\Documents\MATLAB\acquisition_utils\optotuneSteerableMirror\MR-E-2_C#SDK_2.1.2\C#\lib\net45\';
        OPTOPRODUCTMODULEAPIDLL = 'OptoProductModuleApi.dll';
		GENERALMODULEDLL='GeneralModuleCore.dll';
        MRE2MODULESDKDLL = 'MrE2ModuleSdk.dll';
        C = 1 / tand(50); % distance of a wall at which the mirror can -1 to 1
    end

    properties
        isconnected = false;
    end
    
    properties
		asm;
        portNo;
		device;
		xAxis;
		yAxis;
        deviceName;
        rotaxis_phi; % in degrees,  % Angle between rotation axis and y-axis (which to azimuth angle of reflected beam with x-axis)
        % Precomputed when rotaxis_phi is modified
        cosphi;
        sinphi;
    end

	methods
        function h = MRE2(portNo) % 
			if (nargin < 1)
				portNo = 3;
			end
            h.portNo = portNo;
            h.asm = MRE2.loaddlls;
            h.device = MrE2ModuleSdk.Device.MrE2ForMr15Dash30SdkComDeviceController;
			h.xAxis = h.asm.AssemblyHandle.GetType('MrE2ModuleSdk.Dto.EAxis').GetEnumValues().Get(0);
			h.yAxis = h.asm.AssemblyHandle.GetType('MrE2ModuleSdk.Dto.EAxis').GetEnumValues().Get(1);
        end

        function connect(h)  % Connect device
            disp('Connecting...')
            if ~h.isconnected
				h.device.Connect(h.portNo);
                h.isconnected = h.device.IsConnected();
				if (h.isconnected)
                    disp('Connected!')
                    h.enableClosedLoopAngle; % Enables closed loop operation
                    
                    h.rotaxis_phi = h.getAzimuthAngle();
                    h.cosphi = cosd(h.rotaxis_phi);
                    h.sinphi = sind(h.rotaxis_phi);
                else
                    error('Connection Failed.')
                end
            else % Device is already connected
                error('Device is already connected.')
            end
            
        end

        function enableClosedLoopAngle(h)
            ClosedLoopAngleEnum = h.asm.AssemblyHandle.GetType('MrE2ModuleSdk.Dto.EMrE2ControlModeSystems').GetEnumValues().Get(2);
            h.device.ChangeActiveSystem(ClosedLoopAngleEnum,h.xAxis)           
            h.device.ChangeActiveSystem(ClosedLoopAngleEnum,h.yAxis)
            disp('Closed Loop Control Enabled');

        end

        function enableOpenLoop(h)
            OpenLoopEnum = h.asm.AssemblyHandle.GetType('MrE2ModuleSdk.Dto.EMrE2ControlModeSystems').GetEnumValues().Get(0);
            h.device.ChangeActiveSystem(OpenLoopEnum,h.xAxis)
            h.device.ChangeActiveSystem(OpenLoopEnum,h.yAxis)
            disp('Open Loop Control Enabled');
        end

       

		function setXPos(h,val)
            % val is a float in [-1 1], works in closed loop
			if ((val < -1) || (val > 1))
				warning('XY values must be between -1 and 1. Will be clipped.');
			end
			h.device.WriteAngle(h.xAxis, val);
        end

        function setYPos(h,val)
            % val is a float in [-1 1]
			if ((val < -1) || (val > 1))
				warning('XY values must be between -1 and 1. Will be clipped');
			end
			h.device.WriteAngle(h.yAxis, val);
        end

        % Open loop control
        function current = getCurrentX(h)
           current = h.device.ReadCurrent(h.xAxis);
        end
        
        function current = getCurrentY(h)
           current = h.device.ReadCurrent(h.yAxis);
        end

        function setCurrentX(h,current)
            % Current is float in [-0.7,0.7], works in open loop
            if ((current < -0.7) || (current > 0.7))
				error('Current values must be between -0.7 and 0.7');
			end
			h.device.WriteCurrent(h.xAxis, current);
        end

        function setCurrentY(h,current)
            if ((current < -0.7) || (current > 0.7))
				error('Current values must be between -0.7 and 0.7');
			end
			h.device.WriteCurrent(h.yAxis, current);
        end

        function stepCurrentX(h,step)
            h.setCurrentX(h.getCurrentX + step);
        end

        function stepCurrentY(h,step)
            h.setCurrentY(h.getCurrentY + step);
        end
       

		function home(h)
			h.setXPos(0);
			h.setYPos(0);

            h.setCurrentX(-0.0103);
            h.setCurrentY(0.0065);
        end
        
        function pos = getXPos(h)
            pos = h.device.ReadAngle(h.xAxis);
		end

        function pos = getYPos(h)
            pos = h.device.ReadAngle(h.yAxis);
        end

        %% Spherical Coordinate Scanning Control
        function setScanRotationAxis(h,axisAngle) % Fixes Azimuth angle / Rotation axis for scan
            polarangle = h.getScanAngle();

            h.rotaxis_phi = axisAngle;
            h.cosphi = cosd(h.rotaxis_phi);
            h.sinphi = sind(h.rotaxis_phi);
            fprintf('Rotation Axis: %g degrees\n',h.rotaxis_phi);

            % Rotate current coordinates
            h.setScanAngle(polarangle); % Resets with new rotaxis_phi

        end

        function setScanAngle(h,angle)
           % Polar angle (Scanning angle) - with azimuth set by
           % setScanRotationAxis()
           % Note that 'angle' IS NOT the angle of the mirror (which is angle / 2), but the angle of the beam (or where we want to see in the scene)
           rho = MRE2.C * tand(angle);
           if abs(rho) > 1
               warning('Invalid angle beyond scan limits (< 50 deg). Will be clipped');
           end
           x =  h.cosphi * rho;
           y =  h.sinphi * rho;
           h.setXPos(x);
           h.setYPos(y);
           fprintf('Scan Angle: %g degrees\n',h.getScanAngle);
        end

        function polarangle = getScanAngle(h)
            anglesign = sign(h.getXPos * h.cosphi + h.getYPos * h.sinphi);
            polarangle = anglesign * acosd( MRE2.C  / sqrt(MRE2.C^2 + h.getXPos^2 + h.getYPos^2));
        end

        function azangle = getAzimuthAngle(h) % mainly to initialize
            azangle = atan2d(h.getYPos,h.getXPos);
        end

        function stepScanAngle(h,delta)
            h.setScanAngle(h.getScanAngle + delta);
        end

        function kbScanAngleSteer(h, anglestep)
             disp('Control mirror using the keys A (-) and D (+). Use m and n to increase or decrease angle step size.');
            while(1)
                ch = char(getkey);
                switch lower(ch)
                    case 'd'
                        h.stepScanAngle(anglestep);                  
                    case 'a'
                        h.stepScanAngle(-anglestep);                  
                    case 'm'
                        if anglestep *10 > 10
                            disp('cannot increase step size over 10 degrees')
                        else
                            anglestep = anglestep * 10;
                        end
                    case 'n'
                        anglestep = anglestep / 10;
                    otherwise
                        break
                end
            end
        end

        function rotateAxis(h,rotationangle)
            h.setScanRotationAxis(h.rotaxis_phi + rotationangle)
        end

        function kbRotateAxis(h,anglestep)
             disp('Control mirror rotation axis using the keys J (-) and K (+). Use m and n to increase or decrease angle step size.');
            while(1)
                ch = char(getkey);
                switch lower(ch)
                    case 'k'
                        h.rotateAxis(+anglestep);             
                    case 'j'
                        h.rotateAxis(-anglestep);               
                    case 'm'
                        if anglestep *10 > 10
                            warning('Cannot increase step size over 10 degrees')
                        else
                            anglestep = anglestep * 10;
                        end
                    case 'n'
                        anglestep = anglestep / 10;
                    otherwise
                        break
                end
            end
        end

        function kbXYsteer(h,step)
            % game-like steering of mirror using w,a,s,d
            disp('Control mirror using the keys w,a,s,d. Use m and n to increase or decrease step size.');
            while(1)
                ch = char(getkey);
                switch lower(ch)
                    case 'd'
                        h.setXPos(h.getXPos + step);
                    case 's'
                        h.setYPos(h.getYPos - step);
                    case 'a'
                        h.setXPos(h.getXPos - step);
                    case 'w'
                        h.setYPos(h.getYPos + step);
                    case 'm'
                        if step *10 > 0.1
                            disp('cannot increase step size over 0.1')
                        else
                            step = step * 10;
                            fprintf("new step size: %g",step);
                        end
                    case 'n'
                        step = step / 10;
                        fprintf("new step size: %g",step);
                    otherwise
                        break
                end
            end

        end

        function kbXsteer(h,step)
                  disp('Control mirror using the keys A (-X) and D (+X). Use m and n to increase or decrease step size.');
            while(1)
                ch = char(getkey);
                switch lower(ch)
                    case 'd'
                        h.setXPos(h.getXPos + step);
                    case 'a'
                        h.setXPos(h.getXPos - step);
                    case 'm'
                        if step *10 > 0.1
                            disp('cannot increase step size over 0.1')
                        else
                            step = step * 10;
                        end
                    case 'n'
                        step = step / 10;
                    otherwise
                        break
                end
            end
        end

        function kbSteerCurrent(h,currentstep)
            % game-like steering of mirror using w,a,s,d
            disp('Control mirror using the keys w,a,s,d. Use m and n to increase or decrease current step size.');
            while(1)
                ch = char(getkey);
                switch lower(ch)
                    case 'd'
                        h.stepCurrentX( + currentstep);
                    case 's'
                        h.stepCurrentY( - currentstep);
                    case 'a'
                        h.stepCurrentX( - currentstep);
                    case 'w'
                        h.stepCurrentY( + currentstep);
                    case 'm'
                        if currentstep *10 > 0.1
                            disp('cannot increase step size over 0.1')
                        else
                            currentstep = currentstep * 10;
                        end
                    case 'n'
                        currentstep = currentstep / 10;
                    otherwise
                        break
                end
            end

        end

       
        function disconnect(h)
            h.device.Disconnect();
            h.isconnected = false;
        end

        function shutdown(h)
            h.disconnect();
		end
	end

    methods (Static)
        function asm = loaddlls() % Load DLLs
%              if ~exist('MrE2ModuleSdk.Device.MrE2ForMr15Dash30SdkComDeviceController','class')
                try   % Load in DLLs if not already loaded
                    NET.addAssembly([MRE2.PATHDEFAULT,MRE2.OPTOPRODUCTMODULEAPIDLL]);
                    NET.addAssembly([MRE2.PATHDEFAULT,MRE2.GENERALMODULEDLL]);
                    asm = NET.addAssembly([MRE2.PATHDEFAULT,MRE2.MRE2MODULESDKDLL]);
                catch % DLLs did not load
                    error('Unable to load .NET assemblies')
                end
%             end    
         end
    end

end