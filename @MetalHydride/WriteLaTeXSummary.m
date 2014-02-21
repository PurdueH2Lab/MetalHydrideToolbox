function WriteLaTeXSummary(showPlots)
    % Generate figures and tex code to make LaTeX summary of the database
    %
    % This function loads the entire database and PCI curves and generates
    % the raw tex source for a large summary document showing comparison
    % with the PCI data and tabulation of all hydride data.
    %
    % The resulting files in the 'doc' folder can then be compiled into
    % a PDF document by running 'make' on a Unix system with LaTeX
    % installed.
    %
    % Inputs:
    %  showPlots (optional) - Boolean input of whether to show plots
    %
    % Output:
    %  None (produces several files in the 'doc' folder)
    %
    % Example Usage:
    %   MetalHydride.WriteLaTeXSummary();
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
    
    % Set showPlots to the default if not present
    if ~exist('showPlots','var')
        showPlots = false;
    end
    
    % Get paths to doc folder and PCI data folder
    [~,dataPath,PCIpath,docPath] = MetalHydride.GetPaths();

    % First generate the BibTeX reference list
    MetalHydride.WriteBibRefs();

    % Locate all PCI data CSV files
    csvFiles = dir(fullfile(PCIpath,'*_PCI.csv'));
    
    % Make a color map for temperature
    colors = jet(100);

    % Write the document preamble
    docStr = sprintf([...
          '\\documentclass[notitlepage]{article}\n\n',...
          '\\usepackage{hyperref}\n',...
          '\\usepackage[letterpaper, top=0.5in, bottom=0.5in, ',...
          'left=0.75in, right=0.75in]{geometry}\n',...
          '\\usepackage{graphicx}\n',...
          '\\usepackage{capt-of}\n',...
          '\\usepackage{cite}\n',...
          '\\usepackage{multirow}\n\n',...
          '\\pdfinfo{\n',...
          '    /Title (Purdue Metal Hydride Toolbox Summary)\n',...
          '    /Author (Purdue Hydrogen Systems Lab)\n',...
          '}\n\n',...
          '\\begin{document}\n',...
          '\\title{Purdue Metal Hydride Toolbox Summary}\n',...
          '\\author{Tyler Voskuilen, Essene Waters, Timoth\\''ee Pourpoint}\n',...
          '\\maketitle\n\n',...
          'This document contains an automatically generated summary of the ',...
          'contents of the Purdue Metal Hydride Toolbox, including comparisons with ',...
          'all digitized PCI curves from the literature and a tabulation of ',...
          'all hydride data present in the database. For the most current information, ',...
          'please consult the online version of the database at ',...
          '\\url{http://github.com/PurdueH2Lab/MetalHydrideToolbox}\n\n',...
          '\\section{Comparisons with Literature PCI Data}\n\n',...
          'This section shows the comparison between the PCI curves\n',...
          'obtained from the literature and the model used in the Metal Hydride Toolbox\n\n']);


    %% Part 1 - Comparisons with PCI data
    for f = 1:length(csvFiles)
        %Remove the '_PCI.csv' from the filename to get the hydride name
        filename = csvFiles(f).name;
        is = strfind(filename,'_PCI.csv')-1;
        hydrideName = filename(1:is);

        if ~exist(fullfile(dataPath,[hydrideName,'.mh']),'file')
            fprintf('\n*** ERROR: No mh file found for %s ***\n\n',...
                    hydrideName);
            continue
        end

        % Read the PCI data from the excel sheet
        PCIData = MetalHydride.ReadPCIData(hydrideName);

        % Load the corresponding MetalHydride object from the database
        MH = MetalHydride([hydrideName, '.mh']);
        wvec = linspace(0.01,0.97,100).*MH.wMax();

        % Create a figure to plot the data and model
        figure;
        set(gcf,...
            'Name',hydrideName,...
            'Units','inches',...
            'Position',[2 2 6.5 2.75],...
            'PaperPositionMode','auto',...
            'PaperSize',[6.5 2.75],...
            'Visible','off');

        if showPlots
            set(gcf,'Visible','on');
        end
        
        % Make two axes
        ax(1) = subplot(1,2,1);
        hold all
        %th = title([MH.FormattedName, sprintf(' (DOI: %s)',PCIData.DOI)]);
        ax(2) = subplot(1,2,2);
        hold all
        %title(MH.FormattedName)

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
            Pabs(i) = MH.Peq(Tvh(i),0.5*MH.wMax,'abs')./1e5;
            Pdes(i) = MH.Peq(Tvh(i),0.5*MH.wMax,'des')./1e5;
        end

        plot(ax(2),1000./Tvh, Pabs,'-k','LineWidth',2);
        plot(ax(2),1000./Tvh, Pdes,'--k','LineWidth',2);

        % Plot absorption
        for na = 1:length(PCIData.Abs)
            T = PCIData.Abs(na).T;
            cs = max([1 round((T - Tmin) / (Tmax - Tmin) * 100)]);
            PeqModel = MH.Peq(T,wvec,'abs') ./ 1e5;
            plot(ax(1),wvec.*100,PeqModel,'Line','-','LineWidth',2,...
                 'Color',colors(cs,:));
            plot(ax(1),PCIData.Abs(na).w.*100, PCIData.Abs(na).Peq,'Marker','o',...
                 'Color',colors(cs,:),'MarkerFaceColor',colors(cs,:),...
                 'Line','None');

            % Van't Hoff
            [x,idx] = unique(PCIData.Abs(na).w./MH.wMax);
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
            PeqModel = MH.Peq(T,wvec,'des') ./ 1e5;
            plot(ax(1),wvec.*100,PeqModel,'Line','--','LineWidth',2,...
                 'Color',colors(cs,:));
            plot(ax(1),PCIData.Des(nd).w.*100, PCIData.Des(nd).Peq,'Marker','o',...
                 'Color',colors(cs,:),'MarkerFaceColor','w','Line','None');

            % Van't Hoff
            [x,idx] = unique(PCIData.Des(nd).w./MH.wMax);
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
        set(ax(1),'XLim',[0 MH.wMax.*100]);
        set(ax,'LineWidth',1,'Box','on','YScale','log');

        set(ax(1),'Position',[.13 .18 .35 .75]);
        set(ax(2),'Position',[.57 .18 .35 .75]);

        % Save the figure as a pdf
        print(gcf,'-dpdf',fullfile(docPath,sprintf('fig%04d.pdf',f)));

        % write the figure to the tex file
        texStr = sprintf(['  \\begin{center}\n',...
                          '  \\includegraphics{fig%04d}\n',...
                          '  \\captionof{figure}{Isotherms and Vant Hoff plot of $%s$ \\cite{%s}}\n',...
                          '  \\label{fig:%04d}\n',...
                          '  \\end{center}\n\n'],...
                          f,MH.FormattedName,PCIData.DOI,f);

        docStr = sprintf('%s%s',docStr,texStr);
    end

    docStr = sprintf(['%s\\include{hydrideList}\n\n',...
                      '\\bibliographystyle{ieeetr}\n',...
                      '\\bibliography{hydrideRefs}\n',...
                      '\n\\end{document}\n'],docStr);

    fid = fopen(fullfile(docPath,'summary.tex'),'w');
    fprintf(fid,'%s',docStr);
    fclose(fid);


    %% Part 2 - Generate a summary of the entire database
    hydrides = MetalHydride.LoadDatabase();

    hydStr = sprintf(...
       ['\\section{Hydride Database Summary}\n\n',...
        'This section contains an automatically generated summary of the current ',...
        'contents of the Purdue Metal Hydride database. For the most current information, ',...
        'it is recommended that you consult the online version of the database at ',...
        '\\url{http://github.com/PurdueH2Lab/MetalHydrideToolbox}\n\n',...
        'All symbols and reported values are defined using the following nomenclature and units:\n\n',...
        '\\begin{tabbing}\n',...
        '\\hspace*{0.25in}\\=\\hspace*{0.5in}\\= \\kill\n',...
        ' \\> $W_p$       \\>  Maximum reversible weight percent hydrogen ($100m_H$ / ($m_H$ + $m_M$)) \\\\\n',...
        ' \\> $\\Delta H$  \\>  Enthalpy (J/mol$_{H2}$) \\\\\n',...
        ' \\> $\\Delta S$  \\>  Entropy (J/mol$_{H2}-K$) \\\\\n',...
        ' \\> $A$         \\>  Plateau slope energy (J/mol$_{H2}$) \\\\\n',...
        ' \\> $\\rho$      \\>  Metal solid density (kg/m$^3$) \\\\\n',...
        ' \\> $C_p$       \\>  Dehydrided metal heat capacity (J/kg-K) \\\\\n',...
        ' \\> $k_{eff}$   \\>  Hydride bed effective thermal conductivity (W/m-K) \\\\\n',...
        ' \\> $E_a$       \\>  Activation energy (J/mol) \\\\\n',...
        ' \\> $C_a$       \\>  Pre-exponential rate constant (s$^{-1}$) \\\\\n',...
        '\\end{tabbing}\n\n',...
        'For additional notes and details about the specific references of each ',...
        'number, please consult the online database of ASCII formatted mh files.\n\n'...
        ]);

    for i = 1:length(hydrides)
        MH = hydrides(i);
        rn = fieldnames(MH.Refs);
        refs = sprintf('%s',MH.Refs.(rn{1}).ID);
        for r = 2:length(rn)
            refs = sprintf('%s, %s',refs,MH.Refs.(rn{r}).ID);
        end
        subStr = sprintf(['\\subsection{$%s$}\n\n',...
            'The data for $%s$ was obtained from \\cite{%s}.\n\n'],...
            MH.FormattedName,MH.FormattedName,refs);


        % Get properties
        nProps = 1;
        propStr = sprintf(' & $W_p$ = %4.2f \\\\\n',MH.Thermo.WtPct*100);

        if ~MH.kEffAssumed
            propStr = sprintf('%s&& $k_{eff}$ = %3.2f \\\\\n',propStr,MH.kEff);
            nProps = nProps + 1;
        end

        if ~MH.rhoAssumed
            propStr = sprintf('%s&& $\\rho$ = %3.2f \\\\\n',propStr,MH.rho);
            nProps = nProps + 1;
        end

        if ~MH.CpAssumed
            propStr = sprintf('%s&& $C_p$ = %3.2f \\\\\n',propStr,MH.Cp);
            nProps = nProps + 1;
        end

        % Get thermodynamics

        % Absorption
        starFooterStr = '';

        switch MH.ThermoLevel;
            case 0
                absThermoStr = sprintf(' & Default \\\\\n');
                nAbsThermo = 1;
            case 1
                if all(~MH.HysteresisAssumed) && length(MH.HysteresisAssumed) == 1
                    absThermoStr = sprintf(' & $ln(P_a/P_d)$ = %s \\\\\n',...
                        MakeString(MH.Hysteresis,'%4.3f'));
                    nAbsThermo = 1;
                else
                    % if hysteresis was assumed, then one of dH, dS, or
                    % Tc was provided. Tc can be determined, but no way
                    % to distinguish whether dH or dS was the one
                    % provided.

                    absThermoStr = sprintf(...
                        ['  & $\\Delta H$ = %s$^{\\star}$ \\\\\n',...
                         '& & $\\Delta S$ = %s$^{\\star}$ \\\\\n'],...
                         MakeString(MH.Thermo.Hydriding.dH,'%6.0f'),...
                         MakeString(MH.Thermo.Hydriding.dS,'%6.2f'));
                    nAbsThermo = 2;

                    starFooterStr = sprintf('\\\\$^{\\star}$Values calculated using an assumed parameter\n');
                end


            case 2
                absThermoStr = sprintf(...
                        ['  & $\\Delta H$ = %s \\\\\n',...
                         '& & $\\Delta S$ = %s \\\\\n'],...
                         MakeString(MH.Thermo.Hydriding.dH,'%6.0f'),...
                         MakeString(MH.Thermo.Hydriding.dS,'%6.2f'));
                nAbsThermo = 2;
            otherwise
        end

        % Desorption
        desThermoStr = sprintf(...
                        ['  & $\\Delta H$ = %s \\\\\n',...
                         '& & $\\Delta S$ = %s \\\\\n'],...
                         MakeString(MH.Thermo.Dehydriding.dH,'%6.0f'),...
                         MakeString(MH.Thermo.Dehydriding.dS,'%6.2f'));
        nDesThermo = 2;

        if any(~MH.Thermo.SlopeAssumed)
            nDesThermo = nDesThermo + 1;
            desThermoStr = sprintf('%s& & $A$ = %s \\\\\n',...
                desThermoStr,MakeString(MH.Thermo.Dehydriding.A,'%6.2f'));
        end

        if MH.Thermo.Dehydriding.FromIsotherms
            desNoteStr = sprintf('$^{\\dagger}$');
        else
            desNoteStr = '';
        end

        if MH.Thermo.Hydriding.FromIsotherms
            absNoteStr = sprintf('$^{\\dagger}$');
        else
            absNoteStr = '';
        end

        if ~isempty(desNoteStr) || ~isempty(absNoteStr)
            isoFooterStr = sprintf('\\\\$^{\\dagger}$Values obtained from or verified against an isotherm\n');
        else
            isoFooterStr = '';
        end

        % Kinetics

        if MH.Kinetics.Dehydriding.Assumed
            nDesKin = 1;
            desKinStr = sprintf(' & Default \\\\\n');
        else
            nDesKin = 4;

            pFcnStr = func2str(MH.Kinetics.Dehydriding.pFcn);
            wFcnStr = func2str(MH.Kinetics.Dehydriding.wFcn);

            pFcnStr = pFcnStr(10:end-1);
            wFcnStr = wFcnStr(17:end-1);

            pFcnStr = strrep(pFcnStr,'log','ln');
            pFcnStr = strrep(pFcnStr,'peq','p_{eq}');
            pFcnStr = strrep(pFcnStr,'Peq','P_{eq}');

            wFcnStr = strrep(wFcnStr,'log','ln');
            wFcnStr = strrep(wFcnStr,'peq','p_{eq}');
            wFcnStr = strrep(wFcnStr,'Peq','P_{eq}');
            wFcnStr = strrep(wFcnStr,'wmax','w_{max}');

            desKinStr = sprintf([' & $C_a$ = %5.1f \\\\\n',...
                                 '&& $E_a$ = %5.0f \\\\\n',...
                                 '&& $f_p$ = $%s$ \\\\\n',...
                                 '&& $f_w$ = $%s$ \\\\\n'],...
                                 MH.Kinetics.Dehydriding.Ca,...
                                 MH.Kinetics.Dehydriding.Ea,...
                                 pFcnStr,...
                                 wFcnStr);
        end

        if MH.Kinetics.Hydriding.Assumed
            nAbsKin = 1;
            absKinStr = sprintf(' & Default \\\\\n');
        else
            nAbsKin = 4;

            pFcnStr = func2str(MH.Kinetics.Hydriding.pFcn);
            wFcnStr = func2str(MH.Kinetics.Hydriding.wFcn);

            pFcnStr = pFcnStr(10:end-1);
            wFcnStr = wFcnStr(17:end-1);

            pFcnStr = strrep(pFcnStr,'log','ln');
            pFcnStr = strrep(pFcnStr,'peq','p_{eq}');
            pFcnStr = strrep(pFcnStr,'Peq','P_{eq}');

            wFcnStr = strrep(wFcnStr,'log','ln');
            wFcnStr = strrep(wFcnStr,'peq','p_{eq}');
            wFcnStr = strrep(wFcnStr,'Peq','P_{eq}');
            wFcnStr = strrep(wFcnStr,'wmax','w_{max}');


            absKinStr = sprintf([' & $C_a$ = %5.1f \\\\\n',...
                                 '&& $E_a$ = %5.0f \\\\\n',...
                                 '&& $f_p$ = $%s$ \\\\\n',...
                                 '&& $f_w$ = $%s$ \\\\\n'],...
                                 MH.Kinetics.Hydriding.Ca,...
                                 MH.Kinetics.Hydriding.Ea,...
                                 pFcnStr,...
                                 wFcnStr);
        end


        tableStr = sprintf(...
       ['\\begin{center}\n',...
        '\\begin{tabular}{|cc|c|} \\hline\n',...
        '\\multicolumn{2}{|c|}{Alloy}\n',...
        ' &  $%s$ \\\\ \\hline\n',...
        '\\multicolumn{2}{|c|}{Type}\n',...
        ' &  $%s$ \\\\ \\hline\n',...
        '\\multicolumn{2}{|c|}{\\multirow{%d}{*}{Properties}}\n',...
        '%s \\hline\n',...
        '\\multirow{%d}{*}{Thermodynamics} & \\multirow{%d}{*}{Desorption%s}\n',...
        '%s \\cline{2-3}\n',...
        '& \\multirow{%d}{*}{Absorption%s}\n',...
        '%s \\hline\n',...
        '\\multirow{%d}{*}{Kinetics} & \\multirow{%d}{*}{Desorption}\n',...
        '%s \\cline{2-3}\n',...
        '& \\multirow{%d}{*}{Absorption}\n',...
        '%s \\hline\n',...
        '\\end{tabular}\n',...
        '%s%s',...
        '\\end{center}\n\n'],...
        MH.FormattedName,...
        MH.FormattedType,...
        nProps,...
        propStr,...
        nAbsThermo+nDesThermo,...
        nDesThermo,...
        desNoteStr,...
        desThermoStr,...
        nAbsThermo,...
        absNoteStr,...
        absThermoStr,...
        nAbsKin+nDesKin,...
        nDesKin,...
        desKinStr,...
        nAbsKin,...
        absKinStr,...
        isoFooterStr,...
        starFooterStr);


        subStr = sprintf('%s%s',subStr,tableStr);



        hydStr = sprintf('%s%s',hydStr,subStr);

    end

    fid = fopen(fullfile(docPath,'hydrideList.tex'),'w');
    fprintf(fid,'%s',hydStr);
    fclose(fid);

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