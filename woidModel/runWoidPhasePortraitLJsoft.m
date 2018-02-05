function [] = runWoidPhasePortraitLJsoft(N,L)
% run simulations of simplified woid model with single node per woid
% for various speeds, attractions strengths, reversal probabilities...

% issues/todo:

% general model parameters for all test - unless set otherwise
% N = 40; % N: number of objects
M = 36; % M: number of nodes in each object
% L = [7.5, 7.5]; % L: size of region containing initial positions - scalar will give circle of radius L, [Lx Ly] will give rectangular domain
if numel(L)==1
    L = [L, L];
end
T = 1000; % T: simulation duration
rc = 0.035;
% saveevery = round(1/2/param.dT);
paramAll.bc = 'periodic'; % bc: boundary condition, 'free', 'periodic', or 'noflux' (default 'free'), can be single number or 2 element array {'bcx','bcy'} for different bcs along different dimensions
paramAll.segmentLength = 1.13/(M - 1);
paramAll.k_l = 80;
% -- slow-down parameters --
paramAll.vs = 0.018;% vs: speed when slowed down (default v0/3)
paramAll.slowingNodes = [1:M];% slowingNodes: which nodes register contact (default head and tail)
paramAll.slowingMode = 'stochastic_bynode';
paramAll.k_dwell = 0.0036;
paramAll.k_undwell = 1.1;
% -- Lennard-Jones parameters --
paramAll.r_LJcutoff = 3.75*rc;% r_LJcutoff: cut-off above which LJ-force is not acting anymore (default 0)
paramAll.sigma_LJ = 2*rc;  % particle size for Lennard-Jones force
paramAll.eps_LJ = 5e-3;
if paramAll.eps_LJ<=0
    paramAll.r_LJcutoff = -1; % don't need to compute attraction if it's zero
end
paramAll.LJmode = 'soft';
% % -- haptotaxis
% paramAll.f_hapt = 0.2;
% -- speed and time-step --
paramAll.v0 = [0.33]; % npr1 0.33; N2 0.14
paramAll.dT = min(1/2,rc/paramAll.v0/16); % dT: time step, scales other parameters such as velocities and rates
paramAll.saveEvery = round(1/paramAll.dT);

numRepeats = 1;
revRatesClusterEdge = 0:5;
dkdN_dwell_values = 0:0.2:1;
paramCombis = combvec(revRatesClusterEdge,dkdN_dwell_values);
nParamCombis = size(paramCombis,2);
for repCtr = 1:numRepeats
    for paramCtr = 1:nParamCombis
        param = paramAll;
        param.revRateClusterEdge =  paramCombis(1,paramCtr);
        param.dkdN_dwell = paramCombis(2,paramCtr);
        filename = ['woids_N_' num2str(N) '_L_' num2str(L(1)) ...
            '_v0_' num2str(param.v0,'%1.0e') '_vs_' num2str(param.vs,'%1.0e') ...
            '_' param.slowingMode 'SlowDown' '_dwell_' num2str(param.k_dwell) '_' num2str(param.k_undwell) ...
            '_dkdN_' num2str(param.dkdN_dwell)...
            '_revRateClusterEdge_' num2str(param.revRateClusterEdge,'%1.0e')...
            '_LJ' param.LJmode num2str(param.eps_LJ) ...
            ...'_haptotaxis_' num2str(param.f_hapt) ...
            '_run' num2str(repCtr)];
        filepath = 'results/woids/mapping/';
        if ~exist([filepath filename '.mat'],'file')...
                &&isempty(dir([filepath filename '_running_on_*.mat']))
            disp(['running ' filename])
            % make a dummy file to mark that this sim is running on this computer
            [~, hostname] = system('hostname -s'); hostname = strrep(hostname,newline,'');
            tmp_filename = [filepath filename '_running_on_' hostname '.mat'];
            save(tmp_filename,'N','M','L','param')
            rng(repCtr) % set random seed to be the same for each simulation
            [xyarray, currentState] = runWoids(T,N,M,L,param);
            xyarray = single(xyarray); % save space by using single precision
            save([filepath filename '.mat'],'xyarray','T','N','M','L','param','currentState')
            delete(tmp_filename)
        end
    end
end
end