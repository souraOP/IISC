function [ex_reactor, dCdt] = reactor(t, C, V) 
persistent F Vslice Cslice rxn_nodes
persistent glc_ext_idx lac_ext_idx glc_idx lac_idx
persistent compartment_Vpa compartment_Vext

if isempty(F)
    F = model_utils.F; % speedup
    Vslice      = model_utils.get_V_slice(V);
    Cslice      = model_utils.get_C_slice(C);
    rxn_nodes   = model_utils.rxn_nodes;
    glc_ext_idx = Vslice.glc_ext(rxn_nodes);
    lac_ext_idx = Vslice.lac_ext(rxn_nodes);
    glc_idx = Cslice.glc;
    lac_idx = Cslice.lac;
end

% Vstruct = model_utils.get_Vstruct(V);
% Cstruct = model_utils.get_Cstruct(C);
% glc_ext = Vstruct.glc_ext(model_utils.rxn_nodes);
% lac_ext = Vstruct.lac_ext(model_utils.rxn_nodes);
% glc     = Cstruct.glc;
% lac     = Cstruct.lac;

glc_ext = V(glc_ext_idx,:);
lac_ext = V(lac_ext_idx,:);
glc     = C(glc_idx,:);
lac     = C(lac_idx,:);
    
if isempty(compartment_Vpa)    
% Compartment: id = Vpa, name = pancreas tissue, constant
    compartment_Vpa = model_utils.Vpa;
% Compartment: id = Vext, name = pancreas blood, constant
    compartment_Vext = model_utils.comp.Vext;
end    
% Parameter:   id =  GLCIM_Vmax, name = Glucose import
    global_par_GLCIM_Vmax=F*100.0;  
% Parameter:   id =  GLCIM_Km, name = GLCIM_Km
    global_par_GLCIM_Km=1.0;
% Parameter:   id =  LACEX_Vmax, name = Lactate import
    global_par_LACEX_Vmax= F*100; %default:100
% Parameter:   id =  LACEX_Km, name = LACEX_Km
    global_par_LACEX_Km=0.5;
% Parameter:   id =  GLC2LAC_Vmax, name = Glucose utilization
    global_par_GLC2LAC_Vmax=F*0.1; %default:0.1
% Parameter:   id =  GLC2LAC_Km, name = GLC2LAC_Km
    global_par_GLC2LAC_Km=4.5;
% Parameter:   id =  IRS_Vmax, name = Insulin secretion
	global_par_IRS_Vmax=F*1.6E-6;
% Parameter:   id =  IRS_n_glc, name = IRS_n_glc
	global_par_IRS_n_glc=4.0;
% Parameter:   id =  IRS_Km_glc, name = IRS_Km_glc
	global_par_IRS_Km_glc=7.0;
    

% Reaction: id = GLCIM, name = glucose import
    reaction_GLCIM = compartment_Vpa.*(global_par_GLCIM_Vmax/global_par_GLCIM_Km*(glc_ext-glc)./(1+glc_ext/global_par_GLCIM_Km+glc/global_par_GLCIM_Km));
%     sum(reaction_GLCIM)
% Reaction: id = LACEX, name = lactate export
    reaction_LACEX = compartment_Vpa.*(global_par_LACEX_Vmax/global_par_LACEX_Km*(lac_ext-lac)./(1+lac_ext/global_par_LACEX_Km+lac/global_par_LACEX_Km));
%     sum(reaction_LACEX)
% Reaction: id = GLC2LAC, name = glycolysis
    reaction_GLC2LAC = compartment_Vpa.*(global_par_GLC2LAC_Vmax*glc./(glc+global_par_GLC2LAC_Km));

% Reaction: id = IRS, name = IRS insulin secretion (rate is negative here
% for the purpose of making it positive in vessel) Ideally it's rate of formation 
% of insulin and c-peptide so it's positive.
% 	reaction_IRS = -(compartment_Vpa.*(global_par_IRS_Vmax*glc.^global_par_IRS_n_glc)./(glc.^global_par_IRS_n_glc+global_par_IRS_Km_glc^global_par_IRS_n_glc));
    % https://www.comsol.com/support/knowledgebase/952
    %     eps          = 1e-15;
    %     reaction_IRS = max(eps,reaction_IRS); 
    	
    NRxn = model_utils.NRxn;
    
% Species:   id = Cpa_glc, name = glucose, affected by kineticLaw
    dCdt(glc_idx,:) = (1./(compartment_Vpa)).*(( 1.0 * reaction_GLCIM) + (-1.0 * reaction_GLC2LAC));
	
% Species:   id = Cpa_lac, name = lactate, affected by kineticLaw
    dCdt(lac_idx,:) = (1./(compartment_Vpa)).*((1.0 * reaction_LACEX) + ( 2.0 * reaction_GLC2LAC));
    
    % save exchange flux 
    % save_GLCIM(i) = reaction_GLCIM;
    ex_reactor = [reaction_GLCIM; reaction_LACEX]; %; reaction_IRS; reaction_IRS];          
end