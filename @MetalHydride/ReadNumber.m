function value = ReadNumber(lines,str)
    % IUO - Find a numeric entry in an mh file and read the number
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
    
    %general format for a line is:
    % name: 3.14 # refs
    % name: [1, 2.3, 55] # refs
    % name: [NaN, 42, NaN] # words

    % Make sure the entry is present
    if ~MetalHydride.FoundEntry(lines,str)
        error('MetalHydride:ReadNumber',...
              'Required entry "%s" not located',str);
    end

    % Get the entry line
    l = MetalHydride.GetLine(lines,str);

    % Find the ':' on the line to mark where the value begins
    c = strfind(l,':');

    % Get substring between ':' and the end of string. The
    % str2double function ignores whitespace, so it can be left in
    str = l(c+1:end);

    % Make sure something was actually entered
    if isempty(str)
        error('MetalHydride:ReadNumber',...
              'Line "%s" has no entry',l);
    end

    % Check if entry is a single number, or an array
    bs = strfind(str,'[')+1;
    be = strfind(str,']')-1;

    % Use the presence of brackets to determine if it's a single value or
    % an array
    switch isempty(bs) + isempty(be)
        case 0
            % Entry has opening and closing brackets, read as array

            % Separate entries and read into array
            segments = textscan(str(bs:be),'%s','Delimiter',',');
            value = cellfun(@str2double, segments{1});
            
            if any(isnan(value) & ~strcmpi('NaN',segments{1}))
                error('MetalHydride:ReadArray',...
                      'Array entry in "%s" is not a validly formatted entry',l);
            end
            
        case 2
            % Entry has no brackets, read as a number
            
            % Read the value and convert it to a number
            value = str2double(str);

            % Check that it could actually be converted to a number
            if isnan(value)
                error('MetalHydride:ReadNumber',...
                      'Entry in "%s" is not a validly formatted number',l);
            end
    
        otherwise
            error('Element:ReadElements',...
                  'Element list "%s" is missing a bracket', line);
    end
    

end