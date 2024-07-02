classdef PDX1 < handle
    % Benchtop Piezo controllers (including PDXC2)
    properties (Constant, Hidden)
        PATHDEFAULT='C:\Program Files\Thorlabs\Kinesis\'
        DEVICEMANAGERCLASSNAME='Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI'
        DEVICEMANAGERDLL='Thorlabs.MotionControl.DeviceManagerCLI.dll';
        BTPIEZODLL = 'Thorlabs.MotionControl.Benchtop.PiezoCLI.dll';
        GENERICPIEZODLL = 'Thorlabs.MotionControl.GenericPiezoCLI.dll';
        TIMEOUT=100000;    % Default timeout time for settings chang
        POLLINGINT = 25; %polling ms for status to be updated(ms)
    end

    properties
        isconnected = false;
    end
    
    properties
        serialNo;
        deviceNET;
%         currentDeviceSettingsNET;
        deviceInfoNET;
        deviceName;
        DEG2STEPFACTOR = 40000; % step size for 1 degree
    end

    methods
        function h = PDX1(serialNo)
            h.serialNo = serialNo;
            PDX1.loaddlls;
            disp('Currently available devices:')
            disp(h.listdevices());    % Use this call to build a device list in case not invoked beforehand
        end

        function connect(h)  % Connect device
            if ~h.isconnected
                switch(h.serialNo(1:3))
                    case '112' % PDXC2
                        h.deviceNET=Thorlabs.MotionControl.Benchtop.PiezoCLI.PDXC2.InertiaStageController.CreateDevice(h.serialNo);
                    otherwise
                        error('Stage not recognised');
                end
                h.deviceNET.Connect(h.serialNo);          % Connect to device via .NET interface
                h.deviceInfoNET=h.deviceNET.GetDeviceInfo();                    % Get deviceInfo via .NET interface
                h.deviceName = h.deviceNET.GetDeviceName();disp(h.deviceName);
                h.deviceNET.EnableDevice();
                try
                    if ~h.deviceNET.IsSettingsInitialized() % Wait for IsSettingsInitialized via .NET interface
                        h.deviceNET.WaitForSettingsInitialized(h.TIMEOUT);
                    end
                    if ~h.deviceNET.IsSettingsInitialized() % Cannot initialise device
                        error(['Unable to initialize device ',char(h.serialNo)]);
                    else
                        disp('Settings Initialized.')
                    end
                catch % Cannot initialise device
                    error(['Unable to initialise device ',char(h.serialNo)]);
                end
                h.isconnected = true;
            else % Device is already connected
                error('Device is already connected.')
            end

            % Start closed loop operation
            h.EnableClosedLoop(true);

            % Initiate polling to update status
            h.deviceNET.StartPolling(h.POLLINGINT)
            disp('Started Polling')

            %% TODO : set jog step size and initialize setting correctly (for joystick to work correctly, and maybe do steps using jogs instead)
            h.setjogstep(1);
        end

        function setjogstep(h,stepnm)
            % nm step is an int
            params = h.deviceNET.GetJogParameters();
            params.ClosedLoopStepSize = stepnm;
            h.deviceNET.SetJogParameters(params);
            fprintf('Set step size:');
            newparams = h.deviceNET.GetJogParameters();
            fprintf(' %g nm \n',newparams.ClosedLoopStepSize);
        end

        function scalejogstep(h, scale)
            newjogstep = h.getjogstep() * scale;
            h.setjogstep(newjogstep);
        end

        function stepnm = getjogstep(h)
            params = h.deviceNET.GetJogParameters();
            stepnm = (params.ClosedLoopStepSize);
        end

        function EnableClosedLoop(h,enable)
            if enable
                h.deviceNET.SetPositionControlMode(Thorlabs.MotionControl.GenericPiezoCLI.Piezo.PiezoControlModeTypes.CloseLoop)
                disp('Device now in ClosedLoop mode.')
            else
                h.deviceNET.SetPositionControlMode(Thorlabs.MotionControl.GenericPiezoCLI.Piezo.PiezoControlModeTypes.OpenLoop)
                disp('Device now in OpenLoop mode.')
            end
        end

        function home(h)
            % Needed for closed loop operation
%             if h.deviceNET.GetPositionControlMode() ~= Thorlabs.MotionControl.GenericPiezoCLI.Piezo.PiezoControlModeTypes.CloseLoop
                h.deviceNET.Home(h.TIMEOUT);
%             else
%                 disp('Require closed loop operation for homing');
%             end
        end

        function currentpos = getpos(h)
            % returns current position in nm
            currentpos = (h.deviceNET.GetCurrentPosition());
        end

        function jogforward(h)
            h.deviceNET.Jog(Thorlabs.MotionControl.Benchtop.PiezoCLI.PDXC2.PDXC2TravelDirection.Forward,[]);
        end

        function jogbackward(h)
            h.deviceNET.Jog(Thorlabs.MotionControl.Benchtop.PiezoCLI.PDXC2.PDXC2TravelDirection.Reverse,[]);
        end
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

        function settarget(h,postarget)
            % Set a closed loop target
            % If not in closed loop, throw error?
            target = int32(postarget);
            disp('Set target as ')
            disp(target);
            h.deviceNET.SetClosedLoopTarget(target) % in nm for stage
        end
        function move(h)
            % move to the set target (closed loop mode)
            h.deviceNET.MoveStart();
        end

        function move_complete(h,pos)
            h.settarget(pos)
            h.move();pause(10 * h.POLLINGINT * 0.001); % wait for status to be updated               
            disp('Moving..');
            while h.deviceNET.Status.IsMoving
                pause(h.POLLINGINT * 0.001);
            end
            disp('Done');
        end

        function shutdown(h)
            h.stop();
            h.deviceNET.StopPolling();
            h.disconnect();
        end

    end

    methods (Static)
        function serialNumbers=listdevices()  % Read a list of serial number of connected devices
            PDX1.loaddlls; % Load DLLs
            Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.BuildDeviceList();  % Build device list
            serialNumbersNet = Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.GetDeviceList(); % Get device list
            serialNumbers=cell(ToArray(serialNumbersNet)); % Convert serial numbers to cell array
        end

        function loaddlls() % Load DLLs
            if ~exist(PDX1.DEVICEMANAGERCLASSNAME,'class')
                try   % Load in DLLs if not already loaded
                    NET.addAssembly([PDX1.PATHDEFAULT,PDX1.DEVICEMANAGERDLL]);
                    NET.addAssembly([PDX1.PATHDEFAULT,PDX1.GENERICPIEZODLL]);
                    NET.addAssembly([PDX1.PATHDEFAULT,PDX1.BTPIEZODLL]);
                catch % DLLs did not load
                    error('Unable to load .NET assemblies')
                end
            end    
        end
    end

end