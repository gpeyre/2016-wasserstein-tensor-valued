%%
% test for DTI imaging data loading/analyzing.

addpath('/Users/gpeyre/Dropbox/work/wasserstein/wasserstein-tensor-valued/franco_brain_data');

rep = 'results/dti/';
[~,~] = mkdir(rep);

subj = {'three' 'four'};
btype = [2000 2000];

subj = {'one' 'two'};
btype = [1000 2000];


resh = @(x)reshape(x, [2 2 size(x,3)*size(x,4)]);
iresh = @(x)reshape(x, [2 2 sqrt(size(x,3)) sqrt(size(x,3))]);

for k=1:2
    t = k-1;
    % loading
    load(['subj_' subj{k} '_dwi_data_b' num2str(btype(k)) '_aligned_trilin_dt.mat']);    
    N0 = [size(slice,1), size(slice,2)];
    Mu{k} = permute( reshape( slice, [N0 3 3] ), [3 4 1 2]);
    % cropping
    
    n1 = 25; sub = 1;
    sx = 25 + (0:sub:n1-1);
    sy = 65 + (0:sub:n1-1);
    
    n1 = 50; sub = 2;
    sx = 20 + (0:sub:n1-1);
    sy = 40 + (0:sub:n1-1);
    
    n = n1/sub;
    mu{k} = resh( Mu{k}(1:2,1:2,sx,sy) );
    % display
    opt.nb_ellipses = 25;
    opt.image = trM(iresh(mu{k}),1);
    opt.color = [t 0 1-t];
    clf; plot_tensors_2d(iresh(mu{k}), opt);
    saveas(gcf, [rep 'input-' num2str(k) '.png'], 'png');
end


%%
% Compute the coupling using Sinkhorn. 

% Ground cost
c = ground_cost(n,2);
% regularization
epsilon = (.08)^2;  % medium
% fidelity
rho = 1;  %medium

options.niter = 250; % ok for .05^2
options.disp_rate = NaN;
options.tau = 1.8*epsilon/(rho+epsilon);  % prox step, use extrapolation to seed up
fprintf('Sinkhorn: ');
[gamma,u,v,err] = quantum_sinkhorn(mu{1},mu{2},c,epsilon,rho, options);

%%
% Compute interpolation using an heuristic McCann-like formula.

m = 9;
opt.sparse_mult = 100;
opt.disp_tensors = 1;
fprintf('Interpolating: ');
nu = quantum_interp(gamma, mu, m, 2, opt);

%%
% Display with no backgound texture.

for k=1:m
    t = (k-1)/(m-1);
    opt.color = [t 0 1-t];
    opt.image = trM(iresh(nu{k}),1);
    clf; plot_tensors_2d(iresh(nu{k}), opt); drawnow;
    saveas(gcf, [rep 'interpol-ellipses-' num2str(k) '.png']);
end

