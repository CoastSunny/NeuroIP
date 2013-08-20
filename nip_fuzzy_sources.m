function aff = nip_fuzzy_sources(cortex, sigma, file_name)
% aff = nip_fuzzy_sources(cortex, sigma)
% This function returns a matrix that contains information about the
% distance between points in a graph. It places a gaussian with variance = sigma
% in each vertex
% Input:
%       cortex -> Struct. Structure containing the vertices and faces of
%       the graph
%       sigma -> Scalar. Variance of the gaussian placed at each vertex
% Output:
%       aff -> NdxNd. Symmetrical matrix in which the i-th column
%       represents the gaussian placed a round the i-th vertex.
%
% Additional comments: This function uses the graph toolbox to compute the
% distance between each vertex.
%
% Juan S. Castanoo C.
% jscastanoc@gmail.com
% 14 Mar 2013


if ~isfield(cortex, 'vc') && ~isfield(cortex,'tri')
    cortex.vc = cortex.vertices;
    cortex.vertices = [];
    cortex.tri = cortex.faces;
    cortex.faces = [];
end

% Nd = num2str(size(cortex.vc,1));
% A    = sparse(triangulation2adjacency(cortex.faces));

% Search for a file with the precompute geodesic distances. If not found,
% computes them and saves them in a file (This WILL take a while, grab a
% snickers). NOT ANYMORE!
% if nargin < 3
%     file_name = strcat(fileparts(which('nip_init')),'/data/','dist_mat',num2str(Nd),'.mat');
% end
% if exist(file_name,'file')
%     load(file_name)
% else
%     D   = compute_distance_graph(A);
%     save(file_name,'D');
% end

aff = graphrbf(cortex);
aff = exp(-aff.^2/sigma^2);