This folder contains an update version of the MATLAB-HFSS API described in the following publication:
Giannetti, G. (2023). Improved and easy-to-implement HFSS-MATLAB interface without VBA scripts: an insightful application to the numerical design of patch antennas. The Applied Computational Electromagnetics Society Journal (ACES), 377-381.

In particular, the second preliminary step indicated in the above publication is now automatically performed. This improvement speeds up the preparation of the preliminary steps and reduces accidental errors.
The only step that must be performed manually is the extraction of both project and design variables from HFSS.

For further details, see HFSS_MATLAB_interface.m

The only files that are needed to launch the simulations are:
Base.aedt
BaseNoSignposts.txt
VariablesDesign.txt
VariablesProject.txt

All the other files are generated after launching the API.
