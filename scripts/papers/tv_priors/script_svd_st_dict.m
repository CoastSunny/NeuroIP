% Script for dictionaries generated using the principal components of 
% time and space

% Así como está, no dio!
%% Init
clear; close all; clc;

verbose = true;

% Load data, define sample rate, number of eeg channels, etc...
load_data;

% Simulate brain activity and generate pseudo EEG
gen_eeg;

% Show simulated activity
if verbose
    nip_reconstruction3d(model.cortex,sqrt(sum(J.^2,2)),[]);
    pause(0.01)
end

%% Preprocessing
% Depth bias compensation
model.L = nip_depthcomp(model.L,0.1);

%% SVD freq decomposition

% Temporal modes (Ur)
[y_proj, y_rec, Ur, Er] = nip_tempcomp(model.y, model.t, [0.1 40], 2);
Npt = size(Ur,2);

% Spatial mdoes
yyt = model.y*model.y';
[U S V] = svd(yyt);
Us = U(:,1:20);

Nps = size(Us,2);
Np = Npt * Nps;

for i = 1:Npt
    for j = 1:Nps
        y_proj(i,j) = Us(:,j)'*model.y*Ur(:,i);
    end
end


if verbose
    figure('Units','normalized','position',[0.2 0.2 0.14 0.14]);
    Nh = ceil(sqrt(Np));
    Nw = ceil(sqrt(Np));
    ha = tight_subplot(Nh, Nw,  0.05, 0.1, 0.1);
%     for i = 1:Np;
%         axes(ha(i));
%         plot(model.t,(y_proj(:,i)*Ur(:,i)')');
%         title(strcat('Comp ',num2str(i)));
%     end
%     axes(ha(i+1))
%     plot(model.t,model.y')
%     title('Original')
%     pause(0.01)
end

% Spatial dictionary in case we solve with, for example, S-FLEX
sp_dict = nip_fuzzy_sources(model.cortex,2);
idx = find(sp_dict < 0.05*max(abs(sp_dict(:))));
sp_dict(idx) = 0;
sp_dict = sparse(sp_dict);
for i = 1:Npt
    for j = 1:Nps
        %     D(:,i) = nip_lcmv(y_proj(:,i),model.L);
        D(:,i+j*Npt) = nip_sflex(y_proj(i,j),Us(:,j)'*model.L,sp_dict, 1e-6);
        %     [aux,~] = nip_tfmxne_port(Ye(:,:,i),model.L,[])
        %     D(:,i) = sqrt(sum(aux.^2,2));
        %     D(:,i) = D(:,i) - mean(D(:,i));
        D(:,i+j*Npt)  = D(:,i+j*Npt)./norm(D(:,i+j*Npt));
        
        if verbose
            axes(ha(i+j*Npt) );
            nip_reconstruction3d(model.cortex,D(:,i+j*Npt) , []);
            pause(0.01)
        end
    end
end

L = model.L*D;


%% Compute hyperparameters and show results
h = nip_kalman_hyper(model.y,L);

if verbose
    figure('Units','normalized','position',[0.2 0.2 0.14 0.14]);
    plot(model.t,h')
    title('Temporal evolution of the hyperparameters')
    pause(0.01)
end

%% solve