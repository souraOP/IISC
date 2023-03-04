function dV = vessel(t, V_, C, eflux)
%% model settings
model = settings_utils.model;
%% graph props
persistent Graph
persistent pts nnode capillary rxn_nodes volume
persistent hNode tNode t_node_neighbor h_node_neighbor interior_pts hEdgeIdx tEdgeIdx
persistent D_head D_tail
persistent L_dispersion L_disp lap_op advection
persistent Q1
persistent mesh_size
persistent rbv_h rbv_t velocity_h dia
persistent Vspecies Vinf_struct Vslice 

if isempty(Graph)
    Graph     = io_utils.get_H;
    rxn_nodes = model_utils.rxn_nodes;
    nnode     = height(Graph.Nodes);
    pts       = graph_utils.get_pts_H;
    
    hNode           = pts.hNode;
    tNode           = pts.tNode;
    t_node_neighbor = pts.tNode_neighbor;
    h_node_neighbor = pts.hNode_neighbor;
    interior_pts    = pts.interior_pts;
    hEdgeIdx        = pts.hEdgeIdx;
    tEdgeIdx        = pts.tEdgeIdx;

    capillary   = io_utils.get_capillary; 
    dia         = Graph.Edges.segment_dia;  
    Q1          = capillary.velocity*pi*(dia(hEdgeIdx)./2).^2;
    volume      = Graph.Nodes.volume;
    mesh_size   = graph_utils.get_mesh_size;
    
    rbv_h       = Graph.Edges.segment_dia(hEdgeIdx);
    rbv_t       = Graph.Edges.segment_dia(tEdgeIdx);
    velocity_h  = Graph.Edges.velocity(hEdgeIdx);

    lap_op      = laplace_operator(Graph);
    advection   = lap_op.L_adv;
    if model.vessel == true && settings_utils.saveop_4julia == true
        % boundary encoded advection
        adv_test24   = model_utils.get_B_advection(advection, Q1);        
        JULIA_DIR = io_utils.get_julia_dir;
        io_utils.save_mat(fullfile(JULIA_DIR, 'adv_test11.mat'), adv_test24);    
        io_utils.save_mat(fullfile(JULIA_DIR, 'volume_test11.mat'), volume);
        io_utils.save_mat(fullfile(JULIA_DIR, 'x0_test11.mat'), V_);
        
    end
    advection   = advection(interior_pts,:);

    Vspecies    = settings_utils.Vspecies;
    Vinf_struct = settings_utils.Vinf;
    Vslice      = model_utils.get_V_slice(V_);
end

% dispersion coeffs and operator
if isempty(D_head)
    for i = 1:settings_utils.NVs
        D_head.(Vspecies(i))   = Graph.Edges.(strcat(Vspecies(i), '_disp_vol'))(hEdgeIdx);
        D_tail.(Vspecies(i))   = Graph.Edges.(strcat(Vspecies(i), '_disp_vol'))(tEdgeIdx);
        L_dispersion.(Vspecies(i))   = lap_op.(strcat('L_', Vspecies(i), '_disp'));

        if model.vessel == true && settings_utils.saveop_4julia == true
%             % boundary encoded dispersion
%             % https://scicomp.stackexchange.com/questions/37440/specifying-ode-solver-options-to-speed-up-compute-time/37441#37441
            disp_test24 = model_utils.get_B_dispersion(L_dispersion.(Vspecies(i)), D_tail.(Vspecies(i)));
            JULIA_DIR = io_utils.get_julia_dir;
            io_utils.save_mat(fullfile(JULIA_DIR, 'disp_test11.mat'), disp_test24);    
        end
%         else
        L_dispersion.(Vspecies(i))   = L_dispersion.(Vspecies(i))(interior_pts,:);
%         end  
    end
end

%% Concentration
% Vstruct          = model_utils.get_Vstruct(V); %FIXME: revert

if model.vessel == false
%     Cshuttle = model_utils.get_Cshuttle(C);
    eshuttle = model_utils.get_eflux(eflux);
end
%% diff equations
%% Convection : same for all transport species
% dC/dt = 1/Rcell(1/um)[-M^T*v(um/min)*M*C(umol/l)]  [units:umol/l]

% dV          = []; %zeros(nnode*settings_utils.NVs,1);%  %FIXME: revert
dV       =  zeros(size(V_), 'like', V_); 
for i = 1:settings_utils.NVs
    D_h       = D_head.(Vspecies(i)); 
    D_t       = D_tail.(Vspecies(i));  
    
