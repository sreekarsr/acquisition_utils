classdef AptMotorTranslation < handle
	properties (Constant)
		MOTOR_PROGID = 'MGMOTOR.MGMotorCtrl.1',
		CHAN1_ID = 0,
	end
    
	properties (SetAccess = private)
		fig,
		ctrl,
		maxAcc,
		maxVel%
    end
    properties        
        frontlimit;
    end

    
	methods
		function obj = AptMotorTranslation(hwSerial, maxAcc, maxVel)
			if (nargin < 2),
				maxAcc = 40;	% APT default: 1;
			end;
			if (nargin < 3),
				maxVel =200;	% APT default: 2;
			end;
			obj.fig = figure();

			% Create the active x control for the MOTOR control
			obj.ctrl = actxcontrol(AptMotorTranslation.MOTOR_PROGID,...
								[20 20 600 400], obj.fig);

			% Sets the hardware serial number
           
            obj.ctrl.HWSerialNum = hwSerial;
%             pause(1);
            obj.ctrl.StartCtrl;
%             pause(1);
% 			drawnow();
% 			obj.ctrl.SetVelParams(AptMotorTranslation.CHAN1_ID,...
% 								0, maxAcc, maxVel);
            obj.setvelparams(maxAcc,maxVel);
            obj.ctrl.SetHomeParams(obj.CHAN1_ID,1,1,10,1);
			obj.maxAcc = maxAcc;
			obj.maxVel = maxVel;
            obj.ctrl.EnableHWChannel(obj.CHAN1_ID);

            obj.frontlimit = 205.0;

        end

        function enableHWChannel(obj)
            obj.ctrl.EnableHWChannel(obj.CHAN1_ID);
        end
        
        function disableHWChannel(obj)            
            obj.ctrl.DisableHWChannel(obj.CHAN1_ID);
        end


		function [] = home(obj)
			obj.ctrl.MoveHome(AptMotorTranslation.CHAN1_ID, true);
		end
		
		function [] = goto(obj, locationInMm)
            if locationInMm < obj.frontlimit
			    obj.ctrl.MoveAbsoluteEx(AptMotorTranslation.CHAN1_ID,...
									    locationInMm, 0, true);
            else
                fprintf('Cannot go beyond front safety limit: %g',obj.frontlimit);
            end
		end
		
		function [] = moveinc(obj, distanceInMm, numMovements,pausesecs)
			for iterMovement = 1:numMovements
				obj.ctrl.MoveRelativeEx(AptMotorTranslation.CHAN1_ID,...
										distanceInMm, 0, true); pause(pausesecs);
            end
		end

		function [] = translate(obj, distanceInMm)
			obj.ctrl.MoveRelativeEx(AptMotorTranslation.CHAN1_ID,...
									distanceInMm, 0, true);
		end

		function pos = getpos(obj)
% 			pos = obj.ctrl.GetAbsMovePos_AbsPos(AptMotorTranslation.CHAN1_ID); %INCORRECT!
            pos = obj.ctrl.GetPosition_Position(obj.CHAN1_ID);
        end

        function kbmove(obj,step)
            % game-like steering of mirror using a,d
            disp('Control stage using the keys A (backward) and D (forward). Use m and n to increase or decrease step size.');
            while(1)
                ch = char(getkey);
                switch lower(ch)
                    case  'a'
                        obj.goto(obj.getpos - step);
                    case 'd'
                        obj.goto(obj.getpos + step);
                    case 'm'
                        if step *10> 20
                            disp('cannot increase step size over 20');
                        else
                            step = step * 10;
                            fprintf('Step size : %g mm\n',step);
                        end
                    case 'n'
                        step = step / 10;                            
                        fprintf('Step size : %g mm',step);
                    otherwise
                        break
                end
            end
     
            end
		
		function [] = setvelparams(obj, maxAcc, maxVel)
			obj.ctrl.SetVelParams(AptMotorTranslation.CHAN1_ID,...
									0, maxAcc, maxVel);
			obj.maxAcc = maxAcc;
			obj.maxVel = maxVel;
		end

		function [] = delete(obj)
			obj.ctrl.StopCtrl();
			obj.ctrl.delete();
			close(obj.fig);
		end
	end
end