function error_array = nip_calc_error(Y,L,J_sim,J_est)
% error_array = nip_calc_error(y,L,J_sim,J_est)
% Another function to calculate errors: y-LJ, J-J_rec and Jproj-J
% These measurements shouldn't be used I think....
%
% Juan S. Castano C.
% 3 Mar 2013

% Y = model.Y(:,model.fs*0.5:end);
% L = model.L;
J = J_sim;
% J_est = model.J_est(:,model.fs*0.5:end);
Y = full(Y);
L = full(L);
J = full(J);
J_est = full(J_est);
Nd = size(J,1);
Nc = size(Y,1);
Nt = size(J,2);
error_array = zeros(1,3);
res_error = norm(L*J_est - Y, 'fro')^2;
stan_error = sqrt(norm(J_est - J, 'fro'));
J_proj = zeros(size(J));
[U,S,V] = svd(L);
rank_L = rank(L);
for k = 1 : size(Y,2)
    for i = 1 : rank_L
        J_proj(:,k) = J_proj(:,k) + dot(J(:,k),V(:,i))*V(:,i);
    end
end
proj_error = norm(J_est - J_proj, 'fro');

error_array.res = res_error/(Nc*Nt);
error_array.rmse = stan_error/(Nd*Nt);
error_array.proj = proj_error/(Nd*Nt);
