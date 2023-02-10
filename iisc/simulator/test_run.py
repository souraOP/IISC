import subprocess
exe_str = r"C:/Windows/System32/cmd simulator.exe"

# exe_str = r"C:/Windows/System32/cmd I:/differential_networks/simulation/simulator/simulator.exe"

process = subprocess.Popen(exe_str, stderr=subprocess.PIPE, creationflags=0x08000000)
process.wait()
