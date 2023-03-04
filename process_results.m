function results = process_results(t, species)
    
    default('t', []);
    default('species', []);

    vessel      = settings_utils.model.vessel;
    G           = io_utils.get_graph; 
    
    results.nodal_pressure = io_utils.get_graph.Nodes.pressure;
    results.l = io_utils.get_graph.Edges.branch_length;
    results.edge_velocity = io_utils.get_graph.Edges.velocity_um_sec;
    results.qdot = io_utils.get_graph.Edges.qdot_um3_sec;
    results.tau = sum(io_utils.get_graph.Edges.tau);
    results.G = io_utils.get_graph.Edges.G;
    results.mid_xpos = io_utils.get_graph.Edges.mid_xpos;
    results.mid_ypos = io_utils.get_graph.Edges.mid_ypos;
    results.mid_zpos = io_utils.get_graph.Edges.mid_zpos;
    results.t = t*60; % convert from min to secs
    results.species = species;

    %-------------------------------------------------------------------------------------
    % process results of vessel + cell species for a single run
    %-------------------------------------------------------------------------------------
    if  vessel == false
        nnode = height(io_utils.get_H.Nodes);
        rxn_nodes = model_utils.rxn_nodes;
        
        [C, V] = plot_utils.sep_C_V(species);
        Cstruct = plot_utils.get_Cstruct(C);
        cfields = fieldnames(Cstruct);

        for f = 1:length(cfields)
            conc = Cstruct.(cfields{f});
            % multiply with a conversion factor for units required for plotting
            conc = conc*plot_utils.get_model2plot_unitconversion(cfields{f});
            
            values = zeros(length(t),nnode);
            values(:,rxn_nodes) = conc;
            results.(cfields{f}) =  values;
        end

        Vstruct = plot_utils.get_Vstruct(V);
        vfields = fieldnames(Vstruct);

        for f = 1:length(vfields)
            conc = Vstruct.(vfields{f});
            % multiply with a conversion factor for units required for plotting
            conc = conc*plot_utils.get_model2plot_unitconversion(vfields{f});
            results.(vfields{f}) =  conc;
        end

        for row = 1:length(t)
            [flux, ~] = reactor([], C(row,:)', V(row,:)') ;
            glcim(row,:) = flux(1:model_utils.NRxn);
            lacex(row,:) = flux(model_utils.NRxn+1:end);
        end

         results.glcim = glcim;
         results.lacex = lacex;
         results.glcim_net = sum(glcim(end,:),2);
         results.lacex_net = sum(lacex(end, :),2);

    %-------------------------------------------------------------------------------------
    % process results of vessel species for a single run
    %-------------------------------------------------------------------------------------

    elseif vessel == true
        Vstruct = plot_utils.get_Vstruct(species);
        vfields  = fieldnames(Vstruct);

        for f = 1:length(vfields)
            conc = Vstruct.(vfields{f});
            % multiply with a conversion factor for units required for plotting
            conc = conc*plot_utils.get_model2plot_unitconversion(vfields{f});
            results.(vfields{f}) =  conc;
            % peclet number
            results.(strcat('pe_', vfields{f})) = (G.Edges.segment_dia.*G.Edges.velocity)./G.Edges.(strcat(vfields{f}, '_dispersion'));
        end
        if settings_utils.NVs == 1
            results.(strcat('tss_', vfields{f})) = model_utils.get_tss(t*60, species);
            results.(strcat('rt_', vfields{f})) = model_utils.get_rt(t*60, species);
        end 
        
    end

end
