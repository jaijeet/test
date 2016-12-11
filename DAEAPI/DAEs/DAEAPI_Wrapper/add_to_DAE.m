function out = add_to_DAE(DAE, field_name, field_value)
% TODOs (JR 2016/10/03: )
% This function is used to augment the skeleton DAE returned by init_DAE().
% Acceptable field and value 
%	f_takes_inputs: 	        1,0
%	f: 					        function handle
%	q:					        function handle
%	fq:					        function handle, returns [fout, qout]
%	B:					        function handle
%	C:					        function handle
%	D:					        function handle
%	internalfunc:		        function handle
%	uniqIDstr:			        string
%	nameStr:			        string
%	unkname or unknames:        cell of strings
%	eqnname or eqnnames:	    cell of strings
%	inputname or inputnames:    cell of strings
%	outputname or outputnames:  cell of strings
%	parm/parms/param/params:    cell of parameter names and values
%	
%   limitedvarname/limitedvarnames:         cell of strings
%   limited_var_matrix or limited_matrix:   matrix
%   limiting:                               function handle
%   initguess:                              function handle
%	
%	

% updates to allow f(x,u,DAE), q(x, DAE): JR 2016/10/03
% Author: Bichen Wu <bichen@berkeley.edu> 2014/02/03
	if strcmp(field_name, 'f_takes_inputs')
		DAE.f_takes_inputs = field_value;
	
	elseif strcmp(field_name, 'f')
		if DAE.f_takes_inputs == 1
            DAE.f_of_S = field_value;
        	DAE.f = @DAE_f;
		elseif DAE.f_takes_inputs == 0
            DAE.f_of_S = field_value;
        	DAE.f = @DAE_f_no_u;
		else
        	error (['ERROR in add_to_DAE(): Please define .f_takes_inputs before .f ']);
		end
		DAE.f_of_S = field_value;
	
	elseif strcmp(field_name, 'f_x') % field value should be handle to f(x, xlim, u, DAE) or f(x,xlim,  DAE), depending on .f_takes_inputs
        DAE.f = field_value;

	elseif strcmp(field_name, 'q')
		DAE.q_of_S = field_value;
		DAE.q = @DAE_q;
	
	elseif strcmp(field_name, 'q_x')% field value should be handle to q(x, xlim, DAE)
		DAE.q = field_value;
	
	elseif strcmp(field_name, 'fq')
		if DAE.f_takes_inputs == 1
            DAE.fq_of_S = field_value;
        	DAE.fq = @DAE_fq;
		elseif DAE.f_takes_inputs == 0
            DAE.fq_of_S = field_value;
        	DAE.fq = @DAE_fq_no_u;
		else
        	error (['ERROR in add_to_DAE(): Please define .f_takes_inputs before .fq ']);
		end
	
	elseif strcmp(field_name, 'B')
		DAE.B = @(DAE)(feval(field_value,DAE_Bstruct(DAE)));
		DAE.B_of_S = field_value;

	elseif strcmp(field_name ,'C')
		DAE.C = field_value;
	
	elseif strcmp(field_name ,'D')
		DAE.D = field_value;
	
    elseif strcmp (field_name, 'limiting')
		DAE.NRlimiting = @(x, xlimOld, u, DAE)(feval(field_value,DAE_fstruct(x, xlimOld, u, DAE)));
		DAE.NRlimiting_of_S = field_value;

    elseif strcmp (field_name, 'initguess')
		DAE.NRinitGuess = @(u, DAE)(feval(field_value,DAE_ustruct(u, DAE)));
		DAE.NRinitGuess_of_S = field_value;

	elseif strcmp(field_name ,'internalfunc')
        DAE.internalfuncs = @(X, XLim, U, DAE)(feval(field_value, DAE_fstruct(X, U, DAE)));
		DAE.internalfuncs_of_S = field_value;
	
	elseif strcmp(field_name ,'uniqIDstr')
		DAE.uniqIDstr = field_value;

	elseif strcmp(field_name ,'nameStr') || strcmp(field_name ,'name')
		DAE.nameStr = field_value;
	
	elseif strcmp(field_name, 'unkname(s)') || strcmp(field_name, 'unkname') ...
                                            || strcmp(field_name, 'unknames')
		for i=1:length(field_value)
            % JR, 2015/07/16: weird errors occur for unknowns named 'i', 'v1',
            % v2, v3, etc.. exists returns 7 (directory), but cannot find
            % such directories in MAPP or even in the MATLAB installation.
            % Ignoring for the moment.
            % field_value{i}
            % exist(field_value{i})
            % who(field_value{i})
			if exist(field_value{i}) ~= 0
				warning(['Potential name conflict with unknown named ', field_value{i}, ' detected']);
			end
            % JR, 2015/07/16: found no check against unknameList, fixing...
            if sum(strcmp(field_value{i}, DAE.unknameList)) > 0
                error('unknown %s already exists in DAE', field_value{i});
            else
		        DAE.unknameList{end+1} = field_value{i};
            end
		end

	elseif strcmp(field_name,'eqnname(s)') || strcmp(field_name, 'eqnname')...
                                            || strcmp(field_name, 'eqnnames')
		for i=1:length(field_value)
            % JR, 2015/07/16: found no check against unknameList, fixing...
            if sum(strcmp(field_value{i}, DAE.eqnnameList)) > 0
                error('eqn name %s already exists in DAE', field_value{i});
            else
		        DAE.eqnnameList{end+1} = field_value{i};
            end
        end
	elseif strcmp(field_name, 'inputname(s)') ...
           || strcmp(field_name,'inputname') || strcmp(field_name,'inputnames')
		for i=1:length(field_value)
			if exist(field_value{i}) ~= 0
				warning(['Potential name conflict with input named ', field_value{i}, ' detected']);
			end
            % JR, 2015/07/16: found no check against inputnameList, fixing...
            if sum(strcmp(field_value{i}, DAE.inputnameList)) > 0
                error('input %s already exists in DAE', field_value{i});
            else
		        DAE.inputnameList{end+1} = field_value{i};
            end
		end

	elseif strcmp(field_name ,'outputname(s)') ...
           || strcmp(field_name,'outputname') ...
           || strcmp(field_name,'outputnames')
		for i=1:length(field_value)
            % JR, 2015/07/16: found no check against outputnameList, fixing...
            if sum(strcmp(field_value{i}, DAE.outputnameList)) > 0
                error('output %s already exists in DAE', field_value{i});
            else
		        DAE.outputnameList{end+1} = field_value{i};
            end
        end

	elseif strcmp(field_name ,'parm(s)') || strcmp(field_name ,'parm') ...
            || strcmp(field_name ,'parms') || strcmp(field_name ,'param') ...
            || strcmp(field_name ,'params')
		for i=1:2:length(field_value)
			if exist(field_value{i}) ~= 0
				warning(['Potential name conflict with parameter name ', field_value{i}, ' detected']);
			end
		end
        for idx = 1 : 1 : (length(field_value)/2)
            % JR, 2015/07/16: found no check against parmnames, fixing...
            pname = field_value{2*idx-1};
            if sum(strcmp(field_value{i}, DAE.parmnameList)) > 0
                error('parameter %s already exists in DAE', field_value{i});
            else
			    DAE.parmnameList{end+1} = pname;
			    DAE.parm_defaults{end+1} = field_value{2*idx};
			    DAE.parms{end+1} = field_value{2*idx};
            end
		end

	elseif strcmp(field_name ,'limitedvarname(s)') ...
            || strcmp(field_name ,'limitedvarname') ...
            || strcmp(field_name ,'limitedvarnames')
		for i=1:length(field_value)
			if exist(field_value{i}) ~= 0
				warning(['Potential name conflict with limited variable name ', field_value{i}, ' detected']);
			end
            % JR, 2015/07/16: found no check against parmnames, fixing...
            if sum(strcmp(field_value{i}, DAE.limitedvarnameList)) > 0
                error('limited var %s already exists in DAE', field_value{i});
            else
		        DAE.limitedvarnameList{end+1} = field_value{i};
            end
		end

	elseif strcmp(field_name ,'limited_matrix') || ...
                                    strcmp(field_name ,'limited_var_matrix')
		DAE.x_to_xlim_matrix = field_value;
	else
        error (['ERROR in add_to_DAE(): Unrecognized field ', field_name]);
	end

	out = DAE;
