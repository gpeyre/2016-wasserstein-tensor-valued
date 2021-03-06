function mu = load_tensors_pair(name,N, options)

% load_tensors_pair - load tensors fields
%
%    mu = load_tensors_pair(name,N);
%
%   Copyright (c) 2016 Gabriel Peyre

options.null = 0;
normalize = @(x)x/sum(x(:));
% generation of tensor from angle/aniso/scale
tensor = @(t,r,s)tensor_mult(tensor_creation(r, t), tensor_diag(s,s) );

n = N(1);

% helpers 1D
x = linspace(0,1,n)';
vmin = .03;
gaussian1 = @(m,s)exp(-(x-m).^2/(2*s^2));
gaussian  = @(m,s)normalize(vmin + exp(-(x-m).^2/(2*s^2)));
dirac = @(i)[zeros(i-1,1); 1; zeros(n-i,1)];

% helpers 2D
[Y,X] = meshgrid(x,x);
gaussian2d    = @(m,s)exp( -( (X-m(1)).^2 + (Y-m(2)).^2 )/(2*s^2) );
gaussian2dani = @(m,s)exp( -(X-m(1)).^2/(2*s(1)^2) - (Y-m(2)).^2/(2*s(2)^2) );

% orient / aniso / scale 
t = {}; r = {}; s = {}; 
mu = {};
switch name
    case '2d-aniso-fields'
        s = getoptions(options, 'smoothness', 5);
        a = getoptions(options, 'aniso', .025);
        x = [0:n/2-1, -n/2:-1];
        [Y,X] = meshgrid(x,x);
        h = exp( (-X.^2-Y.^2)/(2*s^2) );  h = h/sum(h(:));
        gsmooth = @(x)real( ifft2( fft2(x).*repmat(fft2(h), [1 1 size(x,3)]) ) );
        randn('state', 123);
        for k=1:2
            % random periodic gaussian fields
            e1 = gsmooth(randn(n,n,2));
            e1 = e1 ./ repmat( sqrt(sum(e1.^2,3)), [1 1 2] );
            e2 = cat(3, -e1(:,:,2), e1(:,:,1));
            % variations in size
            g = hist_eq(gsmooth(randn(n,n)), linspace(.1,1,n*n) ); % variation in size
            % variation in anisotropy
            h = hist_eq(gsmooth(randn(n,n)), linspace(.1,.5,n*n) );
            mu{k} = tensor_eigenrecomp(e1,e2,g.*h,g*a);
        end
    case 'iso-orient'
        % first
        t{1} = x*pi;
        r{1} = 1-( .5+x )/1.5;
        s{1} = gaussian(.2,.05);
        % second
        t{2} = (1-x)*pi;
        r{2} = 1-(.5 + 1-x )/1.5;
        s{2} = gaussian(.8,.05);
    case 'cross-orient'
        % first
        t{1} = x*pi;
        r{1} = 1-( .5+x )/1.5;
        s{1} = gaussian(.2,.05);
        % second
        t{2} = x*pi + .3;
        r{2} = 1-(.5 + 1-x )/1.5;
        s{2} = gaussian(.8,.05);
        
    case 'multi-orient'
        % first
        t{1} = x*pi;
        r{1} = x*0+.75;
        s{1} = normalize(x*0+1);
        % second
        t{2} = -x*pi + pi;
        r{2} = x*0+.75;
        s{2} = normalize(x*0+1);
        
    case 'aniso-iso'
        % first
        t{1} = x*pi;
        r{1} = .9-x.^3;
        s{1} = normalize(x*0+1);
        % second
        t{2} = -x*pi + pi;
        r{2} = x;
        s{2} = normalize(x*0+1);
        
    case 'split'
        % first
        t{1} = x*0+0;
        r{1} = x*0 + .7; 
        s{1} = gaussian(.5,.05);
        % second
        t{2} = 1.5*x*pi+.3;
        r{2} = x*0 + .7; 
        s{2} = normalize( gaussian(.15,.05) + gaussian(.85,.05) );
        
    case 'dirac-pairs'
        I = round(n*[.2 .8]); 
        u = dirac(I(1)); v = dirac(I(2));
        vmin = .01;
        s = {vmin + u+v, vmin + u+v};
        t = {.3*pi*u + 1.3*pi*v, .3*pi*v + 1.3*pi*u};
        r = {.95*ones(n,1) .95*ones(n,1)};
        
    case 'dirac-pairs-smooth'        
        % orient / aniso / scale 
        aniso = getoptions(options, 'aniso', .9);
        vmin = 1e-5;
        sigma = .075;
        m = .12;
        u = gaussian1(m,sigma); v = gaussian1(1-m,sigma);
        a = [ones(n/2,1); zeros(n/2,1)]; b = 1-a;
        t{1} = .3*pi*b + 1.3*pi*a; 
        r{1} = aniso*ones(n,1); 
        s{1} = vmin + u + v; 
        %
        u = gaussian1(m,sigma); v = gaussian1(1-m,sigma);
        t{2} = .3*pi*a + 1.3*pi*b; 
        r{2} = aniso*ones(n,1); 
        s{2} = vmin + u + v; 
        
    case '2d-smooth-rand'
        sigma = getoptions(options, 'sigma', 50);
        for i=1:2
            [mu{i},T] = load_rand_2d(n, sigma);
        end
        
    case '2d-iso-bump'
        t = {zeros(n) zeros(n)}; % orient
        r = {zeros(n) zeros(n)}; % aniso
        sigma = .08;
        s = {gaussian2d([.2 .2], sigma) ,  gaussian2d([.8 .8], sigma)};
        
    case '2d-mixt-bump'
        z = zeros(n/2,n);
        t = {[z+pi/4;z+3*pi/4] ...
             [z+3*pi/4;z+pi/4]}; % orient
        r = {ones(n)*.8 ones(n)*.8}; % aniso
        sigma = .05;
        s = {gaussian2d([.2 .2], sigma)+gaussian2d([.8 .2], sigma) ,...
             gaussian2d([.2 .8], sigma)+gaussian2d([.8 .8], sigma)};
        
        
    case '2d-bump-donut'
        aniso = .8;
        sigma = .13;
        sigmar = .13;
        radius = .9;
        %
        aniso = .97;
        sigma = .15;
        sigmar = .14;
        t = linspace(-1,1,n);
        [Y,X] = meshgrid(t,t); R = sqrt(X.^2+Y.^2); T = atan2(Y,X)*2;
        t = {T, zeros(n)}; % orient
        r = {ones(n)*aniso, zeros(n)};
        s = {exp(-(R-radius).^2/(2*sigmar^2)), gaussian2d([.5 .5], sigma)};    
        
        
    case '2d-corners-bar'
        t = linspace(-1,1,n);
        [Y,X] = meshgrid(t,t); R = sqrt(X.^2+Y.^2); T = atan2(Y,X)*2;
        t = {zeros(n)+pi, T}; % orient
        r = {ones(n)*.8, ones(n)*.8};
        sigma = .06; % for bumps in corners
        sigmar = .13; v = .15;
        s = {gaussian2dani([.5 .5], [.07 10]), ...
            gaussian2d([v v], sigma) + ...
            gaussian2d([1-v v], sigma) + ...
            gaussian2d([v 1-v], sigma) + ...
            gaussian2d([1-v 1-v], sigma) ...
            }; 
        
    case '2d-bary'
        C1 = load_tensors_pair('2d-corners-bar',N, options);
        C2 = load_tensors_pair('2d-bump-donut',N, options);
        mu = { C1{:}, C2{:} };
        
    case {'plate-elong' 'aniso-iso-3x3'}
        %%% 3D %%%
        [mu] = load_3x3(name,n);
