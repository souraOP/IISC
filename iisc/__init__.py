from pathlib import Path

BASE_DIR = Path(__file__).parent

SIMULATOR_DIR = BASE_DIR / ".." / "simulator" / "pancreas"
SIMULATOR = SIMULATOR_DIR / "main.exe"
RESULTS_DIR = BASE_DIR / "simulator" / "results" / "adv_disp" / "simgraph"
UPLOAD_DIR = BASE_DIR / ".." / "upload"
SAMPLE_DIR = UPLOAD_DIR / "sample"  # task dir
TASK_DIR = SAMPLE_DIR / "task_tumor_design2"  # task dir
# SAMPLE_TASK_JSON = TASK_DIR / "results.json"
SAMPLE_TASK_JSON = SAMPLE_DIR / "task_islet" / "results.json"

# graph input
INPUT_XLSX = SIMULATOR_DIR / "input.xlsx"

# results file
RESULTS_MAT = RESULTS_DIR / "test11_default_bc1_v1_c0.mat"

