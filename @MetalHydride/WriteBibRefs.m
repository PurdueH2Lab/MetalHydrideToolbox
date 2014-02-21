function WriteBibRefs()
    % Writes database BibTeX reference document
    %
    % This function loads the entire database and writes all references
    % located in the mh files to a single BibTeX file.
    %
    % Inputs:
    %  None
    %
    % Output:
    %  None
    %
    % Example Usage:
    %   MetalHydride.WriteBibRefs();
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

    % Get path to doc folder
    [~,~,~,docPath] = MetalHydride.GetPaths();
    
    hydrides = MetalHydride.LoadDatabase();
    
    refs = Reference();
    rid = 1;
    
    for i = 1:length(hydrides)
        H = hydrides(i);
        
        % Add references to refs array if they are not there already
        refnames = fieldnames(H.Refs);
        for r = 1:length(refnames)
            R = H.Refs.(refnames{r});

            % See if this reference is in the refs array already
            refID = find(refs(1:rid-1)==R,1,'first');

            % If reference is not in the list, add it to the refs array
            if isempty(refID)
                refs(rid) = R;
                rid = rid + 1;
            end
        end
    end
        

    % Write references to a bib file
    fRefs = fopen(fullfile(docPath,'hydrideRefs.bib'),'w');
    fprintf(fRefs,'%% Purdue Metal Hydride Toolbox Reference List\n\n');
    for r = 1:length(refs)
        fprintf(fRefs,'%s\n',refs(r).BibEntry);
    end
    fclose(fRefs);
    