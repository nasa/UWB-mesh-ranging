# Mesh Protocol MATLAB Simulation

MATLAB can be used to simulate the mesh protocol in different scenarios.
This can be achieved by generating a mex-file from the C++ code that is then used inside the simulation environment in MATLAB.
To generate the mex-file, use the script "compile_mex.m". 
The simulations can be started with the script "single_simulation_mex.m" and "batch_simulation_mex.m". Before, a node configuration for the simulation in the form of a .mat-file must be generated. The script "create_node_config_script.m" contains sample scenarios and generates the corresponding .mat-files.
When running a batch-simulation, for each scenario there needs to be an .xls-file containing the file name of the node config. Each scenario will then be run multiple times using different random seeds (e. g. 10,000 times), and the results will be written into the xls-table.
A sample xls-file is placed in /data.

The MATLAB simulation uses ParforProgMon (https://github.com/fsaxen/ParforProgMon/tree/master).
You can find the license here: https://github.com/fsaxen/ParforProgMon/blob/master/license.txt

Note: There is also an implementation of the mesh protocol for MATLAB inside this repository. This implementation was used as a prototyping tool for the actual implementation that was then done in C++. It can be used for testing purposes, but it is not an equivalent to the implementation in C++.