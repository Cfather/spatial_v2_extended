clear 
N = 3;

% Create a random model with N links
model = autoTree(N, 1, pi/3);
model.jtype{1} = 'Fb';
model = postProcessModel(model);

% Random inertial properties
for i = 1:model.NB
    model.I{i} = inertiaVecToMat( rand(10,1) );
    model.I_rotor{i} = inertiaVecToMat( rand(10,1) );
end
[a, a_rot] = getModelInertialParams(model);

% Random configuration and velocity
q   = rand(model.NQ,1);
q   = normalizeConfVec(model, q); 
qd = rand(model.NV,1);

% Compute CMM with CMM algo
[Ag, Agd_qd] = CMM(model,q, qd);
[Ag2] = CMM_from_CRBA(model,q);

% Total energy and momentum from EnerMo
ret = EnerMo( model, q, qd );
p0G = ret.cm;
X0G = [eye(3) zeros(3);  skew2(p0G) eye(3)];
hG = X0G'*ret.htot;

checkValue('Centroidal Momentum', hG, Ag2*qd)
checkValue('Centroidal Mom Matrix', Ag, Ag2)

 dt = sqrt(eps)*1i;
q_new = configurationAddition(model,q,dt*qd);
Ag_new = CMM(model,q_new);
Agdot = CMMTimeDerivative(model, q, qd);
Agdot_finite_difference = real( (Ag_new-Ag) / dt );

checkValue('Centroidal Mom Matrix Time Derivative', Agdot, Agdot_finite_difference)
checkValue('Agdot_qdot', Agd_qd, Agdot*qd)


function checkValue(name, v1, v2, tolerance)
    if nargin == 3
        tolerance = sqrt(eps);
    end
    value = norm(v1(:)-v2(:));
    fprintf('%s \t %e\n',name,value);
    if value > tolerance
        error('%s is out of tolerance',name);
    end
end




    