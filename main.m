function main(TASK_DIR)
% This function runs two steps
% 1. Static solver - computes pressure and velocity profiles
% 2. Dynamic solver - computes transient concentration profiles

% cd('I:\\transport_model\matpancreas')

% clc
% clear all
% clear classes
clear settings_utils
clear graph_utils
clear model_utils

warning('off')
% default('TASK_DIR', io_utils.get_task_dir(fullfile(pwd, 'upload', 'sample', 'task')));

io_utils.get_task_dir(fullfile(TASK_DIR))

ttic = tic();

fprintf('....read data \n')
tbl = readtable(fullfile(TASK_DIR,'input.xlsx'));

fprintf('....create network \n')
G = graph_utils.input(1, 1, 1, tbl);

fprintf('....save input network \n')
io_utils.save_mat(fullfile(TASK_DIR, 'Graph.mat'), G);

fprintf('....static run \n')
[Graph, H] = create_graph(G);

fprintf('....save node and edge properties \n')
io_utils.save_mat(fullfile(TASK_DIR, 'Graph.mat'), Graph);
io_utils.save_mat(fullfile(TASK_DIR,'H.mat'), H);

% save graph node and edge properties as table
io_utils.save_table(fullfile(TASK_DIR, 'Graph_nodes.csv'), Graph.Nodes);
io_utils.save_table(fullfile(TASK_DIR, 'Graph_edges.csv'), Graph.Edges);
io_utils.save_table(fullfile(TASK_DIR, 'H_nodes.csv'), H.Nodes);
io_utils.save_table(fullfile(TASK_DIR, 'H_edges.csv'), H.Edges);

fprintf('....dynamic run \n')
simulation();

ttoc = toc(ttic)
fprintf('runtime %f seconds ...\n', ttoc)

end