function T_truth = importfile_truth(filename, dataLines)
%IMPORTFILE Import data from a text file
%  T_TRUTH = IMPORTFILE(FILENAME) reads data from text file FILENAME for
%  the default selection.  Returns the data as a table.
%
%  T_TRUTH = IMPORTFILE(FILE, DATALINES) reads data for the specified
%  row interval(s) of text file FILENAME. Specify DATALINES as a
%  positive scalar integer or a N-by-2 array of positive scalar integers
%  for dis-contiguous row intervals.
%
%  Example:
%  T_truth = importfile("C:\Users\hungd\Documents\Erik\Work\unclass_data\Truth.csv", [3, Inf]);
%
%  See also READTABLE.
%
% Auto-generated by MATLAB on 13-Apr-2020 15:25:20

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [3, Inf];
end

%% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 42);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["ctsl", "time", "time2", "x", "y", "z", "vx", "vy", "vz", "lat", "long", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "object", "Var29", "m1", "m2", "m3", "m4", "alt", "Var35", "Var36", "Var37", "Var38", "Var39", "Var40", "Var41", "Var42"];
opts.SelectedVariableNames = ["ctsl", "time", "time2", "x", "y", "z", "vx", "vy", "vz", "lat", "long", "object", "m1", "m2", "m3", "m4", "alt"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "double", "double", "double", "double", "double", "char", "char", "char", "char", "char", "char", "char", "char"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "object", "Var29", "Var35", "Var36", "Var37", "Var38", "Var39", "Var40", "Var41", "Var42"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "object", "Var29", "Var35", "Var36", "Var37", "Var38", "Var39", "Var40", "Var41", "Var42"], "EmptyFieldRule", "auto");

% Import the data
T_truth = readtable(filename, opts);

end