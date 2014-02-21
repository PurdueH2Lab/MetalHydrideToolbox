function PrintStats()
    % Prints database statistics to the command window
    %
    % This function loads the entire database and prints some statistics
    % about what is present in the database
    %
    % Inputs:
    %  None
    %
    % Output:
    %  None
    %
    % Example Usage:
    %   MetalHydride.PrintStats();
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
    
    % Load the entire database
    hydrides = MetalHydride.LoadDatabase();
    
    % Extract information from hydride array
    N = length(hydrides);
    NabsKin = sum(~[hydrides.AbsKineticsAssumed]);
    NdesKin = sum(~[hydrides.DesKineticsAssumed]);
    NfullThermo = sum([hydrides.ThermoLevel] == 2);
    NpartialThermo = sum([hydrides.ThermoLevel] == 1);
    NnoHydThermo = sum([hydrides.ThermoLevel] == 0);
    
    % Get type information
    types = {hydrides.Type};
    utypes = unique(types);
    ntypes = cellfun(@(x) sum(strcmpi(types,x)), utypes);
    
    % See how many references need to be verified
    Nver = 0;
    for i = 1:length(hydrides)
        refnames = fieldnames(hydrides(i).Refs);
        for r = 1:length(refnames)
            sf = strfind(hydrides(i).Refs.(refnames{r}).ID,'SandiaDBRef');
            if ~isempty(sf)
                Nver = Nver + 1;
                break
            end
        end
    end
    
    
    % Write the stats to the command window
    fprintf('+%s+\n','-'*ones(1,78));
    fprintf('| Metal Hydride MATLAB Toolbox Database Summary %s |\n',...
            ' '*ones(1,30));
    fprintf('+%s+\n','-'*ones(1,78));
    
    fprintf('\nTotal Hydrides: %d\n',N);
    
    fprintf('\n- Types %s\n','-'*ones(1,72));
    for i = 1:length(utypes)
        fprintf('    %-9s %-3d hydrides\n',utypes{i}, ntypes(i));
    end
    
    fprintf('\n- Thermodynamics %s\n','-'*ones(1,63));
    fprintf('    Full thermodynamics          %3d (two entries for hydriding)\n',NfullThermo);
    fprintf('    Partial thermodynamics       %3d (one entry for hydriding)\n',NpartialThermo);
    fprintf('    No hydriding thermodynamics  %3d (no entries for hydriding)\n',NnoHydThermo);
     
    fprintf('\n- Thermophysical Properties %s\n','-'*ones(1,52));
    fprintf('    Thermal Conductivity %3d hydrides\n',sum(~[hydrides.kEffAssumed]));
    fprintf('    Specific Heat        %3d hydrides\n',sum(~[hydrides.CpAssumed]));
    fprintf('    Density              %3d hydrides\n',sum(~[hydrides.rhoAssumed]));
    
    fprintf('\n- Kinetics %s\n','-'*ones(1,69));
    fprintf('    Hydriding kinetics   %3d hydrides\n',NabsKin);
    fprintf('    Dehydriding kinetics %3d hydrides\n',NdesKin);
    
    fprintf('\n- References %s\n','-'*ones(1,67));
    fprintf('    Number Verified      %3d hydrides\n',N-Nver);
    
    fprintf('\n%s\n','-'*ones(1,80));
    
    
