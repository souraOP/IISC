from pathlib import Path

SIMULATOR_DIR = Path(__file__).parent
SIMULATOR_FILE = SIMULATOR_DIR / "main.exe"
RESULTS_DIR = SIMULATOR_DIR / "results" / "adv_disp" / "simgraph"

# graph input
INPUT_XLSX = SIMULATOR_DIR / "input.xlsx"

# results file
RESULTS_MAT = RESULTS_DIR / "test11_default_bc1_v1_c0.mat"
