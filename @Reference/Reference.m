classdef Reference
    % This class is for representing an archival reference
    % This is used in favor of a simpler structure so that lists of
    % references can be searched to check for duplicates easily and so that
    % the reference formatting is kept in one place.

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
    properties (SetAccess = protected) %You may not change these
        % ID - Unique ID string to identify the reference (usually the DOI)
        ID = '';
        
        % Citation - A string built from authors, title, and other information
        Citation = ''; 
        
        % BibEntry - A bibtex compatible reference string
        BibEntry = '';
    end
        
    %Define class methods (aka functions)
    methods
        %------------------------------------------------------------------
        function ref = Reference(lines)
            % Create a reference object from the lines in the mh file
            %
            % All reference entries must have "ID", "Authors", "Title", and
            % "Year" defined. Optional entries are "Journal" "Volume"
            % "Pages" and "Other"
            
            if exist('lines','var')
                ref.ID = MetalHydride.ReadString(lines,'ID');

                % All entries must have authors, title, journal, and year
                authors = MetalHydride.ReadString(lines,'Authors');
                title = MetalHydride.ReadString(lines,'Title');
                year = MetalHydride.ReadString(lines,'Year');
                
                % Optional entries include Volume, Pages, and Other
                
                if MetalHydride.FoundEntry(lines,'Journal')
                    journal = MetalHydride.ReadString(lines,'Journal');
                else
                    journal = NaN;
                end
                
                if MetalHydride.FoundEntry(lines,'Volume')
                    volume = MetalHydride.ReadString(lines,'Volume');
                else
                    volume = NaN;
                end
                
                if MetalHydride.FoundEntry(lines,'Pages')
                    pages = MetalHydride.ReadString(lines,'Pages');
                else
                    pages = NaN;
                end
                
                if MetalHydride.FoundEntry(lines,'Other')
                    other = MetalHydride.ReadString(lines,'Other');
                else
                    other = NaN;
                end
                
                % Parse the author list?
                
                % Build reference string based on which entries are present
                ref.Citation = [authors,', ',title];
                
                if ischar(journal)
                    bibClass = 'article';
                else
                    bibClass = 'manual';
                end
                
                % Format author list for BibTex
                C = textscan(authors,'%s','Delimiter',',');
                bibAuthors = C{1}{1};
                for a = 2:length(C{1})
                    bibAuthors = sprintf('%s and %s',bibAuthors,C{1}{a});
                end
                
                ref.BibEntry = sprintf(['@%s{%s,\n',...
                                        '  author = {%s},\n',...
                                        '  title = {%s},\n',...
                                        '  year = {%s},\n'],...
                                        bibClass,...
                                        ref.ID, bibAuthors, title, year);
                                        
                            
                if ischar(journal)
                    ref.Citation = [ref.Citation,', ',journal];
                    
                    ref.BibEntry = sprintf('%s  journal = {%s},\n',...
                        ref.BibEntry, journal);
                end
                            
                ref.Citation = [ref.Citation,' (',year,')'];
                            
                if ischar(volume)
                    ref.Citation = [ref.Citation,', Vol. ',volume];
                    
                    ref.BibEntry = sprintf('%s  volume = {%s},\n',...
                        ref.BibEntry, volume);
                end
                
                if ischar(pages)
                    ref.Citation = [ref.Citation,', p. ',pages];
                    
                    ref.BibEntry = sprintf('%s  pages = {%s},\n',...
                        ref.BibEntry, pages);
                end
                
                if ischar(other)
                    ref.Citation = [ref.Citation,', ',other];
                    
                    ref.BibEntry = sprintf('%s  note = {%s},\n',...
                        ref.BibEntry, other);
                end
                
                ref.BibEntry = sprintf('%s}\n',ref.BibEntry);
            end
        end
        
        %------------------------------------------------------------------
        % Reference equality operator based on ID string
        %  now I can use ref1 == ref2 to check for duplicates
        function iseq = eq(r1, r2)
            % Check of two references are the same based on their ID
            iseq = strcmp({r1.ID}, {r2.ID});
        end
        
        % and ref1 ~= ref2
        function noteq = ne(r1, r2)
            % Check of two references are not the same based on their ID
            noteq = ~(r1 == r2);
        end
        
    end %end methods
end %end class