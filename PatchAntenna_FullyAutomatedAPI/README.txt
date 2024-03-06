This folder contains a further version of the MATLAB-HFSS API described in:
Giannetti, G. (2023). Improved and easy-to-implement HFSS-MATLAB interface without VBA scripts: an insightful application to the numerical design of patch antennas. The Applied Computational Electromagnetics Society Journal (ACES), 377-381.

In particular, all the preliminary steps are now performed automatically. This improvement makes the API more user-friendly.

The only files that are needed to launch the simulations are:
- Base.aedt,                             HFSS project
- HFSS_MATLAB_interface_NoVarExport.m,   MATLAB script that implements the API, launches the simulations, and extracts the results

All the other files are generated after launching the API.

Remark! Modify all the paths contained in the MATLAB script according to the location of the files on your computer.
