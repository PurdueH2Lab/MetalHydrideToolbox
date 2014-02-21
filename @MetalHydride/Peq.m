function peq = Peq(self, T, w, type)
    % Calculate the equilibrium pressure for a given T, w, and type
    %
    % Inputs (all required):
    %  T - Temperature in Kelvin
    %  w - Weight fraction of hydrogen (kg_H / kg_Metal)
    %  type - String that is 'abs' or 'des' to indicate which mode
    %         to find. It is not case sensitive. Any other string
    %         will generate an error
    %
    % Output:
    %  peq - The equilibrium pressure in Pa
    %
    % Example Usage:
    %  A = MetalHydride('La[1]Ni[5]');
    %  P = A.Peq(300, A.wMax*0.5, 'des');
    %
    % Note:
    %  The Peq calculation uses the weight fraction of hydrogen,
    %  not the weight percent.
    %    weight fraction = kg_H / kg_Metal
    %    weight percent = kg_H / (kg_H + kg_Metal)
    %  Be sure to use the wMax function and not Thermo.WtPct when
    %  defining relative inputs.
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
    
    % Define constants
    R = 8.314;   %J/mol.K
    p0 = 101325; %Pa

    % Pick which thermo to use
    if strcmpi(type, 'abs')
        thermo = self.Thermo.Hydriding;
    elseif strcmpi(type, 'des')
        thermo = self.Thermo.Dehydriding;
    else 
        error('MetalHydride:Peq',...
              ['Type field must be either "abs" or "des"',...
              ', "%s" is not recognized'],...
              type);
    end

    % Make sure T is a scalar
    if length(T) > 1 && length(w) > 1
        error('MetalHydride:Peq',...
              'Either T or w must be a scalar, they cannot both be arrays');
    end
    
    % Pre-allocate peq if we're looping over T
    if length(T) > 1
        peq = zeros(size(T));
    end

    % Normalize hydrogen fraction
    x = w./self.wMax;

    % Get thermo parameters, average above Tc
    Omega = self.Thermo.Omega;
    widths = self.Thermo.widths;
    centers = self.Thermo.centers;
    minSpans = self.Thermo.minSpans;

    % Limit x to avoid errors from log terms
    x(x<centers(1)-widths(1)/2+1e-4) = centers(1)-widths(1)/2+1e-4;
    x(x>centers(end)+widths(end)/2-1e-4) = centers(end)+widths(end)/2-1e-4;

    for j = 1:length(T)
        % Determine thermo parameters (dH, dS, and A) for each plateau
        subcrit = T(j) < self.Tc;

        dHsuper = 0.5*(self.Thermo.Hydriding.dH + ...
                     self.Thermo.Dehydriding.dH);
        dSsuper = 0.5*(self.Thermo.Hydriding.dS + ...
                     self.Thermo.Dehydriding.dS);
        Asuper = 0.5*(self.Thermo.Hydriding.A + ...
                        self.Thermo.Dehydriding.A);

        dH = thermo.dH.*subcrit + dHsuper.*(~subcrit);
        dS = thermo.dS.*subcrit + dSsuper.*(~subcrit);
        A = thermo.A.*subcrit + Asuper.*(~subcrit);


        % Two-phase zone determinant
        D = (1 - 4.*R.*T(j)./(A + 2.*Omega));
        D(D<0) = 0;

        % Two-phase zone boundaries in normalized units
        xpL = (1 - sqrt(D)) / 2;
        xpR = (1 + sqrt(D)) / 2;

        % Transform to global concentration units
        xL = (xpL-0.5).*widths + centers;
        xR = (xpR-0.5).*widths + centers;

        % Calculate baseline chemical potential
        mu0 = dH - T(j).*dS;
        mu = NaN.*ones(size(x));

        % Calculate limits of two-phase region
        muL = mu0 + A.*(xpL - 0.5);
        muR = mu0 + A.*(xpR - 0.5);

        % Loop through the plateaus and set mu in each plateau, and set
        % the joining polynomial between the plateaus
        for p = 1:length(A)
            if p > 1
                xMid = mean([xL(p); xR(p-1)]);
                xSpan = max([minSpans(p-1), xL(p)-xR(p-1)]);
                xLlim = xMid + xSpan/2;
            else
                xLlim = xL(p);
            end

            if p < length(A)
                xMid = mean([xR(p); xL(p+1)]);
                xSpan = max([minSpans(p), xL(p+1)-xR(p)]);
                xRlim = xMid - xSpan/2;
            else
                xRlim = xR(p);
            end

            plat = x>=xLlim & x<=xRlim;
            mu(plat) = mu0(p) + A(p).*((x(plat)-centers(p))./widths(p)); 

            % set polynomial transitions
            if p < length(A)
                x1 = xRlim;
                
                xMean = mean([xL(p+1); xR(p)]);
                xSpan = max([minSpans(p) xL(p+1)-xR(p)]);
                x2 = xMean + xSpan/2;

                tr = x>x1 & x<x2;

                pA = [x1^3 x1^2 x1 1; ...
                     x2^3 x2^2 x2 1; ...
                     3*x1^2 2*x1 1 0; ...
                     3*x2^2 2*x2 1 0;];

                pB = [mu0(p) + A(p).*((x1-centers(p))/widths(p)); ...
                      mu0(p+1) + A(p+1).*((x2-centers(p+1))/widths(p+1)); ...
                      A(p)./widths(p); ...
                      A(p+1)./widths(p+1);];

                pf = pA\pB;

                mu(tr) = polyval(pf,x(tr));
            end

        end

        % Calculate parameters for regular solution model outside
        % plateaus (lower and upper end)
        muRSL0 = muL(1) - (1-2.*xpL(1)).*Omega(1) - ...
            R.*T(j).*log(xpL(1)./(1-xpL(1)));
        muRSH0 = muR(end) - (1-2.*xpR(end)).*Omega(end) - ...
            R.*T(j).*log(xpR(end)./(1-xpR(end)));

        xpL = (x - centers(1))./widths(1)+0.5;
        xpR = (x - centers(end))./widths(end)+0.5;

        muRSL = muRSL0 + (1-2.*xpL).*Omega(1) + R.*T(j).*log(xpL./(1-xpL));
        muRSH = muRSH0 + (1-2.*xpR).*Omega(end) + R.*T(j).*log(xpR./(1-xpR));

        % Set mu in edge regions to regular solution model
        mu(x<xL(1)) = muRSL(x<xL(1));
        mu(x>xR(end)) = muRSH(x>xR(end));

        % Calculate Peq from mu
        if length(T) > 1
            peq(j) = p0*exp(mu./(R.*T(j)));
        else
            peq = p0*exp(mu./(R.*T));
        end
    end
            