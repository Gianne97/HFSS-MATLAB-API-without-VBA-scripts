oDesktop.RestoreWindow()
oProject = oDesktop.SetActiveProject("Modified")
oDesign = oProject.SetActiveDesign("Design")
oModule = oDesign.GetModule("ReportSetup")
oModule.UpdateReports(["S11mag"])
oModule.ExportToFile("S11mag", "C:\Users\giannetti\Documents\HFSS-MATLAB_interface\Dev6\S11mag.csv")
oModule.UpdateReports(["S11pha"])
oModule.ExportToFile("S11pha", "C:\Users\giannetti\Documents\HFSS-MATLAB_interface\Dev6\S11pha.csv")