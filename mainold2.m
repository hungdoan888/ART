
%% Import Data

T_truth = importfile_truth('Truth.csv');
T = importfile_data('UNITB_TrackMatched.csv');
load phase1_model
load phase1_model2

%% Sort rows by time
% *** Will have to account for 24 hours in the future ***

T_truth = sortrows(T_truth, "time");
T = sortrows(T, "time");

%% Define Globals

MAX_OBJECTS = 20;

%% Add ship position 
% *** This will be improved by using enu2lla in the future ***

% Get ship Position
T.range = sqrt(T.x.^2 + T.y.^2 + T.z.^2);
T_range = T(T.range == min(T.range), :);

% Truth
T_truth.ship_lat = ones(height(T_truth), 1) * T_range.lat(1);
T_truth.ship_long = ones(height(T_truth), 1) * T_range.long(1);
T_truth.ship_alt = ones(height(T_truth), 1) * T_range.alt(1);

% Data
T.ship_lat = ones(height(T), 1) * T_range.lat(1);
T.ship_long = ones(height(T), 1) * T_range.long(1);
T.ship_alt = ones(height(T), 1) * T_range.alt(1);

%% Create enu coordinates to match ship coordinate frame in Truth
% *** Will need to use APL lla2enu in the future ***

% Truth
for i = 1:height(T_truth)
    lla = [T_truth.lat(i), T_truth.long(i), T_truth.alt(i)];
    lla0 = [T_truth.ship_lat(i) T_truth.ship_long(i) T_truth.ship_alt(i)];
    xyzENU = lla2enu(lla, lla0, "flat");
    
    T_truth.x(i) = xyzENU(1);
    T_truth.y(i) = xyzENU(2);
    T_truth.z(i) = xyzENU(3);
end

% Data
for i = 1:height(T)
    lla = [T.lat(i), T.long(i), T.alt(i)];
    lla0 = [T.ship_lat(i) T.ship_long(i) T.ship_alt(i)];
    xyzENU = lla2enu(lla, lla0, "flat");
    
    T.x(i) = xyzENU(1);
    T.y(i) = xyzENU(2);
    T.z(i) = xyzENU(3);
end

%% Calculate Range

T.range = sqrt(T.x.^2 + T.y.^2 + T.z.^2);
T_truth.range = sqrt(T_truth.x.^2 + T_truth.y.^2 + T_truth.z.^2);

%% Plot to see data before ML

unique_objects = unique(T_truth.object);
cmap = prism(length(unique_objects));

% x vs y
figure(1)
set(gca,'Color','black')
hold on

% range vs time
figure(2)
set(gca,'Color','black')
hold on
for i = 1:length(unique_objects)
    
   % Plot Truth
   T_truth_object = T_truth(strcmp(T_truth.object, unique_objects(i)), :);
   figure(1)
   plot(T_truth_object.x, T_truth_object.y, '.-', 'color', cmap(i, :))
   figure(2)
   plot(T_truth_object.time, T_truth_object.range, '.-', 'color', cmap(i, :))

   
   % Plot Data
   T_object = T(strcmp(T.object, unique_objects(i)), :);
   unique_ctsl = unique(T_object.ctsl);
   for j = 1:length(unique_ctsl)
       T_ctsl = T_object(T_object.ctsl == unique_ctsl(j), :);
       figure(1)
       plot(T_ctsl.x, T_ctsl.y, 'x-', 'color', cmap(i, :))
       figure(2)
       plot(T_ctsl.time, T_ctsl.range, 'x-', 'color', cmap(i, :))
   end
end

%% Interpolate Truth

T_truth_interp = table();

% Filter on object
unique_object = unique(T_truth.object);
for i = 1:length(unique_object)
   T_object = T_truth(strcmp(T_truth.object, unique_object(i)), :); 
   
   % Filter on ctsl
   unique_ctsl = unique(T_object.ctsl);
   for j = 1:length(unique_ctsl)
      T_ctsl = T_object(T_object.ctsl == unique_ctsl(j), :); 
      
      % Append to interp
      T_interp_temp = interp_T_ctsl(T_ctsl);
      T_truth_interp = [T_truth_interp; T_interp_temp];
   end
