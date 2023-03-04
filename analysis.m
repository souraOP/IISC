%% Integrating using stiff solver ode15s
time_course = plot_utils.plot_set.tc;
heat_map    = plot_utils.plot_set.hmap;
molebalance = plot_utils.plot_set.molebalance;
flux        = plot_utils.plot_set.flux; 
single      = settings_utils.run.single;
gscan        = settings_utils.run.gscan;
vessel      = settings_utils.model.vessel;
xlimit      = model_utils.get_xlim;
p = 1;

%-------------------------------------------------------------------------------------
% analysis1: Plots time course profiles of vessel + cell species for a single run 
%-------------------------------------------------------------------------------------

if single == true && time_course == true && vessel == false
    %[tail,head] = graph_utils.input;
    g = graph_utils.input([],[],1,[]); %graph(tail,head);
    nnode = height(g.Edges);
    file = io_utils.get_simgraph_f;
    results = io_utils.load_mat(file);
    
    t  = results.t;
    species = results.species;
    
    [C, V] = plot_utils.sep_C_V(species);
    %% Plots : time course data of reactor species 
    Cstruct = plot_utils.get_Cstruct(C);
    fields = fieldnames(Cstruct);
    
    for f = 1:length(fields)
        [display_name, cmap] = plot_utils.get_display_name_cell;
        figure(2)
        subplot(1,2,p)
        conc = Cstruct.(fields{f});
        
        % multiply with a conversion factor for units required for plotting
        conc = conc*plot_utils.get_model2plot_unitconversion(fields{f});
        
        plt = plot(t*60,conc, 'Linewidth',1)
        set(gca,'ColorOrder',cmap);
        set(plt, {'DisplayName'}, display_name);
        
        legend show        
        title(fields{f})
        xlabel('time (s)')
        
        units = plot_utils.get_plot_units(fields{f});
        ylabel(strcat('concentration (',units,')'));
        xlim(xlimit)
        grid on
        %ax1 = gca;
        
        %% inset https://in.mathworks.com/matlabcentral/answers/60376-how-to-make-an-inset-of-matlab-figure-inside-the-figure
%         xinset = 60*t(1000:1500,:);
%         yinset = conc(1000:1500,:);
%         ax2 = axes('Position',[0.7 0.65 .15 .15])
%         box on;
%         plot(xinset, yinset,'LineWidth', 1.5)
%         set(gca,'ColorOrder',cmap)
%         ytickformat('%.1f')
%         grid on;
         p = p+1;
    end
    
    %% Plots : time course data of  vessel species
    Vstruct = plot_utils.get_Vstruct(V);
    fields = fieldnames(Vstruct);
    p=1;
    for f = 1:length(fields)
        [display_name, cmap] = plot_utils.get_display_name;        
        
        figure(3)
        subplot(1,settings_utils.NVs,p)
        conc = Vstruct.(fields{f});
        
        % multiply with a conversion factor for units required for plotting
        conc = conc*plot_utils.get_model2plot_unitconversion(fields{f});
        
        plt = plot(t*60,conc,'LineWidth', 1.5);
        set(gca,'ColorOrder',cmap);
        set(plt, {'DisplayName'}, display_name);
        legend show
        title(fields{f},'Interpreter','none')
        xlabel('time (s)')
        
        units = plot_utils.get_plot_units(fields{f});
        ylabel(strcat('concentration (',units,')'));
        xlim(xlimit);
        grid on
        p = p+1;
     end
%    ttl = sprintf('Scaling factor of V_{max} = %d',settings_utils.get_speedup);
%    suptitle(ttl)
    

%-------------------------------------------------------------------------------------
% analysis2: Plots time course profiles of vessel species for a single run 
%-------------------------------------------------------------------------------------

elseif single == true && time_course == true && vessel == true
    
    p=1;    
    file    = io_utils.get_simgraph_f;
    results = io_utils.load_mat(file);
    t       = results.t;
    V       = results.species;
    Vstruct = plot_utils.get_Vstruct(V);
    fields  = fieldnames(Vstruct);

    for f = 1:length(fields)
        G     = test_utils.get_input.G;
        nnode = height(G.Nodes);
        display_name = cell(nnode,1);
        for k = nnode:-1:1
            display_name{k} = sprintf('blood vessel:node %d',k);
        end
        cmap = colormap(flipud(gray(nnode+1)));
        cmap = cmap(2:end,:);
        
        %figure(p)
        subplot(1,settings_utils.NVs,p)
        conc = Vstruct.(fields{f});
        % multiply with a conversion factor for units required for plotting
        conc = conc*plot_utils.get_model2plot_unitconversion(fields{f});
        
        plt = plot(t*60,conc,'LineWidth', 1.5);
        set(gca,'ColorOrder',cmap);
        set(plt, {'DisplayName'}, display_name);
        legend show

        title(fields{f},'Interpreter','none');
        units = plot_utils.get_plot_units(fields{f});
        
        xlabel('time (s)');
        ylabel(strcat('concentration (',units,')'));
        xlim(xlimit);
        grid on
        p = p+1;
        io_utils.save_fig(gcf)    
    end

