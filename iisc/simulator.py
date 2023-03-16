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
from pprint import pprint
from types import SimpleNamespace
from typing import Dict, List
import scipy.io as sio
import logging
from collections import OrderedDict
from dataclasses import dataclass

# import subprocess
# import sys
# from simulator.utils.io_utils_py import _get_file


# @dataclass
# class GraphData:
#     data_path: str
#
#     @property
#     def graph_ndata_path(self):  # node data path
#         return os.path.join(self.data_path, "Graph_nodes.csv")
#
#     @property
#     def graph_ndata(self):  # node data path
#         return pd.read_csv(self.graph_ndata_path)
#
#     @property
#     def graph_edata_path(self):  # node data path
#         return os.path.join(self.data_path, "Graph_edges.csv")
#
#     @property
#     def graph_edata(self):  # node data path
#         return pd.read_csv(self.graph_edata_path)


class Simulator:
    def __init__(
        self, data_path: Path = None
    ):
        self.data_path = data_path
        self.r_path = os.path.join(data_path, "results.mat")
        self.r_json = os.path.join(data_path, "results.json")
        self.input_xlsx = os.path.join(data_path, "input.xlsx")

    @property
    def graph_ndata_path(self):  # node data path
        return os.path.join(self.data_path, "Graph_nodes.csv")

    @property
    def graph_ndata(self, dataframe=True):  # node data path
        df = pd.read_csv(self.graph_ndata_path)
        df.rename(columns={'Name': 'nodes'}, inplace=True)
        if dataframe:
            return df
        else:
            d = df.to_dict()
            return d

    @property
    def graph_edata_path(self):  # node data path
        return os.path.join(self.data_path, "Graph_edges.csv")

    @property
    def graph_edata(self, dataframe=True) -> pd.DataFrame:  # node data path

        df = pd.read_csv(self.graph_edata_path)
        df.rename(
            columns={
                'EndNodes_1': 'tail',
                'EndNodes_2': 'head',
                'branch_length': 'l',
                'segment_dia': 'd',
            },
            inplace=True
        )

        if dataframe:
            return df
        else:
            d = df.to_dict()
            return d

    @property
    def h_ndata_path(self):  # node data path
        return os.path.join(self.data_path, "H_nodes.csv")

    @property
    def h_ndata(self):  # node data path
        return pd.read_csv(self.h_ndata_path)

    @property
    def h_edata_path(self):  # node data path
        return os.path.join(self.data_path, "H_edges.csv")

    @property
    def h_edata(self):  # node data path
        return pd.read_csv(self.h_edata_path)

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
    def pressure(self):
        return list(self.graph_node_data['pressure'])

    @property
    def species(self):
        return ["glc_ext", "glc", "lac", "lac_ext"]

    @property
    def nspecies(self):
        return len(self.species)

    def get_graph_data(self) -> Dict:

        # node data
        n: pd.DataFrame = self.graph_ndata
        pprint(n.columns)

        # edge data
        e: pd.DataFrame = self.graph_edata
        pprint(e.columns)

        ed_ls = [(t, h) for t, h in zip(e['tail'], e['head'])]

        xpos = OrderedDict(zip(n.nodes, n.xpos))
        ypos = OrderedDict(zip(n.nodes, n.ypos))
        zpos = OrderedDict(zip(n.nodes, n.zpos))
        pressure = OrderedDict(zip(n.nodes, n.pressure))

        edge_x, edge_y, edge_z = [], [], []  # edge pos
        pressure_gradient = []  # gradient color for pressure
        u, v, w = [], [], []

        for edge in ed_ls:
            source, target = edge
            edge_x.extend([xpos[source], xpos[target], None])
            edge_y.extend([ypos[source], ypos[target], None])
            edge_z.extend([zpos[source], zpos[target], None])
            pressure_gradient.extend([pressure[source], pressure[target], None])

            # orientation
            u.append(xpos[target] - xpos[source])
            v.append(ypos[target] - ypos[source])
            w.append(zpos[target] - zpos[source])

        # node info
        g_data = {
            'nodes': list(n.nodes),
            'edges': ed_ls,
            'nnodes': len(n.nodes),
            'nedges': len(ed_ls),
            'ncones': len(ed_ls),
            'x': list(n.xpos), 'y': list(n.ypos), 'z': list(n.zpos),
            'edge_x': edge_x, 'edge_y': edge_y, 'edge_z': edge_z,
            'pressure_gradient': pressure_gradient,
            'x_cone': list(e.mid_xpos), 'y_cone': list(e.mid_ypos), 'z_cone': list(e.mid_zpos),
            'u_cone': u, 'v_cone': v, 'w_cone': w,
            'velocity': list(e.velocity),
            'max_velocity': max(e.velocity),
            'min_velocity': min(e.velocity),
        }

        return g_data

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

        d = self.get_graph_data()
        with open(self.r_json, 'w') as outfile:
            json.dump(d, outfile, indent=4)


if __name__ == '__main__':
    sim = Simulator(data_path=TASK_DIR)

    sim.runsimulation() #task_dir=TASK_DIR)
    sim.save_results()
