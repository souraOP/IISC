""" model simulator """
import os
import time
from iisc import (
    SIMULATOR_DIR,
    SIMULATOR,
    RESULTS_MAT
)
# import json
# import networkx as nx
# from vedo import *
# from network_creation.utils.graph_utils import create_graph
# from network_creation import test_case
# from typing import Dict
# from collections import OrderedDict
# import subprocess
# import sys

def runsimulation():
    # clear results dir
    try:
        os.remove(RESULTS_MAT)
        print("cleaning results directory")
    except OSError:
        pass

    start = time.time()
    os.chdir(SIMULATOR_DIR)
    print("running simulation ...")
    os.system(f'{SIMULATOR}')
    stop = time.time()
    print("simulation is complete \n Elapsed time: ", stop - start)

if __name__ == '__main__':
    # G = create_graph(attributes=True, directed=True, sheet=test_case)
    runsimulation()