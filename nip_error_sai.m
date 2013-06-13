function [sai, Ms, Mr] = nip_error_sai(cortex, J_sim,J_rec, r)
% [sai] = nip_error_sai(cortex, J_sim,J_rec, r)
%
% Computes an spatial accuracy index to evaluate the spatial quality of an
% inverse solution.
%
% Input:
%       cortex -> struct. Describes the volume to be drawn. Should contain
%               the fields 'faces' and 'vertices' corresponding to the graph 
%               of the tessellated brain surface.
%       J_sim -> NdxNt. Simulated brain activity.
%       J_rec -> NdxNt. Reconstructed brain activity.
%       r -> scalar. If a local maximum in the reconstructed activity is
%           with a radius r of a local maximum in the simulated activity, then
%           it is considered a True Positive
% Output:
%       sai -> scalar. Spatial Accuracy Index
%       Ms ->   Ndx1. Indexes local maxima of the simulated activity 
%                   Contains 1 if the corresponding dipole is a
%                   local maximum. 0 otherwise.
%       Mr ->   Ndx1. Indexes local maxima of the reconstructed activity 
%                   Contains 1 if the corresponding dipole is a
%                   local maximum. 0 otherwise.
%
% Additional Comments: See Belardinelli et al 2012 for further information about
% this error measurement (Source Reconstruction Accuracy of MEG and EEG...)
%
% TO FIX: At the moment, it "tries" to normalize with respect to the
% average distance between neighboring dipoles. But it does not work
% completely good.
%
% Juan S. Castano C.
% 20 May 2013.


% Search for a file with the precompute geodesic distances. If not found,
% computes them and saves them in a file (This WILL take a while, grab a
% snickers).
Nd = num2str(size(cortex.vertices,1));
file_name = strcat(fileparts(which('nip_init')),'/data/','dist_mat',num2str(Nd),'.mat');
A    = triangulation2adjacency(cortex.faces);
if exist(file_name,'file')
    load(file_name)
else    
    D   = compute_distance_graph(A);
    save(file_name,'D');
end

Nd = size(cortex.vertices,1);

% Calculate mean distance between neighboring dipoles.
n = 0;
meanDist = 0;
for i = 1:Nd
    for j = find(A(:,i))'
        meanDist = meanDist + norm(cortex.vertices(i,:)-cortex.vertices(j,:));
        n = n + 1;
    end
end
meanDist = meanDist/n;
D = D*meanDist;

GeoD = D;

% Create spatial "masks"
sp_tol = 0.5; % If the energy of a dipole is the biggest within an area of sp_tol, then it is a local maxima
idx = find(D > sp_tol);
D(idx) = 0;
idx = find(D);
D(idx) = 1;
D = D+speye(Nd);

% Average activity and Normalize
Es = mean(J_sim.^2,2);
Es = Es-min(Es);
Es = Es/max(Es);
Er = mean(J_rec.^2,2);
Er = Er-min(Er);
Er = Er/max(Er);

% Threshold values of the average (denoise(?))
thr = 0.05;
idx = find(Es < thr);
Es(idx) = 0;
idx = find(Er < thr);
Er(idx) = 0;

% Find local maxima
Ms = sparse(Nd,1);
Mr = sparse(Nd,1);
for i = find(Es)'  
    % Check if activity in the i-th vertex is a local maxima in the
    % simulated activity
    Cpatch = D(:,i).*Es;
    idx = find(Cpatch > Es(i));
    if sum(idx)==0
        Ms(i) = 1;
    end
end
for i = find(Er)'  
    % The same thing for the reconstructed activity    
    Cpatch = D(:,i).*Er;
    idx = find(Cpatch > Er(i));
    if sum(idx)==0
        Mr(i) = 1;
    end
end


TP = 0; % True positives
FP = 0; % False positives
D = GeoD;
idx = find(D > r);
D(idx) = 0;
idx = find(D);
D(idx) = 1;
D = D+speye(Nd);
for i = find(Mr)'
    if sum(D(:,i).*Ms) > 0
        TP = TP + 1;
    else
        FP = FP + 1;
    end
end

sai = TP/(TP+FP);
   
end

