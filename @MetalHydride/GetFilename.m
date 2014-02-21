function filepath = GetFilename(inputStr)
    % Takes an input string and figures out the appropriate file path.
    % Valid input options are, using LaNi5 as an example:
    %   La[1]Ni[5].mh    <- Use filename directly
    %   La[1]Ni[5]       <- Use without 'mh' extension
    %   LaNi5            <- Use without brackets and compositions of '1'
    %                       (NOTE: this is not supported yet, see tricky
    %                        case below, which makes this harder to do)
    %
    % Non-elemental cases are tricky, for example:
    %   HydralloyC1.mh    <- Use filename directly
    %   HydralloyC1       <- Use without 'mh' extension, however this would
    %                        parse to 'HydralloyC1[1].mh'
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
    
    % Get the path where the MetalHydride class is defined
    MHpath = fileparts(fileparts(which('MetalHydride')));

    % Catch short entries
    if length(inputStr) < 3
        error('MetalHydride:GetFilename',...
              ['Input string "%s" is too short and may be mal-formed,',...
              ' did you forget to use a [1]?'],...
              inputStr);
    end
    
    % Check if the file extension is missing and add it if it is
    if ~strcmp(inputStr(end-2:end),'.mh')
        file = strcat(inputStr,'.mh');
    else
        file = inputStr;
    end
    
    % Build the full file path
    filepath = fullfile(MHpath,'data',file);
    
    % Check if the file exists. If not, return an error
    if ~exist(filepath,'file')
        error('MetalHydride:GetFilename',...
              'Specified input file "%s" does not exist',...
              filepath);
    end
    