end

function out = DAE_f(x, xlim, u, DAE)
	if 3 == nargin
		DAE = u; u = xlim;
		xlim = feval(DAE.xTOxlim, x, DAE);
	end
	out = feval(DAE.f_of_S, DAE_fstruct(x, xlim, u, DAE));
end % DAE_f

function out = DAE_f_no_u(x, xlim, DAE)
	if 2 == nargin
		DAE = xlim;
		xlim = feval(DAE.xTOxlim, x, DAE);
	end
	out = feval(DAE.f_of_S, DAE_qstruct(x, xlim, DAE));
end % DAE_f_no_u

function out = DAE_q(x, xlim, DAE)
	if 2 == nargin
		DAE = xlim;
		xlim = feval(DAE.xTOxlim, x, DAE);
	end
	out = feval(DAE.q_of_S, DAE_qstruct(x, xlim, DAE));
end % DAE_q

function [fout, qout] = DAE_fq(x, xlim, u, flag, DAE)
	if 4 == nargin
		DAE = flag; flag = u; u = xlim;
		xlim = feval(DAE.xTOxlim, x, DAE);
	end
	S = DAE_fqstruct(x, xlim, u, DAE);
	S.flag = flag;
	[fout, qout] = feval(DAE.fq_of_S, S);
end % DAE_f

function [fout, qout] = DAE_fq_no_u(x, xlim, flag, DAE)
	if 3 == nargin
		DAE = flag; flag = xlim;
		xlim = feval(DAE.xTOxlim, x, DAE);
	end
	S = DAE_qstruct(x, xlim, DAE);
	S.flag = flag;
	[fout, qout] = feval(DAE.fq_of_S, S);
end % DAE_f_no_u
