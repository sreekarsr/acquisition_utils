classdef PGM1SE < handle
    % Piezo Gimbal PGM1S controlled with PPC102 controller
    properties (Constant, Hidden)
        PATHDEFAULT='C:\Program Files\Thorlabs\Kinesis\'
        DEVICEMANAGERCLASSNAME='Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI'
        DEVICEMANAGERDLL='Thorlabs.MotionControl.DeviceManagerCLI.dll';

        BTPIEZODLL = 'Thorlabs.MotionControl.Benchtop.PiezoCLI.dll';
        GENERICPIEZODLL = 'Thorlabs.MotionControl.GenericPiezoCLI.dll';

        PRECPZCLIDLL = 'Thorlabs.MotionControl.Benchtop.PrecisionPiezoCLI.dll'
%         PRECPZDLL = 'Thorlabs.MotionControl.Benchtop.PrecisionPiezo.dll'


        TIMEOUT=100000;    % Default timeout time for settings chang
        POLLINGINT = 25; %polling ms for status to be updated(ms)
    end

    properties
        isconnected = false;
    end
    
    properties
        serialNo;
        deviceNET;
        CH1;
        CH2;
        deviceInfoNET;
        deviceName;
        rot_CH_def;
%         DEG2STEPFACTOR = 40000; % step size for 1 degree
    end

    methods
        function h = PGM1SE(serialNo)
            h.serialNo = serialNo;
            PGM1SE.loaddlls;
            disp('Currently available devices:')
            disp(h.listdevices());    % Use this call to build a device list in case not invoked beforehand
        end

        function connect(h)  % Connect device
            if ~h.isconnected
                switch(h.serialNo(1:2))
                    case '95' % PPC102
%                         h.deviceNET=Thorlabs.MotionControl.Benchtop.PiezoCLI.PDXC2.InertiaStageController.CreateDevice(h.serialNo);
%                          h.deviceNET=Thorlabs.MotionControl.Benchtop.PiezoCLI.PDXC2.InertiaStageController.CreateDevice(h.serialNo);
                         h.deviceNET=Thorlabs.MotionControl.Benchtop.PrecisionPiezoCLI.BenchtopPrecisionPiezo.CreateBenchtopPiezo(h.serialNo);
                    otherwise
                        error('Stage not recognised');
                end
                h.deviceNET.Connect(h.serialNo);          % Connect to device via .NET interface
                h.deviceInfoNET=h.deviceNET.GetDeviceInfo();                    % Get deviceInfo via .NET interface
                h.deviceName = h.deviceNET.GetDeviceName();disp(h.deviceName);

                h.CH1 = h.deviceNET.GetChannel(1);
                h.CH2 = h.deviceNET.GetChannel(2);

                h.CH1.EnableDevice();
                h.CH2.EnableDevice();

                h.rot_CH_def = 1; % default rotation axis is CH1

                if ~h.CH1.IsSettingsInitialized() % 
                    h.CH1.WaitForSettingsInitialized(h.TIMEOUT);
                end
                if ~h.CH2.IsSettingsInitialized() %
                    h.CH2.WaitForSettingsInitialized(h.TIMEOUT);
                end

                if ~h.CH1.IsSettingsInitialized() % Cannot initialise device
                    error(['Unable to initialize settings for CH1 ',char(h.serialNo)]);
                elseif ~h.CH2.IsSettingsInitialized() % Cannot initialise device
                    error(['Unable to initialize settings for CH2 ',char(h.serialNo)]);
                else
                    disp('Settings for both channels initialized.')
                end
               
                h.isconnected = true;
            else % Device is already connected
                error('Device is already connected.')
            end

            % Start closed loop operation
            h.EnableClosedLoop()

            % Initiate polling to update status
            h.CH1.StartPolling(h.POLLINGINT)
            h.CH2.StartPolling(h.POLLINGINT)

            disp('Started Polling')

%             h.setjogstep(1);
        end

%         function setjogstep(h,anglestep)
%             % angle step is a float in degrees
%             params = h.deviceNET.GetJogParameters();
%             params.ClosedLoopStepSize = anglestep * h.DEG2STEPFACTOR;
%             h.deviceNET.SetJogParameters(params);
%             disp('Actual set step size:')
%             newparams = h.deviceNET.GetJogParameters();
%             disp(double(newparams.ClosedLoopStepSize) / h.DEG2STEPFACTOR)
%         end

%         function scalejogstep(h, scale)
%             newjogstep = h.getjogstep() * scale;
%             h.setjogstep(newjogstep);
%         end

%         function anglestep = getjogstep(h)
%             params = h.deviceNET.GetJogParameters();
%             anglestep = double(params.ClosedLoopStepSize) / h.DEG2STEPFACTOR;
%         end

        function EnableClosedLoop(h)
                h.CH1.SetPositionControlMode(Thorlabs.MotionControl.GenericPiezoCLI.Piezo.PiezoControlModeTypes.CloseLoop)
                h.CH2.SetPositionControlMode(Thorlabs.MotionControl.GenericPiezoCLI.Piezo.PiezoControlModeTypes.CloseLoop)
                disp('Both channels in closed loop mode.')
        end
        function EnableOpenLoop(h)
                h.CH1.SetPositionControlMode(Thorlabs.MotionControl.GenericPiezoCLI.Piezo.PiezoControlModeTypes.OpenLoop) ;              
                h.CH2.SetPositionControlMode(Thorlabs.MotionControl.GenericPiezoCLI.Piezo.PiezoControlModeTypes.OpenLoop);
                disp('Both channels in open loop mode.')
        end

