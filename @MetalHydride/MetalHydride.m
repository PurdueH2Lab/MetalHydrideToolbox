classdef MetalHydride
    %MetalHydride A class for encapsulating metal hydride properties
    % This class is inherently tied to the metal hydride database saved in
    % the data folder in ASCII *.mh files.
    %
    % Type 'doc MetalHydride' for more information
    %
    % Note:
    %  Some of the static functions are marked IUO (Internal Use Only).
    %  These functions are for reading of the mh file and are only public
    %  so that the Reference and KineticsModel classes can use them too.
    %  They have no general purpose and should not need to be called at the
    %  user-level.

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
    % Dependent properties (looked up from sub-structures)
    properties (Dependent = true, SetAccess = private)
        kEff % Effective thermal conductivity (W/(m*K))
        rho  % Hydride density (kg/m^3)
        Slope % Hydride plateau slope at 298 K
        Hysteresis % Hydride hysteresis values at 298 K
        ThermoLevel % Level of information in thermodynamics
        RefList % Cell of compiled citations for this hydride
        TcAssumed  % Whether Tc was assumed
        SlopeAssumed % Whether the plateau slope was assumed (boolean/logical)
        NumPlateaus % Number of plateaus
        HysteresisAssumed % Whether the hysteresis was assumed (boolean/logical)
        AbsKineticsAssumed % Whether the absorption kinetics were assumed (boolean/logical)
        DesKineticsAssumed % Whether the desorption kinetics were assumed (boolean/logical)
        kEffAssumed % Whether the thermal conductivity was assumed (boolean/logical)
        rhoAssumed % Whether the density was assumed (boolean/logical)
        CpAssumed % Whether the specific heat was assumed (boolean/logical)
        AbsFromIsotherms % Whether the absorption thermo is from isotherms (boolean/logical)
        DesFromIsotherms % Whether the desorption thermo is from isotherms (boolean/logical)
    end
    
    %----------------------------------------------------------------------
    % Base protected properties (read or calculated)
    properties (SetAccess = protected)
        Type = ''; % Hydride type string (e.g. 'AB5' or 'AB2')
        SourceFile = ''; % Full path of the mh source file
        wMax % Maximum hydrogen weight fraction (kg_H / kg_Metal)
        HM   % Hydrogen to metal atomic ratio (LaNi5H6 would be HM = 1, MgH2 would be HM = 2)
        Pc   % Critical pressure (Pa)
        Name % Compact hydride name (e.g. 'LaNi5')
        FormattedName % Formatted hydride name (e.g. 'LaNi_{5}')
        FormattedType % Formatted hydride type (e.g. 'AB_{5}')
        W    % Hydride molar mass (g/mol or kg/kmol)
        Tc   % Critical temperature (K)
    end
    
    %----------------------------------------------------------------------
    % Base private properties - for debugging it can be helpful to set this
    % to 'SetAccess = protected' so you can see the stored values
    properties %(Access = private)
        % Elements - Array of Element objects
        Elements = Element(); 
        
        % Props - Structure of thermal properties
        % Access to the data in this structure is handled by use of the
        % 'getter' functions
        Props = struct(); 
        
        % Thermo - Structure for containing the thermodynamics properties
        % The thermo structure contains the following information:
        %   Thermo.WtPct - Maximum weight percent hydrogen (H/(H+M))
        %   Thermo.Tc - Hydride critical temperature (K)
        %   Thermo.Omega - Solution interaction energy calculated from Tc (J/mol_H2)
        %   Thermo.TcAssumed - Boolean indicating if Tc was assumed
        %   Thermo.SlopeAssumed - Boolean indicating if plateau slope was assumed
        %   Thermo.HysteresisAssumed - Boolean indicating if hysteresis was assumed
        %   Thermo.Dehydriding.dH - Dehydriding enthalpy (J/mol_H2)
        %   Thermo.Dehydriding.dS - Dehydriding entropy (J/mol_H2/K)
        %   Thermo.Dehydriding.A - Dehydriding plateau slope (J/mol_H2)
        %   Thermo.Dehydriding.FromIsotherms - Boolean indicating source
        %   Thermo.Hydriding.dH - Hydriding enthalpy (J/mol_H2)
        %   Thermo.Hydriding.dS - Hydriding entropy (J/mol_H2/K)
        %   Thermo.Hydriding.A - Hydriding plateau slope (J/mol_H2)
        %   Thermo.Hydriding.FromIsotherms - Boolean indicating source
        %
        % For information on how these properties are used, see
        % MetalHydride.Peq and MetalHydride.dH.
        %
        % You should not need to directly access items from Thermo, use the
        % MetalHydride functions instead
        Thermo = struct();
        
        % Kinetics - Instance of the KineticsModel class
        Kinetics = KineticsModel();
        
        % Refs - Structure of Reference objects
        Refs = struct();
    end
    
    % Private static methods - for internal use only
    methods(Static = true, Access = private)
        %------------------------------------------------------------------
        % Get filename from entry string
        filename = GetFilename(inputStr)
        
        %------------------------------------------------------------------
        % Read the thermodynamic inputs - function in separate file
        thermo = ReadThermo(thermoStruct, elements, name, type)

        %------------------------------------------------------------------
        % Read the property inputs - function in separate file
        props = ReadProps(propStruct, type)
        
        %------------------------------------------------------------------
        % Parse lines into a zone-based structure recursively - 
        % function in separate file
        data = ReadZones(lines)
        
        %------------------------------------------------------------------
        % Read the entire mh file into a cell array of one string per line
        lines = ReadFile(filename)
        
        %------------------------------------------------------------------
        % Get paths to parts of the toolbox - function in separate file
        [base,data,PCI,doc] = GetPaths()
        
        %------------------------------------------------------------------
        % Write database reference file in BibTex format
        WriteBibRefs()
        
        %------------------------------------------------------------------
        function lm = LineMatch(l,s)
            % Get an array of lines that have a given entry string
            lm = cellfun(@(x) ~isempty(strfind(lower(x),[lower(s),':'])),l);
        end
        
        %------------------------------------------------------------------
        function line = GetLine(lines,str)
            % Find the line in an mh file with a given entry
            lc = lines( MetalHydride.LineMatch(lines,str) );
            line = lc{1};
        end
        
        %------------------------------------------------------------------
        function refs = ReadReferences(refDict)
            % Read the reference list from an mh file
            refNames = fieldnames(refDict);
            refs = struct();
            
            for i = 1:length(refNames)
                refs.(refNames{i}) = ...
                    Reference(refDict.(refNames{i}).entryLines);
            end
        end
        
        %------------------------------------------------------------------
        % Find the "Elements" entry and read it
        function elements = ReadElements(lines)
            if MetalHydride.FoundEntry(lines,'elements')
                elements = Element.ReadElements(...
                    MetalHydride.GetLine(lines,'elements'));
            else
                error('MetalHydride:ReadElements',...
                      'No "Elements" entry located');
            end
        end
 
        %------------------------------------------------------------------
        % Get bracket divisions on lines. This marks where the sub-sections
        % are in the file.
        function brackets = GetBrackets(lines)
            nl = length(lines);
            brackets = zeros(nl,1);
            for i = 1:nl
                brackets(i) = length(strfind(lines{i},'{')) - ...
                              length(strfind(lines{i},'}'));
            end
            brackets = cumsum(brackets);
        end
    end % end private static methods
    
    % Public static methods
    methods(Static)
        %------------------------------------------------------------------
        % Load entire database - function in separate file
        hydrides = LoadDatabase(forceReload)

        %------------------------------------------------------------------
        % Write database summary spreadsheet - function in separate file
        WriteExcelSummary()
        
        %------------------------------------------------------------------
        % Write database summary LaTeX - function in separate file
        WriteLaTeXSummary(showPlots)
        
        %------------------------------------------------------------------
        % Print database statistics - function in separate file
        PrintStats()
        
        %------------------------------------------------------------------
        % Read PCI data from a csv file in data/supporting
        PCIdata = ReadPCIData(alloyName)
        
        %------------------------------------------------------------------
        % Read PCI data and fit key parameters to it
        FitPCIData(alloyName,varargin)
        
        % The following functions are for internal use only, but cannot be
        % private since the References and KineticsModel classes use them
        % too
        
        %------------------------------------------------------------------
        % IUO - Find a string entry and read it - function in separate file
        value = ReadString(lines,str)

        %------------------------------------------------------------------
        % IUO - Find a numeric entry and read it - function in separate file
        value = ReadNumber(lines,str)
        
        %------------------------------------------------------------------
        % IUO - Get a named property for a given hydride type
        value = GetTypeProperty(propName,type)
        
        %------------------------------------------------------------------
        function f = FoundEntry(lines,str)
            % IUO - Returns a boolean of whether an entry is found on a set of lines
            f = any( MetalHydride.LineMatch(lines,str) );
        end
        
        %------------------------------------------------------------------
        function f = FoundEntries(lines,strs)
            % IUO - Returns a boolean of whether all entries in a list are found in a set of lines
            f = true;
            for i = 1:length(strs)
                if ~MetalHydride.FoundEntry(lines,strs{i})
                    f = false;
                    break;
                end
            end
        end
    end % end public static methods
    
    %Define class methods
    methods
        %------------------------------------------------------------------
        % Calculate the equilibrium for the given hydride
        peq = Peq(self, T, w, type)
        
        %------------------------------------------------------------------
        function mh = MetalHydride(inputStr)
            % Construct a metal hydride object with a single string input
            % The input string can be one of the following things:
            %
            %  * No input - This creates a "NaN" hydride with no
            %    loaded information
            %
            %  * The name of an mh file - This loads the file
            %
            %  * The name of an mh file missing the '.mh' - It is added
            %    automatically
            %
            % Once the file is selected, the loading follows these steps:
            %  1. Read the contents of the mh file into a cell array
            %  2. Break the cell array into structures and sub-structures
            %     based on the '{' and '}' markers in the file
            %  3. Read the "Type" and "Elements" entries from the file
            %  4. Generate the "Name" using the Elements array
            %  5. Read the "References" sub-structure with ReadReferences
            %  6. Read the "Thermodynamics" sub-structure with ReadThermo
            %  7. Read the "Properties" sub-structure with ReadProps
            %  8. Create the KineticsModel from the "Kinetics"
            %     sub-structure
            %
            % There is extensive error-checking in this process and if an
            % error is encountered while reading or processing the file, it
            % stops execution and displays a relevant message
            
            if nargin > 0
                try
                    % Locate the source file name (checks if it exists too)
                    mh.SourceFile = MetalHydride.GetFilename(inputStr);

                    % Read the file into a cell array, one line per cell
                    lines = MetalHydride.ReadFile(mh.SourceFile);

                    % Parse the lines into a structure. Each zone has a list
                    % of line strings and an array of subDict structures.
                    % They are nested, so the subDict is a "zone", and has
                    % its own list of line strings and array of subDicts.
                    data = MetalHydride.ReadZones(lines);

                    % Read top-level entries (Type and Elements)
                    mh.Type = MetalHydride.ReadString(...
                        data.entryLines,'type');

                    mh.Elements = ...
                        MetalHydride.ReadElements(data.entryLines);
                    
                    mh.Name = Element.MakeNameString(mh.Elements);
                    
                    % Read references
                    mh.Refs = MetalHydride.ReadReferences    ...
                    (                                        ...
                        data.subDicts.References.subDicts    ...
                    );

                    % Read thermo entry
                    mh.Thermo = MetalHydride.ReadThermo      ...
                    (                                        ...
                        data.subDicts.Thermodynamics,        ...
                        mh.Elements,                         ...
                        mh.Name,                             ...
                        mh.Type                              ...
                    );

                    % Read the properties entry
                    mh.Props = MetalHydride.ReadProps        ...
                    (                                        ...
                        data.subDicts.Properties,            ...
                        mh.Type                              ...
                    );

                    % Read the kinetics entry
                    mh.Kinetics = KineticsModel              ...
                    (                                        ...
                       data.subDicts.Kinetics.subDicts,      ...
                       mh.Type                               ...
                    );
                   
                catch err
                    fprintf('\n*** Error reading "%s"\n\n',mh.SourceFile);
                    rethrow(err)
                end
                
                % Set constant properties for this metal hydride
                mh.FormattedName = Element.MakeFormattedString(mh.Elements);
                mh.FormattedType = regexprep(mh.Type,'([0-9]+)','_{$1}');
                
                % Set the wMax, molar mass, and atomic H/M values
                mh.wMax = mh.Thermo.WtPct/(1-mh.Thermo.WtPct);
                mh.W = sum([mh.Elements.W].*[mh.Elements.Mols]);
                mh.Tc = mh.Thermo.Tc;
                mh.HM = mh.Thermo.WtPct/(1 - mh.Thermo.WtPct) * ...
                    mh.W/(1.008*sum([mh.Elements.Mols]));
                
                % Set the critical point
                mh.Pc = 101325*exp(mh.Thermo.Dehydriding.dH./(8.314.*mh.Tc)...
                    - mh.Thermo.Dehydriding.dS./8.314);
                
                
            else
                % Always set the Name property, even for Null hydrides
                mh.Name = Element.MakeNameString(mh.Elements);
            end
            
        end
        
        %------------------------------------------------------------------
        function [hFig,DOI] = ComparePCI(self, showPlot)
            % Compare a hydride's Peq model with its isotherms, if available
            %
            % Call on a metal hydride to create a plot comparing any
            % isotherms for that hydride with its Peq model. Returns a NaN
            % figure handle if there are no isotherms to compare.
            %
            % Inputs:
            %  showPlot  - Optional boolean to show plot or not (Defaults
            %              to true)
            %
            % Outputs:
            %  hFig  -  Handle to figure, or NaN if not PCI data
            %  DOI   -  DOI for the PCI data, or a blank string
            
            [~,~,PCIpath,~] = MetalHydride.GetPaths();
            [~,PCIfilename] = fileparts(self.SourceFile);
            
            if ~exist('showPlot','var')
                showPlot = true;
            end

            if exist(fullfile(PCIpath,[PCIfilename,'_PCI.csv']),'file')
                PCIData = MetalHydride.ReadPCIData(PCIfilename);
                
                wvec = linspace(0.01,0.97,100).*self.wMax;
                colors = jet(100);
                
                hFig = figure;
                set(hFig,...
                    'Name',self.Name,...
                    'Units','inches',...
                    'Position',[2 2 6.5 2.75],...
                    'PaperPositionMode','auto',...
                    'PaperSize',[6.5 2.75],...
                    'Visible','off');
                
                if showPlot
                    set(hFig,'Visible','on');
                end

                % Make two axes
                ax(1) = subplot(1,2,1);
                hold all
                ax(2) = subplot(1,2,2);
                hold all

                % Find the max and min temperature from the data
                Tmax = 0;
                Tmin = 3000;

                if ~isempty(PCIData.Abs)
                    Tmax = max([Tmax max([PCIData.Abs.T])]);
                    Tmin = min([Tmin min([PCIData.Abs.T])]);
                end

                if ~isempty(PCIData.Des)
                    Tmax = max([Tmax max([PCIData.Des.T])]);
                    Tmin = min([Tmin min([PCIData.Des.T])]);
                end

                % Make Van't Hoff plot
                Tvh = linspace(Tmin-20, Tmax+50, 100);
                Pabs = zeros(size(Tvh));
                Pdes = zeros(size(Tvh));
                for i = 1:length(Tvh)
                    Pabs(i) = self.Peq(Tvh(i),0.5*self.wMax,'abs')./1e5;
                    Pdes(i) = self.Peq(Tvh(i),0.5*self.wMax,'des')./1e5;
                end

                plot(ax(2),1000./Tvh, Pabs,'-k','LineWidth',2);
                plot(ax(2),1000./Tvh, Pdes,'--k','LineWidth',2);

                % Plot absorption
                for na = 1:length(PCIData.Abs)
                    T = PCIData.Abs(na).T;
                    cs = max([1 round((T - Tmin) / (Tmax - Tmin) * 100)]);
                    PeqModel = self.Peq(T,wvec,'abs') ./ 1e5;
                    plot(ax(1),wvec.*100,PeqModel,'Line','-','LineWidth',2,...
                         'Color',colors(cs,:));
                    plot(ax(1),PCIData.Abs(na).w.*100, PCIData.Abs(na).Peq,'Marker','o',...
                         'Color',colors(cs,:),'MarkerFaceColor',colors(cs,:),...
                         'Line','None');

                    % Van't Hoff
                    [x,idx] = unique(PCIData.Abs(na).w./self.wMax);
                    y = PCIData.Abs(na).Peq(idx);
                    Pmid = interp1(x,y,0.5);
                    plot(ax(2),1000./T,Pmid,'Marker','o',...
                         'Color','k','MarkerFaceColor','k',...
                         'Line','None');
                end

                % Plot desorption
                for nd = 1:length(PCIData.Des)
                    T = PCIData.Des(nd).T;
                    cs = max([1 round((T - Tmin) / (Tmax - Tmin) * 100)]);
                    PeqModel = self.Peq(T,wvec,'des') ./ 1e5;
                    plot(ax(1),wvec.*100,PeqModel,'Line','--','LineWidth',2,...
                         'Color',colors(cs,:));
                    plot(ax(1),PCIData.Des(nd).w.*100, PCIData.Des(nd).Peq,'Marker','o',...
                         'Color',colors(cs,:),'MarkerFaceColor','w','Line','None');

                    % Van't Hoff
                    [x,idx] = unique(PCIData.Des(nd).w./self.wMax);
                    y = PCIData.Des(nd).Peq(idx);
                    Pmid = interp1(x,y,0.5);
                    plot(ax(2),1000./T,Pmid,'Marker','o',...
                         'Color','k','MarkerFaceColor','w',...
                         'Line','None');
                end

                % Format the axes
                xlabel(ax(1),'w_H / w_M (%)')
                ylabel(ax(1),'P (bar)')
                xlabel(ax(2),'1000/T (K^{-1})')
                ylabel(ax(2),'P (bar)')
                set(ax(1),'XLim',[0 self.wMax.*100]);
                set(ax,'LineWidth',1,'Box','on','YScale','log');

                set(ax(1),'Position',[.13 .18 .35 .75]);
                set(ax(2),'Position',[.57 .18 .35 .75]);
                
                DOI = PCIData.DOI;
            else
                hFig = NaN;
                DOI = '';
            end
        end
        
        %------------------------------------------------------------------
        function Teq = Teq(self, P, w, type)
            % Calculate the equilibrium temperature at a given P, w, and type
            %
            % This is a complement function to Peq, since it is often
            % useful to find the equilibrium temperature at a given
            % pressure. Due to the complex nature of the regular solution
            % model used to calculate Peq, this function uses a numerical
            % approach
            %
            % Inputs (all required):
            %  P - Pressure in Pa
            %  w - Weight fraction of hydrogen (kg_H / kg_Metal)
            %  type - String that is 'abs' or 'des' to indicate which mode
            %         to find. It is not case sensitive. Any other string
            %         will generate an error
            %
            % Output:
            %  Teq - The equilibrium temperature in K
            %
            % Example Usage:
            %  A = MetalHydride('La[1]Ni[5]');
            %  T = A.Teq(5e5, A.wMax*0.5, 'des');
            %
            % Note:
            %  Since this function uses a numerical approach, it is
            %  considerably slower to evaluate than the Peq function. Keep
            %  that in mind when attempting numerous function calls.
            %
            %  If you can find an analytical solution for x of:
            %
            %    (A + Bx)/(C + Dx) = ln(x/(1-x))
            %
            %  with A, B, C, and D as constants then you can code the 
            %  analytical solution.
            
            % Enforce w and P of equal size. If one is a scalar, expand it
            % to be a vector
            if length(P) > 1 && length(w) == 1
                w = w*ones(size(P));
            elseif length(w) > 1 && length(P) == 1
                P = P*ones(size(w));
            end
            Teq = zeros(size(P));
            
            % As w -> 0 and P -> Large, Teq -> Infinity, so limit T
            % Conversely, as w -> wMax, Teq -> 0 or -Infinity (not sure) so
            % limit T the other way too
            Tmin = 5;
            Tmax = 3000;
            
            for i = 1:length(Teq)
                if self.Peq(Tmax,w(i),type) < P(i)
                    Teq(i) = Tmax;
                elseif self.Peq(Tmin,w(i),type) > P(i)
                    Teq(i) = Tmin;
                else
                    Teq(i) = fzero(@(T) self.Peq(T,w(i),type)-P(i),...
                        [Tmin Tmax]);
                end
            end
        end
        
        %------------------------------------------------------------------
        function weq = weq(self, P, T, type) %#ok<MANU,STOUT,INUSD>
            % NOT IMPLEMENTED - NOT SURE IT IS USEFUL
            %
            % If you call this function, it will generate a 
            % 'Not Implemented' fatal error
            error('MetalHydride:weq','Not implemented');
        end
        
        %------------------------------------------------------------------
        function [tau,assumed] = tau(self, type, T, P, w)
            % Use the KineticsModel to calculate the kinetic time constant
            %
            % This function uses a cascading series of optional inputs. The
            % only required input is the 'type' string, but as you supply
            % other inputs they have to go in order. See the example usage
            % for more information.
            %
            % Inputs:
            %  type - String that is 'abs' or 'des' to indicate which mode
            %         to find. It is not case sensitive. Any other string
            %         will generate an error. This is required.
            %  T - Temperature in Kelvin (optional, defaults to 300 K)
            %  P - Pressure in Pa (optional, pressure function not included
            %      in tau if P is not provided)
            %  w - Weight fraction of hydrogen (kg_H / kg_Metal)
            %      (optional, defaults to wMax/2 if not provided)
            %
            % Outputs:
            %  tau - The time constant in seconds
            %  assumed - Whether this is based on assumed kinetics or not
            %
            % Example Usage:
            %  A = MetalHydride('La[1]Ni[5]');
            %  t1 = A.tau('abs');
            %  t2 = A.tau('abs',400);
            %  [t3,a3] = A.tau('abs',400,5e5);
            %  [t4,a4] = A.tau('abs',400,5e5,0.2*A.wMax);

            if ~exist('T','var')
                T = 300;
            end
            
            if ~exist('P','var')
                [tau,assumed] = self.Kinetics.tau(type,T);
            else
                if ~exist('w','var')
                    w = self.wMax/2;
                end
                
                Peq = self.Peq(T,w,type);
                [tau,assumed] = self.Kinetics.tau(type,T,P,Peq);
            end
        end
        
        %------------------------------------------------------------------
        function [dwdt, dEdt] = dwdt(self, T, P, w)
            % Calculate the reaction rate using the KineticsModel
            %
            % Whether the reaction is hydriding or dehydriding is
            % determined in the KineticsModel class by comparing P with Peq
            % at the current T and w
            %
            % Inputs (all inputs are required)
            %  T - Temperature in Kelvin
            %  P - Pressure in Pa
            %  w - Weight fraction of hydrogen (kg_H / kg_Metal)
            %
            % Outputs:
            %  dwdt - The reaction rate in kg_H / (kg_Metal * s)
            %  dEdt - The reaction heating rate in W / kg_Metal
            %
            % Example Usage:
            %  A = MetalHydride('La[1]Ni[5]');
            %  dwdt = A.dwdt(400, 5e5, 0.5*A.wMax);
            %  [dwdt, dEdt] = A.dwdt(400, 5e5, 0.5*A.wMax);

            % Calculate thermodynamic properties
            Peq_abs = self.Peq(T, w, 'abs');
            Peq_des = self.Peq(T, w, 'des');
            
            % Call KineticsModel to calculate reaction rate
            dwdt = self.Kinetics.dwdt(T,P,Peq_abs,Peq_des,w,self.wMax);
            
            % Calculate heating rate
            dEdt = self.dH(dwdt, w) * dwdt;
        end
        
        %------------------------------------------------------------------
        function q = dEdt(self, T, P, w)
            % Calculate the heating rate using the KineticsModel
            %
            % Whether the reaction is hydriding or dehydriding is
            % determined in the KineticsModel class by comparing P with Peq
            % at the current T and w. This is the same as calling:
            %
            %   dwdt(T,P,w) * dH(dwdt(T,P,w))
            %
            % Inputs (all inputs are required)
            %  T - Temperature in Kelvin
            %  P - Pressure in Pa
            %  w - Weight fraction of hydrogen (kg_H / kg_Metal)
            %
            % Outputs:
            %  dEdt - The heating rate in W / kg_Metal
            %
            % Example Usage:
            %  A = MetalHydride('La[1]Ni[5]');
            %  q = A.dEdt(400, 5e5, 0.5*A.wMax);

            % Call dwdt to calculate reaction rate
            dwdt = self.dwdt(T,P,w);
            
            % Then use dH to calculate heating rate
            q = self.dH(dwdt, w) * dwdt;
        end
        
        %------------------------------------------------------------------
        function r = RxnRate(self, T, type)
            % Calculate the reaction rate constant using the KineticsModel
            %
            % Whether the reaction is hydriding or dehydriding is
            % determined in the KineticsModel class by comparing P with Peq
            % at the current T and w
            %
            % Inputs (all inputs are required)
            %  T - Temperature in Kelvin
            %  type - String that is 'abs' or 'des' to indicate which mode
            %         to find. It is not case sensitive. Any other string
            %         will generate an error.
            %
            % Outputs:
            %  r - The reaction rate constant in 1/s
            %
            % Example Usage:
            %  A = MetalHydride('La[1]Ni[5]');
            %  r = A.RxnRate(400, 'des');

            % Call KineticsModel to calculate reaction rate
            r = self.Kinetics.RxnRate(T,type);
        end
        
        %------------------------------------------------------------------
        function [hasEle, amount] = HasElement(self, eleStr)
            % Checks if the metal hydride has a given element (by name)
            %
            % Inputs (all inputs are required)
            %  eleStr - Element string to check for. This must be the
            %           element's abbreviated name (e.g. 'Mg' or 'La'). If
            %           the string is not a valid element name, an error is
            %           generated. Run 'Element.ListElements()' to see a
            %           list of valid elements.
            %           
            %
            % Outputs:
            %  hasEle - Logical (true/false) of whether it has the element
            %  amount - Amount of the element that it has
            %
            % Example Usage:
            %  A = MetalHydride('La[1]Ni[5]');
            %  if A.HasElement('La')
            %    [~,amt] = A.HasElement('Ni');
            %    fprintf('%s has %f Ni\n',A.Name, amt);
            %  end

            hasEle(size(self)) = false;
            amount(size(self)) = 0;
            ele = Element(eleStr);
            
            for s = 1:length(self)
                matches = find(self(s).Elements == ele);

                if ~isempty(matches)
                    amount(s) = sum([self(s).Elements(matches).Mols]);
                    hasEle(s) = true;
                end
            end
        end
        
        %------------------------------------------------------------------
        function istype = IsType(self, type)
            % Checks if the metal hydride is a given type (by name)
            %
            % Inputs (all inputs are required)
            %  type - Case insensitive string of type to check for   
            %
            % Outputs:
            %  istype - Whether the hydride is of the indicated type
            %
            % Example Usage:
            %  A = MetalHydride('La[1]Ni[5]');
            %  if A.IsType('AB5')
            %    fprintf('%s is AB5\n',A.Name);
            %  end

            istype = strcmpi({self.Type}, type);
        end      
        
        %------------------------------------------------------------------
        function dH = dH(self, arg, w)
            % Calculate the enthalpy of reaction in J/kg-H
            %
            % Inputs (arg is required, w is optional)
            %  arg -  This can either by a string that is 'abs' or 'des'
            %         to indicate which mode to find (not case sensitive)
            %         or the value of dwdt, whose sign will be used to
            %         determine whether it is absorbing or desorbing.
            %  w  -   Specific weight fraction to evaluate dH at. If
            %         omitted, this takes the average from all plateaus 
            %         weighted by the plateau width. This is only relevant
            %         for multi-plateau hydrides. This can also be an array
            %         of two values between which dH is integrated.
            %
            % Output:
            %  dH - Absolute value of the reaction enthalpy
            %
            % Example Usage:
            %  A = MetalHydride('La[1]Ni[5]');
            %  DH = A.dH('des');
            %  DH = A.dH('abs',0.01);
            %  DH = A.dH('abs',[0.005 0.01]);
            %  DH = A.dH(120.6);
            %  DH = A.dH(A.dwdt(300, 5e5, 0.5*A.wMax));
            %
            % Note:
            %  This returns the absolute value of the enthalpy, not a
            %  signed enthalpy. Whether a reaction is exothermic or
            %  endothermic depends on the direction of reaction (the sign
            %  of dwdt).

            
            switch class(arg)
                
                case {'char', 'cell'}
                    % If input argument is a string, make sure it is either
                    % 'abs' or 'des' and set 'isAbs'
                    
                    if ischar(arg)
                        arg = {arg};
                    end
                    
                    isAbs = strcmpi(arg,'abs');
                    isDes = strcmpi(arg,'des');
                    
                    if sum(isAbs) + sum(isDes) ~= length(arg)
                        error('MetalHydride:dH',...
                              ['Input field string must be either "abs"',...
                              ' or "des"']);
                    end
                    
                case 'double'
                    % If input argument is a number, assume it is dwdt and
                    % use its sign to determine type
                    isAbs = (arg>=0);
                    
                otherwise
                    % Generate an error for any other type of input
                    error('MetalHydride:dH',...
                          'First input must either be a cell/string or number');
                        
            end
            
            % Select which thermo to use
            if isAbs
                thermo = self.Thermo.Hydriding;
            else
                thermo = self.Thermo.Dehydriding;
            end
            
            % For multiple plateaus, use an inverse distance weighted
            % average if 'w' was provided, otherwise use a weighting by the
            % plateau widths.
            if length(thermo.dH) > 1 && exist('w','var')
                x = w/self.wMax;
                wgts = zeros(size(thermo.dH));
                
                if length(x) == 1
                    if x < self.Thermo.centers(1)
                        wgts(1) = 1;
                    elseif x > self.Thermo.centers(end)
                        wgts(end) = 1;
                    else
                        % There can be gaps between plateaus. If the
                        % specified value is in a gap, we have to get a
                        % valid answer still. The inverse distance weighted
                        % method accomplishes that, giving a linear
                        % weighting between the two plateau values in the
                        % gap.
                        dist = 2./self.Thermo.widths.*abs(x-self.Thermo.centers)-1;
                        dist(dist<1e-6) = 1e-6;

                        wgts = 1./dist;
                        wgts = wgts./sum(wgts);
                    end
                    
                elseif length(x) == 2
                    % If two values provided, consider it an integration
                    % between the two values
                    
                    x = sort(x);
                    xL = self.Thermo.centers-self.Thermo.widths/2;
                    xR = self.Thermo.centers+self.Thermo.widths/2;

                    for i = 1:length(thermo.dH)
                        xpts = [-2e-6 -1e-6 0 1 1+1e-6 1+2e-6 0 0];
                        ypts = [0 1 1 1 1 0 0 0];
                        
                        if i > 1
                            xMid = mean([xR(i-1), xL(i)]);
                            xSpan = max([self.Thermo.minSpans(i-1), xL(i)-xR(i-1)]);
                            xpts(3) = xMid + xSpan/2;
                            xpts(2) = xMid - xSpan/2;
                            ypts(2) = 0;
                        end

                        if i < length(thermo.dH)
                            xMid = mean([xR(i),xL(i+1)]);
                            xSpan = max([self.Thermo.minSpans(i), xL(i+1)-xR(i)]);
                            xpts(4) = xMid - xSpan/2;
                            xpts(5) = xMid + xSpan/2;
                            ypts(5) = 0;
                        end
                        
                        y = interp1(xpts(1:6),ypts(1:6),x);
                        xpts(7:8) = x;
                        ypts(7:8) = y;

                        [~,idx] = unique(xpts);
                        xpts = xpts(idx);
                        ypts = ypts(idx);

                        idx = xpts>=x(1) & xpts<=x(2);
                        xpts = xpts(idx);
                        ypts = ypts(idx);

                        wgts(i) = trapz(xpts,ypts);
                    end

                    wgts = wgts./(x(2)-x(1));
                else
                    error('MetalHydride:dH',...
                          'w vector is too long');
                end
            else
                wgts = self.Thermo.widths ./ sum(self.Thermo.widths);
            end

            % Stored dH values are in J/mol-H2, convert to J/kg-H (note
            % that J/kg-H is the same as J/kg-H2)
            dH = abs(sum(thermo.dH.*wgts).*1000./2.016);
        end
                   
        %------------------------------------------------------------------
        function slope = get.Slope(self)
            % Get the slope property
            if isnan(self)
                slope = [];
            else
                slope = self.Thermo.Dehydriding.A./(8.314*298);
            end
        end
        
        %------------------------------------------------------------------
        function rho = get.rho(self)
            % Return the hydride density
            if isnan(self)
                rho = [];
            else
                rho = self.Props.rho;
            end
        end
        
        %------------------------------------------------------------------
        function kEff = get.kEff(self)
            % Return the hydride powder effective thermal conductivity
            if isnan(self)
                kEff = [];
            else
                
                kEff = self.Props.kEff;
            end
        end

        %------------------------------------------------------------------
        function rhoCp = rhoCp(self, w) 
            % Returns the hydride thermal mass in J/(m^3*K)
            % 
            % Input (optional):
            %  w - Current hydrogen weight fraction (Assumes 0 if omitted)
            %
            % Output:
            %  rhoCp - The thermal mass in J/(m^3*K)
            %
            % Example Usage:
            %  A = MetalHydride('La[1]Ni[5]');
            %  rhoCp = A.rhoCp;
            %  rhoCp = A.rhoCp(A.wMax);
            
            if ~exist('w','var')
                w = 0;
            end
            
            props = [self.Props];
            rhoCp = [props.rho] .* self.Cp(w);
        end
        
        %------------------------------------------------------------------
        function Cp = Cp(self, w) 
            % Returns the hydride specific heat in J/(kg*K)
            % 
            % Input (optional):
            %  w - Current hydrogen weight fraction (Assumes 0 if omitted)
            %
            % Output:
            %  Cp - The specific heat capacity in J/(kg*K)
            %
            % Example Usage:
            %  A = MetalHydride('La[1]Ni[5]');
            %  Cp = A.Cp;
            %  Cp = A.Cp(A.wMax);
            %
            % This uses the relationship between hydrogen content
            % and heat capacity measured by Dadson and Fluckiger and
            % supported by the Debye model, which is:
            %
            %  Cp = Cp_metal*(1 + N*w/wMax)
            
            if ~exist('w','var')
                F = 0;
            else
                F = w ./ [self.wMax];
            end
            
            props = [self.Props];
            Cp = [props.Cp].*(1 + F.*[self.HM]);
        end
        
        %------------------------------------------------------------------
        function disp(self)
            % Displays the hydride Name property
            disp({self.Name}');
        end
        
        %------------------------------------------------------------------
        function in = isnan(self)
            % Checks for Null or NaN hydrides (not linked to an mh file)
            in = strcmp({self.Name},'');
        end
        
        %------------------------------------------------------------------
        function iseq = eq(mh1, mh2)
            % Check of two hydrides are the same based on their name
            % This overloads the '==' operator so you can do a logical test
            % of (if A and B are hydrides). Either argument can be a
            % MetalHydride, a string, or a cell.
            %
            % if A == B
            %   do stuff
            % end
            %
            % if A == 'LaNi5'
            %   do stuff
            % end
            
            if isa(mh1,'MetalHydride')
                mh1CellStr = {mh1.Name};
            elseif ischar(mh1) || iscell(mh1)
                mh1CellStr = mh1;
            else
                error('MetalHydride:eq',...
                    'Cannot compare MetalHydride to object of class "%s"',...
                    class(mh1));
            end
            
            if isa(mh2,'MetalHydride')
                mh2CellStr = {mh2.Name};
            elseif ischar(mh2) || iscell(mh2)
                mh2CellStr = mh2;
            else
                error('MetalHydride:eq',...
                    'Cannot compare MetalHydride to object of class "%s"',...
                    class(mh2));
            end
            
            iseq = strcmp(mh1CellStr, mh2CellStr);
        end
        
        %------------------------------------------------------------------
        function noteq = ne(mh1, mh2)
            % Check of two hydrides are not the same based on their name
            % This overloads the '~=' operator so you can do a logical test
            % of (if A and B are hydrides)
            %
            % if A ~= B
            %   do stuff
            % end
            %
            % if A ~= 'LaNi5'
            %   do stuff
            % end
            
            noteq = ~(mh1 == mh2);
        end
        
        %------------------------------------------------------------------
        function emp = empty(self)
            % Checks if a hydride is empty (the same as isnan)
            emp = strcmp({self.Name},'');
        end
        
        %------------------------------------------------------------------
        function str = char(self)
            % Converts the hydride to a string (e.g. 'LaNi5')
            % Calling char(A) is the same as calling A.Name
            str = {self.Name};
        end
        
        %------------------------------------------------------------------
        function reflist = get.RefList(self)
            if isnan(self)
                reflist = {};
            else
                refNames = fieldnames(self.Refs);
                reflist = cell(length(refNames),1);
                for r = 1:length(refNames)
                    reflist{r} = self.Refs.(refNames{r}).Citation;
                end
            end
        end
        
        %------------------------------------------------------------------
        function hysteresis = get.Hysteresis(self)
            if isnan(self)
                hysteresis = [];
            else
                hysteresis = ((self.Thermo.Hydriding.dH - ...
                    self.Thermo.Dehydriding.dH)./298 - ...
                    self.Thermo.Hydriding.dS + ...
                    self.Thermo.Dehydriding.dS)./8.314;
            end
        end
        
        %------------------------------------------------------------------
        function level = get.ThermoLevel(self)
            if isnan(self)
                level = [];
            else
                level = min(self.Thermo.Level);
            end
        end
        
        %------------------------------------------------------------------
        function assumed = get.TcAssumed(self)
            if isnan(self)
                assumed = [];
            else
                assumed = any(self.Thermo.TcAssumed);
            end
        end
        
        %------------------------------------------------------------------
        function assumed = get.SlopeAssumed(self)
            if isnan(self)
                assumed = [];
            else
                assumed = any(self.Thermo.SlopeAssumed);
            end
        end
        
        %------------------------------------------------------------------
        function np = get.NumPlateaus(self)
            if isnan(self)
                np = [];
            else
                np = length(self.Thermo.Dehydriding.dH);
            end
        end
        
        %------------------------------------------------------------------
        function assumed = get.HysteresisAssumed(self)
            if isnan(self)
                assumed = [];
            else
                assumed = any(self.Thermo.HysteresisAssumed);
            end
        end
        
        %------------------------------------------------------------------
        function assumed = get.AbsKineticsAssumed(self)
            if isnan(self)
                assumed = [];
            else
                assumed = self.Kinetics.Hydriding.Assumed;
            end
        end
        
        %------------------------------------------------------------------
        function assumed = get.DesKineticsAssumed(self)
            if isnan(self)
                assumed = [];
            else
                assumed = self.Kinetics.Dehydriding.Assumed;
            end
        end
        
        %------------------------------------------------------------------
        function assumed = get.kEffAssumed(self)
            if isnan(self)
                assumed = [];
            else
                assumed = self.Props.kEffAssumed;
            end
        end
        
        %------------------------------------------------------------------
        function assumed = get.rhoAssumed(self)
            if isnan(self)
                assumed = [];
            else
                assumed = self.Props.rhoAssumed;
            end
        end
        
        %------------------------------------------------------------------
        function assumed = get.CpAssumed(self)
            if isnan(self)
                assumed = [];
            else
                assumed = self.Props.CpAssumed;
            end
        end
        
        %------------------------------------------------------------------
        function fromIsotherms = get.AbsFromIsotherms(self)
            if isnan(self)
                fromIsotherms = [];
            else
                fromIsotherms = self.Thermo.Hydriding.FromIsotherms;
            end
        end
        
        %------------------------------------------------------------------
        function fromIsotherms = get.DesFromIsotherms(self)
            if isnan(self)
                fromIsotherms = [];
            else
                fromIsotherms = self.Thermo.Dehydriding.FromIsotherms;
            end
        end
        
        %------------------------------------------------------------------
        function simFactor = SimilarTo(self,other)
            % Determines if a hydride is of similar composition to another
            %
            % This determines a similarity score based on the difference in
            % elemental composition between the hydrides
            
            simFactor = Element.CompareAlloys(self.Elements,other.Elements);
        end
        
        %------------------------------------------------------------------
        function Evaluate(self, makePlots)
            % Runs tests on a given hydride to check its functions
            %
            % This can be called on an array of hydrides to test each
            % hydride in the array, or on a single hydride. I do not
            % recommend setting makePlots to true when calling on the
            % entire hydride database, since that will generate more than
            % 650 figures. However, running with plotting on can be useful
            % for looking a single problematic hydride or a small group of
            % them.
            
            if ~exist('makePlots','var')
                makePlots = false;
            end
            
            for i = 1:length(self)
                % Call the basic functions and make sure none are 'NaN' or
                % 'Inf'
                dwdt = self(i).dwdt(300,5e5,0);
                dH = self(i).dH('des');
                PeqA = self(i).Peq(300,0.5*self(i).wMax,'abs');
                PeqD = self(i).Peq(300,0.5*self(i).wMax,'des');
                rhoCp = self(i).rhoCp;

                if isnan(dwdt) || isinf(dwdt) || ...
                   isnan(dH) || isinf(dH) || ...
                   isnan(PeqA) || isinf(PeqA) || ...
                   isnan(PeqD) || isinf(PeqD) || ...
                   isnan(rhoCp) || isinf(rhoCp)

                    error('MetalHydride:Evaluate',...
                          'Metal hydride %s failed function test',...
                          self(i).Name);
                end
                
                if PeqD > PeqA
                    error('MetalHydride:Evaluate',...
                          ['Metal hydride %s has desorption equilibrium',...
                          ' greater than absorption'],...
                          self(i).Name);
                end
                
                % Isothermal reaction at 300 K
                T = 300;
                P = 4*self(i).Peq(T,self(i).wMax*0.5,'abs');
                [t,w] = ode15s(@(t,w) self(i).dwdt(T,P,w),[0 10],0);
                
                % Plot the hydrides
                if makePlots
                    self(i).plot();

                    figure;
                    plot(t,w)
                end
                
                % Check for exact elemental duplicates. This could occur if
                % you listed TiFeCr and TiCrFe in the database as separate
                % hydrides
                if length(self) > 1
                    for j = i+1:length(self)
                        if self(i).SimilarTo(self(j)) == 0
                            error('MetalHydride:Evaluate',...
                                  ['Database has two elementally ',...
                                  'identical hydrides in different ',...
                                  'entries (%s and %s)'],...
                                  self(i).Name, self(j).Name);
                        end
                    end
                end
                
            end
        end
        
        %------------------------------------------------------------------
        function hFig = plot(self,Trange,Nlines)
            % Make a plot of the metal hydride (PCI and Van't Hoff plot)
            %
            % Inputs (optional):
            %   Trange - Array of two elements for range of temperatures to
            %            plot (defaults to [300 420])
            %   Nlines - Number of isotherms to plot in temperature range
            %            (defaults to 7 lines)
            %
            % Output:
            %  hFig - Figure handle things are plotted on
            %
            % Example Usage:
            %  A = MetalHydride('La[1]Ni[5]');
            %  A.plot();
            %  hF = A.plot([300 600],12);

            if ~exist('Trange','var')
                Trange = [300, 420];
            end
            
            if ~exist('Nlines','var')
                Nlines = 7;
            end
            
            T = linspace(Trange(1),Trange(2),Nlines);
            colors = jet(Nlines);
            w = linspace(0.02*self.wMax,0.98*self.wMax,50);
        
            hFig = figure;
            set(hFig,'Units','inches','Position',[2 2 7 4]);
        
            subplot(1,2,1);
            hold on
            title(self.FormattedName)
            h = zeros(size(T));
            for t = 1:length(T)
                h(t) = plot(w.*100,self.Peq(T(t),w,'abs')./1e5,...
                            'Line','-',...
                            'Color',colors(t,:),...
                            'LineWidth',2,...
                            'DisplayName',sprintf('%3.0f K',T(t)));
                        
                plot(w.*100,self.Peq(T(t),w,'des')./1e5,'Line','--',...
                     'Color',colors(t,:),'LineWidth',2);
            end
            lh = legend(h,'Location','NorthWest');
            set(lh,'Box','off');
            ylabel('P (bar)');
            xlabel('w_H / w_M (%)');
            xlim([0 self.wMax*100])
            set(gca,'Box','on','LineWidth',1,'YScale','log');
            
            subplot(1,2,2);
            hold on

            T = 270:2:700;
            PeqA = zeros(size(T));
            PeqD = PeqA;
            for t = 1:length(T)
                PeqA(t) = self.Peq(T(t),0.5*self.wMax,'abs')./1e5;
                PeqD(t) = self.Peq(T(t),0.5*self.wMax,'des')./1e5;
            end
            plot(1000./T, PeqA, '-k','LineWidth',2);
            plot(1000./T, PeqD, '--k','LineWidth',2);
            plot(1000./self.Tc, self.Pc./1e5,'ok','MarkerFaceColor','k');
            set(gca,'Box','on','LineWidth',1,'YScale','log');
            lh = legend('Absorption','Desorption','Critical Point');
            set(lh,'Location','NorthEast','Box','off')
            ylabel('P (bar)');
            xlabel('1000/T (1/K)');

            %Write dH and dS values on plot
            Tlim = get(gca,'XLim');
            Plim = get(gca,'YLim');

            Tmin = Tlim(1);
            Plim10 = log10(Plim);
            span = Plim10(2) - Plim10(1);

            text(Tmin+0.1,10^(Plim10(1)+0.29*span),...
                ['\DeltaH_{des} = ',...
                num2str(self.Thermo.Dehydriding.dH/1000,'%3.1f kJ/mol')]);
            text(Tmin+0.1,10^(Plim10(1)+0.22*span),...
                ['\DeltaS_{des} = ',...
                num2str(self.Thermo.Dehydriding.dS,'%3.1f J/mol.K')]);

            text(Tmin+0.1,10^(Plim10(1)+0.12*span),...
                ['\DeltaH_{abs} = ',...
                num2str(self.Thermo.Hydriding.dH/1000,'%3.1f kJ/mol')]);
            text(Tmin+0.1,10^(Plim10(1)+0.05*span),...
                ['\DeltaS_{abs} = ',...
                num2str(self.Thermo.Hydriding.dS,'%3.1f J/mol.K')]);
        end
        
    end %end methods
end %end class
