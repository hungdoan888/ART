function [T_correct, T_incorrect] = getCorrectInocorrectTablesPhase2(T_truth_interp, Table4ML3)

% Create two separte tables that have correct and incorrect values
T_correct = table();
T_incorrect = table();

unique_truth_objects = unique(T_truth_interp.object);
for i = 1:length(unique_truth_objects)
    correct_columns = 1 + ((i - 1) * 11 + 1:(i - 1) * 11 + 11);
    incorrect_columns = setdiff(2:width(Table4ML3), correct_columns);
    T_object = Table4ML3(strcmp(Table4ML3.object, unique_truth_objects(i)), :);
    
    % Add object to correct
    T_correct_temp = table();
    T_correct_temp.object = T_object.object;
    
    % Add object to incorrect
    T_incorrect_temp = table();
    T_incorrect_temp.object = T_object.object;
    
    % Add correct and incorrect columns
    T_correct_temp = [T_correct_temp T_object(:, correct_columns)];
    T_incorrect_temp = [T_incorrect_temp T_object(:, incorrect_columns)];
    
    % Reset variable names for concatenation for correct table
    for j = 2:width(T_correct_temp)
        T_correct_temp.Properties.VariableNames{j} = ['correct_' char(string(j - 1))];
    end
    
    % Reset variable names for concatenation for incorrect table
    for j = 2:width(T_incorrect_temp)
        T_incorrect_temp.Properties.VariableNames{j} = ['incorrect_' char(string(j - 1))];
    end
    
    % Append Tables
    T_correct = [T_correct; T_correct_temp];
    T_incorrect = [T_incorrect; T_incorrect_temp];
end
end