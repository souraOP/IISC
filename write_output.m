function write_output()

    vessel      = settings_utils.model.vessel;
    test_case   = graph_utils.get_test_case;
    file  = io_utils.get_simgraph_f;
    results = io_utils.load_mat(file);
    t  = results.t;
    t = t*60;

    if vessel == false
        species = results.species;
        [C, V] = plot_utils.sep_C_V(species);
        data = plot_utils.get_Vstruct(V);
        Cstruct = plot_utils.get_Cstruct(C);

        f = fieldnames(Cstruct);
        for i = 1:length(f)
            data.(f{i}) = Cstruct.(f{i});
        end
        data = cell2struct(struct2cell(orderfields(data)), {'glc_cell', 'glc_ext', 'lac_cell', 'lac_ext'});

    elseif vessel == true
        V = results.species;
        data = plot_utils.get_Vstruct(V);    
    end

    NVertex = 1:model_utils.NVertex; % model_utils.rxn_nodes
    rxn_nodes = model_utils.rxn_nodes;
    
    % append time column to data
    field_data = fieldnames(data);
    for i = 1:length(field_data)
        if contains(field_data{i}, 'cell')
            data.(field_data{i}) = horzcat(t, data.(field_data{i}));
        elseif contains(field_data{i}, 'ext')
            data.(field_data{i}) = horzcat(t, data.(field_data{i})(:,NVertex));
        end
    end

    % writing data headers
    bv ={};
    rxn = {};
 

    for v = 1:length(NVertex) 
        bv{v} = sprintf('%s%d','node',NVertex(v));
    end
    bv = [{'time'}, bv ];

    for c = 1:length(rxn_nodes)
        rxn{c} = sprintf('%s%d','node',rxn_nodes(c)); 
    end
    rxn = [{'time'}, rxn ];

    data_contents = structfun(@(M) {num2cell(M)}, data)

    %excelFilename = strcat('C:\Users\deepa\Dropbox\Network_COMSOL\results\' ,test_case, '.xlsx')
    excelFilename = fullfile(io_utils.get_results_dir, 'comsol', strcat(test_case, '.xlsx'))

    structFieldnames = fieldnames(data); 
    for k = 1:length(structFieldnames)
        fieldname = structFieldnames{k};

        if contains(fieldname, 'ext')
            content = [bv; data_contents{k}]; 
        elseif contains(fieldname, 'cell')
            content = [rxn; data_contents{k}];
        end

        writecell(content, excelFilename{1}, 'Sheet', sprintf('%s%s', fieldname, '_simgraph_ad')); %_ad ; sink eqfull
    end
end
