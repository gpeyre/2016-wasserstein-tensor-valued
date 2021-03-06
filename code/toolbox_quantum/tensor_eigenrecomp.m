function T = tensor_eigenrecomp(e1,e2,l1,l2)

% perform_tensor_recomp - create the tensor field corresponding to the given eigendecomposition.
%
%   T = tensor_eigenrecomp(e1,e2,l1,l2);
%
%   'e1(i,j,:)' is the main eigenvector at location (i,j)
%       with associated largest eigenvalue 'l1(i,j)'.
%   'e2(i,j,:)' is the second eigenvector at location (i,j)
%       with associated smallest eigenvalue 'l2(i,j)'.
%
%   You have
%       T = l1*e1*e1' + l2*e2*e2'
%
%   Copyright (c) 2004 Gabriel Peyre

if isreal(e1)
    T = zeros( [size(l1),2,2] );
    T(:,:,1,1) = l1.*e1(:,:,1).^2 + l2.*e2(:,:,1).^2;
    T(:,:,1,2) = l1.*e1(:,:,1).*e1(:,:,2) + l2.*e2(:,:,1).*e2(:,:,2);
    T(:,:,2,1) = T(:,:,1,2);
    T(:,:,2,2) = l1.*e1(:,:,2).^2 + l2.*e2(:,:,2).^2;
else
    T = zeros( [size(l1),2,2] );
    T(:,:,1,1) = l1.*abs(e1(:,:,1)).^2 + l2.*abs(e2(:,:,1)).^2;
    T(:,:,1,2) = l1.*e1(:,:,1).*conj(e1(:,:,2)) + l2.*e2(:,:,1).*conj(e2(:,:,2));
    T(:,:,2,1) = conj(T(:,:,1,2));
    T(:,:,2,2) = l1.*abs(e1(:,:,2)).^2 + l2.*abs(e2(:,:,2)).^2;
end
T = permute(T, [3 4 1 2]);

end
