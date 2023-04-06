# HFSS-MATLAB-API-without-VBA-scripts
The repository contains the code to drive HFSS from MATLAB without the need of scripts.

File desciption:
- Dipole_base.aedt, Model to simulate;
- Dipole_base.txt, Model with signposts substituting the variables to be varied;
- HFSS_MATLAB_interface.m, API HFSS-MATLAB;
- HFSS_MATLAB_interface_opt.m, API HFSS-MATLAB optimizing the dipole length to have the dipole resonating at a given frequency.

  All other files are auxiliary and are generated in the execution of the code.
  
  To run the API, simply run either HFSS_MATLAB_interface.m or HFSS_MATLAB_interface_opt.m.
  Please, modify the file paths for your specific case.
