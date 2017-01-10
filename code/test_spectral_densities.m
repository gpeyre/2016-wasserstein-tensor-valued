%%
% Test for matrix-valued densities.
% Need to implement a windowing estimator. 

addpath('toolbox/');
addpath('toolbox_quantum/');
addpath('data/textures/');

name = 'stonewall';
name = 'grayfabric';

f = load_image(name);
n0 = size(f,1);

% window for estimation
n = 64;
w = sin( pi*(0:n-1)'/n ).^2; w = w*w';
% number of extracted window
q = 4000;

T = zeros(3,3,n,n);
for it=1:q
    progressbar(it,q);
    a = 1+floor(rand(2,1)*(n0-n));
    h = repmat(w, [1 1 3]) .* f(a(1):a(1)+n-1, a(2):a(2)+n-1,:);
    H = fft2(h);
    for i=1:3
        for j=1:3
            T(i,j,:,:) = T(i,j,:,:) + reshape(H(:,:,i) .* conj(H(:,:,j)), [1 1 n n]);
        end
    end
end
T = T/q;

% extract eigenvalues
S = zeros(n,n,3); U = [];
for i=1:n
    for j=1:n
        [U(:,:,i,j),s] = eig(T(:,:,i,j)); s = diag(s);
        S(i,j,:) = reshape( s, [1 1 3] ); 
    end
end

% anisotropy ratio
A = ( S(:,:,3)-S(:,:,2) ) ./ ( S(:,:,3)+S(:,:,2) );
B = ( S(:,:,2)-S(:,:,1) ) ./ ( S(:,:,2)+S(:,:,1) );

img = @(x)imagesc(fftshift(x));
clf; 
subplot(2,2,1);
img(log(S(:,:,3))); axis image; axis off; colorbar;
title('log(Amplitude)');
subplot(2,2,2);
img(A); axis image; axis off; colorbar;
title('Anisotropy 3/2');
subplot(2,2,3);
img(B); axis image; axis off; colorbar;
title('Anisotropy 3/2');
subplot(2,2,4);
a = U(:,1,:,:);
imageplot( squeeze(a(1,:,:,:) ) );
title('Orientation');
colormap jet(256); 

