function simulation()
%  SIMULATION https://in.mathworks.com/matlabcentral/fileexchange/7481-manuscript-of-solving-index-1-daes-in-matlab-and-simulink


%% settings of simulation run
tspan = settings_utils.run.tspan;
    
%% Integrator settings
options = odeset('abstol', 1e-10, 'reltol', 1e-9, 'Stats', 'on');

%% run
VSpecies = settings_utils.IC_Vspecies;
species0 = initial_conc(VSpecies);

% jacobian settings
f0 = factory(0, species0);
joptions = struct('diffvar', 2, 'vectvars', 2, 'thresh', 1e-8, 'fac', []);
J = odenumjac(@factory,{0 species0}, f0, joptions); 

sparsity_pattern = sparse(J~=0.);

if settings_utils.jpattern_set == true && settings_utils.jacobian_set == false
    options = odeset('abstol', 1e-6, 'reltol', 1e-3, 'Stats', 'on', 'JPattern', sparsity_pattern, 'Vectorized','on');
elseif settings_utils.jpattern_set == false && settings_utils.jacobian_set == true
    options = odeset('abstol', 1e-10, 'reltol', 1e-9, 'Stats', 'on', 'Jacobian', J, 'Vectorized','on');
elseif settings_utils.jpattern_set == true && settings_utils.jacobian_set == true
    options = odeset('abstol', 1e-10, 'reltol', 1e-9, 'Stats', 'on', 'JPattern', sparsity_pattern, 'Jacobian', J, 'Vectorized','on');                  
end

tic
[t, species]  = ode15s(@(t,s) factory(t,s), tspan , species0, options);
toc
results = process_results(t, species)
f_path = io_utils.get_task_dir;
io_utils.save_mat_struct(fullfile(f_path, "results"), results);

end