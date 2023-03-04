function species0 = initial_conc(VSpecies)
% run only blood vessel or both
model = settings_utils.model;

%% settings for initializing concentration at all nodes of vessel
init = model_utils.init_set;
pts  = graph_utils.get_pts_H;
%% Initialize

% reactor loop through species in cell C0

% vessel V0
V0 =[];
vessel_species = fieldnames(VSpecies);
if init.equal == true
    for i = 1:settings_utils.NVs %numel(vessel_species)
      V0 = vertcat(V0, VSpecies.(vessel_species{i})*ones(model_utils.get_NVertex,1));
    end

elseif init.equal == false    
    for i = 1:settings_utils.NVs %numel(vessel_species)
        V = zeros(model_utils.NVertex,1);
        %V = ones(model_utils.NVertex,1);
        V(pts.hNode) = VSpecies.(vessel_species{i}); 
        V0 = vertcat(V0, V);    
    end

else
    temp =  1.0*ones(model_utils.get_NVertex,1);
    for i = 1:model_utils.get_NVertex
        if rem(i,2) ==0
            temp(i) = 1.5;
        end
    end
    for i = 1:numel(vessel_species)
      V0 = vertcat(V0, VSpecies.(vessel_species{i})*temp);
    end
end

if model.vessel == false
    C0 =[];
    CSpecies = settings_utils.IC_Cspecies;
    cell_species = fieldnames(CSpecies);
    for i = 1:numel(cell_species)
      C0 = vertcat(C0, CSpecies.(cell_species{i})*ones(model_utils.NRxn,1));
    end
    species0 = vertcat(C0,V0);
else
    species0 = vertcat(V0);
end    
end