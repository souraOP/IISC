function dS = factory(t,s)
model = settings_utils.model;
dS = zeros(size(s), 'like', s) ;

if model.vessel == false 
    % split the concentrations of reactor and vessel
    [C, V] = model_utils.sep_C_V(s); 
    [eflux, dC(:,:)] = reactor(t, C, V); 
    dV(:,:) = vessel(t, V, C, eflux);
    dS(:,:) = [dC;dV];
    
elseif model.vessel == true
    C = [];
    eflux = [];
    V = s;
    dV(:,:) = vessel(t, V, C, eflux);
    dS(:,:) = dV;
end
end