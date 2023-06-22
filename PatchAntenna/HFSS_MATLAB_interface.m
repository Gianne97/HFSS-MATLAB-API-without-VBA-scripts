% HFSS API
% Trapezoidal feed with step.

% Author: Giacomo Giannetti, University of Florence
% Date: 06/12/2022

%% Preamble

clear
PAF = PathAndFile;

SaC.f0 = 2; SaC.Neval = 1; SaC.f_offset = 0.005; SaC.S11min = -40;
W = 4.94; wm = 0.2;

X.x0 = [49.83,59.29,28.51,2.07,2.07]; % Analytical design
X.lb = [46,57,26,1.5,1.5];
X.ub = [50,61,32, 0.5*(W-wm), 0.5*(W-wm)];

%% Optimization

SaC.x0 = X.x0;
IdxVarToOpt = 1; SaC.IdxVarToOpt = IdxVarToOpt;

fToOpt = @(x) fcost_fresCentering(x,PAF,SaC);
options = optimset("Display", "iter", "MaxIter", 50, 'OutputFcn',@StopBelowTolerance);
[xopt,fval,exitflag,output] = fminbnd(fToOpt,X.lb(IdxVarToOpt),X.ub(IdxVarToOpt),options);
xopt1 = xopt;

SaC.x0(IdxVarToOpt) = xopt;
IdxVarToOpt = [2, 3, 4, 5]; SaC.IdxVarToOpt = IdxVarToOpt;

fToOpt = @(x) fcost_matching_min(x,PAF,SaC);
options = optimoptions("fmincon",Display="iter",ObjectiveLimit=SaC.S11min);
[xopt,fval,exitflag,output] = fmincon(fToOpt,SaC.x0(IdxVarToOpt),[],[],[],[],X.lb(IdxVarToOpt),X.ub(IdxVarToOpt),[],options);
xopt2 = xopt;

SaC.x0(IdxVarToOpt) = xopt;
IdxVarToOpt = 1; SaC.IdxVarToOpt = IdxVarToOpt;

fToOpt = @(x) fcost_fresCentering(x,PAF,SaC);
options = optimset("Display", "iter", "MaxIter", 50, 'OutputFcn',@StopBelowTolerance);
[xopt,fval,exitflag,output] = fminbnd(fToOpt,X.lb(IdxVarToOpt),X.ub(IdxVarToOpt),options);
xopt3 = xopt;

%% Functions

function cost = fcost_fresCentering(x,PAF,SaC)
    f0 = SaC.f0;
    sx = SaC.x0; sx(SaC.IdxVarToOpt) = x;
    OutputSim = SimHFSS_Matlab(sx,PAF);
    tmp = table2array(OutputSim{1});
    [Min,IdxMin] = min(tmp(:,2),[],'all');
    f_res = tmp(IdxMin,1);
    
    cost = abs(f_res - f0);
    
    disp([x, f_res, cost, Min])
    Res1(:,SaC.Neval) = tmp(:,2);
    SaC.Neval = SaC.Neval + 1;
end

function stop = StopBelowTolerance(x, optimValues, state)
stop = false;
% Check if objective function is 0
if optimValues.fval < 0.005
    stop = true;
end
end

function cost = fcost_matching_min(x,PAF,SaC)
    f0 = SaC.f0;
    sx = SaC.x0; sx(SaC.IdxVarToOpt) = x;
    OutputSim = SimHFSS_Matlab(sx,PAF);
    tmp = table2array(OutputSim{1});
    [cost, idxMin] = min(tmp(:,2));
    freq = tmp(:,1);
    
    disp([x, cost, freq(idxMin)])
    Res2(:,SaC.Neval) = tmp(:,2);
    SaC.Neval = SaC.Neval + 1;
end

function cost = fcost_matching(x,PAF,SaC)
    f0 = SaC.f0;
    OutputSim = SimHFSS_Matlab(x,PAF);
    tmp = table2array(OutputSim{1});
    cost = interp1(tmp(:,1),tmp(:,2),f0);
    
    disp([x, cost])
    Res2(:,SaC.Neval) = tmp(:,2);
    SaC.Neval = SaC.Neval + 1;
end

%% Functions HFSS-MATLAB API

function PAF = PathAndFile
% Paths to change
PAF.mainPath = "C:\Users\giannetti\Documents\HFSS-MATLAB_interface\Dev5\TrapezoidalFeed\";
PAF.HFSSpath = "C:\""Program Files\AnsysEM\AnsysEM21.2\Win64\ansysedt.exe""";
PAF.HFSSfile_filename = "Modified.aedt";
PAF.model_name = "Design";
PAF.HFSSscript_filename = "ExportToFile_Sparam.py";
PAF.HFSSoutput_filename = ["S11mag", "S11pha"];
PAF.filenameIN_filename  = "Base.txt";
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
end

function ParameterUpdate(sx,filenameIN,filenameOUT)
fid = fopen(filenameIN); % Open the file to modify
C = textscan(fid,'%s','delimiter','\n');
fclose(fid);

formatSpec = "%.14f";

SignpostList = ["1A1A","1B1B","2A2A","2B2B","2C2C"];

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