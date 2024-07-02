classdef AptPZMotor < handle
    properties (Constant)
        MOTOR_PROGID = 'APTPZMOTOR.APTPZMotorCtrl.1', % Note: this is what works for new KIM101 piezo controllers. See the APT Server help file for details.
        CHAN1_ID = 0,
    end
     
    properties (SetAccess = public)
        fig,
        ctrl
    end
     
    methods
        function obj = AptPZMotor(hwSerial)
            
            fpos    = get(0,'DefaultFigurePosition'); % figure default position 
            fpos(3) = 650; % figure window size;Width 
            fpos(4) = 450; % Height 
            
            obj.fig =figure('Position', fpos,... 
           'Menu','None',... 
           'Name','APT GUI');  

            % Create the active x control for the MOTOR control
            obj.ctrl = actxcontrol(AptPZMotor.MOTOR_PROGID,...
                                [20 20 600 400], obj.fig);
            % Sets the hardware serial number
            obj.ctrl.StartCtrl; 

            obj.ctrl.HWSerialNum = hwSerial;
            obj.ctrl.EnableHWChannel(AptPZMotor.CHAN1_ID);
            drawnow();

        end
        
        function [] = goto(obj, loc)
            % Move to an absolute lcoation 
            %TODO: add safety constraint to make sure it does not go beyond
            %the edge? Or does not move too far relative to zero?
                  obj.ctrl.MoveAbsoluteStepsEx(AptPZMotor.CHAN1_ID,loc,true);
        end

        function [] = translate(obj, steps)
            % Move a certain number of steps (specify direction with sign)
            % relative to current position
            obj.ctrl.MoveRelativeStepsEx(AptPZMotor.CHAN1_ID,...
                                   steps, true);
        end

        function [] = setzero(obj)
            % Sets the current position as zero
            obj.ctrl.SetPositionSteps(AptPZMotor.CHAN1_ID,0)
        end
 
        function pos = getpos(obj)
          pos = obj.ctrl.GetPositionSteps_Steps(AptPZMotor.CHAN1_ID);
        end
        
        function [] = delete(obj)
            obj.ctrl.StopCtrl();
            obj.ctrl.delete();
            close(obj.fig);
        end
    end
end