%         function home(h)
            % Needed for closed loop operation
%             if h.deviceNET.GetPositionControlMode() ~= Thorlabs.MotionControl.GenericPiezoCLI.Piezo.PiezoControlModeTypes.CloseLoop
%                 h.Ch1.Home(h.TIMEOUT);
%             else
%                 disp('Require closed loop operation for homing');
%             end
%         end

        function pos = getpos(h,varargin)
            if nargin>1
                chno=varargin{1};
            else
                chno=h.rot_CH_def;
            end

            if chno==1
                pos = System.Decimal.ToDouble(h.CH1.GetPosition());
            elseif chno==2
                pos = System.Decimal.ToDouble(h.CH2.GetPosition());
            else
                error('Unrecognized Channel Index');
            end
        end

        function setpos(h,pos,varargin)
            if nargin>2
                chno=varargin{1};
            else
                chno=h.rot_CH_def;
            end
            if chno==1
                h.CH1.SetPosition(pos)
            elseif chno==2
                h.CH2.SetPosition(pos)
            else
                error('Unrecognized Channel Index')
            end
        end

        function home(h)
            h.setpos(0,1);
            h.setpos(0,2);
        end

%         function currentpos = getpos(h)
%             % returns current angle in degrees
%             currentpos = double(h.deviceNET.GetCurrentPosition()) / h.DEG2STEPFACTOR;
%         end
% 
%         function jogforward(h)
%             h.deviceNET.Jog(Thorlabs.MotionControl.Benchtop.PiezoCLI.PDXC2.PDXC2TravelDirection.Forward,[]);
%         end
% 
%         function jogbackward(h)
%             h.deviceNET.Jog(Thorlabs.MotionControl.Benchtop.PiezoCLI.PDXC2.PDXC2TravelDirection.Reverse,[]);
%         end
        function status = ismoving(h)
            status = h.deviceNET.Status.IsMoving();
        end

        function stop(h)
            h.deviceNET.MoveStop();
        end

        function disconnect(h)
            h.deviceNET.Disconnect();
            h.isconnected = false;
        end

%         function settarget(h,angletarget)
%             % Set a closed loop target
%             % If not in closed loop, throw error?
%             target = int32(h.DEG2STEPFACTOR * angletarget);
%             disp('Set target as ')
%             disp(double(target) / h.DEG2STEPFACTOR)
%             h.deviceNET.SetClosedLoopTarget(target) % in nm for stage
%         end
%         function move(h)
%             % move to the set target (closed loop mode)
%             h.deviceNET.MoveStart();
%         end
% 
%         function move_complete(h,anglepos) % TODO: change this to angle conversion for rotation stage PDXR1
%             h.settarget(anglepos)
%             h.move();pause(10 * h.POLLINGINT * 0.001); % wait for status to be updated               
%             disp('Moving..');
%             while h.deviceNET.Status.IsMoving
%                 pause(h.POLLINGINT * 0.001);
%             end
%             disp('Done');
%         end

        function shutdown(h)
%             h.stop();
%             h.deviceNET.StopPolling();
            h.disconnect();
        end

    end

    methods (Static)
        function serialNumbers=listdevices()  % Read a list of serial number of connected devices
            PGM1SE.loaddlls; % Load DLLs
            Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.BuildDeviceList();  % Build device list
            serialNumbersNet = Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.GetDeviceList(Thorlabs.MotionControl.Benchtop.PrecisionPiezoCLI.BenchtopPrecisionPiezo.DevicePrefix95); % Get device list
            serialNumbers=cell(ToArray(serialNumbersNet)); % Convert serial numbers to cell array
        end

        function loaddlls() % Load DLLs
%             if ~exist(PGM1SE.DEVICEMANAGERCLASSNAME,'class')
%                 try   % Load in DLLs if not already loaded
                    NET.addAssembly([PGM1SE.PATHDEFAULT,PGM1SE.DEVICEMANAGERDLL]);
                    NET.addAssembly([PGM1SE.PATHDEFAULT,PGM1SE.GENERICPIEZODLL]);
                    NET.addAssembly([PGM1SE.PATHDEFAULT,PGM1SE.BTPIEZODLL]);
                    NET.addAssembly([PGM1SE.PATHDEFAULT,PGM1SE.PRECPZCLIDLL]);
%                     NET.addAssembly([PGM1SE.PATHDEFAULT,PGM1SE.PRECPZDLL]);
                    disp('Loaded DLLs');

%                 catch % DLLs did not load
%                     error('Unable to load .NET assemblies')
%                 end
%             end    
        end
    end

end