classdef AptMotorPiezo < handle
    properties (Constant)
        MOTOR_PROGID = 'MGPIEZO.MGPiezoCtrl.1', % Note: this works with KPZ101, but not newer 4-channel KIM101 motor controllers
        CHAN1_ID = 0,
        CONVERSION = 3; % Volt / um
    end
     
    properties (SetAccess = public)
        fig,
        ctrl
    end
     
    methods
        function obj = AptMotorPiezo(hwSerial)
            
            obj.fig = figure();
 
            % Create the active x control for the MOTOR control
            obj.ctrl = actxcontrol(AptMotorPiezo.MOTOR_PROGID,...
                                [20 20 600 400], obj.fig);
 
            % Sets the hardware serial number
            obj.ctrl.HWSerialNum = hwSerial;
            obj.ctrl.StartCtrl(); 
            obj.ctrl.EnableHWChannel(AptMotorPiezo.CHAN1_ID);
            drawnow();

        end
        
        function [] = goto(obj, locationInUm)
            if locationInUm > 25 || locationInUm < 0
                error('locationInUm should be between 0 and 25');
            else
                obj.ctrl.SetVoltOutput(AptMotorPiezo.CHAN1_ID,...
                                       locationInUm*obj.CONVERSION);
            end
        end
%          
%         function [] = gotoenc(obj, locationInMm)
%             obj.ctrl.MoveAbsoluteEnc(AptMotorPiezo.CHAN1_ID,...
%                                     locationInMm, 0, 1000, true);
%         end
%          
%         function [] = translateenc(obj, distanceInMm)
%             obj.ctrl.MoveRelativeEnc(AptMotorPiezo.CHAN1_ID,...
%                                     distanceInMm, 0, 1000, true);
%         end
%  
%         function [] = translate(obj, distanceInMm)
%             obj.ctrl.MoveRelativeEx(AptMotorPiezo.CHAN1_ID,...
%                                     distanceInMm, 0, true);
%         end
%  
%         function pos = getpos(obj)
% %           pos = obj.ctrl.GetAbsMovePos_AbsPos(AptMotorPiezo.CHAN1_ID);
%             pos = obj.ctrl.GetPosition_Position(AptMotorPiezo.CHAN1_ID);
%         end
%          
%         function [] = setvelparams(obj, maxAcc, maxVel)
%             obj.ctrl.SetVelParams(AptMotorPiezo.CHAN1_ID,...
%                                     0, maxAcc, maxVel);
%             obj.maxAcc = maxAcc;
%             obj.maxVel = maxVel;
%         end
%  
%         function [] = delete(obj)
%             obj.ctrl.StopCtrl();
%             obj.ctrl.delete();
%             close(obj.fig);
%         end
    end
end