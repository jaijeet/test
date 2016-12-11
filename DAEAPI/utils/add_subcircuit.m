function cktnetlist = add_subcircuit(cktnetlist, subcktnetlist, subcktname,...
															nodes, parms, uinfo)
%function cktnetlist = add_subcircuit(cktnetlist, subcktnetlist, subcktname,
%															nodes, parms, uinfo)
%
%This function adds an element to a circuit netlist structure; returns the
%updated version.
%
%inputs:
%
% - cktnetlist: the circuit netlist structure to be updated
%
% - subcktnetlist:  the subcircuit netlist structure to be added
%
% - subcktname: name of the subcircuit element (string)
%
% - nodes:   list of circuit nodes the subcircuit is connected to (specified as
%            a cell array of strings). Must match the number of nodes for the
%			 subcircuit's terminalnames, and be in the same order as in the 
%			 subcircuit's terminalnames.
%
% - parms:   cell array of parameter-name,value pairs: 
%                {{'devicename1:::parmname1', val1}, ...
%					{'devicename2:::parmname2', val2}} 
%				or
%                {{'devicename1', 'parmname1', val1}, ...
%					{'devicename2', 'parmname2', val2}}
%				or
%                {{'devicename1', val1}}
%				here devicename1' has only one parameter, e.g. R for resistor
%
% - uinfo:   a list of lists of independent source (u) information for the
%            device, in the format {u1info, u2info, ...}. Each uinfo has the
%            format (but there are special simple forms if the device has only
%            one u input, see below):
%
%            uiinfo = {srcname, spec1, spec2, ...}, where:
%
%                - srcname is a string that should exactly match device's name and
%                  ModSpec's internal name for the src.
%					e.g., 'Vdd:::E'
%					%TODO: alternatives without separator like parms
%
%                - each specj is a cell array with one of the following 
%                  formats:
%
%                  - {'DC' DCval}
%                    - where DCval is a real number (the DC value).
%
%                  - {'AC' ACval} OR {'AC' ACfunc ACargs}
%                    - ACval should be a complex number (the AC input value)
%                    - ACfunc should be a function handle of the form:
%                      ACfunc = @(f, ACargs) <return scalar complex number>
%                      - f represents frequency
%                        - ACargs is a structure containing any data needed by
%                          ACfunc
%
%                  - {'TRAN' tranfunc tranargs}
%                    - tranfunc = @(t, tranargs) should be a scalar real 
%                      function handle with two arguments: t and tranargs
%                      - t represents time
%                      - tranargs is a structure containing any data
%                        needed by tranfunc
%
%
%output:
%
% - cktnetlist: updated circuit netlist structure with the subcircuit added.
%
%Examples
%--------
% [TODO]
%
%See also
%--------
%
% add_element, MAPPcktnetlists, MAPPanalyses, MNA_EqnEngine[TODO], DAE[TODO], DAEAPI[TODO]
% 
%Author: Tianshi Wang, 2013/10/31


	separator = '->';

	newparms = {};
	if nargin < 5
	else
		for c = 1:length(parms)
			parm = parms{c};
			if 3 == length(parm)
				the_newparm.devicename = parm{1};
				the_newparm.parmname = parm{2};
				the_newparm.value = parm{3};
			elseif 2 == length(parm) 
				the_newparm.value = parm{2};
				names = parm{1};
				idx = strfind(names, separator);
				if 1 == length(idx)
					the_newparm.devicename = names(1:(idx-1));
					the_newparm.parmname = names((idx+3):end);
				elseif 0 == length(idx)
					the_newparm.devicename = names;
					the_newparm.parmname = '';
				else
					%error
				end
			else
				%error
			end
			newparms = {newparms{:}, the_newparm};
		end
	end

	newuinfo = {};
	if nargin < 6
	else
		for c = 1:length(uinfo)
			the_uinfo = uinfo{c};
			the_newuinfo.value = the_uinfo{2:end};
			names = the_uinfo{1};
			idx = strfind(names, separator);
			if 1 == length(idx)
				the_newuinfo.devicename = names(1:(idx-1));
				the_newuinfo.uname = names((idx+3):end);
			elseif 0 == length(idx)
				the_newuinfo.devicename = names;
				the_newuinfo.uname = '';
			else
				%error
			end
			newuinfo = {newuinfo{:}, the_newuinfo};
		end
	end
