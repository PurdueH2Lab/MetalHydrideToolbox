function props = ReadProps(propStruct,type)
    % Read the property entries from the mh file and save in a structure
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
    
    lines = propStruct.entryLines;
    props = struct('kEffAssumed',false,...
                   'CpAssumed',false,...
                   'rhoAssumed',false);

    % Effective (not solid) thermal conductivity
    if MetalHydride.FoundEntry(lines,'keff')
        props.kEff = MetalHydride.ReadNumber(lines,'keff');
    else
        props.kEff = MetalHydride.GetTypeProperty('kEff',type);
        props.kEffAssumed = true;
    end

    % Solid specific heat
    if MetalHydride.FoundEntry(lines,'cp')
        props.Cp = MetalHydride.ReadNumber(lines,'cp');
    else
        props.Cp = MetalHydride.GetTypeProperty('Cp',type);
        props.CpAssumed = true;
    end

    % Solid density
    if MetalHydride.FoundEntry(lines,'rho')
        props.rho = MetalHydride.ReadNumber(lines,'rho');
    else
        props.rho = MetalHydride.GetTypeProperty('rho',type);
        props.rhoAssumed = true;
    end
end