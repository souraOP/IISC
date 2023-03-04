%% Integrating using stiff solver ode15s
time_course     = plot_utils.plot_set.tc;
heat_map        = plot_utils.plot_set.hmap;
molebalance     = plot_utils.plot_set.molebalance;
single          = settings_utils.run.single;
gscan            = settings_utils.run.gscan;
vessel          = settings_utils.model.vessel;
p = 1;
figure(1)
H               = io_utils.get_H; 
plot(H);
if single == true && time_course == true && vessel == false
    
    
    file = io_utils.get_simgraph_f;
    results = io_utils.load_mat(file);
    
    t           = results.t;
    species     = results.species;
    caxis([min(species(:)), max(species(:))]);
    [C, V]      = plot_utils.sep_C_V(species);
    %% Plots : time course data of reactor species 
    Cstruct     = plot_utils.get_Cstruct(C);
    fields      = fieldnames(Cstruct);
    pts         = graph_utils.get_pts_H;
    temp_H      = rmnode(H,[pts.hNode,pts.tNode]);
    
for f = 1:length(fields)
    subplot(2,2,p)
    conc = Cstruct.(fields{f});
    [rows,cols] = size(conc);
    for k=1:1:300
        r_pts = model_utils.get_rxn_nodes;
        temp(1:height(H.Nodes),1)  = NaN;
        temp(r_pts) = conc(k,:);
        
        plt = plot(H, 'XData', H.Nodes.xpos, 'YData', H.Nodes.ypos, 'ZData', H.Nodes.zpos);
        plt.Marker = 'o';
        plt.MarkerSize = 15;
        
        plt.NodeLabel = {};
        upperLabels   = string(round(temp,3));
        lowerLabels   = H.Nodes.Name;
        
        % label each node and offset the labels in the North and South directions. 
        % You can play around with this offset values ------vvv
        % labelpoints(plt.XData, plt.YData, upperLabels, 'N', 0.3, 'Color', 'k');
        % labelpoints(plt.XData, plt.YData, lowerLabels, 'S', 0.3, 'Color', 'b','FontSize',8);

        %------------------------------------------------------------------------------------
        plt.NodeCData      = temp;
        plt.EdgeLabel      = round(H.Edges.velocity_um_sec,1); 
        plt.EdgeLabelColor = 'c';
                
        colormap(flipud(gray(256)));
        colorbar;
        caxis([min(species(:)), max(species(:))]);
    
        %Add plotting options
        grid on
        ttl = strcat(fields{f}, {'     '}, 'time: ', num2str(t(k)*60), {' '}, 's');
        title(ttl,'Interpreter','none')
                
        %% Step 3: Take a Snapshot
        %Save the frame
        movieVector(k) = getframe(gcf);
    end
    p=p+1;
       % check for empty frames
       % https://in.mathworks.com/matlabcentral/answers/266234-using-videowriter-for-imagesc#answer_228067

        all_valid = true;
        flen = length(movieVector);
        for K = 1 : flen
          if isempty(movieVector(K).cdata)
            all_valid = false;
            fprintf('Empty frame occurred at frame #%d of %d\n', K, flen);
          end
        end
        if ~all_valid
           error('Did not write movie because of empty frames')
        end

        %% Step 4: Save movie
        file = io_utils.get_simgraph_f;
        myWriter = VideoWriter(file);   
        %myWriter = VideoWriter('curve','MPEG-4');   %create an .mp4 file
        myWriter.FrameRate = 20;

        %Open the VideoWriter object, write the movie, and close the file
        open(myWriter);
        writeVideo(myWriter, movieVector);
        close(myWriter);

        disp('DONE!')

end

%% Plots : time course data of  vessel species

Vstruct = plot_utils.get_Vstruct(V);
fields = fieldnames(Vstruct);
for f = 1:length(fields)
   subplot(2,2,p)
   conc = Vstruct.(fields{f});
   [rows,cols] = size(conc);

   for k=1:10:rows
        H.Nodes.Value = conc(k,:)';
        plt = plot(H)
        plt.Marker = 'o';
        plt.MarkerSize = 15;
        plt.NodeCData = H.Nodes.Value;
        colorbar
        %caxis([min(conc(:)), max(conc(:))]);
        
        %Add plotting options
        grid on
        title(fields{f},'Interpreter','none')
        view([30 35])

        %% Step 3: Take a Snapshot
        %Save the frame
        movieVector(k) = getframe;
    end
    p = p+1;
