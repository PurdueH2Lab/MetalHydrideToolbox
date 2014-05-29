classdef KineticsModel
    % General kinetics model class, contains submodels for hydriding and dehydriding
    %
    % The reaction rates evaluated by the kinetics model are broken into a
    % rate (Ca*exp(-Ea/RT)), a pressure function (e.g. log(P/Peq)), and a
    % composition function (e.g. (wMax - w)). The total rate is the product
    % of these three components. Available forms of the pressure and
    % composition functions are stored in this class as function handles in
    % a structure and selected by name from the MH file. Every composition
    % function must have a "Hydriding" form and a "Dehydriding" form
    % specified.
    
    % Copyright (c) 2014, Tyler Voskuilen
    % All rights reserved.
    % 
    % Redistribution and use in source and binary forms, with or without 
    % modification, are permitted provided that the following conditions are 
    % met:
    % 
    %     * Redistributions of source code must retain the above copyright 
    %       notice, this list of conditions and the following disclaimer.
    %     * Redistributions in binary form must reproduce the above copyright 
    %       notice, this list of conditions and the following disclaimer in 
    %       the documentation and/or other materials provided with the 
    %       distribution
    %       
    % THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
    % IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
    % THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR  
    % PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
    % CONTRIBUTORS BE  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
    % EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
    % PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
    % PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
    % LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
    % NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
    % SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


    %----------------------------------------------------------------------
    % These are protected attributes
    properties (SetAccess = protected)
        % Hydriding - Structure of hydriding kinetics properties
        Hydriding   = struct('Assumed',false);  
        
        % Dehydriding - Structure of dehydriding kinetics properties
        Dehydriding = struct('Assumed',false);  
    end
    
    % Static properties
    properties (Constant, Access = private)
        % pFcnList - List of available pressure functions
        % Each entry in the list is a structure with a Name and a function
        % handle that takes two arguments (P and Peq)
        pFcnList = [struct('Name','Log','Handle',@(p,peq) (log(p/peq)));...
                    struct('Name','Linear','Handle',@(p,peq) (p-peq));...
                    struct('Name','Normalized Linear','Handle',@(p,peq) ((p-peq)/peq))];
                
        % wFcnList - List of available w functions
        % Each entry in the list is a structure with a Name and a function
        % handle that takes four arguments (w, wmax, P, and Peq)
        % The 'Chaise' functions are from Chaise et al. 
        % (IJHE Vol 35 p 6311)
        wFcnList = [struct('Name','1st Order Hydriding','Handle',  @(w,wmax,p,peq,T) (wmax-w));...
                    struct('Name','1st Order Dehydriding','Handle',@(w,wmax,p,peq,T) (w));...
                    struct('Name','0th Order Hydriding','Handle',  @(w,wmax,p,peq,T) (wmax));...
                    struct('Name','0th Order Dehydriding','Handle',@(w,wmax,p,peq,T) (wmax));];
    end
    
    methods(Static = true, Access = private)
        %------------------------------------------------------------------
        % Create the function for the p-portion of the kinetics model
        function [fh,ID] = CreatePFcnHandle(str)
            if iscell(str)
                str = str{1};
            end
            ss = strtrim(str);
            
            pList = KineticsModel.pFcnList;
            pFcnNames = {pList.Name};
            ID = find(cellfun(@(s) strcmpi(s,ss),pFcnNames));
            
            if isempty(ID)
                try
                    fh = str2func(['@(p,peq) ',lower(ss)]);
                    fh(10,12); % Test function evaluation
                catch err
                    disp(err)
                    error('KineticsModel:CreatePFcnHandle',...
                          'Pressure function "%s" not recognized',ss);
                end

            else
                fh = KineticsModel.pFcnList(ID).Handle;
            end
            
            
        end
        
        %------------------------------------------------------------------
        % Create the function for the w-portion of the kinetics model
        function [fh,ID] = CreateWFcnHandle(str,mode)
            if iscell(str)
                str = str{1};
            end
            ss = strtrim(str);
            fcnStr = [ss,' ',mode];
            wList = KineticsModel.wFcnList;
            
            wFcnNames = {wList.Name};
            ID = find(cellfun(@(s) strcmpi(s,fcnStr),wFcnNames));
            
            if isempty(ID)
                try
                    fh = str2func(['@(w,wmax,p,peq,t) ',lower(ss)]);
                    fh(0,0.01,10,12,300); % Test function evaluation
                catch err
                    disp(err)
                    error('KineticsModel:CreateWFcnHandle',...
                          'W function "%s" not recognized',ss);
                end
            else
                fh = KineticsModel.wFcnList(ID).Handle;
            end
        end
    end
    
    % Public static methods
    methods(Static = true)
        %------------------------------------------------------------------
        function ListPFcns()
            % Print currently available pressure functions

            % Set column widths (in characters)
            c1 = 30;
            c2 = 30;
            
            fprintf('+-%s-+-%s-+\n','-'*ones(1,c1),'-'*ones(1,c2));
            fprintf('| Name %s | Function %s |\n',...
                ' '*ones(1,c1-5),' '*ones(1,c2-9));
            fprintf('+-%s-+-%s-+\n','-'*ones(1,c1),'-'*ones(1,c2));
            for i = 1:length(KineticsModel.pFcnList)
                fprintf('| %-30s | %-30s |\n',...
                    KineticsModel.pFcnList(i).Name, ...
                    func2str(KineticsModel.pFcnList(i).Handle));
            end
            fprintf('+-%s-+-%s-+\n','-'*ones(1,c1),'-'*ones(1,c2));
            
        end
        
        %------------------------------------------------------------------
        function ListWFcns()
            % Print currently available composition functions
            
            % Set column widths (in characters)
            c1 = 25;
            c2 = 50;
            
            fprintf('+-%s-+-%s-+\n','-'*ones(1,c1),'-'*ones(1,c2));
            fprintf('| Name %s | Function %s |\n',...
                ' '*ones(1,c1-5),' '*ones(1,c2-9));
            fprintf('+-%s-+-%s-+\n','-'*ones(1,c1),'-'*ones(1,c2));
            for i = 1:length(KineticsModel.wFcnList)
                fprintf('| %-25s | %-50s |\n',...
                    KineticsModel.wFcnList(i).Name, ...
                    func2str(KineticsModel.wFcnList(i).Handle));
            end
            fprintf('+-%s-+-%s-+\n','-'*ones(1,c1),'-'*ones(1,c2));
            
        end
    end
    
    %Define class methods
    methods
        %------------------------------------------------------------------
        function km = KineticsModel(entryDicts, type)
            % Create the KineticsModel from the mh file entry
            if nargin > 0
                
                % Load dehydriding kinetics if present
                readEntries = false;
                if isfield(entryDicts, 'Dehydriding')
                    lines = entryDicts.Dehydriding.entryLines;

                    if MetalHydride.FoundEntries(lines,{'Ca','Ea','pFcn','wFcn'})

                        km.Dehydriding.Assumed = false;
                        km.Dehydriding.Ca = MetalHydride.ReadNumber(lines,'Ca');
                        km.Dehydriding.Ea = MetalHydride.ReadNumber(lines,'Ea');

                        % Generate function handle
                        fcnString = MetalHydride.ReadString(lines,'pFcn');
                        [km.Dehydriding.pFcn, km.Dehydriding.pFcnID] = ...
                             KineticsModel.CreatePFcnHandle(fcnString);

                        fcnString = MetalHydride.ReadString(lines,'wFcn');
                        [km.Dehydriding.wFcn, km.Dehydriding.wFcnID] = ...
                             KineticsModel.CreateWFcnHandle(fcnString,'Dehydriding');

                        readEntries = true;
                    end
                end

                % If entries were not found, select defaults based on family
                if ~readEntries
                    km.Dehydriding = struct('Assumed',true,...
                        'Ca',MetalHydride.GetTypeProperty('Ca Dehydriding',type),...
                        'Ea',MetalHydride.GetTypeProperty('Ea Dehydriding',type));

                    [km.Dehydriding.pFcn, km.Dehydriding.pFcnID] = ...
                        KineticsModel.CreatePFcnHandle('log');
                    [km.Dehydriding.wFcn, km.Dehydriding.wFcnID] = ...
                        KineticsModel.CreateWFcnHandle('1st Order','Dehydriding');
                end

                % Load hydriding kinetics if present
                readEntries = false;
                if isfield(entryDicts,'Hydriding')
                    lines = entryDicts.Hydriding.entryLines;

                    if MetalHydride.FoundEntries(lines,{'Ca','Ea','pFcn','wFcn'})

                        km.Hydriding.Assumed = false;
                        km.Hydriding.Ca = MetalHydride.ReadNumber(lines,'Ca');
                        km.Hydriding.Ea = MetalHydride.ReadNumber(lines,'Ea');

                        % Generate function handle
                        fcnString = MetalHydride.ReadString(lines,'pFcn');
                        [km.Hydriding.pFcn, km.Hydriding.pFcnID] = ...
                             KineticsModel.CreatePFcnHandle(fcnString);

                        fcnString = MetalHydride.ReadString(lines,'wFcn');
                        [km.Hydriding.wFcn, km.Hydriding.wFcnID] = ...
                             KineticsModel.CreateWFcnHandle(fcnString,'Hydriding');

                        readEntries = true;
                    end
                end

                % If entries were not found, select defaults based on family
                if ~readEntries
                    km.Hydriding = struct('Assumed',true,...
                        'Ca',MetalHydride.GetTypeProperty('Ca Hydriding',type),...
                        'Ea',MetalHydride.GetTypeProperty('Ea Hydriding',type));

                    [km.Hydriding.pFcn, km.Hydriding.pFcnID] = ...
                        KineticsModel.CreatePFcnHandle('log');
                    [km.Hydriding.wFcn, km.Hydriding.wFcnID] = ...
                        KineticsModel.CreateWFcnHandle('1st Order','Hydriding');
                end
            end
        end
        
        %------------------------------------------------------------------
        function r = dwdt(self,T,P,Peq_abs,Peq_des,w,wmax)
            % Calculate the reaction rate (kg_H / (kg_M*s))
            % You should not call this directly, call MetalHydride.dwdt
            
            R = 8.314; %J/mol.K
            if P > Peq_abs && w < wmax
                % Hydriding
                r = self.Hydriding.Ca*exp(-self.Hydriding.Ea/(R*T))*...
                    self.Hydriding.wFcn(w,wmax,P,Peq_abs,T) * ...
                    self.Hydriding.pFcn(P,Peq_abs);
            elseif P < Peq_des && w > 0
                % Dehydriding
                r = self.Dehydriding.Ca*exp(-self.Dehydriding.Ea/(R*T))*...
                    self.Dehydriding.wFcn(w,wmax,P,Peq_des,T) * ...
                    self.Dehydriding.pFcn(P,Peq_des);
            else
                % Not reacting
                r = 0;
            end
        end
        
        %------------------------------------------------------------------
        function r = RxnRate(self,T,type)
            % Calculate the reaction rate constant (kg_H / (kg_M*s))
            % You should not call this directly, call MetalHydride.RxnRate
            
            R = 8.314; %J/mol.K
            if strcmpi(type,'abs')
                % Hydriding
                r = self.Hydriding.Ca*exp(-self.Hydriding.Ea/(R*T));
            elseif strcmpi(type,'des')
                % Dehydriding
                r = self.Dehydriding.Ca*exp(-self.Dehydriding.Ea/(R*T));
            else
                error('KineticsModel:RxnRate',...
                      ['Type field must be either "abs" or "des"',...
                      ', "%s" is not recognized'],...
                      type);
            end
        end
        
        %------------------------------------------------------------------
        function [tau, assumed] = tau(self,type,T,P,Peq)
            % Calculate the reaction time constant (s)
            % You should not call this directly, call MetalHydride.tau
            
            R = 8.314; %J/mol.K
            
            % Select which kinetics to use
            if strcmpi(type,'abs')
                K = self.Hydriding;
            elseif strcmpi(type,'des')
                K = self.Dehydriding;
            else
                error('KineticsModel:tau',...
                      ['Type field must be either "abs" or "des"',...
                      ', "%s" is not recognized'],...
                      type);
            end
            
            % Add pFcn if P and Peq provided
            if exist('P','var') && exist('Peq','var')
                pf = abs(K.pFcn(P,Peq));
            else
                pf = 1;
            end
            
            % Calculate tau
            tau = 1/(K.Ca.*exp(-K.Ea./(R.*T)).*pf);
            assumed = K.Assumed;
        end
        
        %------------------------------------------------------------------
        function pfName = pFcnName(self,type)
            % Return the name of the pressure function
            % This is used for the summary spreadsheet
            
            pList = KineticsModel.pFcnList;
            pFcnNames = {pList.Name};
            if strcmpi(type,'abs')
                if ~isempty(self.Hydriding.pFcnID)
                    pfName = pFcnNames{self.Hydriding.pFcnID};
                else
                    pfName = 'Custom';
                end
            elseif strcmpi(type,'des')
                if ~isempty(self.Dehydriding.pFcnID)
                    pfName = pFcnNames{self.Dehydriding.pFcnID};
                else
                    pfName = 'Custom';
                end
            else
                error('KineticsModel:pFcnName',...
                      ['Type field must be either "abs" or "des"',...
                      ', "%s" is not recognized'],...
                      type);
            end
        end
        
        %------------------------------------------------------------------
        function wfName = wFcnName(self,type)
            % Return the name of the w function
            % This is used for the summary spreadsheet
            
            wList = KineticsModel.wFcnList;
            wFcnNames = {wList.Name};
            if strcmpi(type,'abs')
                if ~isempty(self.Hydriding.wFcnID)
                    wfName = wFcnNames{self.Hydriding.wFcnID};
                else
                    wfName = 'Custom';
                end
            elseif strcmpi(type,'des')
                if ~isempty(self.Dehydriding.wFcnID)
                    wfName = wFcnNames{self.Dehydriding.wFcnID};
                else
                    wfName = 'Custom';
                end
            else
                error('KineticsModel:wFcnName',...
                      ['Type field must be either "abs" or "des"',...
                      ', "%s" is not recognized'],...
                      type);
            end
        end

    end %end methods
end %end class
