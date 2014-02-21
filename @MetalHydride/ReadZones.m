function data = ReadZones(lines)
    % Recursively parses lines from mh file into a zone-based structure
    %
    % How it works:
    %
    % Determine where the brackets '{' and '}' are located in the set of
    % lines given as an input. For example:
    %
    % Line |  B  | bl |  File Contents
    %              F
    %  1   |  0  | F  |  Name: Something
    %  2   |  0  | F  |  
    %  3   |  0  | F  |  Thermodynamics
    %  4   |  1  | T  |  {
    %  5   |  1  | T  |     Weight Percent: 1.5
    %  6   |  1  | T  |
    %  7   |  1  | T  |     Dehydriding
    %  8   |  2  | T  |     {
    %  9   |  2  | T  |        DH: -22000
    %  10  |  2  | T  |        DS: -115
    %  11  |  1  | T  |     }
    %  12  |  0  | F  |  }
    %  13  |  0  | F  |  
    %  14  |  0  | F  |  Kinetics
    %  15  |  1  | T  |  {
    %  16  |  1  | T  |     nothing here
    %  17  |  1  | T  |     or here
    %  18  |  1  | T  |  }
    %  19  |  0  | F  |  
    %  20  |  0  | F  |  
    %              F
    %
    % B is the 'brackets' variable and in this case bs and be would be:
    %  bs = [4, 15]
    %  be = [11, 18]
    %
    % Thus the code has identified two sub-sections, from lines 4 to 11 and
    % from lines 15 to 18. Each section is then broken into its own set of
    % lines, excluding its bounding bracket lines, so lines 5-10 are parsed
    % recursively by sending them to ReadZones and lines 16-17 are sent to
    % ReadZones. The results from this parsing are stored in a structure
    % whose entries are named by lines bs-1 (lines 3 and 14)
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
    
    brackets = MetalHydride.GetBrackets(lines);

    bl = [false;brackets~=0;false];
    bs = strfind(bl',[0,1]);
    be = strfind(bl',[1,0])-1;

    data.subDicts = struct();

    if ~isempty(bs)
        ns = length(bs);
        for i = 1:ns
            % Get the lines within the sub-section and the name line
            dictLines = lines(bs(i)+1:be(i));
            dictName = strtrim(lines{bs(i)-1});

            % Make the first letter capitalized, so you can call the entry
            % 'kinetics' or 'Kinetics' or 'kinETIcs' and it will not matter
            dictName = lower(strtrim(dictName));
            dictName(1) = upper(dictName(1));
            
            % Replace dashes and spaces with underscores
            dictName(dictName=='-') = '_';
            dictName(dictName==' ') = '_';
            
            % Then do a final clean to guarantee it is a valid name
            dictName = genvarname(dictName);
            
            % Recursion is neato!
            data.subDicts.(dictName) = ...
                MetalHydride.ReadZones(dictLines);

            % After reading the section, flip the lines with section names
            % and closing '}' to 1 so they aren't included in normal lines
            brackets(bs(i)-1) = 1;
            brackets(be(i)+1) = 1;
        end
    end

    % Get all lines not within brackets and store them as entry lines
    data.entryLines = strtrim(lines(brackets==0 & ...
        ~cellfun(@isempty,strtrim(lines))));
end
