function PCI = ReadPCIData(alloyName)
    % Read PCI data for the specified alloy name into a PCI structure.
    %
    % Inputs:
    %  alloyName
    %
    % Output:
    %  PCI data structure
    %
    % Example Usage:
    %   PCIdata = MetalHydride.ReadPCIData('La[1]Ni[5]');
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
    
    % Get path to PCI data folder
    [~,~,PCIpath,~] = MetalHydride.GetPaths();
    
    % Generate PCI data file name and check that it exists before opening
    PCIfile = fullfile(PCIpath,[alloyName,'_PCI.csv']);
    
    if exist(PCIfile,'file')
        raw = importdata(PCIfile,',',7);
    else
        error('MetalHydride:ReadPCIData',...
              'PCI file for "%s" not found',alloyName);
    end
    
    % Read header information (author, DOI, location)
    A = textscan(raw.textdata{1,1},'Author,%s,%*s','Delimiter',',');
    D = textscan(raw.textdata{2,1},'DOI,%s,%*s','Delimiter',',');
    L = textscan(raw.textdata{3,1},'Location,%s,%*s','Delimiter',',');
    
    PCI = struct('wmax',0);
    PCI.Author = A{1}{1};
    PCI.DOI = D{1}{1};
    PCI.Location = L{1}{1};

    % Parse Row 5 to determine which columns are abs and des
    AD = textscan(raw.textdata{5,1},'%s','Delimiter',',');
    absDesRow = AD{1}';

    absCols = strcmpi(absDesRow,'abs');
    desCols = strcmpi(absDesRow,'des');

    absColIDs = find(absCols);
    desColIDs = find(desCols);

    Nabs = sum(absCols);
    Ndes = sum(desCols);
    
    % Parse row 6 to read isotherm temperatures
    RTs = textscan(raw.textdata{6,1},'%s','Delimiter',',');
    Ts = cellfun(@str2double, RTs{1})';
     
    % Create appropriately sized empty structures to hold the
    % absorption and desorption data
    PCI.Abs(1:Nabs) = struct();
    PCI.Des(1:Ndes) = struct();

    % Read absorption data
    for i = 1:Nabs
        % Figure out which row the 'NaN's start at
        Li = find(isnan(raw.data(:,absColIDs(i))),1,'first')-1;
        if isempty(Li)
            Li = length(raw.data(:,1));
        end

        PCI.Abs(i).T = Ts(absColIDs(i));
        PCI.Abs(i).w = raw.data(1:Li,absColIDs(i))./100;
        PCI.Abs(i).Peq = raw.data(1:Li,absColIDs(i)+1);

        PCI.wmax = max([PCI.wmax max(PCI.Abs(i).w)]);
    end

    % Read desorption data
    for i = 1:Ndes
        % Figure out which row the 'NaN's start at
        Li = find(isnan(raw.data(:,desColIDs(i))),1,'first')-1;
        if isempty(Li)
            Li = length(raw.data(:,1));
        end

        PCI.Des(i).T = Ts(desColIDs(i));
        PCI.Des(i).w = raw.data(1:Li,desColIDs(i))./100;
        PCI.Des(i).Peq = raw.data(1:Li,desColIDs(i)+1);

        PCI.wmax = max([PCI.wmax max(PCI.Des(i).w)]);
    end


    
    