end

%% Interpolate Data

T_interp = table();

% Filter on object
unique_object = unique(T.object);
for i = 1:length(unique_object)
   T_object = T(strcmp(T.object, unique_object(i)), :); 
   
   % Filter on ctsl
   unique_ctsl = unique(T_object.ctsl);
   for j = 1:length(unique_ctsl)
      T_ctsl = T_object(T_object.ctsl == unique_ctsl(j), :); 
      
      % Append to interp
      T_interp_temp = interp_T_ctsl(T_ctsl);
      T_interp = [T_interp; T_interp_temp];
   end
end

%% Create Table for ML
% 
% Matrix for ML
Matrix4ML = [];
Matrix4ML_temp = ones(height(T_interp), 5) * NaN;  % 5 - x, y, vx, vy, range

% Define max values for normalization
max_diff_x = 0;
max_diff_y = 0;
max_diff_vx = 0;
max_diff_vy = 0;
max_diff_range = 0;

% Find differences of x, y, vx, vy, range
unique_truth_objects = unique(T_truth_interp.object);
for i = 1:length(unique_truth_objects)
    fprintf('%d out of %d \n', i, length(unique_truth_objects))
    for j = 1:height(T_interp)
        T_truth_temp = T_truth_interp(strcmp(T_truth_interp.object, unique_truth_objects(i)) & ...
                                             T_truth_interp.time == T_interp.time(j), :);
        if height(T_truth_temp) == 0
            continue
        end
        
        diff_x = abs(T_truth_temp.x(1) - T_interp.x(j));         
        diff_y = abs(T_truth_temp.y(1) - T_interp.y(j));
        diff_vx = abs(T_truth_temp.vx(1) - T_interp.vx(j));
        diff_vy = abs(T_truth_temp.vy(1) - T_interp.vy(j)); 
        diff_range = abs(T_truth_temp.range(1) - T_interp.range(j));
        
        % Update Max diff
        if diff_x > max_diff_x
            max_diff_x = diff_x;
        end
        
        if diff_y > max_diff_y
            max_diff_y = diff_y;
        end
        
        if diff_vx > max_diff_vx
            max_diff_vx = diff_vx;
        end
        
        if diff_vy > max_diff_vy
            max_diff_vy = diff_vy;
        end
        
        if diff_range > max_diff_range
            max_diff_range = diff_range;
        end

        Matrix4ML_temp(j, 1) = diff_x;
        Matrix4ML_temp(j, 2) = diff_y;
        Matrix4ML_temp(j, 3) = diff_vx;
        Matrix4ML_temp(j, 4) = diff_vy;
        Matrix4ML_temp(j, 5) = diff_range;
    end
    Matrix4ML = [Matrix4ML Matrix4ML_temp];
end

%% Normalize Values

for i = 1:size(Matrix4ML, 2)
    
    if mod(i, 5) == 1 % x
       Matrix4ML(:, i) = Matrix4ML(:, i) / max_diff_x;
    
    elseif mod(i, 5) == 2  % y
       Matrix4ML(:, i) = Matrix4ML(:, i) / max_diff_y;
       
    elseif mod(i, 5) == 3  % vx
       Matrix4ML(:, i) = Matrix4ML(:, i) / max_diff_vx;
    
    elseif mod(i, 5) == 4  % vy
       Matrix4ML(:, i) = Matrix4ML(:, i) / max_diff_vy;
    
    else  % range
       Matrix4ML(:, i) = Matrix4ML(:, i) / max_diff_range;
    end
end

%% Create Table for ML

Table4ML = table();
Table4ML.object = T_interp.object;
Table4ML = [Table4ML array2table(Matrix4ML)];

% Set non truth objects to Non-TOI
nonTruthObjects = setdiff(T.object, T_truth.object);
for i = 1:length(nonTruthObjects)
    Table4ML.object(strcmp(Table4ML.object, nonTruthObjects(i))) = {'Non-TOI'};
