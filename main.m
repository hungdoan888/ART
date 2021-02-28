%% Import Data

T_truth = importfile_truth('Truth.csv');
T = importfile_data('UNITB_TrackMatched.csv');
load phase1_226
load phase2_test

%% Sort rows by time

T_truth = sortrows(T_truth, "time");
T = sortrows(T, "time");

%% Add ship position 

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

% Matrix for ML
Matrix4ML = [];
Matrix4ML_temp = ones(height(T_interp), 5) * NaN;  % 5 - x, y, vx, vy, range

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

        Matrix4ML_temp(j, 1) = diff_x;
        Matrix4ML_temp(j, 2) = diff_y;
        Matrix4ML_temp(j, 3) = diff_vx;
        Matrix4ML_temp(j, 4) = diff_vy;
        Matrix4ML_temp(j, 5) = diff_range;
    end
    Matrix4ML = [Matrix4ML Matrix4ML_temp];
end

% Create Table for ML
Table4ML = table();
Table4ML.object = T_interp.object;
Table4ML = [Table4ML array2table(Matrix4ML)];

% Set non truth objects to Non-TOI
nonTruthObjects = setdiff(T.object, T_truth.object);
for i = 1:length(nonTruthObjects)
    Table4ML.object(strcmp(Table4ML.object, nonTruthObjects(i))) = {'Non-TOI'};
end

%% Create a new Table 4 ML

Table4ML2 = table();
[T_correct, T_incorrect] = getCorrectInocorrectTables(T_truth_interp, Table4ML);
T_correct.object = [];
T_incorrect.object = [];

% Splitting Point for incorrect table
unique_truth_objects = unique(T_truth.object);
for i = 1:length(unique_truth_objects)
    split_index_for_incorrect = (i - 1) * 5;
    Table4ML2_temp = table();
    Table4ML2_temp.object = cellstr(repmat(unique_truth_objects(i), height(T_correct), 1));
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

%% Rename object column to object

Table4ML2.Properties.VariableNames{1} = 'object';

%% Reset variable names for Table 4 ML

for j = 2:width(Table4ML)
    Table4ML.Properties.VariableNames{j} = ['var_' char(string(j - 1))];
end

%% Run phase 1 of ML

% Run Model
[phase1, scores] = phase1_226.predictFcn(Table4ML);
%phase1 = phase1_model.predictFcn(Table4ML);
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
   
   % Plot Truth
   T_truth_object = T_truth(strcmp(T_truth.object, unique_objects(i)), :);
   figure(3)
   plot(T_truth_object.x, T_truth_object.y, 'sq-', 'color', cmap(i, :))
   figure(4)
   plot(T_truth_object.time, T_truth_object.range, 'sq-', 'color', cmap(i, :))
   
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

%% Create Table4ML3 with Track History/Future Scores

[Table4ML3, Table4ML4] = createTables4ML(scores, T, T_interp, T_truth, T_truth_interp);

%% Run phase 2 of ML

% Run Model
[phase2, scores2] = phase2_test.predictFcn(Table4ML3);

% Insert model results into T_interp
T_interp.phase2 = phase2;
T_interp = movevars(T_interp, 'phase2', 'After', 'object');

% Insert model results into Table4ML
Table4ML3.phase2 = phase2;
Table4ML3 = movevars(Table4ML3, 'phase2', 'After', 'object');

%% Plot to see difference in Phase 2

unique_objects = unique(T_interp.object);
cmap = prism(length(unique_objects));

% x vs y
figure(5)
set(gca,'Color','black')
hold on

% range vs time
figure(6)
set(gca,'Color','black')
hold on
for i = 1:length(unique_objects)
   
   % Plot Truth
   T_truth_object = T_truth(strcmp(T_truth.object, unique_objects(i)), :);
   figure(5)
   plot(T_truth_object.x, T_truth_object.y, 'sq-', 'color', cmap(i, :))
   figure(6)
   plot(T_truth_object.time, T_truth_object.range, 'sq-', 'color', cmap(i, :))
   
   % Plot Data
   T_object = T_interp(strcmp(T_interp.object, unique_objects(i)), :);
   unique_ctsl = unique(T_object.ctsl);
   for j = 1:length(unique_ctsl)
       T_ctsl = T_object(T_object.ctsl == unique_ctsl(j), :);
       figure(5)
       plot(T_ctsl.x, T_ctsl.y, '.-', 'color', cmap(i, :))
       figure(6)
       plot(T_ctsl.time, T_ctsl.range, '.-', 'color', cmap(i, :))
   end
end

% Find where ML does not match 
index_setDiff_ML_Data = find(strcmp(T_interp.object, T_interp.phase2) == 0);
figure(5)
plot(T_interp.x(index_setDiff_ML_Data), T_interp.y(index_setDiff_ML_Data), 'ro')
figure(6)
plot(T_interp.time(index_setDiff_ML_Data), T_interp.range(index_setDiff_ML_Data), 'ro')
