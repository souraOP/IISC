"""
Interpreter: Python 3.6 venv ( issue with X display in WSL py3.7 interpreter)
"""
import matlab.engine


if __name__ == '__main__':

    # generate simgraph data
    eng = matlab.engine.start_matlab()
    eng.main(nargout=0)

    # generate comsol data
    # eng.process_results(nargout=0)
