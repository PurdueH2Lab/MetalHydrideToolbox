function WriteExcelSummary()
    % Writes a summary of the database to an excel sheet and generates a reference list
    %
    % This function loads the entire database and writes it to an excel
    % file. Each unique reference is numbered sequentially and written to a
    % references text file. Assumed properties are not written to the excel
    % spreadsheet, so the spreadsheet contains only direct input numbers.
    %
    % Inputs:
    %  None
    %
    % Output:
    %  None (produces two files in the 'doc' folder)
    %
    % Example Usage:
    %   MetalHydride.WriteDatabase();
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
    
    [~,~,~,docPath] = MetalHydride.GetPaths();
    
    hydrides = MetalHydride.LoadDatabase();
    
    c = cell(length(hydrides)+1,5);
    hr = 1;

    % Write the column headers
    c{1,1} = 'Name';
    c{1,2} = 'Type';
    c{1,3} = 'Properties';
    c{1,4} = ['Hydriding',char(10),'Thermo'];
    c{1,5} = ['Hydriding',char(10),'Kinetics'];
    c{1,6} = ['Dehydriding',char(10),'Thermo'];
    c{1,7} = ['Dehydriding',char(10),'Kinetics'];
    c{1,8} = 'Refs';
    c{1,9} = 'Verified?';
    
    refs = Reference();
    rid = 1;
    
    for i = 1:length(hydrides)
        H = hydrides(i);
        col = 1;
        
        %------------------------------------------------------------------
        % Name
        c{i+hr,col} = H.Name;
        col = col + 1;
        
        %------------------------------------------------------------------
        % Type
        c{i+hr,col} = H.Type;
        col = col + 1;
        
        %------------------------------------------------------------------
        % Properties
        propStr = ['wtpct = ',num2str(H.Thermo.WtPct*100,'%4.2f')];
        
        if ~H.Thermo.TcAssumed
            propStr = [propStr,...
                       char(10),...
                       'Tc = ',MakeString(H.Thermo.Tc,'%4.1f')]; %#ok<AGROW>
        end
        
        % TODO add center and width
        
        if ~H.Props.kEffAssumed
            propStr = [propStr,...
                       char(10),...
                       'kEff = ',num2str(H.Props.kEff,'%4.2f')];%#ok<AGROW>
        end
        
        if ~H.Props.CpAssumed
            propStr = [propStr,...
                       char(10),...
                       'Cp = ',num2str(H.Props.Cp,'%4.0f')]; %#ok<AGROW>
        end
        
        if ~H.Props.rhoAssumed
            propStr = [propStr,...
                       char(10),...
                       'rho = ',num2str(H.Props.rho,'%4.0f')]; %#ok<AGROW>
        end

        c{i+hr,col} = propStr;
        col = col + 1;
        
        %------------------------------------------------------------------
        % Thermo
        
        % Hydriding
        switch H.ThermoLevel
            case 0
                thermoStr = 'Default';
            case 1
                if all(~H.HysteresisAssumed) && length(H.HysteresisAssumed) == 1
                    thermoStr = ['LP = ',num2str(H.Hysteresis,'%5.3f')];
                else
                    % if hysteresis was assumed, then one of dH, dS, or
                    % Tc was provided. Tc can be determined, but no way
                    % to distinguish whether dH or dS was the one
                    % provided.
                    thermoStr = ['dH = ',MakeString(H.Thermo.Hydriding.dH,'%6.0f'),'*',...
                                 char(10),...
                                 'dS = ',MakeString(H.Thermo.Hydriding.dS,'%6.2f'),'*'];
                end
            otherwise
                thermoStr = ['dH = ',MakeString(H.Thermo.Hydriding.dH,'%6.0f'),...
                             char(10),...
                             'dS = ',MakeString(H.Thermo.Hydriding.dS,'%6.2f')];
        end

        c{i+hr,col} = thermoStr;
        
        
        % Dehydriding
        thermoStr = ['dH = ',MakeString(H.Thermo.Dehydriding.dH,'%6.0f'),...
                     char(10),...
                     'dS = ',MakeString(H.Thermo.Dehydriding.dS,'%6.2f')];
                     
        if any(~H.Thermo.SlopeAssumed)
            thermoStr = [thermoStr,...
                         char(10),...
                         'A = ',MakeString(H.Thermo.Dehydriding.A,'%6.2f')]; %#ok<AGROW>
        else
            
        end
        
        c{i+hr,col+2} = thermoStr;
        col = col + 1;
        
        %------------------------------------------------------------------
        % Kinetics
        if H.Kinetics.Hydriding.Assumed
            c{i+hr,col} = 'Default';
        else
            c{i+hr,col} = ['Ca = ',num2str(H.Kinetics.Hydriding.Ca,'%5.1f'),...
                         char(10),...
                         'Ea = ',num2str(H.Kinetics.Hydriding.Ea,'%5.0f'),...
                         char(10),...
                         'Pfcn = ',H.Kinetics.pFcnName('abs'),...
                         char(10),...
                         'Wfcn = ',H.Kinetics.wFcnName('abs')];
        end
        
        if H.Kinetics.Dehydriding.Assumed
            c{i+hr,col+2} = 'Default';
        else
            c{i+hr,col+2} = ['Ca = ',num2str(H.Kinetics.Dehydriding.Ca,'%5.1f'),...
                         char(10),...
                         'Ea = ',num2str(H.Kinetics.Dehydriding.Ea,'%5.0f'),...
                         char(10),...
                         'Pfcn = ',H.Kinetics.pFcnName('des'),...
                         char(10),...
                         'Wfcn = ',H.Kinetics.wFcnName('des')];
        end
        
        col = col + 3;
        
        %------------------------------------------------------------------
        % References
        refnames = fieldnames(H.Refs);
        refnums = zeros(size(refnames));
        hasSandiaRefs = false;
        for r = 1:length(refnames)
            R = H.Refs.(refnames{r});
            
            sf = strfind(R.ID,'SandiaDBRef');
            if ~isempty(sf)
                hasSandiaRefs = true;
            end

            % See if this reference is in the refs array already
            refID = find(refs(1:rid-1)==R,1,'first');

            % If reference is not in the list, add it to the refs array
            if isempty(refID)
                refID = rid;
                refs(rid) = R;
                rid = rid + 1;
            end

            refnums(r) = refID;
        end
        refStr = sprintf('%d, ', sort(refnums));
        c{i+hr,col} = refStr(1:end-2);
        col = col + 1;
        
        % write if references are verified
        if hasSandiaRefs
            c{i+hr,col} = 'NO';
        else
            c{i+hr,col} = '';
        end
    end
    
    % Get value defaults to write to summary spreadsheet
    props = {'Tc',...
             'Slope',...
             'Hysteresis',...
             'Ca Hydriding',...
             'Ea Hydriding',...
             'Ca Dehydriding',...
             'Ea Dehydriding',...
             'kEff',...
             'Cp',...
             'rho'};
    units = {'(K)',...
             '(ln(P)/(w/w_max))',...
             '(ln(Pa/Pd))',...
             '(1/s)',...
             '(J/mol)',...
             '(1/s)',...
             '(J/mol)',...
             '(W/m-K)',...
             '(J/kg-K)',...
             '(kg/m3)'};
    
    types = unique({hydrides.Type})';
    cD = cell(length(types)+1,length(props)+1);
    cD{1,1} = 'Type';
    
    for i = 1:length(types)
        cD{i+1,1} = types{i};
        for j = 1:length(props)
            cD{1,j+1} = [props{j},char(10),units{j}];
            cD{i+1,j+1} = MetalHydride.GetTypeProperty(props{j},types{i});
        end
    end
    
    % Write references to a text file
    fRefs = fopen(fullfile(docPath,'refs.txt'),'w');
    fprintf(fRefs,'Database Reference List\n');
    for r = 1:length(refs)
        fprintf(fRefs,'%d. %s\n',r,refs(r).Citation);
    end
    fclose(fRefs);
        
    % Write summary table to Excel
    try
        tableFile = fullfile(docPath,'dbSummary.xlsx');
        
        % write the value defaults to sheet 2
        xlswrite(tableFile,cD,2);
        
        % write database to sheet 1
        xlswrite(tableFile,c,1);
        
        % open a COM interface to the Excel file
        hExcel = actxserver('Excel.Application');
        hWorkbook = hExcel.Workbooks.Open(tableFile);
        
        % Configure the workbook sheets
        hWorkbook.Sheets.Item(1).Name = 'Database'; % Rename sheet 1
        hWorkbook.Sheets.Item(2).Name = 'Defaults'; % Rename sheet 2
        hWorkbook.Sheets.Item(3).Delete; % Delete sheet 3
        
        letters = 'ABCDEFGHIJKLMNOP';
        
        % Set column widths in sheet 1
        hWorksheet1 = hWorkbook.Sheets.Item(1);
        cWidths = [45,10,12,12,26,12,26,11,9];
        for c = 1:length(cWidths)
            hWorksheet1.Columns.Item(c).columnWidth = cWidths(c);
            hWorksheet1.Range(sprintf('%c1',letters(c))).Font.Bold = 1;
        end
        hWorksheet1.Application.ActiveWindow.SplitRow = 1;
        hWorksheet1.Application.ActiveWindow.FreezePanes = true;
        
        % Set column widths in sheet 2
        hWorksheet2 = hWorkbook.Sheets.Item(2);
        cWidths = [9,9,18,11,12,12,14,14,9,9,9];
        for c = 1:length(cWidths)
            hWorksheet2.Columns.Item(c).columnWidth = cWidths(c);
            hWorksheet2.Range(sprintf('%c1',letters(c))).Font.Bold = 1;
        end
        
        % Save the changes and close
        hWorkbook.Save;
        hWorkbook.Close;
        hExcel.Quit;
        
    catch err
        switch err.identifier
            case 'MATLAB:xlswrite:LockedFile'
                warning('MetalHydride:WriteExcelSummary',...
                        ['Unable to write Excel file because ',...
                        'the file is currently open']);
            otherwise
                warning('MetalHydride:WriteExcelSummary',...
                        ['The Excel writer encountered an error and ',...
                        'will create a csv file instead']);
                
                % This will be sufficient but not pretty
                tableFile = fullfile(docPath,'dbSummary.csv');
                fid = fopen(tableFile,'w');
                joinerFcn = @(str)sprintf('%s,',str);
                
                for i = 1:length(c)
                    
                    rowChars = cellfun(joinerFcn, {c{i,:}}, ...
                                       'UniformOutput',false);
                    rowChars = strcat(rowChars{:});
                    rowChars(rowChars==char(10)) = ' ';
                    
                    fprintf(fid,'%s\n',rowChars(1:end-1));
                end
                fclose(fid);
        end
    end
        
end


function str = MakeString(arg,fmt)
    % Make a string from an input argument which can be either a single
    % value or an array of values
    if length(arg) > 1
        str = '[';
        for i = 1:length(arg)
            str = [str,num2str(arg(i),fmt)]; %#ok<AGROW>
            if i < length(arg)
                str = [str,', ']; %#ok<AGROW>
            end
        end
        str = [str,']'];
    else
        str = num2str(arg,fmt);
    end
end