%-------------------------------------------------------------------------------------
% analysis3: Plots heatmap of vessel + cell species for glucose gscan.
%            tend of the timecourse data is used for plotting the heatmap
%-------------------------------------------------------------------------------------
    
elseif gscan == true && heat_map == true && vessel == false && flux == false
    
    f_path  = io_utils.get_simgraph_f;
    results = io_utils.load_mat(f_path);
    results =  results.variable;
    
    dose    = settings_utils.glucose_scan;
    s       = [];
    
    for d = length(dose):-1:1
        species = results(d).species;
        t       = results(d).t;    
        s       = vertcat(s, species(end,:)); 
    end
    
    [C, V]  = plot_utils.sep_C_V(s);
    
    %% Plots : glc_ext gscan data of reactor species 
    Cstruct = plot_utils.get_Cstruct(C);
    fields  = fieldnames(Cstruct);
    NVs     = settings_utils.NVs;
    for f = 1:length(fields)
        subplot(2,3,p)
        h   = heatmap(Cstruct.(fields{f}))
        h.XDisplayLabels = model_utils.get_rxn_nodes;
        h.YDisplayLabels = flip(dose); 
        title(fields{f})
        xlabel('reaction nodes')
        ylabel('glucose dose (mM)')
        
        p = p+1;
    end

    %% Plots : glc_ext gscan data of vessel species 
    Vstruct = plot_utils.get_Vstruct(V);
    fields = fieldnames(Vstruct);
    for f = 1:length(fields)
        subplot(2,3,p)
        %plot(dose,Vstruct.(fields{f}), '*')
        h = heatmap(Vstruct.(fields{f}))
        
        h.XDisplayLabels = io_utils.get_H.Nodes.Name;
        h.YDisplayLabels = flip(dose); 
        
        title(fields{f})
        
        set(groot,'defaulttextinterpreter','none');  
        set(groot,'defaultAxesTickLabelInterpreter','none');  
        set(groot,'defaultLegendInterpreter','none');

        xlabel('blood vessel nodes')
        ylabel('glucose dose (mM)')
        p = p+1;
    end

%-------------------------------------------------------------------------------------
% analysis4: Plots heatmap of vessel + cell glc, lac exchange fluxes for glucose gscan.
%            tend of the timecourse data is used for plotting the heatmap
%-------------------------------------------------------------------------------------
    
elseif gscan == true && heat_map == true && vessel == false && flux == true
    
    f_path  = io_utils.get_simgraph_f;
    f_path  = strcat(f_path,'_flux');
    results = io_utils.load_mat(f_path);
    results =  results.variable;
    
    dose    = settings_utils.glucose_scan;
    glcim   = [];
    lacex   = [];
    
    for d = length(dose):-1:1    
        g       = results(d).glcim;
        l       = results(d).lacex;
        glcim   = vertcat(glcim, g); 
        lacex   = vertcat(lacex, l);
    end
    
    % plot glcim in repsonse to 
    subplot(1,2,1)
    h_glcim                = heatmap(glcim);
    h_glcim.XDisplayLabels = model_utils.get_rxn_nodes;
    h_glcim.YDisplayLabels = flip(dose); 
    title('Glucose exchange flux (mmol/min)')
    xlabel('reaction nodes')
    ylabel('glucose dose (mM)')

% plot glcim in repsonse to 
    subplot(1,2,2)
    h_lacex                = heatmap(lacex);
    h_lacex.XDisplayLabels = model_utils.get_rxn_nodes;
    h_lacex.YDisplayLabels = flip(dose); 
    title('Lactate exchange flux (mmol/min)')
    xlabel('reaction nodes')
    ylabel('glucose dose (mM)')
    

%-------------------------------------------------------------------------------------
% analysis5: Plots pancreas_min_2_glcscan 
%-------------------------------------------------------------------------------------
    
    
%-------------------------------------------------------------------------------------
% Plots molebalance species for a single run 
%-------------------------------------------------------------------------------------
    
