function [Table4ML3, Table4ML4] = createTables4ML(scores, T, T_interp, T_truth, T_truth_interp)

%% Create Table4ML3 with Track History/Future Scores

Table4ML3 = table();
Table4ML3.object = T_interp.object;
Table4ML3.ctsl = T_interp.ctsl;

% Create Object 1 Table of past, present, and future scores
Table4ML3.object1_t0 = scores(:,1);
Table4ML3.object1_h1 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object1_h2 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object1_h3 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object1_h4 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object1_h5 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object1_f1 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object1_f2 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object1_f3 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object1_f4 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object1_f5 = ones(height(Table4ML3),1)*NaN;

% Create Object 2 Table of past, present, and future scores
Table4ML3.object2_t0 = scores(:,2);
Table4ML3.object2_h1 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object2_h2 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object2_h3 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object2_h4 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object2_h5 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object2_f1 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object2_f2 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object2_f3 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object2_f4 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object2_f5 = ones(height(Table4ML3),1)*NaN;

% Create Object 3 Table of past, present, and future scores
Table4ML3.object3_t0 = scores(:,3);
Table4ML3.object3_h1 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object3_h2 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object3_h3 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object3_h4 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object3_h5 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object3_f1 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object3_f2 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object3_f3 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object3_f4 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object3_f5 = ones(height(Table4ML3),1)*NaN;

% Create Object 4 Table of past, present, and future scores
Table4ML3.object4_t0 = scores(:,4);
Table4ML3.object4_h1 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object4_h2 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object4_h3 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object4_h4 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object4_h5 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object4_f1 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object4_f2 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object4_f3 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object4_f4 = ones(height(Table4ML3),1)*NaN;
Table4ML3.object4_f5 = ones(height(Table4ML3),1)*NaN;

unique_ctsl = unique(Table4ML3.ctsl);

for i = 1:length(unique_ctsl)
    T_ctsl = Table4ML3(Table4ML3.ctsl == unique_ctsl(i), :);
    
    % Append past/future object1 data points of scores to T_ctsl
    T_ctsl.object1_h1 = [T_ctsl.object1_t0(1); T_ctsl.object1_t0(1:end-1)];
    T_ctsl.object1_h2 = [T_ctsl.object1_h1(1); T_ctsl.object1_h1(1:end-1)];
    T_ctsl.object1_h3 = [T_ctsl.object1_h2(1); T_ctsl.object1_h2(1:end-1)];
    T_ctsl.object1_h4 = [T_ctsl.object1_h3(1); T_ctsl.object1_h3(1:end-1)];
    T_ctsl.object1_h5 = [T_ctsl.object1_h4(1); T_ctsl.object1_h4(1:end-1)];
    T_ctsl.object1_f1 = [T_ctsl.object1_t0(2:end); T_ctsl.object1_t0(end)];
    T_ctsl.object1_f2 = [T_ctsl.object1_f1(2:end); T_ctsl.object1_f1(end)];
    T_ctsl.object1_f3 = [T_ctsl.object1_f2(2:end); T_ctsl.object1_f2(end)];
    T_ctsl.object1_f4 = [T_ctsl.object1_f3(2:end); T_ctsl.object1_f3(end)];
    T_ctsl.object1_f5 = [T_ctsl.object1_f4(2:end); T_ctsl.object1_f4(end)];
    
    % Append past/future object2 data points of scores to T_ctsl
    T_ctsl.object2_h1 = [T_ctsl.object2_t0(1); T_ctsl.object2_t0(1:end-1)];
    T_ctsl.object2_h2 = [T_ctsl.object2_h1(1); T_ctsl.object2_h1(1:end-1)];
    T_ctsl.object2_h3 = [T_ctsl.object2_h2(1); T_ctsl.object2_h2(1:end-1)];
    T_ctsl.object2_h4 = [T_ctsl.object2_h3(1); T_ctsl.object2_h3(1:end-1)];
    T_ctsl.object2_h5 = [T_ctsl.object2_h4(1); T_ctsl.object2_h4(1:end-1)];
    T_ctsl.object2_f1 = [T_ctsl.object2_t0(2:end); T_ctsl.object2_t0(end)];
    T_ctsl.object2_f2 = [T_ctsl.object2_f1(2:end); T_ctsl.object2_f1(end)];
    T_ctsl.object2_f3 = [T_ctsl.object2_f2(2:end); T_ctsl.object2_f2(end)];
    T_ctsl.object2_f4 = [T_ctsl.object2_f3(2:end); T_ctsl.object2_f3(end)];
    T_ctsl.object2_f5 = [T_ctsl.object2_f4(2:end); T_ctsl.object2_f4(end)];
    
    % Append past/future object3 data points of scores to T_ctsl
    T_ctsl.object3_h1 = [T_ctsl.object3_t0(1); T_ctsl.object3_t0(1:end-1)];
    T_ctsl.object3_h2 = [T_ctsl.object3_h1(1); T_ctsl.object3_h1(1:end-1)];
    T_ctsl.object3_h3 = [T_ctsl.object3_h2(1); T_ctsl.object3_h2(1:end-1)];
    T_ctsl.object3_h4 = [T_ctsl.object3_h3(1); T_ctsl.object3_h3(1:end-1)];
    T_ctsl.object3_h5 = [T_ctsl.object3_h4(1); T_ctsl.object3_h4(1:end-1)];
    T_ctsl.object3_f1 = [T_ctsl.object3_t0(2:end); T_ctsl.object3_t0(end)];
    T_ctsl.object3_f2 = [T_ctsl.object3_f1(2:end); T_ctsl.object3_f1(end)];
    T_ctsl.object3_f3 = [T_ctsl.object3_f2(2:end); T_ctsl.object3_f2(end)];
    T_ctsl.object3_f4 = [T_ctsl.object3_f3(2:end); T_ctsl.object3_f3(end)];
    T_ctsl.object3_f5 = [T_ctsl.object3_f4(2:end); T_ctsl.object3_f4(end)];
    
    % Append past/future object4 data points of scores to T_ctsl
    T_ctsl.object4_h1 = [T_ctsl.object4_t0(1); T_ctsl.object4_t0(1:end-1)];
    T_ctsl.object4_h2 = [T_ctsl.object4_h1(1); T_ctsl.object4_h1(1:end-1)];
    T_ctsl.object4_h3 = [T_ctsl.object4_h2(1); T_ctsl.object4_h2(1:end-1)];
    T_ctsl.object4_h4 = [T_ctsl.object4_h3(1); T_ctsl.object4_h3(1:end-1)];
    T_ctsl.object4_h5 = [T_ctsl.object4_h4(1); T_ctsl.object4_h4(1:end-1)];
    T_ctsl.object4_f1 = [T_ctsl.object4_t0(2:end); T_ctsl.object4_t0(end)];
    T_ctsl.object4_f2 = [T_ctsl.object4_f1(2:end); T_ctsl.object4_f1(end)];
    T_ctsl.object4_f3 = [T_ctsl.object4_f2(2:end); T_ctsl.object4_f2(end)];
    T_ctsl.object4_f4 = [T_ctsl.object4_f3(2:end); T_ctsl.object4_f3(end)];
    T_ctsl.object4_f5 = [T_ctsl.object4_f4(2:end); T_ctsl.object4_f4(end)];
    
    % Insert past/future points back into Table4ML3
    Table4ML3(Table4ML3.ctsl == unique_ctsl(i), :) = T_ctsl; 
