classdef XPSMotor < handle
	properties (Constant)
		Port = 5001,
        TimeOut = 5,
        Group = 'Group1',
        Positioner = 'Group1.Pos',
	end
    
	properties (SetAccess = private)
        ip,
		socketID,
		errorCode
    end
    properties
        minpos = -70;
    end
    
	methods
		function obj = XPSMotor(ip)
			obj.ip = ip;
			XPS_load_drivers;
			% Connect to XPS
			obj.socketID = TCP_ConnectToServer(obj.ip, XPSMotor.Port, XPSMotor.TimeOut);
			if (obj.socketID < 0)
				disp('Connection to XPS failed, check ip & Port');
				return ;
			end
			
			[obj.errorCode] = GroupKill(obj.socketID, XPSMotor.Group);
			if (obj.errorCode ~= 0)
				disp (['Error ' num2str(obj.errorCode) ' occurred while doing GroupKill!']);
				return ;
			end
			[obj.errorCode] = GroupInitialize(obj.socketID, XPSMotor.Group);
			if (obj.errorCode ~= 0)
				disp(['Error ' num2str(obj.errorCode) ' occurred while doing GroupInitialize!']);
				return ;
            end

%             obj.setvelparams(1,1);
		end

		function [] = home(obj)
			[obj.errorCode] = GroupKill(obj.socketID, XPSMotor.Group);
			if (obj.errorCode ~= 0)
				disp (['Error ' num2str(obj.errorCode) ' occurred while doing GroupKill!']);
				return ;
			end
			[obj.errorCode] = GroupInitialize(obj.socketID, XPSMotor.Group);
			if (obj.errorCode ~= 0)
				disp(['Error ' num2str(obj.errorCode) ' occurred while doing GroupInitialize!']);
				return ;
			end
			[obj.errorCode] = GroupHomeSearch(obj.socketID, XPSMotor.Group);
			if (obj.errorCode ~= 0)
				disp(['Error ' num2str(obj.errorCode) ' occurred while doing GroupHomeSearch!']);
				return ;
			end
        end

		
		function [] = goto(obj, locationInMm)
            if locationInMm < obj.minpos
                error('Caution reached minimum safe limit.');
            end
			[obj.errorCode] = GroupMoveAbsolute(obj.socketID, XPSMotor.Positioner, locationInMm);
			if (obj.errorCode ~= 0)
				disp (['Error ' num2str(obj.errorCode) ' occurred while doing GroupMoveAbsolute!']);
				return ;
			end
		end
		
		function [] = moveinc(obj, distanceInMm, numMovements)
             if obj.getpos + distanceInMm*numMovements < obj.minpos
                error('Caution reached minimum safe limit.');
            end
			for iterMovement = 1:numMovements,
                pause(0.5);
				[obj.errorCode] = GroupMoveRelative(obj.socketID, XPSMotor.Positioner, distanceInMm);
				if (obj.errorCode ~= 0)
					disp (['Error ' num2str(obj.errorCode) ' occurred while doing GroupMoveAbsolute!']);
					return ;
				end
			end;
		end

		function [] = translate(obj, distanceInMm)
            if obj.getpos + distanceInMm < obj.minpos
                error('Caution reached minimum safe limit.');
            end
            
			[obj.errorCode] = GroupMoveRelative(obj.socketID, XPSMotor.Positioner, distanceInMm);
			if (obj.errorCode ~= 0)
				disp (['Error ' num2str(obj.errorCode) ' occurred while doing GroupMoveAbsolute!']);
				return ;
			end
		end

		function pos = getpos(obj)
			[obj.errorCode, pos] = GroupPositionCurrentGet(obj.socketID, XPSMotor.Positioner, 1);
			if (obj.errorCode ~= 0)
				disp (['Error ' num2str(obj.errorCode) ' occurred while doing GroupPositionCurrentGet!']);
				return ;
			end
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
% 		function [] = setvelparams(obj, maxAcc, maxVel)
% 			obj.ctrl.SetVelParams(AptMotorTranslation.CHAN1_ID,...
% 									0, maxAcc, maxVel);
% 			obj.maxAcc = maxAcc;
% 			obj.maxVel = maxVel;
% 		end

% 		function [] = delete(obj)
% 			% Kill the group
% 			[obj.errorCode] = GroupKill(obj.socketID, XPSMotor.Group);
% 			if (obj.errorCode ~= 0)
% 				disp (['Error ' num2str(obj.errorCode) ' occurred while doing GroupKill!']);
% 				return ;
% 			end
% 			TCP_CloseSocket(obj.socketID);
% 		end
	end
end