% recap of what is in subcktnetlist
	% cktname: ''
	% nodenames: {'',  '',  '',  ''}
	% groundnodename: ''				may not be present
	% terminalnames:  {'',  ''}			may contain groundnodename
	% elements: {[1x1 struct]  [1x1 struct]  [1x1 struct]  [1x1 struct]  [1x1 struct]}
	% for each element:
	%	name:  string
    %	model: ModSpec obj
    %	nodes: {''  ''}
    %	parms: cellarray
    %	udata: cellarray

	terminals = subcktnetlist.terminalnames;
	if isfield(subcktnetlist, 'groundnodename') && ~isempty(subcktnetlist.groundnodename)
		nodenames = {subcktnetlist.nodenames{:}, subcktnetlist.groundnodename};
		idx = find(strcmp(subcktnetlist.terminalnames, subcktnetlist.groundnodename));
		if 0 == length(idx)
			% global ground, may need to change name
			nodes = {nodes{:}, cktnetlist.groundnodename};
			terminals = {terminals{:}, subcktnetlist.groundnodename};
		end
	else
		nodenames = subcktnetlist.nodenames;
	end
	nonterminals = setdiff(nodenames, terminals);

	% nodes     --> in top level
	% terminals --> in subcircuit level, need to convert to nodes
	% nonterminals --> newly added nodes without prefix, should add prefix then add to top level
	prefix = strcat(subcktname, separator);
	if isempty(nonterminals)
		extranodes = {};
	else
		extranodes = strcat(prefix, nonterminals);
	end
	cktnetlist.nodenames = {cktnetlist.nodenames{:}, extranodes{:}};
	for c = 1:length(subcktnetlist.elements)
		the_element = subcktnetlist.elements{c};
		% update parms
		for d = 1:length(newparms)
			the_newparm = newparms{d};
			if strcmp(the_element.name, the_newparm.devicename)
				the_element = update_parms(the_element, the_newparm.parmname, the_newparm.value);
			end
		end
		% update udata
		for d = 1:length(newuinfo)
			the_newuinfo = newuinfo{d};
			if strcmp(the_element.name, the_newuinfo.devicename)
				the_element = update_udata(the_element, the_newuinfo.uname,  the_newuinfo.value);
			end
		end
		% update name, nodes
        the_element.name = strcat(prefix, the_element.name);
		for d = 1:length(the_element.nodes)
			idx = find(strcmp(terminals, the_element.nodes{d}));
			if 0 == length(idx)
				the_element.nodes{d} = strcat(prefix, the_element.nodes{d});
			elseif 1 == length(idx)
				the_element.nodes{d} = nodes{idx};
			else
				error(sprintf('node %s not found exactly once amongst circuit nodes',the_element.nodes{d}));
			end
		end % for nodes
		% add to top level circuit
		cktnetlist.elements = {cktnetlist.elements{:}, the_element};
	end % for devices
end % add_subcircuit


function the_element = update_parms(the_element, pname, pvalue)
	nparms = length(the_element.parms);
	parmnames = feval(the_element.model.parmnames, the_element.model);
	elname = the_element.name;
	modelname = feval(the_element.model.ModelName, the_element.model);

	% JR's code below
	if ~isempty(pname)
		idx = find(strcmp(parmnames, pname));
		if 0 == length(idx)
				error('%s: parameter %s not available for model %s', elname, pname, modelname);
		elseif 1 == length(idx)
				the_element.parms{idx} = pvalue;
		else
				error('%s: model %s definition error: parameter %s defined more than once', elname, modelname, pname);
		end
	else % special form: just one value
		if 1==length(pvalue) && 1==nparms
				the_element.parms = {parms};
		else
				error('%s: model %s has %d parameters but special form with one un-identified value (%g) used.\n', elname, modelname, nparms, pvalue);
		end
	end
end % update_parms


