%% Dipole length API
%
% Description of the filenames in the preamble:
% PAF.mainPath: working folder (also present working directory). Pay
%   attention to the fact that PAF.mainPath must be a string terminating with
%   a backslash
% PAF.HFSSpath: executable file of HFSS
% PAF.HFSSfile_filename: file containing the updated HFSS model
% PAF.model_name: name of the model contained in the file Dipole_base.aedt
% PAF.HFSSscript_filename: python file for the extraction of the results
% PAF.HFSSoutput_filename: name of the report in the HFSS model to be
%   exported
% PAF.filenameIN_filename: name of the HFSS model as .txt file with unique
%   strings for the variables to substitute
% PAF.filenameOUT_filename: depending on the scope of the code, this is the
% file for an intermediate substitution that is to be used either for
%   hierarchical or for optimizations combined with parametric sweeps

% Structure of the code:
% 1) definition of the paths and files required for the simulations
% 2) definition of the parameters to be used in the optimization and of
%       some electrical parameters
% 3) HFSS simulation and optimization
% 4) Plot of the result

% Author: Giacomo Giannetti, University of Florence, ORCID 0000-0002-4318-8176
% Date: 06/04/2023

%% Preamble

% Paths and files

% Paths to change
PAF.mainPath = "C:\Users\giannetti\Documents\HFSS-MATLAB_interface\Dev4\";
PAF.HFSSpath = "C:\""Program Files\AnsysEM\AnsysEM21.2\Win64\ansysedt.exe""";
PAF.HFSSfile_filename = "Dipole_modified.aedt";
PAF.model_name = "without_balun";
PAF.HFSSscript_filename = "ExportToFile_S11.py";
PAF.HFSSoutput_filename = ["S11"];
PAF.filenameIN_filename  = "Dipole_base.txt";
PAF.filenameOUT_filename = PAF.HFSSfile_filename;

% To not change
PAF.strBatchSolve = " /Ng /BatchSolve ";
PAF.strBatchExtract = " /Ng /BatchExtract ";

PAF.HFSSfile = strcat(PAF.mainPath, PAF.HFSSfile_filename);
PAF.HFSSscript = strcat(PAF.mainPath,PAF.HFSSscript_filename," ");
PAF.HFSSoutput = strcat(PAF.mainPath,PAF.HFSSoutput_filename);
PAF.filenameIN  = strcat(PAF.mainPath,PAF.filenameIN_filename);
PAF.filenameOUT = strcat(PAF.mainPath,PAF.filenameOUT_filename);
PAF.filenameLOG = strcat(PAF.mainPath, PAF.HFSSfile_filename, ".batchinfo\", erase(PAF.HFSSfile_filename, "aedt"), "log");
PAF.cmdHFSSsim = convertStringsToChars(strcat(PAF.HFSSpath, PAF.strBatchSolve, PAF.HFSSfile));
PAF.cmdHFSSres = convertStringsToChars(strcat(PAF.HFSSpath, PAF.strBatchExtract, PAF.HFSSscript, PAF.HFSSfile));

WritingExportFile(PAF)

%% Variables

L = [0.46, 0.47, 0.48];
S = length(L);
OutputSim = cell(1,S);

for idx = 1:S
    sx = [L(idx)];
    OutputSim{idx} = SimHFSS_Matlab(sx,PAF);
end

%% Functions

function ParameterUpdate(sx,filenameIN,filenameOUT)
fid = fopen(filenameIN); % Open the file to modify
C = textscan(fid,'%s','delimiter','\n');
fclose(fid);

formatSpec = "%.16f";

SignpostList = ["1A1A","1B1B","1C1C","1D1D","1E1E","1F1F","1G1G","1H1H","1I1I","1L1L","1M1M","1N1N","1O1O","1P1P","1Q1Q","1R1R","1S1S","1T1T","1U1U","1V1V","1Z1Z"];

% Update the variables
for k=1:500 % numel(C{1,1})
    % Find the values to substitute
    for idx=1:length(sx)
        C{1,1}(k) = regexprep(C{1,1}(k),convertStringsToChars(SignpostList(idx)), num2str(sx(idx), formatSpec));
    end
end

% Print new file
fid = fopen(filenameOUT,'w');
for k=1:numel(C{1,1})
    fprintf(fid,'%s\r\n',C{1,1}{k,1});
end
fclose(fid);
end

function output = SimHFSS_Matlab(x,PAF)

HFSSfile = PAF.HFSSfile;
HFSSoutput = PAF.HFSSoutput;
filenameLOG = PAF.filenameLOG;
filenameIN  = PAF.filenameIN;
filenameOUT = HFSSfile;
cmdHFSSsim = PAF.cmdHFSSsim;
cmdHFSSres = PAF.cmdHFSSres;

ParameterUpdate(x,filenameIN,filenameOUT)
system(cmdHFSSsim);

% Check if the simulation was successful
fid = fopen(filenameLOG);
C = textscan(fid,'%s','delimiter','\n');
fclose(fid);

idx = 1;
while convertCharsToStrings(C{1,1}{end}) == "[Exiting application]"
    % Notify that HFSS stopped
    t = now; TimeNow = datetime(t,'ConvertFrom','datenum');
    DateString = datestr(TimeNow);
    warning(strcat("HFSS is not working properly and stopped at ", DateString))

    % The execution pauses if 10 trials to launch the simulation failed
    idx = idx + 1;
    if idx > 10
        pause % Something does not work properly (e.g. the internet connection is missing)
    end

    % Launch again the simulation
    pause(10)
    delete(strcat(HFSSfile, ".lock"))
    pause(10)
    system(cmdHFSSsim);
    
    fid = fopen(filenameLOG);
    C = textscan(fid,'%s','delimiter','\n');
    fclose(fid);
end

% Result extraction
system(cmdHFSSres);
output = Results(HFSSoutput);
end

function output = Results(HFSSoutput)
Nout = length(HFSSoutput);
T = cell(1,Nout);

for idx=1:Nout
    T{idx} = readtable(strcat(HFSSoutput(idx), ".csv"), 'VariableNamingRule', 'preserve');
end

output = T;
end

function WritingExportFile(PAF)
N = length(PAF.HFSSoutput_filename);

fid = fopen(strcat(PAF.mainPath,PAF.HFSSscript_filename),'w');

fprintf(fid,'oDesktop.RestoreWindow()\r\n');
fprintf(fid,'oProject = oDesktop.SetActiveProject("%s")\r\n',erase(PAF.HFSSfile_filename,".aedt"));
fprintf(fid,'oDesign = oProject.SetActiveDesign("%s")\r\n',PAF.model_name);
fprintf(fid,'oModule = oDesign.GetModule("ReportSetup")\r\n');

for idx = 1:N
    fprintf(fid,'oModule.UpdateReports(["%s"])\r\n',PAF.HFSSoutput_filename(idx));
    fprintf(fid,'oModule.ExportToFile("%s", "%s%s.csv")\r\n',PAF.HFSSoutput_filename(idx),PAF.mainPath,PAF.HFSSoutput_filename(idx));
end

fclose(fid);
end