end
ttl = sprintf('Scaling factor of V_{max} = %d',settings_utils.get_speedup);
suptitle(ttl)
elseif single == true && time_course == true && vessel == true
    % http://faculty.washington.edu/lum/EducationalVideoFiles/Matlab05/AnimationMatlab.m
    p=1;
    
    file = io_utils.get_simgraph_f;
    results = io_utils.load_mat(file);
    
    t  = results.t;
    V = results.species;
    Vstruct = plot_utils.get_Vstruct(V);
    fields = fieldnames(Vstruct);
    
    for f = 1:settings_utils.NVs
       subplot(1,1,p)
       conc = Vstruct.(fields{f});
       [rows,cols] = size(conc);
       if plot_utils.animate_set.t_ss == false  
           % row_idx contains the tstep at which all nodes reach same ss value  
           row_idx = analysis_utils.get_max_tstamp_idx;
           for k=1:1:700  
                H.Nodes.Value = conc(k,:)';
                plt = plot(H, 'XData', H.Nodes.xpos, 'YData', H.Nodes.ypos, 'ZData', H.Nodes.zpos);
                plt.Marker = 'o';
                plt.MarkerSize = 10;
                
                %-----------------------------------------------------------------------------
                plt.NodeLabel = {}; 
                % Define upper and lower labels (they can be numeric, characters, or strings)
                upperLabels = string(round(H.Nodes.Value,3));
                lowerLabels = H.Nodes.Name; 
                % label each node and offset the labels in the North and South directions. 
                % You can play around with this offset values ------vvv
                labelpoints(plt.XData, plt.YData, upperLabels, 'N', 0.3, 'Color', 'k');
                labelpoints(plt.XData, plt.YData, lowerLabels, 'S', 0.3, 'Color', 'b','FontSize',8);

                %-----------------------------------------------------------------------------
                plt.NodeCData      = H.Nodes.Value;
                plt.EdgeLabel      = round(H.Edges.velocity,1); %velocity_um_sec
                plt.EdgeLabelColor = 'c';
                %https://in.mathworks.com/help/matlab/ref/colormap.html
                map =  [0 0 0.4
                        0 0 0.5
                        0 0 0.6
                        0 0 0.7
                        0 0 0.8
                        0 0 0.9];
                colormap(flipud(gray(256)));
                %colormap(flipud(map));
                colorbar;
                
                caxis([min(conc(:)), max(conc(:))]);

                %Add plotting options
                grid on
                ttl = strcat(fields{f}, {'     '}, 'time: ', num2str(t(k)*60), {' '}, 's');
                title(ttl,'Interpreter','none')
                %view([30 35])

                %% Step 3: Take a Snapshot
                %Save the frame
                movieVector(k) = getframe(gcf);
           end
           % check for empty frames
           % https://in.mathworks.com/matlabcentral/answers/266234-using-videowriter-for-imagesc#answer_228067
           
                all_valid = true;
                flen = length(movieVector);
                for K = 1 : flen
                  if isempty(movieVector(K).cdata)
                    all_valid = false;
                    fprintf('Empty frame occurred at frame #%d of %d\n', K, flen);
                  end
                end
                if ~all_valid
                   error('Did not write movie because of empty frames')
                end
                
                %% Step 4: Save movie
                file = io_utils.get_simgraph_f;
                myWriter = VideoWriter(file);   
                %myWriter = VideoWriter('curve','MPEG-4');   %create an .mp4 file
                myWriter.FrameRate = 20;

                %Open the VideoWriter object, write the movie, and close the file
                open(myWriter);
                writeVideo(myWriter, movieVector);
                close(myWriter);

                disp('DONE!')
                
       elseif plot_utils.animate_set.t_ss == true
            %https://in.mathworks.com/matlabcentral/answers/502305-adding-two-node-labels-to-graph
            t_ss            = analysis_utils.get_tstamp;      
            plt             = plot(H, 'XData', H.Nodes.xpos, 'YData', H.Nodes.ypos, 'ZData', H.Nodes.zpos);  
            plt.EdgeLabel   = round(H.Edges.velocity_um_sec,1);
            plt.Marker      = 'o';
            plt.MarkerSize  = 15;
            plt.NodeCData   = t_ss';
            colormap(flipud(gray(256)));
            colorbar
    end
        p = p+1;
    end
    
end
