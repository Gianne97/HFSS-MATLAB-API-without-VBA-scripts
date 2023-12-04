% MATLAB-HFSS API
% Author: Giacomo Giannetti, University of Florence

%% Preamble

clear
clc
PAF = PathAndFile;

filename1 = "VariablesProject.txt"; % Project variables from HFSS
VariablesProject = importfile(filename1);
filename2 = "VariablesDesign.txt"; % Design variables from HFSS
VariablesDesign = importfile(filename2);
Variables = [VariablesProject(:,1:3); VariablesDesign(:,1:3)];
Var2Sub = SignpostSubstitution(PAF.filenameINstart_filename,PAF.filenameIN_filename,Variables);
PAF.SignpostList = Var2Sub{:,4};

x = Var2Sub{:,2};

output = SimHFSS_Matlab(x,PAF);

figure
hold on
plot(output{1}{:,1},output{1}{:,2})
hold off

figure
hold on
plot(output{2}{:,1},output{2}{:,2})
hold off

%% Functions signposts
function Var2Sub = SignpostSubstitution(filenameIN,filenameOUT,Variables)

Var2Sub = Variables(~isnan(Variables{:,2}),:);

[Nvar, ~] = size(Var2Sub);
SignpostList = generateSignposts(Nvar);
Var2Sub = [Var2Sub, SignpostList];

fid = fopen(filenameIN); % Open the file to modify
C = textscan(fid,'%s','delimiter','\n');
fclose(fid);

% Update the variables
for k=1:500 % numel(C{1,1})
    % Find the values to substitute
    if contains(C{1,1}(k),"VariableProp")
        for idx=1:Nvar
            ActualVar = extractBetween(C{1,1}(k),"VariableProp('","', '");
            if strcmp(ActualVar, Var2Sub{idx,1})
                %                 C{1,1}(k) % Before substitution
                if contains(C{1,1}(k),"oa(")
                    help = extractBetween(C{1,1}(k),"', '","', oa(");
                else
                    help = extractBetween(C{1,1}(k),"', '","')");
                end
                ValueUnit = reverse(extractBefore(reverse(help),"'")); % Numeric value with unit
                Value = erase(ValueUnit,char(Var2Sub{idx,3}));
                C{1,1}(k) = regexprep(C{1,1}(k), Value, SignpostList{idx});
                %                 C{1,1}(k) % After substitution
            end
        end
    end
end

% Print new file
fid = fopen(filenameOUT,'w');
for k=1:numel(C{1,1})
    fprintf(fid,'%s\r\n',C{1,1}{k,1});
end
fclose(fid);

end

function Signposts = generateSignposts(Nvar)

Numbers = ["0"; "1"; "2"; "3"; "4"; "5"; "6"; "7"; "8"; "9"];
Words = ["A"; "B"; "C"; "D"; "E"; "F"; "G"; "H"; "L"; "M"];
NWords = length(Words);

Signposts = cell(NWords,1);

for idx = 1:Nvar
    idxNumbers = floor(idx./NWords)+1;
    idxWords = mod(idx, NWords);
    if idxWords == 0
        idxWords = NWords;
        idxNumbers = idxNumbers - 1;
    end

    Signposts{idx} = strcat(Numbers(idxNumbers), Words(idxWords), Numbers(idxNumbers), Words(idxWords));
end

end

function Variables = importfile(filename, dataLines)
%IMPORTFILE Import data from a text file
%  VARIABLES = IMPORTFILE(FILENAME) reads data from text file FILENAME
%  for the default selection.  Returns the data as a table.
%
%  VARIABLES = IMPORTFILE(FILE, DATALINES) reads data for the specified
%  row interval(s) of text file FILENAME. Specify DATALINES as a
%  positive scalar integer or a N-by-2 array of positive scalar integers
%  for dis-contiguous row intervals.

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 8);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["Name", "Value", "Unit", "EvaluatedValue", "Description", "Readonly", "Hidden", "Sweep"];
opts.VariableTypes = ["char", "double", "categorical", "double", "char", "categorical", "categorical", "categorical"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["Name", "Description"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Name", "Unit", "Description", "Readonly", "Hidden", "Sweep"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "EvaluatedValue", "TrimNonNumeric", true);
opts = setvaropts(opts, "EvaluatedValue", "ThousandsSeparator", ",");

% Import the data
Variables = readtable(filename, opts);

end

%% Functions HFSS-MATLAB API

function PAF = PathAndFile
% Paths to change
PAF.mainPath = "C:\Users\giannetti\Documents\HFSS-MATLAB_interface\Dev6\";
PAF.HFSSpath = "C:\""Program Files\AnsysEM\AnsysEM21.2\Win64\ansysedt.exe""";
PAF.HFSSfile_filename = "Modified.aedt";
PAF.model_name = "Design";
PAF.HFSSscript_filename = "ExportToFile_Sparam.py";
PAF.HFSSoutput_filename = ["S11mag", "S11pha"];
PAF.filenameINstart_filename  = "BaseNoSignposts.txt";
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

function ParameterUpdate(sx,filenameIN,filenameOUT,PAF)
fid = fopen(filenameIN); % Open the file to modify
C = textscan(fid,'%s','delimiter','\n');
fclose(fid);

formatSpec = "%.14f";
SignpostList = PAF.SignpostList;

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

ParameterUpdate(x,filenameIN,filenameOUT,PAF)
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