end

Table4ML3.ctsl = [];

% Set non truth objects to Non-TOI
nonTruthObjects = setdiff(T.object, T_truth.object);
for i = 1:length(nonTruthObjects)
    Table4ML3.object(strcmp(Table4ML3.object, nonTruthObjects(i))) = {'Non-TOI'};
end

%% Create a new Table 4 ML

Table4ML4 = table();
[T_correct, T_incorrect] = getCorrectInocorrectTablesPhase2(T_truth_interp, Table4ML3);
T_correct.object = [];
T_incorrect.object = [];

% Splitting Point for incorrect table
unique_truth_objects = unique(T_truth.object);
for i = 1:length(unique_truth_objects)
    split_index_for_incorrect = (i - 1) * 11;
    Table4ML4_temp = table();
    Table4ML4_temp.object = cellstr(repmat(unique_truth_objects(i), height(T_correct), 1));
    Table4ML4_temp = [Table4ML4_temp ...
                      T_incorrect(:, 1:split_index_for_incorrect) ...
                      T_correct ...
                      T_incorrect(:, split_index_for_incorrect + 1:end)];
    
    % Reset variable names for concatenation for incorrect table
    for j = 1:width(Table4ML4_temp)
        Table4ML4_temp.Properties.VariableNames{j} = ['var_' char(string(j - 1))];
    end
    
    Table4ML4 = [Table4ML4; Table4ML4_temp];
end

%% Add non TOI to Table4ML4

T_nonTOI = Table4ML3(strcmp(Table4ML3.object, 'Non-TOI'), :);
% Reset variable names for concatenation for incorrect table
for j = 1:width(T_nonTOI)
    T_nonTOI.Properties.VariableNames{j} = ['var_' char(string(j - 1))];
end
Table4ML4 = [Table4ML4; T_nonTOI];

%% Rename object column to object

Table4ML4.Properties.VariableNames{1} = 'object';

%% Reset variable names for Table 4 ML

for j = 2:width(Table4ML3)
    Table4ML3.Properties.VariableNames{j} = ['var_' char(string(j - 1))];
end

end