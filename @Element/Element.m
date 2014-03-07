classdef Element
    % This class is for representing an element (or quasi-element like Mm)
    %
    % It stores the element name, amount, and molar mass obtained from its
    % periodic table. It also contains a number of static methods for
    % reading and displaying alloy names in different formats. An alloy is
    % represented by an array of Elements.
    
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
        Name = ''; % Element name
        W = 0;     % Element molar mass
        Mols = 0;  % Amount of element present
    end
    
    properties (Constant, Access = private)
        % pTable - This is the element class's periodic table
        pTable = struct...
        (...
            'H',1.0079,     ...  1
            ...
            'Li',6.941,     ...  3
            'Be',9.01218,   ...  4
            'B',10.81,      ...  5
            'C',12.011,     ...  6
            'N',14.007,     ...  7
            'O',15.999,     ...  8
            'F',18.998,     ...  9
            ...
            'Na',22.98977,  ...  11
            'Mg',24.305,    ...  12
            'Al',26.98154,  ...  13
            'Si',28.0855,   ...  14
            ...
            'K',39.0983,    ...  19
            'Ca',40.078,    ...  20
            'Sc',44.9559,   ...  21
            'Ti',47.867,    ...  22
            'V',50.9415,    ...  23
            'Cr',51.996,    ...  24
            'Mn',54.938,    ...  25
            'Fe',55.847,    ...  26
            'Co',58.9332,   ...  27
            'Ni',58.693,    ...  28
            'Cu',63.546,    ...  29
            'Zn',65.41,     ...  30
            'Ga',69.723,    ...  31
            'Ge',72.64,     ...  32
            ...
            'Y',88.9059,    ...  39
            'Zr',91.22,     ...  40
            'Nb',92.9064,   ...  41
            'Mo',95.94,     ...  42
            'Tc',97.91,     ...  43
            'Ru',101.07,    ...  44
            'Rh',102.9055,  ...  45
            'Pd',106.4,     ...  46
            'Ag',107.868,   ...  47
            'Cd',112.41,    ...  48
            'In',114.82,    ...  49
            'Sn',118.69,    ...  50
            ...
            'La',138.9055,  ...  57
            'Ce',140.12,    ...  58
            'Pr',140.91,    ...  59
            'Nd',144.24,    ...  60
            'Pm',144.91,    ...  61
            'Sm',150.36,    ...  62
            'Eu',151.96,    ...  63
            'Gd',157.25,    ...  64
            'Tb',158.93,    ...  65
            'Dy',162.50,    ...  66
            'Ho',164.93,    ...  67
            'Er',167.26,    ...  68
            'Tm',168.93,    ...  69
            'Yb',173.05,    ...  70
            'Lu',174.97,    ...  71
            'Hf',178.49,    ...  72
            ...
            'Ir',192.22,    ...  77
            'Pt',195.08,    ...  78
            ...
            'Th',232.04,    ...  90
            'Pa',231.0359,  ...  91
            ...
            ... 'Pseudo-Elements'
            'Lm', 138.9055, ... "La-rich" mischmetal
            'Mm', 140.311,  ...  Mischmetal
            'Vf', 53.39     ...  Ferrovanadium
         );
        
    end
    
    methods(Static, Access = private)
        %------------------------------------------------------------------
        % Takes an array of elements and makes a formatted compound string
        function cstr = BuildString(elements,s1,s2)
            cstr = '';
            
            for e = 1:length(elements)
                M = elements(e).Mols;
                if M == 1 || M == 0
                    cstr = strcat(cstr,elements(e).Name);
                else
                    % Convert M to a string
                    eps = 1e-6;
                    l = floor(M);
                    s = sprintf('%d',l);

                    if l ~= M
                        s = strcat(s,'.');
                        d = M - l;

                        while abs(d) > eps
                            s = strcat(s,sprintf('%1d',floor(10*d + eps)));
                            d = 10*d - floor(10*d + eps);
                        end
                    end
                    
                    cstr = strcat(cstr,sprintf('%s%s%s%s',...
                            elements(e).Name,s1,s,s2));
                end
            end
        end
    end
    
    %Static methods
    methods(Static)
        %------------------------------------------------------------------
        function sf = CompareAlloys(A,B)
            % Compare the composition of alloys A and B and calculate their
            % average difference in elemental composition
            %
            % A and B are either MetalHydride objects or arrays of Element
            % objects
            
            if isa(A,'MetalHydride')
                A = A.Elements;
            end
            
            if isa(B,'MetalHydride')
                B = B.Elements;
            end
            
            sf = 0;
            
            % First normalize alloy compositions so all elements are
            % expressed as a fractional amount per formula unit. This is
            % so that 'TiMn2' is recognized as the same as 'Ti2Mn4' and
            % very similar to 'Ti10Mn20V0.1'
            nA = sum([A.Mols]);
            nB = sum([B.Mols]);
            
            for i = 1:length(A)
                A(i).Mols = A(i).Mols / nA;
            end
            
            for i = 1:length(B)
                B(i).Mols = B(i).Mols / nB;
            end
            
            % Then compare the alloy elements
            for i = 1:length(A)
                Bid = find(B==A(i),1);
                if ~isempty(Bid)
                    % Element is in both, add difference in composition
                    sf = sf + abs(A(i).Mols - B(Bid).Mols);
                    B(Bid).Mols = 0;
                else
                    % Element is only in A, add it to the difference
                    sf = sf + A(i).Mols;
                end
            end
            
            % add the elements in B that weren't in A
            sf = sf + sum([B.Mols]);
            
        end
        
        
        %------------------------------------------------------------------
        function ListElements()
            % Print all element names currently available
            
            elements = fieldnames(Element.pTable);
            fprintf('+---------+-------------+\n')
            fprintf('| Element |  Molar Mass |\n')
            fprintf('+---------+-------------+\n')
            for e = 1:length(elements)
                fprintf('|    %2s   |  % 9.4f  |\n',...
                    elements{e}, Element.pTable.(elements{e}));
            end
            fprintf('+---------+-------------+\n')
        end
        
        %------------------------------------------------------------------
        function elements = ReadElements(line)
            % Read the element line from the mh file
            %
            % This expects an input formatted like:
            %
            %   some text  [ Element: Amount, Element: Amount ] other text
            %
            % and uses the position of the '[' and ']' to determine where
            % to read (things outside the brackets are ignored)
            
            ss = strfind(line,'[')+1;
            se = strfind(line,']')-1;
            
            if isempty(ss) || isempty(se)
                error('Element:ReadElements',...
                      'Element list "%s" is missing a bracket', line);
            end
            
            data = line(ss:se);
            segments = textscan(data,'%s','Delimiter',',');
            ne = length(segments{1});
            elements(1:ne) = Element();
            for e = 1:ne
                m = strfind(segments{1}{e},':');
                name = strtrim(segments{1}{e}(1:m-1));
                mols = str2double(strtrim(segments{1}{e}(m+1:end)));
                
                if isnan(mols)
                    error('Element:ReadElements',...
                          'Unable to read number for "%s" entry',name);
                end
                
                elements(e) = Element(name,mols);
            end
        end
        
        %------------------------------------------------------------------
        function cstr = MakeNameString(elements)
            % Make a name string for the hydride (e.g. 'LaNi5')
            cstr = Element.BuildString(elements,'','');
        end
                
        %------------------------------------------------------------------
        function cstr = MakeCompoundString(elements)
            % Make a name string for the hydride with '(' and ')' (e.g. 'LaNi(5)')
            cstr = Element.BuildString(elements,'(',')');
        end
        
        %------------------------------------------------------------------
        function cstr = MakeFormattedString(elements)
            % Make a name string formatted for subscripts (e.g. 'LaNi_{5}')
            cstr = Element.BuildString(elements,'_{','}');
        end
        

        %------------------------------------------------------------------
        function eList = ParseCompoundString(str)
            % Reads elements from a conventional compound string (e.g. 'LaNi5')
            
            %First check if the string is an entire element composition
            % This is to catch entries like:
            %   HydralloyC2
            %   Mg
            %   
            if isfield(Element.pTable, str)
                eList = Element(str,1);
                return
            end
                
            %Parse the string to get its chemical composition
            [elements,first,last] = regexp(str,'[A-Z][a-z]?','match');
                                   
            first = [first length(str)+1];
            Ne = length(elements);
            eList(1:Ne) = Element();
            
            for e = 1 : Ne
                if isfield(Element.pTable,elements{e})

                    % Find the numbers following the element
                    nd = last(e)+1 : first(e+1)-1;
                    
                    if isempty(nd)
                        N = 1;
                    else
                        N = str2double(str(nd));
                    end
                    
                    eList(e) = Element(elements{e}, N);
                else
                    error('Element:ParseCompoundString',...
                          'Unable to interpret "%s" from string "%s"',...
                           elements{e},str);
                end
            end
        end
    end
    
    %Define class methods
    methods
        %------------------------------------------------------------------
        function e = Element(name, amount)
            % Construct an element given the element's name and amount
            if nargin > 0
            
                % Set amount to 0 if not provided
                if ~exist('amount','var')
                    amount = 0;
                end
                
                % Set name and amount
                e.Name = name;
                e.Mols = amount;

                % Find the element or return an error
                if isfield(Element.pTable, name)
                    e.W = Element.pTable.(name);
                else
                    error('Element:Properties',...
                          'Element "%s" is not recognized',name);
                end

            else
                e.Name = '';
            end
        end
        
        %------------------------------------------------------------------
        function equal = eq(e1, e2)
            % Check if two elements are equal (the same element)
            equal = strcmpi({e1.Name},{e2.Name});
        end
        
        %------------------------------------------------------------------
        function noteq = ne(e1, e2)
            % Check of two elements are not equal
            noteq = ~(e1 == e2);
        end
        
    end %end methods
end %end class