function the_element = update_udata(the_element, uname, the_data)
	% uname may be 'E', 'I', etc., it may also be ''.
	%
	% the_data may be:
	% {{'DC' dcval} {'AC' acmag acphase} {'tran' tranfunch funcargs}}
	% {'DC' dcval} or {'AC' acmag acphase} or {'tran' tranfunch funcargs}
	% {{'DC' dcval}} or {{'AC' acmag acphase}} or {{'tran' tranfunch funcargs}}
	%
	elname = the_element.name;
	modelname = feval(the_element.model.ModelName, the_element.model);
	MOD = the_element.model;

	unames = feval(MOD.uNames, MOD);
	if 1 == length(unames)
		if isempty(uname) || strcmp(uname, unames)
			uname = unames{1};
		else
			% error
		end
	end
	uinfo = {{uname, the_data}}; % length is always 1, 

	% JR's code below
                ninfos = length(uinfo);
                % the_element.udata = {}; % start from original udata
                for i=1:ninfos
                        the_data = uinfo{i}; %  the_data looks like {'E' {'DC' dcval} {'AC' acmag acphase} {'tran' tranfunch funcargs}}
                        the_data_len = length(the_data);
                        uname = the_data{1}; % eg, 'E' or 'I'
                        idx = find(strcmp(unames, uname)); % is it defined?
                        if 0 == length(idx)
                                error('%s: uName %s not available for model %s', elname, uname, modelname);
                        elseif 1 == length(idx)
                                uidata.uname = uname; % eg, 'E' or 'I'
                        else
                                error('%s: model %s definition error: uName %s defined more than once', elname, modelname, uname);
                        end

                        % support of {'E', {'DC/QSS', dcval}, {'AC/LTISSS', ACmag, ACphase}, }{'transient', tranfunc, funcargs} entries
                        for j=2:the_data_len
                                inputspec = the_data{j}; % {'DC', dcval} or {'AC', ACmag, ACphase}
                                                         % or {'tran', tranfunc, funcargs}
                                speclen = length(inputspec);
                                if ~iscell(inputspec) || 0 == speclen 
                                        error('%s: expecting DC/AC/tran input specification in a cell', elname);
                                end

                                analysistype = inputspec{1};
                                if ~ischar(analysistype) 
                                        error('%s: expecting a string (''DC'', ''AC'' or ''tran'') for the input specification', elname);
                                end

                                switch upper(analysistype) % case insensitive
                                  case {'DC', 'QSS', 'UQSS'}
                                          if 2 ~= speclen
                                                error('%s: expecting exactly one argument DCVAL for DC input specification', elname);
                                        end
                                        uidata.QSSval = inputspec{2};
                                  case {'AC', 'LTISSS', 'ULTISSS'}
                                          % valid syntaxes are: {'AC' <complex number>},  {'AC', @(f,args) <scalar complex number>, args}
                                        %                     {'AC', @(f,args) <scalar complex number>} (args assumed = [])
                                          if speclen < 2 || speclen > 3
                                                error('%s: expecting 1 or 2 arguments in AC input specification', elname);
                                        end
                                        
                                        % first argument: numeric or function handle
                                        if isnumeric(inputspec{2})
                                                uidata.uLTISSS = @(f, args) inputspec{2}; % constant with frequency
                                                uidata.uLTISSSargs = [];
                                                  if speclen > 2 
                                                        error('%s: more than 1 argument in AC input specification when first arg has numeric type', elname);
                                                end
                                        elseif isa(inputspec{2}, 'function_handle')
                                                uidata.uLTISSS = inputspec{2};
                                        else
                                                error('%s: AC input specification is neither numeric nor a function handle', elname);
                                        end

                                        if 3 == speclen % an args argument is provided
                                                uidata.uLTISSSargs = inputspec{3};
                                        else % not provided
                                                uidata.uLTISSSargs = [];
                                        end
                                  case {'TR', 'TRAN', 'TRANSIENT', 'UTRANSIENT'}
                                          % valid syntaxes are: {'tr', @(t,args) <real-function>, args}, or
                                        %                     {'tr', @(t,args) <real-function>} (args assumed = [])
                                          if speclen < 2 || speclen > 3
                                                error('%s: expecting 1 or 2 arguments in TRANSIENT input specification', elname);
                                        end
                                        
                                        % first argument: function handle
                                        if isa(inputspec{2}, 'function_handle')
                                                uidata.utransient = inputspec{2};
                                        else
                                                error('%s: TRANSIENT input specification is not a function handle', elname);
                                        end

                                        if 3 == speclen % an args argument is provided
                                                uidata.utransientargs = inputspec{3};
                                        else % not provided
                                                uidata.utransientargs = [];
                                        end
                                  otherwise
                                        error('%s: only input specifications of type DC/QSS/uQSS/AC/LTISSS/uLTISSS/TR/TRAN/TRANSIENT/uTRANSIENT are supported', elname);
                                end
                        end
                        the_element.udata{i} = uidata;
                end
end % update_udata
