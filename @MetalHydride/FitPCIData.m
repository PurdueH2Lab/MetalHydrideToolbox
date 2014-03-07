function FitPCIData(alloyName, varargin)
    % Read PCI data for the specified alloy name then do fitting
    %
    % All optional arguments are input in name-value pairs. See the
    % example usage below.
    %
    % Inputs:
    %  alloyName          Name of alloy (e.g. 'La[1]Ni[5]')
    %  TcEst              Estimate for critical temperature (optional)
    %  PlateauWidth       Normalized plateau width for slope fitting
    %                     (optional, defaults to 0.75)
    %  PlateauCenter      Normalized plateau center for slope and Van't
    %                     Hoff fitting (optional, defaults to 0.5)
    %
    % Output:
    %  None (prints fitted parameters to command window)
    %
    % Example Usage:
    %   MetalHydride.FitPCIData('La[1]Ni[5]','TcEst',500);
    %   MetalHydride.FitPCIData('La[1]Ni[5]','PlateauWidth',0.5);
    
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
    
    [~,dataPath,~,~] = MetalHydride.GetPaths();
    
    PCIData = MetalHydride.ReadPCIData(alloyName);
    
    inputs = varargin_to_struct(varargin);
    
    
    % Load the hydride if it exists and make a plot
    if exist(fullfile(dataPath,[alloyName,'.mh']),'file')
        MH = MetalHydride(alloyName);
        hFig = MH.ComparePCI(true);
        ax(2:-1:1) = get(hFig,'Children');
        wMax = MH.wMax;
    else
        hFig = figure;
        set(hFig,...
            'Name',self.Name,...
            'Units','inches',...
            'Position',[2 2 6.5 2.75],...
            'PaperPositionMode','auto',...
            'PaperSize',[6.5 2.75]);
        
        % Make two axes
        ax(1) = subplot(1,2,1);
        hold all
        ax(2) = subplot(1,2,2);
        hold all
        
        % Determine wMax from PCIData
        wMax = 0;
        for na = 1:length(PCIData.Abs)
            wMax = max([wMax, max(PCIData.Abs(na).w)]);
        end
        
        for nd = 1:length(PCIData.Des)
            wMax = max([wMax, max(PCIData.Des(nd).w)]);
        end
        
        % Plot PCIData
        for na = 1:length(PCIData.Abs)
            
            % PCI curve
            plot(ax(1),PCIData.Abs(na).w.*100, PCIData.Abs(na).Peq,...
                 'Marker','o',...
                 'Color','k',...
                 'MarkerFaceColor','k',...
                 'Line','None');

            % Van't Hoff
            [x,idx] = unique(PCIData.Abs(na).w./wMax);
            y = PCIData.Abs(na).Peq(idx);
            Pmid = interp1(x,y,inputs.PlateauCenter);
            plot(ax(2),1000./PCIData.Abs(na).T,Pmid,...
                 'Marker','o',...
                 'Color','k',...
                 'MarkerFaceColor','k',...
                 'Line','None');
        end

        % Plot desorption
        for nd = 1:length(PCIData.Des)
            
            % PCI curve
            plot(ax(1),PCIData.Des(nd).w.*100, PCIData.Des(nd).Peq,...
                 'Marker','o',...
                 'Color','k',...
                 'MarkerFaceColor','w',...
                 'Line','None');

            % Van't Hoff
            [x,idx] = unique(PCIData.Des(nd).w./wMax);
            y = PCIData.Des(nd).Peq(idx);
            Pmid = interp1(x,y,inputs.PlateauCenter);
            plot(ax(2),1000./PCIData.Des(nd).T,Pmid,...
                 'Marker','o',...
                 'Color','k',...
                 'MarkerFaceColor','w',...
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
    end
    
    set(ax(1),'YScale','log');
    
    % Now perform fitting - Enthalpy and entropy
    if length(PCIData.Abs) > 1
        xA = zeros(size(PCIData.Abs));
        yA = zeros(size(PCIData.Abs));
        
        for na = 1:length(PCIData.Abs)
            [x,idx] = unique(PCIData.Abs(na).w./wMax);
            y = PCIData.Abs(na).Peq(idx);
            Pmid = interp1(x,y,inputs.PlateauCenter);
            
            xA(na) = 1000./PCIData.Abs(na).T;
            yA(na) = log(Pmid);
        end
        
    else
        xA = [];
        yA = [];
    end
    
    if length(PCIData.Des) > 1
        xD = zeros(size(PCIData.Des));
        yD = zeros(size(PCIData.Des));
        
        for nd = 1:length(PCIData.Des)
            [x,idx] = unique(PCIData.Des(nd).w./wMax);
            y = PCIData.Des(nd).Peq(idx);
            Pmid = interp1(x,y,inputs.PlateauCenter);
            
            xD(nd) = 1000./PCIData.Des(nd).T;
            yD(nd) = log(Pmid);
        end
        
    else
        xD = [];
        yD = [];
    end
    
    % Include estimated Tc in fitting
    if ~isempty(inputs.TcEst) && ~isempty(xA) && ~isempty(xD)
        pfA = polyfit(xA,yA,1);
        pfD = polyfit(xD,yD,1);
        
        logpEstA = polyval(pfA,1000./TcEst);
        logpEstD = polyval(pfD,1000./TcEst);
        
        logPest = 0.5*(logpEstA+logpEstD);
        
        xA = [xA(:); 1000./TcEst];
        yA = [yA(:); logPest];
        
        xD = [xD(:); 1000./TcEst];
        yD = [yD(:); logPest];
    end
    
    % Find slopes
    xLow  = inputs.PlateauCenter - inputs.PlateauWidth/2;
    xHigh = inputs.PlateauCenter + inputs.PlateauWidth/2;
    xLine = linspace(xLow,xHigh,10);
    
    minP = Inf;
    maxP = 0;
    
    if ~isempty(PCIData.Abs)
        slopesA = zeros(size(PCIData.Abs));
        
        for na = 1:length(PCIData.Abs)
            [x,idx] = unique(PCIData.Abs(na).w./wMax);
            y = log(PCIData.Abs(na).Peq(idx));
            
            is = find(x>xLow,1,'first');
            ie = find(x<xHigh,1,'last');
            
            if ie - is > 0
                x = x(is:ie);
                y = y(is:ie);

                pf = polyfit(x,y,1);
                
                plot(ax(1),x*wMax*100,exp(y),'or',...
                     'MarkerSize',3,'MarkerFaceColor','r');
                plot(ax(1),xLine*wMax*100,exp(polyval(pf,xLine)),'--r');
                
                maxP = max([maxP; max(exp(y))]);
                minP = min([minP; min(exp(y))]);
                
                slopesA(na) = pf(1)*PCIData.Abs(na).T/298;
            else
                warning('MetalHydride:FitPCIData',...
                        'Not enough points in absorption plateau for slope fitting');
                slopesA(na) = NaN;
            end
        end
    else
        slopesA = [];
    end
    
    if ~isempty(PCIData.Des)
        slopesD = zeros(size(PCIData.Des));
        
        for nd = 1:length(PCIData.Des)
            [x,idx] = unique(PCIData.Des(nd).w./wMax);
            y = log(PCIData.Des(nd).Peq(idx));
            
            is = find(x>xLow,1,'first');
            ie = find(x<xHigh,1,'last');
            
            if ie - is > 0
                x = x(is:ie);
                y = y(is:ie);

                pf = polyfit(x,y,1);
                
                plot(ax(1),x*wMax*100,exp(y),'or',...
                     'MarkerSize',3,'MarkerFaceColor','r');
                plot(ax(1),xLine*wMax*100,exp(polyval(pf,xLine)),'--r');

                maxP = max([maxP; max(exp(y))]);
                minP = min([minP; min(exp(y))]);
                
                slopesD(nd) = pf(1)*PCIData.Des(nd).T/298;
            else
                warning('MetalHydride:FitPCIData',...
                        'Not enough points in desorption plateau for slope fitting');
                slopesD(nd) = NaN;
            end
        end
    else
        slopesD = [];
    end
    
    if ~isinf(minP) && inputs.ZoomIsotherms
        pSpan = maxP - minP;
        set(ax(1),'YLim',[round(minP-0.8*pSpan) round(maxP+0.8*pSpan)],...
            'YScale','linear');
    end
    
    fprintf('Absorption:\n');
    if xA
        pfA = polyfit(xA,yA,1);
        fprintf(' DH = %5.0f J/mol\n DS = %5.1f J/mol.K\n\n',...
                pfA(1)*1000*8.314,-pfA(2)*8.314);
    else
        fprintf(' *** Not enough isotherms for absorption thermodynamics\n\n');
    end
    
    if ~isempty(slopesA)
        fprintf(' Slopes Normalized to 298 K:\n  %s\n\n',...
                sprintf('%4.2f ',slopesA));
    end
        
    fprintf('Desorption:\n');
    if xD
        pfD = polyfit(xD,yD,1);
        fprintf(' DH = %5.0f J/mol\n DS = %5.1f J/mol.K\n\n',...
                pfD(1)*1000*8.314,-pfD(2)*8.314);
    else
        fprintf(' *** Not enough isotherms for desorption thermodynamics\n\n');
    end
    
    if ~isempty(slopesD)
        fprintf(' Slopes Normalized to 298 K:\n  %s\n\n',...
                sprintf('%4.2f   ',slopesD));
    end
    
    
end

function inputs = varargin_to_struct(args)

   % Define structure of inputs with default values
   inputs = struct('TcEst',[],...
                   'PlateauWidth',0.75,...
                   'PlateauCenter',0.5,...
                   'ZoomIsotherms',true);

   % Verify that there are an even number of args
   if mod(size(args,2),2)
       error('MetalHydride:FitPCIData',...
             'Inputs must be valid name-value pairs');
   else
       nargs = size(args,2)/2;
   end
   
   % Put input arguments into structure
   for i = 1:nargs
       flag = args{2*(i-1)+1};
       value = args{2*(i-1)+2};
       
       if isfield(inputs,flag)
           inputs.(flag) = value;
       else
           error('MetalHydride:FitPCIData',...
                 'Invalid input "%s"',flag);
       end
   end

end
    