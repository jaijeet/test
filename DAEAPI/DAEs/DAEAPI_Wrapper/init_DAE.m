function DAE = init_DAE()
% Build the skeleton of DAEAPI

% Author: Bichen Wu <bichen@berkeley.edu> 2014/02/03
	DAE = DAEAPI_common_skeleton();
	DAE.B = @(arg) [];
	DAE.C = @(arg) [];
	DAE.D = @(arg) [];
	DAE.support_initlimiting = 1;
end
