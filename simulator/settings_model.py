import os
from pathlib import Path

test_case = "test24_default"
comsol = False
single = True
gscan = False
pscan = False
ascan = False
pb = False
nspecies = 4
SPECIES = ["glc_ext", "glc", "lac", "lac_ext"]
ESPECIES = ["glc_ext", "lac_ext"]

test_cases = ["test11_default"] #, "test9_default", "test10_default", "test11_default"]
if pb: test_cases = ["test11_default_pb", "test9_default_pb", "test10_default_pb"]

BASE_DIR = Path(__file__).parent

# BASE_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT_DIR = os.path.join(BASE_DIR, "pancreas", "input")
INPUT_XLSX = os.path.abspath(os.path.join(INPUT_DIR, "input.xlsx"))

# upload directory
UPLOAD_DIR = BASE_DIR / ".." / "upload"

# task dir
TASK_DIR = UPLOAD_DIR / "sample" / "task"

# image processing
SPARC_DIR = os.path.join(BASE_DIR, "..", "image_processing", "sparc")
SPARC_XML = os.path.join(BASE_DIR, "..", "image_processing", "sparc", "derivative", "sub-6238", "islet4.xml")  #sub-6384_20x_MsGcg_RbCol4_SMACy3_islet3_large_segment

# cad files
CAD_DIR = os.path.join(BASE_DIR, "..", "cad")  # "image_processing"
GRAPH_LISP_FILE = os.path.abspath(os.path.join(CAD_DIR, "graph.lsp"))
GRAPH_SCR_FILE = os.path.abspath(os.path.join(CAD_DIR, "graph.scr"))
GRAPH_DWG_FILE = os.path.abspath(os.path.join(CAD_DIR, "graph.dwg"))
GRAPH_COMMAND_FILE = os.path.abspath(os.path.join(CAD_DIR, "graph_command.lsp"))
GRAPH_DXF_FILE = os.path.abspath(os.path.join(CAD_DIR, f"{test_case.split('_')[0]}.dxf"))
# GRAPH_DXF_FILE = os.path.abspath(os.path.join(CAD_DIR, "test.dxf"))
GRAPH_MESH_FILE = os.path.abspath(os.path.join(CAD_DIR, "test11_cd.msh"))  # test2_gmsh

RESULTS_DIR = os.path.abspath(os.path.join(BASE_DIR, "results"))
RESULTS_PLOTS_DIR = os.path.join(RESULTS_DIR, "plots")
RESULTS_COMSOL_DIR = os.path.join(RESULTS_DIR, "adv_disp", "comsol")
RESULTS_SIMGRAPH_DIR = os.path.join(RESULTS_DIR, "adv_disp", "simgraph")

RESULTS_SIMGRAPH_FILE = os.path.join(RESULTS_SIMGRAPH_DIR, f"test11_default_bc1_v2_c2.mat") #f"{test_case}_bc1_v1_c0.mat"
