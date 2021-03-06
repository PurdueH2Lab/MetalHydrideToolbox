function value = GetTypeProperty(propName,type)
    % IUO - Return the default value for a named property for a given hydride type
    % As we get more hydrides in the database, these values should be
    % periodically re-evaluated.
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
    
    % Set type to all caps
    type = upper(type);
    
    switch propName
        
        %-----------------------------------------------------------------
%         case 'Tc'
%             switch type
%                 case 'AB5'
%                     value = 500; %K
%                 case 'AB2'
%                     value = 370; %K
%                 otherwise
%                     value = 600; %K
%             end
            case 'Tc'
                switch type
                    case 'AB5'
                        value = 586; %K
                    case 'AB2'
                        value = 451; %K
                    case 'AB'
                        value = 502; %K
                    case 'AB3'
                        value = 343; %K
                    case 'Complex'
                        value = 2330; %K
                    case 'MG'
                        value = 663; %K
                    case 'SS'
                        value = 473; %K
                    otherwise
                        value = 600; %K
              end

        %-----------------------------------------------------------------
%         case 'Slope' %assumed for desorption
%             switch type
%                 case 'AB5'
%                     value = 0.5;
%                 case 'AB2'
%                     value = 0.64;
%                 case 'AB'
%                     value = 0.5;
%                 otherwise
%                     value = 0;
%             end
        case 'Slope' %assumed for desorption
                    switch type
                        case 'AB'
                            value = 0.92;
                        case 'AB2'
                            value = 1.25;
                        case 'AB3'
                            value = 1.2;  
                        case 'AB5'
                            value = 0.43;
                        case 'MG'
                            value = 0.02;
                        case 'SS'
                            value = 0.33;                      
                        otherwise
                            value = 0;
                end
            
        %-----------------------------------------------------------------
%         case 'Hysteresis'
%             switch type
%                 case 'AB5'
%                     value = 0.2;
%                 case 'AB2'
%                     value = 0.4;
%                 case 'AB'
%                     value = 0.4;
%                 otherwise
%                     value = 0;
%             end
            case 'Hysteresis' %assumed for desorption
                    switch type
                        case 'AB'
                            value = 0.51;
                        case 'AB2'
                            value = 0.54;
                        case 'AB3'
                            value = 0.29;  
                        case 'AB5'
                            value = 0.39;
%                         case 'Mg'
%                             value = 3.71;
                        case 'SS'
                            value = 0.80;                      
                        otherwise
                            value = 0;
                end
            
        %-----------------------------------------------------------------
%         case 'Ca Hydriding'
%             switch type
%                 case 'MG'
%                     value = 9.8e9; % DOI 10.1016/j.ijhydene.2010.03.057
%                 otherwise
%                     value = 57;
%             end
            case 'Ca Hydriding' %assumed for desorption
                    switch type
                        case 'AB'
                            value = 7523;
                        case 'AB2'
                            value = 473;
                        case 'AB3'
                            value = 24.4;  
                        case 'AB5'
                            value = 620;
                        case 'Complex'
                            value = 2e9;
                        case 'MG'
                            value = 9.8e9;                      
                        otherwise
                            value = 57;
                end
            
        %-----------------------------------------------------------------
        case 'Ca Dehydriding'
            switch type
                case 'AB'
                    value = 99;
                case 'AB2'
                    value = 58;
                case 'AB5'
                    value = 90;
                case 'Complex'
                    value = 1.8e9;
                case 'MG'
                    value = 10; % DOI 10.1016/j.ijhydene.2010.03.057
                otherwise
                    value = 9.57;
            end
            
        %-----------------------------------------------------------------
        case 'Ea Hydriding'
            switch type
                case 'AB'
                    value = 40038;
                case 'AB2'
                    value = 24900;
                case 'AB3'
                    value = 25730;
                case 'AB5'
                    value = 30867;
                case 'MG'
                    value = 132000; % DOI 10.1016/j.ijhydene.2010.03.057
                case 'Complex'
                    value = 91520;
                otherwise
                    value = 20000;
            end
            
        %-----------------------------------------------------------------
        case 'Ea Dehydriding'
            switch type
                case 'AB'
                    value = 30161;
                case 'AB2'
                    value = 22100;
                case 'AB5'
                    value = 28250;
                case 'Complex'
                    value = 93070;
                case 'MG'
                    value = 41000; % DOI 10.1016/j.ijhydene.2010.03.057
                otherwise
                    value = 16420;
            end
            
        %-----------------------------------------------------------------
        case 'kEff'
            switch type
                case 'AB2'
                    value = 1.6;
                case 'AB5'
                    value = 1.6;
                case 'Complex'
                    value = 0.42;
                case 'MG'
                    value = 0.48;
                otherwise
                    value = 1;
            end
            
            
        %-----------------------------------------------------------------
        case 'Cp'
            switch type
                case 'AB'
                    value = 502;
                case 'AB2'
                    value = 419;
                case 'AB5'
                    value = 419;
                case 'Complex'
                    value = 1075;
                case 'MG'
                    value = 889;
                otherwise
                    value = 500;
            end
            
        %-----------------------------------------------------------------
        case 'rho'
            switch type
                case 'AB'
                    value = 6500;
                case 'AB2'
                    value = 6700;
                case 'AB5'
                    value = 8200;
                case 'Complex'
                    value = 1800;
                case 'MG'
                    value = 1750;
                otherwise
                    value = 6600;
            end
            
        %-----------------------------------------------------------------
        otherwise
            error('MetalHydride:GetTypeProperty',...
                  'Invalid property "%s"',propName)
    end