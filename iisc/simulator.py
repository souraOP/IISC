""" model simulator """
import os
import time
import json
import numpy as np
import pandas as pd
import networkx as nx
from pathlib import Path
from iisc import (
    SIMULATOR_DIR,
    SIMULATOR,
    RESULTS_MAT,
    TASK_DIR
)
from types import SimpleNamespace
from typing import Dict
import scipy.io as sio
import logging
from collections import OrderedDict
# import json
# import networkx as nx
# from vedo import *
# from network_creation.utils.graph_utils import create_graph
# from network_creation import test_case
# from typing import Dict
# from collections import OrderedDict
# import subprocess
# import sys
# from simulator.utils.io_utils_py import _get_file


class Simulator:
    def __init__(
        self, data_path: Path = None
    ):
        self.data_path = data_path
        # self.graph_nodes_path = os.path.join(data_path, "Graph_nodes.csv")
        # self.graph_edges_path = os.path.join(data_path, "Graph_edges.csv")
        # self.r_path = os.path.join(data_path, "results.mat")
        # self.r_json = os.path.join(data_path, "results.json")
        self.input_xlsx = os.path.join(data_path, "input.xlsx")

    def runsimulation(self):  #input_files
        """
        :fpath: param user input file
        """
        # clear results dir
        try:
            os.remove(RESULTS_MAT)
            print("cleaning results directory")
        except OSError:
            pass
        start = time.time()
        os.chdir(SIMULATOR_DIR)
        print("running simulation ...")
        os.system(f'{SIMULATOR} {self.data_path}')
        stop = time.time()
        print("simulation is complete \n Elapsed time: ", stop - start)

    @property
    def load_results(self):
        return sio.loadmat(self.r_path, struct_as_record=False, squeeze_me=True)

    @property
    def species(self):
        return ["glc_ext", "glc", "lac", "lac_ext"]

    @property
    def nspecies(self):
        return len(self.species)

    def get_graph(self) -> Dict:
        """
        load graph data: nodes, edges, node_attributes and edge_attributes
        - input is in excel file
        - by default loads the input file with all graphs
        :return:
        """
        output = {}
        df = pd.read_excel(open(self.input_xlsx, 'rb'), sheet_name=0, index_col=None)
        df = df[df.notna()]
        tail = df.t
        head = df.h
        tail = tail[~np.isnan(tail)]
        head = head[~np.isnan(head)]
        tail = tail.astype(int)
        head = head.astype(int)
        ed_ls = [(t, h) for t, h in zip(tail, head)]

        d = df.d
        l = df.l
        d = d[~np.isnan(d)]
        l = l[~np.isnan(l)]

        output['tail'] = tail
        output['head'] = head
        output['l'] = l
        output['d'] = d
        output['ed_ls'] = ed_ls

        if 'nodes' in df.columns:
            nodes = df.nodes
            nodes = nodes[~np.isnan(nodes)]
            nodes = [int(n) for n in nodes]
            output['nodes'] = nodes

        if 'hNode' and 'tNode' in df.columns:
            output['source'] = df.hNode.dropna()
            output['target'] = df.tNode.dropna()

        if 'xpos' and 'ypos' and 'zpos' in df.columns:
            xpos = df.xpos
            xpos = xpos[~np.isnan(xpos)]
            ypos = df.ypos
            ypos = ypos[~np.isnan(ypos)]
            zpos = df.zpos
            zpos = zpos[~np.isnan(zpos)]
            xyz = [[x, y, z] for x, y, z in zip(xpos, ypos, zpos)]
            output['xyz'] = xyz

        return output

    def create_graph(
            self,
            directed=False,
            attributes=False,
            derived_attr=False,
            sheet=None
    ):
        """
        created directed/ undirected graph
        :param derived_attr: node_radius and node_lengths of volume elements around the node
        :param cd:  if true, sets centerline lengths as edge lengths
        :param actual_pos: if False, sets the repositioned (uniform mesh) nodes coordinates (this is no longer
        applicable, in v0 coordinates were moved  to create uniform mesh. In the current verison non-uniform mesh
        is used. So always use actual_pos = False to set the vmtk node node coordinates.)
        :param attributes:
        :param output:
        :param directed:
        :return:
        """
        output = self.get_graph()

        if directed:
            G = nx.OrderedDiGraph()
        else:
            G = nx.OrderedGraph()

        G.add_edges_from(output['ed_ls'])
        if 'xyz' in output:
            nodes = list(sorted(G.nodes()))
            assert (nodes == output['nodes'])
            pos = OrderedDict(zip(nodes, output['xyz']))
            nx.set_node_attributes(G, pos, 'pos')

        else:  # pseudo positions
            logging.warning("Coordinate positions assigned from networkx's layout ...")
            pos = nx.random_layout(G, dim=3, seed=1)
            nx.set_node_attributes(G, pos, 'pos')

        if attributes:
            # edges = sorted(G.edges)
            # assert(edges == list(zip(list(output['tail']), list(output['head']))))
            edges = list(zip(list(output['tail']), list(output['head'])))
            d = OrderedDict(zip(edges, output['d']))
            nx.set_edge_attributes(G, d, 'd')
            l = OrderedDict(zip(edges, output['l']))
            nx.set_edge_attributes(G, l, 'l')

        if derived_attr:
            node_r = OrderedDict(zip(nodes, output['node_r']))
            nx.set_node_attributes(G, node_r, 'node_r')
            node_l = OrderedDict(zip(nodes, output['node_l']))
            nx.set_node_attributes(G, node_l, 'node_l')

        return G

    def process_results2(self):
        r = self.load_results
        d = {}

        if isinstance(r, dict):
            r = SimpleNamespace(**r)

        # static

        d['pressure'] = [round(p, 3) for p in list(r.nodal_pressure)]
        d['velocity'] = [round(v, 3) for v in list(r.edge_velocity)]

        # dynamic
        d['time'] = [round(t, 3) for t in list(r.t)]

        # concentration
        for i in range(0, self.nspecies):
            s = self.species[i]
            values = np.round(getattr(r, s), 3)
            d[s] = [list(c) for c in list(values)]

        return d

    def save_results(self):
        d = self.process_results()
        with open(self.r_json, 'w') as outfile:
            json.dump(d, outfile, indent=2)

    def process_results(self):
        """ topology of input network (undiscretized)"""

        def node_data():
            df: pd.DataFrame = pd.read_csv(self.graph_nodes_path)
            df.rename(columns={'Name': 'nodes'}, inplace=True)

            return {
                'ids': list(df['nodes']),
                'x': list(df['xpos']),
                'y': list(df['ypos']),
                'z': list(df['zpos']),
                'pressure': list(df['pressure'])
            }

        def edge_data():
            df: pd.DataFrame = pd.read_csv(self.graph_edges_path)
            df.rename(
                columns={
                'EndNodes_1': 'tail',
                'EndNodes_2': 'head',
                'branch_length': 'l',
                'segment_dia': 'd',
                },
                inplace=True
            )

            return {
                'source': list(df['tail']),
                'target': list(df['head']),
                'midx': list(df['mid_xpos']),
                'midy': list(df['mid_ypos']),
                'midz': list(df['mid_zpos']),
                'velocity': list(df['velocity']),
                'max_velocity': max(df['velocity']),
                'min_velocity': min(df['velocity']),
            }

        def plotly_input_format():
            """
            ploly input format:
            (source, target, null)
            """
            ouput = self.get_graph()
            exit()
            edges = list(zip(r['edges']['source'], list(r['edges']['target'])))
            for edge in edges:
                s, t = edge
                edge_x = [r['nodes']['x'][s]]
                edge_y = []
                edge_z = []
            pass

        # df = pd.read_csv(self.graph_edges_path)
        # df.rename(columns={'Name': 'nodes'}, inplace=True)

        r = {}
        # raw data
        # r["nodes"] = node_data()
        # r["edges"] = edge_data()
        plotly_input_format()
        # plotly format
        return r


if __name__ == '__main__':
    sim = Simulator(data_path=TASK_DIR)
    # sim.runsimulation(task_dir=TASK_DIR)
    # sim.save_results()
    sim.save_results()