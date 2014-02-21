function thermo = ReadThermo(thermoStruct, elements, name, type)
    % Read the thermodynamic entries from the mh file and save in a structure
    %
    
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
    
    lines = thermoStruct.entryLines;
    thermo = struct('TcAssumed',false,...
                    'HysteresisAssumed',false,...
                    'SlopeAssumed',false,...
                    'Level',0);
                
    % Declare constants
    R = 8.314; %J/mol.K
    Tref = 298; %K

    %---------------------------------------------------------------------
    % Determine hydride capacity
    if MetalHydride.FoundEntry(lines,'weight percent')
        
        %Read weight percent directly
        thermo.WtPct = MetalHydride.ReadNumber(lines,'weight percent')/100;

    elseif MetalHydride.FoundEntry(lines,'H/M')
        
        %Calculate weight percent from provided H/M
        HM = MetalHydride.ReadNumber(lines,'H/M');
        WM = sum([elements.Mols].*[elements.W]);
        thermo.WtPct = HM*1.008 / (HM*1.008 + WM);
        
    else
        % Return an error if the capacity is not provided
        error('ReadThermo:WeightPercent',...
              'Hydride capacity not provided');
    end
    

    %---------------------------------------------------------------------
    %Load dehydriding thermodynamics (DH, DS, and optionally slope)
    if isfield(thermoStruct.subDicts,'Dehydriding')
        thermo.Dehydriding = struct();
        lines = thermoStruct.subDicts.Dehydriding.entryLines;
        
        % Check if the dehydriding values are from an isotherm
        if MetalHydride.FoundEntry(lines,'From Isotherms')
            thermo.Dehydriding.FromIsotherms = strcmpi(...
                MetalHydride.ReadString(lines,'From Isotherms'),'true');
        else
            thermo.Dehydriding.FromIsotherms = false;
        end
        
        % Get main thermo parameters (dH and dS)
        % For dehydriding, you must provide dH and dS
        if MetalHydride.FoundEntries(lines,{'DH','DS'})

            % Read dH and dS. Entries here for dH and dS can be single
            % values or an array of values for multiple plateaus
            thermo.Dehydriding.dH = MetalHydride.ReadNumber(lines,'DH');
            thermo.Dehydriding.dS = MetalHydride.ReadNumber(lines,'DS');
            
            basis = ones(size(thermo.Dehydriding.dH));
            
            % Read plateau center, width, and min joiner function span. 
            % These must be entered if there are multiple plateaus. 
            % They default to 0.5, 1, and [] for single
            % plateaus if not entered
            if MetalHydride.FoundEntries(lines,{'centers','widths','minSpans'})
                
                thermo.centers = MetalHydride.ReadNumber(lines,'centers');
                thermo.widths = MetalHydride.ReadNumber(lines,'widths');
                thermo.minSpans = MetalHydride.ReadNumber(lines,'minSpans');
                
            elseif length(basis) > 1
                error('MetalHydride:ReadThermo',...
                      ['Incomplete dehydriding thermodynamics ',...
                      '(multi-plateau thermodynamics require plateau ',...
                      'center and width entries)']);
            else
                thermo.centers = 0.5;
                thermo.widths = 1;
                thermo.minSpans = [];
            end
            
            % Check that centers and widths are valid
            if min(thermo.centers - thermo.widths/2) < 0 || ...
                   max(thermo.centers + thermo.widths/2) > 1
               error('MetalHydride:ReadThermo',...
                      'Listed centers and widths lie outside 0 to 1');
            end
            
            if length(basis) > 1
                if any(thermo.minSpans/2 > thermo.widths(1:end-1)/2) || ...
                   any(thermo.minSpans/2 > thermo.widths(2:end)/2)

                    error('MetalHydride:ReadThermo',...
                          ['Listed minimum spans are too wide ',...
                          'relative to plateau widths']);
                end
            end
            
            % Check that all entries are the proper length
            if length(basis) ~= length(thermo.Dehydriding.dS) || ...
               length(basis) ~= length(thermo.centers) || ...
               length(basis) ~= length(thermo.widths) || ...
               length(basis)-1 ~= length(thermo.minSpans)
                
                error('MetalHydride:ReadThermo',...
                      ['Incomplete dehydriding thermodynamics ',...
                      '(some entries are not the same size)']);
            end
            
        else
            error('MetalHydride:ReadThermo',...
                  ['Incomplete dehydriding thermodynamics ',...
                   '(DH and DS are both required)']);
        end
        
        % Check if plateau slope is given
        if MetalHydride.FoundEntry(lines,'slope')
            
            % Check if the slope temperature is present, otherwise use Tref
            if MetalHydride.FoundEntry(lines,'Ts')
                Ts = MetalHydride.ReadNumber(lines,'Ts').*basis;
            else
                Ts = Tref.*basis;
            end

            thermo.Dehydriding.A = ...
                MetalHydride.ReadNumber(lines,'slope').*R.*Ts;
            
            % Set NaNs to default value. Even though this means some
            % defaults were used, we will treat this as slope not being
            % assumed, since this is only the case in multiplateau
            % hydrides, which almost always come from an isotherm anyway.
            thermo.Dehydriding.A(isnan(thermo.Dehydriding.A)) = ...
                MetalHydride.GetTypeProperty('Slope',type)*R*Tref;
        else 
            thermo.Dehydriding.A = ...
                MetalHydride.GetTypeProperty('Slope',type)*R*Tref*basis;
            thermo.SlopeAssumed = true;
        end

    else
        error('MetalHydride:ReadThermo',...
              'Dehydriding thermodynamics section missing');
    end

    %---------------------------------------------------------------------
    % Read hydriding entries. First check if anything is entered at all,
    % if not assume no hysteresis
    if isfield(thermoStruct.subDicts,'Hydriding')
        thermo.Hydriding = struct();
        lines = thermoStruct.subDicts.Hydriding.entryLines;
        
        % Check if the dehydriding values are from an isotherm
        if MetalHydride.FoundEntry(lines,'From Isotherms')
            thermo.Hydriding.FromIsotherms = strcmpi(...
                MetalHydride.ReadString(lines,'From Isotherms'),'true');
        else
            thermo.Hydriding.FromIsotherms = false;
        end
        
        % Hydriding plateau slope must be the same as dehydriding to ensure
        % that Peq_abs > Peq_des for all conditions
        thermo.Hydriding.A = thermo.Dehydriding.A;
            
        % Update Tc unless the assumed Tc was used in calculating DH
        % and DS or Tc was entered directly
        updateTc = true.*basis;

        % Build data matrix of NaNs
        data = NaN.*ones(length(basis),4);
        
        % Populate data matrix with any provided numbers
        if MetalHydride.FoundEntry(lines,'Tc')
            data(:,1) = MetalHydride.ReadNumber(lines,'Tc');
        end
        
        if MetalHydride.FoundEntry(lines,'ln(Pa/Pd)')
            data(:,2) = MetalHydride.ReadNumber(lines,'ln(Pa/Pd)');
        end
        
        if MetalHydride.FoundEntry(lines,'DH')
            data(:,3) = MetalHydride.ReadNumber(lines,'DH');
        end
        
        if MetalHydride.FoundEntry(lines,'DS')
            data(:,4) = MetalHydride.ReadNumber(lines,'DS');
        end
        
        % Check what information is provided     
        Nd = sum(~isnan(data),2);
        
        % If more than 2 entries are present, thermodynamics are
        % over-specified, otherwise set the thermo level. Level 2
        % thermodynamics are fully specified, Level 1 are partially
        % specified, and Level 0 are completely assumed. The thermo level
        % can be different for each plateau
        if any(Nd > 2)
            error('MetalHydride:ReadThermo',...
                  'Hydriding thermodynamics are over-specified for %s',...
                  name);
        else
            thermo.Level = min(Nd);
        end
        
        % Generate a unique ID number for each possible combination of data
        % for each plateau
        ID = sum(~isnan(data).*2.^repmat(3:-1:0,length(basis),1),2); 
        
        % Get Tc and Hysteresis, using default values if not found. This
        % replaces the 'NaN' entries in the data matrix with the defaults
        
        % Record which plateaus had ln(Pa/Pd)
        thermo.HysteresisAssumed = isnan(data(:,2));
        
        % Replace NaN entries in column 2 with default ln(Pa/Pd)
        data(repmat(1:4,length(basis),1)==2 & isnan(data)) = ...
            MetalHydride.GetTypeProperty('Hysteresis',type);

        % Set/get hysteresis temperature
        if MetalHydride.FoundEntry(lines,'T')
            T = MetalHydride.ReadNumber(lines,'T').*basis;
        else
            T = Tref.*basis;
        end

        % See which plateaus had Tc
        thermo.TcAssumed = isnan(data(:,1));
        
        % Replace NaN entries in column 1 with default Tc
        data(repmat(1:4,length(basis),1)==1 & isnan(data)) = ...
            MetalHydride.GetTypeProperty('Tc',type);

        % Initialize dH, dS, and Tc from data matrix (may be NaN)
        thermo.Hydriding.dH = data(:,3);
        thermo.Hydriding.dS = data(:,4);
        thermo.Tc = data(:,1);
        
        % Select calculation method based on what data is available for
        % each plateau
        for p = 1:length(basis)
            
            switch ID(p)
                case 3 % has dH and dS (update Tc)
                    thermo.HysteresisAssumed(p) = false;

                case {6 2} % has dH and ln(Pa/Pd) or just dH (update Tc)

                    % calculate dS
                    thermo.Hydriding.dS(p) = thermo.Dehydriding.dS(p) + ...
                        (thermo.Hydriding.dH(p)-thermo.Dehydriding.dH(p))/T(p) - R*data(p,2);

                case {5 1} % has dS and ln(Pa/Pd) or just dS (update Tc)

                    % calculate dH
                    thermo.Hydriding.dH(p) = thermo.Dehydriding.dH(p) + ...
                        T(p)*(R*data(p,2) + thermo.Hydriding.dS(p) - thermo.Dehydriding.dS(p));

                case 10 % has dH and Tc (do not update Tc)
                    
                    % calculate dS
                    thermo.Hydriding.dS(p) = thermo.Dehydriding.dS(p) + ...
                        (thermo.Hydriding.dH(p)-thermo.Dehydriding.dH(p))/thermo.Tc(p);

                case 9 % has dS and Tc (do not update Tc)

                    % calculate dH
                    thermo.Hydriding.dH(p) = thermo.Dehydriding.dH(p) + ...
                        thermo.Tc(p)*(thermo.Hydriding.dS(p) - thermo.Dehydriding.dS(p));

                case {12 8 4 0} % has Tc and ln(Pa/Pd), just Tc, just ln(Pa/Pd), or neither
                    updateTc(p) = false;

                    %Calculate dH and dS from hysteresis at T
                    % A value for ln(Pa/Pd) at a given temperature is not enough
                    % to get both dH AND dS, so we use the critical temperature
                    % Tc as the second point, which by definition has 
                    % ln(Pa/Pd) = 0
                    thermo.Hydriding.dH(p) = thermo.Dehydriding.dH(p) + ...
                        R*data(p,2)/(1/T(p) - 1/thermo.Tc(p));

                    thermo.Hydriding.dS(p) = thermo.Dehydriding.dS(p) + ...
                        (thermo.Hydriding.dH(p)-thermo.Dehydriding.dH(p))/thermo.Tc(p);

                otherwise
                    error('MetalHydride:ReadThermo',...
                          'Could not interpret hydriding thermodynamics for %s',...
                          name);
            end
        
            % Update the critical temperature if possible
            if updateTc(p) && thermo.TcAssumed(p)
                if thermo.Hydriding.dS(p) == thermo.Dehydriding.dS(p) 
                    % Warn and do not update Tc if dS_abs == dS_des
                    warning('MetalHydride:ReadThermo',...
                            ['Absorption and desorption thermo have equal',...
                             ' dS, Tc cannot be calculated for %s'],name)
                else

                    % Update Tc based on hydriding dH and dS
                    thermo.Tc(p) = (thermo.Hydriding.dH(p) - thermo.Dehydriding.dH(p))/...
                        (thermo.Hydriding.dS(p) - thermo.Dehydriding.dS(p));
                    thermo.TcAssumed(p) = false;

                    % Check for unusually low values of Tc and warn
                    if thermo.Tc(p) < 150 || thermo.Tc(p) > 2000
                        warning('MetalHydride:ReadThermo',...
                                'Calculated Tc (%4.1f K) is very low or high for %s',...
                                thermo.Tc,name)
                    end
                end
            end
            
        end % end plateau loop
        
    else
        % Use completely assumed hydriding thermo based on type
        lnPaPd = MetalHydride.GetTypeProperty('Hysteresis',type).*basis;
        thermo.HysteresisAssumed = true.*basis;
        
        thermo.Tc = MetalHydride.GetTypeProperty('Tc',type).*basis;
        thermo.TcAssumed = true.*basis;
            
        thermo.Hydriding.dH = thermo.Dehydriding.dH + ...
            R.*lnPaPd./(1./Tref - 1./thermo.Tc);

        thermo.Hydriding.dS = thermo.Dehydriding.dS + ...
            (thermo.Hydriding.dH-thermo.Dehydriding.dH)./thermo.Tc;
        
        thermo.Hydriding.A = thermo.Dehydriding.A;
        thermo.Hydriding.FromIsotherms = false;
    end
    
    % Calculate regular solution energy from Tc
    thermo.Omega = 2.*R.*thermo.Tc;
end