%     V         = Vstruct.(Vspecies(i)); %FIXME: revert
    V         = V_(Vslice.(Vspecies(i)),:);
    dVessel   = zeros(size(V), 'like', V); %FIXME: revert to zeros(nnode,1) 
    
    Vinf      = Vinf_struct.(Vspecies(i));
    L_disp    = L_dispersion.(Vspecies(i));
    
    %% Diff equations
    % Ref: https://in.mathworks.com/matlabcentral/answers/438547-defining-mass-matrix-for-solving-transport-equation
    
    %% ----------------------------------------------------------------------------------------------------------------------------------------
    %  bc1 applies for all tests and validation
    %% ----------------------------------------------------------------------------------------------------------------------------------------

    if model_utils.bc == "bc1"
        if model_utils.physics == "adv"
            % Dirichlet BC
            dVessel(hNode,1)  = 0; %V(hNode) - 5; %(1/volume(hNode))*capillary.velocity*pi*capillary.rbv^2*(Vinf - V(hNode));
            % Neumann BC (diffusive flux =0)
            dVessel(tNode,1)  = (1/volume(tNode))*(Q1*(V(t_node_neighbor)-V(tNode)));
            
        elseif model_utils.physics == "disp" 
            % Dirichlet BC
            dVessel(hNode,1) = 0;
            % Neumann BC (diffusive flux =0)
            %dVessel(tNode,1)  = (1/volume(tNode))*(2*D_t*pi*rbv_t^2*(V(t_node_neighbor) - V(tNode)))/mesh_size; 
            dVessel(tNode,1)  = (1/volume(tNode))*(2*D_t*(V(t_node_neighbor) - V(tNode))); 
                                
        elseif model_utils.physics == "adv_disp" % && settings_utils.jacobian_set == false 
             % both advection and dispersion/diffusion
             % Dirichlet BC
            dVessel(hNode,:) = 0; %V(hNode) - 5; %(1/volume(hNode))*capillary.velocity*pi*capillary.rbv^2*(Vinf - V(hNode));
            % Neumann BC (diffusive flux =0)
            dVessel(tNode,:)  =  (1/volume(tNode))*(Q1*(V(t_node_neighbor)-V(tNode))) + ...
                                 (1/volume(tNode))*(2*D_t*(V(t_node_neighbor) - V(tNode)));

        end
    
    %% ----------------------------------------------------------------------------------------------------------------------------------------
    
    elseif model_utils.bc == "bc2" && model_utils.physics == "disp"
        % Applicable physics : diffusion alone
        % Dirichlet BC
        dVessel(hNode,1) = (1/volume(hNode))*(2*D_h*(-V(hNode) + V(h_node_neighbor)));
        % Neumann BC (diffusive flux =0)
        dVessel(tNode,1) = (1/volume(tNode))*(2*D_t*(V(t_node_neighbor) - V(tNode)));
   
    %% ----------------------------------------------------------------------------------------------------------------------------------------       
    elseif model_utils.bc == "bc3" && model_utils.physics == "adv_disp"
        
        t0 = settings_utils.run.tspan(end)/1000;
        if t <= t0
            influx = velocity_h*Vinf;
        else
            influx = 0;
        end
        
        VL = V(h_node_neighbor) + ((2*mesh_size)/D_h)*(influx - velocity_h*V(hNode));
        
        dVessel(hNode,1)  =  (1/volume(hNode))*(Q1*(VL - V(hNode))) + ...
                             (1/volume(hNode))*(D_h)*(VL - 2*V(hNode) + V(h_node_neighbor));
        
        dVessel(tNode,1)  =  (1/volume(tNode))*(Q1*(V(t_node_neighbor)-V(tNode))) + ...
                                 (1/volume(tNode))*(2*D_t*(V(t_node_neighbor) - V(tNode)));
        
    end
    %% ----------------------------------------------------------------------------------------------------------------------------------------    
    %% ----------------------------------------------------------------------------------------------------------------------------------------
    % Intermediate nodes
    %% ----------------------------------------------------------------------------------------------------------------------------------------
    
    if model.vessel == false
        %% Reaction
        % exchange flux is divided by 1e-15 to convert flux in mmol/min to mmol/min/l (1um^3 = 1e-15 litre) 
        reaction = zeros(1, nnode); % preallocating for speed #length(interior_pts)
        reaction(rxn_nodes) =  eshuttle.(Vspecies(i));
        
        dVessel(interior_pts,:) =   (1./volume(interior_pts)).*(advection*V + L_disp*V) - (1./(1e-15.*volume(interior_pts))).*reaction(interior_pts)';
       
    
    elseif model.vessel == true
        if model_utils.physics == "adv"
            dVessel(interior_pts,1) =   diag(1./volume(interior_pts))*(advection*V);
        
        elseif model_utils.physics == "disp"
            dVessel(interior_pts,1) =   diag(1./volume(interior_pts))*(L_disp*V);
       
        elseif model_utils.physics == "adv_disp"
            % encoding boundary terms in advection and dispersion matrices
            %if settings_utils.jacobian_set == true
            %    dVessel(:,:) =   (1./volume).*(advection*V + L_disp*V);
            %else
            dVessel(interior_pts,:) =   (1./volume(interior_pts)).*(advection*V + L_disp*V);
            %end
            %kcat = 19.5 1/s from hresko2016
            %dVessel(interior_pts,1) =   (1./volume(interior_pts)).*(advection*V + L_disp*V) - (19.5*V(interior_pts)); %19.5
%           dVessel(interior_pts,:) =   (1./volume(interior_pts)).*(advection*V + L_disp*V) - 0.001; % point source
        
        end
    end
    %% ----------------------------------------------------------------------------------------------------------------------------------------
    
    % dV = vertcat(dV, dVessel); %FIXME: revert
    dV(Vslice.(Vspecies(i)),:) = dVessel;
end
end