end

%% Artificially add objects until there are MAX_OBJECTS objects

% Create object string (Object_1, Object_2, ..., Object_MAX_OBJECTS)
object_string1 = repmat('Object_', MAX_OBJECTS, 1);
object_string2 = string(1:MAX_OBJECTS)';
object_string = cellstr(strcat(object_string1, object_string2));

% Convert Truth object names to generic object names
unique_truth_objects = unique(T_truth_interp.object);
object_mapping = table();
object_mapping.truth = unique_truth_objects;
object_mapping.generic = object_string(1:length(unique_truth_objects));

%% Create two separte tables that have correct and incorrect values

[~, T_incorrect] = getCorrectInocorrectTables(T_truth_interp, Table4ML);

%% Make Table4ML MAX_OBJECTS * 5 columns (1 for object, 5*MAX_OBJECTS (5 - x, y, vx, vy, range, MAX_OBJECTS - max number of objects)

% Table4ML
Matrix_temp = ones(height(Table4ML), 5 * MAX_OBJECTS + 1 - width(Table4ML)) * NaN;
Table4ML = [Table4ML array2table(Matrix_temp)];

% Table4ML
Matrix_temp = ones(height(Table4ML), 5 * MAX_OBJECTS + 1 - width(Table4ML)) * NaN;
Table4ML = [Table4ML array2table(Matrix_temp)];

%% Fill in the rest of the table with incorrect values

unique_truth_objects = unique(T_truth_interp.object);
startColumn = (length(unique_truth_objects) * 5) + 2;
for i = 1:length(unique_truth_objects)
   unique_truth_objects_index = find(strcmp(Table4ML.object, unique_truth_objects(i)));
   T_incorrect_temp = T_incorrect(strcmp(T_incorrect.object, unique_truth_objects(i)), :);
   T_incorrect_temp.object = [];  % Get rid of object to make it easier to mod
   T_incorrect_temp_column_index = 1;
   for j = startColumn:width(Table4ML)
      Table4ML(unique_truth_objects_index, j) = T_incorrect_temp(:, T_incorrect_temp_column_index);
      
      % Increment T_incorrect_temp
      T_incorrect_temp_column_index = mod(T_incorrect_temp_column_index + 1, width(T_incorrect_temp));
      if T_incorrect_temp_column_index == 0
          T_incorrect_temp_column_index = width(T_incorrect_temp);
      end
   end
end

%% Fill in Non-TOI NaN values

unique_truth_objects = unique(T_truth_interp.object);
startColumn = (length(unique_truth_objects) * 5) + 2;

T_incorrect_temp = Table4ML(strcmp(Table4ML.object, 'Non-TOI'), 2:startColumn - 1);
T_incorrect_temp_column_index = 1;
for j = startColumn:width(Table4ML)
    Table4ML(strcmp(Table4ML.object, 'Non-TOI'), j) = T_incorrect_temp(:, T_incorrect_temp_column_index);

    % Increment T_incorrect_temp
    T_incorrect_temp_column_index = mod(T_incorrect_temp_column_index + 1, width(T_incorrect_temp));
    if T_incorrect_temp_column_index == 0
        T_incorrect_temp_column_index = width(T_incorrect_temp);
    end
end

%% Create a new Table 4 ML that has MAX_OBJECTS objects for training

Table4ML2 = table();
[T_correct, T_incorrect] = getCorrectInocorrectTables(T_truth_interp, Table4ML);
T_correct.object = [];
T_incorrect.object = [];

% Splitting Point for incorrect table
for i = 1:length(object_string)
    fprintf('Table4ML2 object %d out of %d\n', i, length(object_string))
    split_index_for_incorrect = (i - 1) * 5;
    Table4ML2_temp = table();
    Table4ML2_temp.object = cellstr(repmat(object_string(i), height(T_correct), 1));
    Table4ML2_temp = [Table4ML2_temp ...
                      T_incorrect(:, 1:split_index_for_incorrect) ...
                      T_correct ...
                      T_incorrect(:, split_index_for_incorrect + 1:end)];
    
    % Reset variable names for concatenation for incorrect table
    for j = 1:width(Table4ML2_temp)
        Table4ML2_temp.Properties.VariableNames{j} = ['var_' char(string(j - 1))];
    end
    
    Table4ML2 = [Table4ML2; Table4ML2_temp];
end

%% Add non TOI to Table4ML2

T_nonTOI = Table4ML(strcmp(Table4ML.object, 'Non-TOI'), :);
% Reset variable names for concatenation for incorrect table
for j = 1:width(T_nonTOI)
    T_nonTOI.Properties.VariableNames{j} = ['var_' char(string(j - 1))];
end
Table4ML2 = [Table4ML2; T_nonTOI];

%% Run phase 1 of ML

% Run Model
[phase1, score] = phase1_model.predictFcn(Table4ML);
% phase1 = phase1_model2.predictFcn(Table4ML2);

% Insert model results into T_interp
T_interp.phase1 = phase1;
T_interp = movevars(T_interp, 'phase1', 'After', 'object');

% Insert model results into Table4ML
Table4ML.phase1 = phase1;
Table4ML = movevars(Table4ML, 'phase1', 'After', 'object');

%% Plot to see difference

unique_objects = unique(T_interp.object);
cmap = prism(length(unique_objects));

% x vs y
figure(3)
set(gca,'Color','black')
hold on

% range vs time
figure(4)
set(gca,'Color','black')
hold on
for i = 1:length(unique_objects)
   
   % Plot Data
   T_object = T_interp(strcmp(T_interp.object, unique_objects(i)), :);
   unique_ctsl = unique(T_object.ctsl);
   for j = 1:length(unique_ctsl)
       T_ctsl = T_object(T_object.ctsl == unique_ctsl(j), :);
       figure(3)
       plot(T_ctsl.x, T_ctsl.y, '.-', 'color', cmap(i, :))
       figure(4)
       plot(T_ctsl.time, T_ctsl.range, '.-', 'color', cmap(i, :))
   end
end

% Find where ML does not match 
index_setDiff_ML_Data = find(strcmp(T_interp.object, T_interp.phase1) == 0);
figure(3)
plot(T_interp.x(index_setDiff_ML_Data), T_interp.y(index_setDiff_ML_Data), 'ro')
figure(4)
plot(T_interp.time(index_setDiff_ML_Data), T_interp.range(index_setDiff_ML_Data), 'ro')

%% Input track history into Table4ML

unique_objects = unique(T_truth.object);
track_neighbors = table();
track_neighbors.hist1 = cellstr(repmat("", height(T_interp), 1));
track_neighbors.hist2 = cellstr(repmat("", height(T_interp), 1));
track_neighbors.hist3 = cellstr(repmat("", height(T_interp), 1));
track_neighbors.hist4 = cellstr(repmat("", height(T_interp), 1));
track_neighbors.hist5 = cellstr(repmat("", height(T_interp), 1));
track_neighbors.fut1 = cellstr(repmat("", height(T_interp), 1));
track_neighbors.fut2 = cellstr(repmat("", height(T_interp), 1));
track_neighbors.fut3 = cellstr(repmat("", height(T_interp), 1));
track_neighbors.fut4 = cellstr(repmat("", height(T_interp), 1));
track_neighbors.fut5 = cellstr(repmat("", height(T_interp), 1));

Table4ML = [track_neighbors Table4ML];
Table4ML = movevars(Table4ML, 'object', 'Before', 'hist1');
Table4ML = movevars(Table4ML, 'phase1', 'Before', 'hist1');
Table4ML = movevars(Table4ML, 'ctsl', 'Before', 'hist1');

unique_phase1 = unique(Table4ML.phase1);
for i = 1:length(unique_phase1)
    T_phase1 = Table4ML(strcmp(Table4ML.phase1, unique_phase1(i)), :);
    unique_ctsl = unique(T_phase1.ctsl);
    for j = 1:length(unique_ctsl)
        T_ctsl = T_phase1(T_phase1.ctsl == unique_ctsl(j), :);
    end
end


















