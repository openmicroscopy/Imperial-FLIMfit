function doc_node = serialise_object(obj,input,name)

    % Copyright (C) 2013 Imperial College London.
    % All rights reserved.
    %
    % This program is free software; you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License along
    % with this program; if not, write to the Free Software Foundation, Inc.,
    % 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
    %
    % This software tool was developed with support from the UK 
    % Engineering and Physical Sciences Council 
    % through  a studentship from the Institute of Chemical Biology 
    % and The Wellcome Trust through a grant entitled 
    % "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

    % Author : Sean Warren
    
    file = [];
    doc_node = [];
    if ischar(input)
        file = input;
    elseif isa(input,'org.apache.xerces.dom.DocumentImpl')
        doc_node = input;
    elseif ~isempty(input)
        throw(MException('FLIMfit:serialise_object','Expected second argument to be filename or XML document node'));
    end
    
    if isempty(doc_node)
        doc_node = com.mathworks.xml.XMLUtils.createDocument('FLIMfit');
    end
    
    if isstruct(obj)
        if nargin < 3
            name = 'data';
        end
        flds = fieldnames(obj); 
    else        
        flds = {};
        mc = metaclass(obj);
        mp = mc.Properties;
        name = mc.Name;
        for i=1:length(mp)
            if mp{i}.Transient == false && mp{i}.Dependent == false && mp{i}.Constant == false
                flds{end+1} = mp{i}.Name;
            end
        end
    end

    
    %try
        % Create a sample XML document.
        root_element = doc_node.createElement(name);
        for i=1:length(flds)
            val = obj.(flds{i});
            if ~isstruct(val) && ~iscell(val) && ~isjava(val)                
                this_element = doc_node.createElement(flds{i}); 
                
                if all(size(val)>1)% check for a multidimensional matrix
                    str = serialize(val);
                    str = base64encode(str,'java',true);
                    this_element.setAttribute('encoded','true');
                else
                    str = mat2str(val);
                end

                this_element.appendChild(doc_node.createTextNode(str));
                root_element.appendChild(this_element);
            end
        end
        doc_node.getDocumentElement().appendChild(root_element);
    
        if ~isempty(file)
            xmlwrite(file,doc_node);
        end
        
    %catch e
    %    warning('GlobalAnalysis:CouldNotWriteFile','Could not write serialised file');
    %end
    
end