function T_object = select_object (T_combined)

%% Data Selection

data_type = {'gps', 'radar', 'both'};
[selection_index, ~] = listdlg('PromptString', 'Select Data type:',...
                               'ListSize', [300, 600],...
                               'SelectionMode', 'single',... 
                               'ListString', data_type);
                           
% Filter to only gps data
if selection_index == 1
    
    T_data_type = T_combined (strcmp(T_combined.data_type, 'gps'),:);

% Filter on only radar data
elseif selection_index == 2
    
    T_data_type = T_combined (strcmp(T_combined.data_type, 'radar'),:);

% No filter
else
    
    T_data_type = T_combined;
end
                        
%% Object Selection

unique_object = unique(T_data_type.object);

[selection_index, ~] = listdlg('PromptString', 'Select Object:',...
                               'ListSize', [300, 600],...
                               'SelectionMode', 'multiple',... 
                               'ListString', unique_object);       
                           
% Finding values selected in data
object_index = [];
for i = 1:length(selection_index)
    
    object_index_temp = find(strcmp(T_data_type.object, unique_object(selection_index(i))));
    object_index = [object_index; object_index_temp];
end

T_object = T_data_type(object_index,:);
T_object = sortrows(T_object, 'time');

end
                           