elseif single ==true && molebalance == true
    
    % check molebalance for simgraph
    file = io_utils.get_simgraph_f;
    results = io_utils.load_mat(file);
    
    species = results.species;
    t = results.t;
    
    stoic = settings_utils.get_stoic;
    Ntot = zeros(length(results.t),1);
    if settings_utils.model.vessel == false
        [C,V]   = plot_utils.sep_C_V(species);
        Cstruct = plot_utils.get_Cstruct(C);
        Vstruct = plot_utils.get_Vstruct_rxnnodes(V);
        cfields = fieldnames(Cstruct);
        vfields = fieldnames(Vstruct);
        for f = 1:length(cfields)
            s = stoic.(cfields{f}); 
            Ntot = Ntot + s*sum(Cstruct.(cfields{f}),2);
        end
        for f = 1:length(vfields)
            s = stoic.(cfields{f});
            Ntot = Ntot + s*sum(Vstruct.(vfields{f}),2);
        end
        Ntot = 0.5*Ntot;
    else
        Vstruct = plot_utils.get_Vstruct(species);
        vfields = fieldnames(Vstruct);
        for f = 1:length(vfields)
            s = stoic.(vfields{f});
            Ntot = Ntot + s*sum(Vstruct.(vfields{f}),2); %2 is for specifying row/column sum
        end
        Ntot
    end
    
    plot(t*60,Ntot,'ko');
    xlabel('time(s)')
    ylabel('N_{tot}(mmol)')
    title('Graph model - convection + diffusion + reaction')

 % heatmaps   
%{    
% %-------------------------------------------------------------------------------------
% % Plots heatmap of vessel + cell species for a single run
% %-------------------------------------------------------------------------------------
 
elseif heat_map == true && settings_utils.model.full == true 
    if single ==  true    
        results = io_utils.load_mat(fullfile(io_utils.get_results_dir,"single.mat"));
        nskip = 10;
    else
        results = io_utils.load_mat(fullfile(io_utils.get_results_dir,"gscan.mat"));
        results = results.variable;
        nskip = 50;
    end
    nscan = length(results);
    for i = 1:length(results)
        species = results(i).species;
        t = results(i).t;
        [C, V] = plot_utils.sep_C_V(species);
        Cstruct = plot_utils.get_Cstruct(C);
        Vstruct = plot_utils.get_Vstruct(V);
        fields_Vstruct = fieldnames(Vstruct);
        
        fields_Cstruct = fieldnames(Cstruct);
        for f = 1:length(fields_Vstruct)
            C = Cstruct.(fields_Cstruct{f});
            figure(1)
            subplot(nscan,2,p);
            h1 = heatmap(C(1:nskip:end,:));
            h1.YDisplayLabels = num2cell(t(1:nskip:end));
            h1.XDisplayLabels = model_utils.get_rxn_nodes;%{'2','4','6','8'};

            title(fields_Cstruct{f})
            xlabel('coupled')
            ylabel('Time(min)')
            V = Vstruct.(fields_Vstruct{f});
            
            figure(2)
            subplot(nscan,2,p);
            h2 = heatmap(V(1:nskip:end,:));
            h2.YDisplayLabels = num2cell(t(1:nskip:end));
            h2.XDisplayLabels = io_utils.get_H.Nodes.Name;
            [C,V] = plot_utils.sep_C_V(species);
            Cstruct = plot_utils.get_Cstruct(C);
            Vstruct = plot_utils.get_Vstruct(V);
            title(fields_Vstruct{f})
            xlabel('coupled')
            ylabel('Time(min)')
            p = p+1;
        end
    end
    

%-------------------------------------------------------------------------------------
% Plots heatmap of  vessel species for a single run 
%------------------------------------------------------------------------------------- 
elseif heat_map == true && settings_utils.model.vessel == true
    if single ==  true    
        results = io_utils.load_mat(fullfile(io_utils.get_results_dir,"single.mat"));
        nskip = 1;
    else
        results = io_utils.load_mat(fullfile(io_utils.get_results_dir,"gscan.mat"));
        results = results.variable;
        nskip = 50;
    end
    nscan = length(results);
    for i = 1:length(results)
        V = results(i).species;
        t = results(i).t;
        Vstruct = plot_utils.get_Vstruct(V);
        fields_Vstruct = fieldnames(Vstruct);
        for f = 1:length(fields_Vstruct)
            figure(1)
            subplot(nscan,2,p);            
            V = Vstruct.(fields_Vstruct{f});
            h2 = heatmap(V(1:nskip:end,:));
            h2.YDisplayLabels = num2cell(t(1:nskip:end));
            h2.XDisplayLabels = io_utils.get_H.Nodes.Name;
            title(fields_Vstruct{f})
            xlabel('uncoupled')
            ylabel('Time(min)')
            p = p+1;
        end
    end
 %}
end