end

if isempty(mu)
for i=1:length(t)
    mu{i} = tensor(t{i},r{i},s{i});
end
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [C1,T] =  load_rand_2d(n, sigma)

op = load_helpers(n);
T0 = op.tensorize(randn(n,n,2));
T = op.blur( T0, sigma);
% remat the eigenvalues to a target anisotropy
[e1,e2,l1,l2] = tensor_eigendecomp(op.T2C(T));
[a,e] = eigen_remaper(l1,l2,+1);
[L1,L2] = eigen_remaper(ones(n)*.9,e,-1);
C1 = tensor_eigenrecomp(e1,e2,L1,L2);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mu] = load_3x3(name,n)

% cross product
crossp = @(a,b)[a(:,2).*b(:,3)-a(:,3).*b(:,2), -a(:,1).*b(:,3)+a(:,3).*b(:,1), a(:,1).*b(:,2)-a(:,2).*b(:,1)];
dotp3 = @(a,b)sum(a.*b,2);
normalize3 = @(x)x ./ repmat(sqrt(sum(x.^2,2)), [1 3]);
tprod1 = @(a,b)[...
    a(1,1,:).*b(1,1,:), a(1,1,:).*b(1,2,:), a(1,1,:).*b(1,3,:); ...
    a(1,2,:).*b(1,1,:), a(1,2,:).*b(1,2,:), a(1,2,:).*b(1,3,:); ...
    a(1,3,:).*b(1,1,:), a(1,3,:).*b(1,2,:), a(1,3,:).*b(1,3,:)];
tprod = @(a,b)tprod1( reshape(a', [1 3 size(a,1)]), reshape(b', [1 3 size(a,1)]) );

x = (0:n-1)'/n;
vmin = .03;
gaussian = @(m,s)exp(-(x-m).^2/(2*s^2));

vmin  = .03;
sigma = .07;
aniso = .15;

switch name
    case 'plate-elong'
        % elongated tensors
        Theta{1} = x*2*pi;
        Phi{1}   = x*pi;
        S{1} = vmin + gaussian(.2,sigma); % size
        Alpha{1} = 1*S{1};
        Beta{1} = .15*S{1};
        % flat tensors
        Theta{2} = (1-x)*2*pi;
        Phi{2}   = x.^2*pi;
        S{2} = vmin + gaussian(.8,sigma); % size
        Alpha{2} = .15*S{2};
        Beta{2} = 1*S{2};
    case 'aniso-iso-3x3'
        Theta{1} = x*pi;
        Phi{1}   = x*pi;
        Alpha{1} = 1-x;
        Beta{1} = x;
        % flat tensors
        Theta{2} = (1-x)*2*pi;
        Phi{2}   = x.^2*pi;
        Alpha{2} = x;
        Beta{2} = x*0+1;
end

for k=1:2
    theta = Theta{k};
    phi = Phi{k};
    alpha = Alpha{k};
    beta = Beta{k};
    % eigenvectors
    e{1} = [cos(theta).*sin(phi), cos(theta).*cos(phi), sin(theta)];
    e{2} = normalize3( crossp(e{1},randn(n,3)) );
    e{3} = normalize3( crossp(e{1},e{2}) );
    % sume of rank 1
    remap = @(x)repmat(reshape(x,[1 1 n]), [3 3 1]);
    mu{k} = remap(alpha).*tprod(e{1},e{1}) + remap(beta).*tprod(e{2},e{2}) + remap(beta).*tprod(e{3},e{3});
end

end