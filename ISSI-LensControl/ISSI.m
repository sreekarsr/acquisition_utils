classdef ISSI < handle
    % ISSI LC-2 Canon Ethernet Lens controller communication using UDP
    properties(Constant)
        port = 1339;
    end
    
    properties
        u % udp port      
        focuslims
        aperlims
        ip
    end
    
    methods
        function obj = ISSI(ip)
            if(nargin < 1)
                ip = '192.168.2.252';
            end
            obj.ip = ip;
            obj.u = udpport("datagram", "IPV4");
            fprintf('Connected to %s\n',obj.getver);
            obj.ping;
            disp('Call focusInit() to initialise focusing range')
%             obj.focuslims = focusInit(obj); % initialize and identify focusing range (doesn't raise error on its own if going out of range)
        end
        
        function verstr = getver(obj)
            obj.u.flush;
            obj.write("ver");
            dg = obj.u.read(1,"string");
            verstr = dg.Data;
        end

        function ping(obj)
            obj.u.flush;
            obj.write("ping");
            dg = obj.u.read(7,"string"); pause(1);
            strarr = [dg.Data];
            fprintf("%s\n",strarr);
            obj.focuslims = obj.parseRangeStr(strarr(2));
            obj.aperlims = obj.parseRangeStr(strarr(3));
            if(obj.parseVal(strarr(5))==0)
                warning("Focusing switch is set to MF. Switch to AF for focus control.");
            end
        end

        function flims = focusInit(obj)
            disp('Initializing focusing range..')
            obj.u.flush();
            obj.write("refRange");
            dg = obj.u.read(1,"string");
            disp(dg.Data);
            fstr = dg.Data;
            flims = obj.parseRangeStr(fstr);
            obj.focuslims = flims;
        end

        function focusval = setFocus(obj,f)
            obj.u.flush;
            if(f < obj.focuslims(1) || f > obj.focuslims(2))
                error('Input value %d outside focus range : [%d %d]', f, obj.focuslims(1), obj.focuslims(2));
            else
                obj.write(sprintf("setFocus=%04.0f",f));
            end
            resp = obj.u.read(2,"string");
            fprintf('\n%s %s\n', (resp.Data));
            strarr = [resp.Data];
            focusval = obj.parseVal(strarr(1));
        end

        function aperval = setAper(obj,fnum)
            obj.u.flush;
            obj.write(sprintf("setAper=%g",fnum));
            resp = obj.u.read(1,"string");
            fprintf('\n%s\n', ([resp.Data]));
            if(strcmpi(resp.Data,"errorAperLimits"))
                error('Aperture limits : [%g, %g]\n', obj.aperlims(1), obj.aperlims(2));
            else
                aperval = obj.parseVal(resp.Data);
            end
        end

        function openAper(obj)
            % open aperture to the maximum value
            obj.u.flush;
            obj.write("openAper");
            resp = obj.u.read(1,"string");
            disp(resp.Data);
        end

        function focusMIN(obj) 
            obj.u.flush;
            disp('Minumum focus position')
            obj.write("goMIN");
        end

       function focusMAX(obj) 
            obj.u.flush;
            disp('Maximum focus position')
            obj.write("goMAX");
        end
        
        function write(obj,str)
            obj.u.write(str, obj.ip, ISSI.port);
        end

        function delete(obj)
            disp('Deleting LC object');
            obj.u.delete; % delete udp socket
        end

    end

    methods (Access = private)
        function val = parseVal(~, str)
            C = strsplit(str, "=");
            val = double(C(2));
        end
        function rangelims = parseRangeStr(~,str)
            % parse text of the form 'x..x=a,b'
            C = strsplit(str,"=");
            rangelims =  double(strsplit(C(2), ","));
        end

    end
end

