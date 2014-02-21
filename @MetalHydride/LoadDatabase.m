function hydrides = LoadDatabase(forceReload)
    % Load entire database - uses fast load from MAT file if possible
    %
    % This function locates all the mh files in the 'data' folder and reads
    % the 'hydrides.mat' file from the last load. The timestamps of the
    % current files and the saved ones from the last load are compared, and
    % if they are the same, the hydride array from hydrides.mat is
    % returned. If they are different or if forceReload is true, all the 
    % mh files are re-read. If the 'hydrides.mat' file is not present, all
    % the mh files are re-read.
    %
    % Input:
    %  forceReload - Indicate whether to re-read all the mh files whether
    %                or not they have changed (optional, defaults to false)
    %
    % Output:
    %  hydrides - Array of all hydrides in the database
    %
    % Example Usage:
    %  hydrides = MetalHydride.LoadDatabase();
    %  hydrides = MetalHydride.LoadDatabase(true);
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
    
    % Set forceReload to default if not provided
    if ~exist('forceReload','var')
        forceReload = false;
    end

    % Get some file paths
    MHpath = fileparts(fileparts(which('MetalHydride')));
    MATfile = fullfile(MHpath,'data','hydrides.mat');
    dataPath = fullfile(MHpath,'data','*.mh');
    filelist = dir(dataPath);

    % The fastest option is to read the MAT file from the last run
    doReload = false;
    if exist(MATfile,'file') && ~forceReload
        db = load(MATfile);
        hydrides = db.hydrides;

        if length(db.times) ~= length(filelist)
            % Number of hydrides in database changed, do reload
            doReload = true;
        elseif max(abs(db.times-[filelist.datenum])) > 1e-1
            % File timestamps have changed, do reload
            doReload = true;
        end
    else
        doReload = true;
    end
        
    % However, if the files have changed, reload manually
    if doReload
        hydrides(1:length(filelist),:) = MetalHydride();

        for i = 1:length(filelist)
            hydrides(i) = MetalHydride(filelist(i).name);
        end

        times = [filelist.datenum]; %#ok<NASGU>

        save(MATfile,'hydrides','times');
    end
end     