
%% Import Data

T_truth = importfile_truth('Truth.csv');
T = importfile_data('UNITB_TrackMatched.csv');
load phase1_model
load phase1_model2

%% Sort rows by time
% *** Will have to account for 24 hours in the future ***

T_truth = sortrows(T_truth, "time");
T = sortrows(T, "time");

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

T_ML = table();
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
        
        object = T_interp.object(j);
        ctsl = T_interp.ctsl(j);
        time = T_interp.time(j);
        diff_x = abs(T_truth_temp.x(1) - T_interp.x(j));         
        diff_y = abs(T_truth_temp.y(1) - T_interp.y(j));
        diff_vx = abs(T_truth_temp.vx(1) - T_interp.vx(j));
        diff_vy = abs(T_truth_temp.vy(1) - T_interp.vy(j)); 
        diff_range = abs(T_truth_temp.range(1) - T_interp.range(j));
        match = strcmp(T_truth_temp.object(1), T_interp.object(j));

        T_ML_temp = table(object, ctsl, time, diff_x, diff_y, diff_vx, diff_vy, diff_range, match);
        T_ML = [T_ML; T_ML_temp];
    end
end

%% Normalize Data

T_ML.diff_x = T_ML.diff_x / max(T_ML.diff_x);
T_ML.diff_y = T_ML.diff_y / max(T_ML.diff_y);
T_ML.diff_vx = T_ML.diff_vx / max(T_ML.diff_vx);
T_ML.diff_vy = T_ML.diff_vy / max(T_ML.diff_vy);
T_ML.diff_range = T_ML.diff_range / max(T_ML.diff_range);

%% Add past and future values

% past1
T_ML.past1_diff_x = ones(height(T_ML), 1) * NaN;
T_ML.past1_diff_y = ones(height(T_ML), 1) * NaN;
T_ML.past1_diff_vx = ones(height(T_ML), 1) * NaN;
T_ML.past1_diff_vy = ones(height(T_ML), 1) * NaN;
T_ML.past1_diff_range = ones(height(T_ML), 1) * NaN;

% past2
T_ML.past2_diff_x = ones(height(T_ML), 1) * NaN;
T_ML.past2_diff_y = ones(height(T_ML), 1) * NaN;
T_ML.past2_diff_vx = ones(height(T_ML), 1) * NaN;
T_ML.past2_diff_vy = ones(height(T_ML), 1) * NaN;
T_ML.past2_diff_range = ones(height(T_ML), 1) * NaN;

% past3
T_ML.past3_diff_x = ones(height(T_ML), 1) * NaN;
T_ML.past3_diff_y = ones(height(T_ML), 1) * NaN;
T_ML.past3_diff_vx = ones(height(T_ML), 1) * NaN;
T_ML.past3_diff_vy = ones(height(T_ML), 1) * NaN;
T_ML.past3_diff_range = ones(height(T_ML), 1) * NaN;

% past4
T_ML.past4_diff_x = ones(height(T_ML), 1) * NaN;
T_ML.past4_diff_y = ones(height(T_ML), 1) * NaN;
T_ML.past4_diff_vx = ones(height(T_ML), 1) * NaN;
T_ML.past4_diff_vy = ones(height(T_ML), 1) * NaN;
T_ML.past4_diff_range = ones(height(T_ML), 1) * NaN;

% past5
T_ML.past5_diff_x = ones(height(T_ML), 1) * NaN;
T_ML.past5_diff_y = ones(height(T_ML), 1) * NaN;
T_ML.past5_diff_vx = ones(height(T_ML), 1) * NaN;
T_ML.past5_diff_vy = ones(height(T_ML), 1) * NaN;
T_ML.past5_diff_range = ones(height(T_ML), 1) * NaN;

% future1
T_ML.future1_diff_x = ones(height(T_ML), 1) * NaN;
T_ML.future1_diff_y = ones(height(T_ML), 1) * NaN;
T_ML.future1_diff_vx = ones(height(T_ML), 1) * NaN;
T_ML.future1_diff_vy = ones(height(T_ML), 1) * NaN;
T_ML.future1_diff_range = ones(height(T_ML), 1) * NaN;

% future2
T_ML.future2_diff_x = ones(height(T_ML), 1) * NaN;
T_ML.future2_diff_y = ones(height(T_ML), 1) * NaN;
T_ML.future2_diff_vx = ones(height(T_ML), 1) * NaN;
T_ML.future2_diff_vy = ones(height(T_ML), 1) * NaN;
T_ML.future2_diff_range = ones(height(T_ML), 1) * NaN;

% future3
T_ML.future3_diff_x = ones(height(T_ML), 1) * NaN;
T_ML.future3_diff_y = ones(height(T_ML), 1) * NaN;
T_ML.future3_diff_vx = ones(height(T_ML), 1) * NaN;
T_ML.future3_diff_vy = ones(height(T_ML), 1) * NaN;
T_ML.future3_diff_range = ones(height(T_ML), 1) * NaN;

% future4
T_ML.future4_diff_x = ones(height(T_ML), 1) * NaN;
T_ML.future4_diff_y = ones(height(T_ML), 1) * NaN;
T_ML.future4_diff_vx = ones(height(T_ML), 1) * NaN;
T_ML.future4_diff_vy = ones(height(T_ML), 1) * NaN;
T_ML.future4_diff_range = ones(height(T_ML), 1) * NaN;

% future5
T_ML.future5_diff_x = ones(height(T_ML), 1) * NaN;
T_ML.future5_diff_y = ones(height(T_ML), 1) * NaN;
T_ML.future5_diff_vx = ones(height(T_ML), 1) * NaN;
T_ML.future5_diff_vy = ones(height(T_ML), 1) * NaN;
T_ML.future5_diff_range = ones(height(T_ML), 1) * NaN;

% Insert past and future values
unique_object = unique(T_ML.object);
for i = 1:length(unique_object)
   fprintf("object %d out of %d\n", i, length(unique_object))
   T_object = T_ML(strcmp(T_ML.object, unique_object(i)), :); 
   unique_ctsl = unique(T_object.ctsl);
   
   for j = 1:length(unique_ctsl)
      fprintf("\tctsl %d out of %d\n", j, length(unique_ctsl))
      T_ctsl = T_object(T_object.ctsl == unique_ctsl(j), :); 
      
      for k = 1:height(T_ctsl)
          
          % past1
          if k - 1 >= 1
              % diff_x
              T_ML.past1_diff_x(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_x(k - 1);
              % diff_y            
              T_ML.past1_diff_y(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_y(k - 1);
                            
              % diff_y            
              T_ML.past1_diff_vx(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vx(k - 1);
                            
              % diff_y            
              T_ML.past1_diff_vy(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vy(k - 1);
                            
              % diff_y            
              T_ML.past1_diff_range(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_range(k - 1);           
          end
          
          % past2
          if k - 2 >= 1
              % diff_x
              T_ML.past2_diff_x(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_x(k - 2);
              % diff_y            
              T_ML.past2_diff_y(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_y(k - 2);
                            
              % diff_y            
              T_ML.past2_diff_vx(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vx(k - 2);
                            
              % diff_y            
              T_ML.past2_diff_vy(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vy(k - 2);
                            
              % diff_y            
              T_ML.past2_diff_range(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_range(k - 2);           
          end
          
          % past3
          if k - 3 >= 1
              % diff_x
              T_ML.past3_diff_x(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_x(k - 3);
              % diff_y            
              T_ML.past3_diff_y(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_y(k - 3);
                            
              % diff_y            
              T_ML.past3_diff_vx(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vx(k - 3);
                            
              % diff_y            
              T_ML.past3_diff_vy(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vy(k - 3);
                            
              % diff_y            
              T_ML.past3_diff_range(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_range(k - 3);           
          end
          
          % past4
          if k - 4 >= 1
              % diff_x
              T_ML.past4_diff_x(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_x(k - 4);
              % diff_y            
              T_ML.past4_diff_y(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_y(k - 4);
                            
              % diff_y            
              T_ML.past4_diff_vx(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vx(k - 4);
                            
              % diff_y            
              T_ML.past4_diff_vy(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vy(k - 4);
                            
              % diff_y            
              T_ML.past4_diff_range(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_range(k - 4);           
          end
          
          % past5
          if k - 5 >= 1
              % diff_x
              T_ML.past5_diff_x(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_x(k - 5);
              % diff_y            
              T_ML.past5_diff_y(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_y(k - 5);
                            
              % diff_y            
              T_ML.past5_diff_vx(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vx(k - 5);
                            
              % diff_y            
              T_ML.past5_diff_vy(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vy(k - 5);
                            
              % diff_y            
              T_ML.past5_diff_range(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_range(k - 5);           
          end
          
          % future1
          if k + 1 <= height(T_ML)
              % diff_x
              T_ML.future1_diff_x(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_x(k + 1);
              % diff_y            
              T_ML.future1_diff_y(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_y(k + 1);
                            
              % diff_y            
              T_ML.future1_diff_vx(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vx(k + 1);
                            
              % diff_y            
              T_ML.future1_diff_vy(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vy(k + 1);
                            
              % diff_y            
              T_ML.future1_diff_range(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_range(k + 1);           
          end
          
          % future2
          if k + 2 <= height(T_ML)
              % diff_x
              T_ML.future2_diff_x(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_x(k + 2);
              % diff_y            
              T_ML.future2_diff_y(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_y(k + 2);
                            
              % diff_y            
              T_ML.future2_diff_vx(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vx(k + 2);
                            
              % diff_y            
              T_ML.future2_diff_vy(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vy(k + 2);
                            
              % diff_y            
              T_ML.future2_diff_range(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_range(k + 2);           
          end
          
          % future3
          if k + 3 <= height(T_ML)
              % diff_x
              T_ML.future3_diff_x(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_x(k + 3);
              % diff_y            
              T_ML.future3_diff_y(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_y(k + 3);
                            
              % diff_y            
              T_ML.future3_diff_vx(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vx(k + 3);
                            
              % diff_y            
              T_ML.future3_diff_vy(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vy(k + 3);
                            
              % diff_y            
              T_ML.future3_diff_range(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_range(k + 3);           
          end
          
          % future4
          if k + 4 <= height(T_ML)
              % diff_x
              T_ML.future4_diff_x(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_x(k + 4);
              % diff_y            
              T_ML.future4_diff_y(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_y(k + 4);
                            
              % diff_y            
              T_ML.future4_diff_vx(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vx(k + 4);
                            
              % diff_y            
              T_ML.future4_diff_vy(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vy(k + 4);
                            
              % diff_y            
              T_ML.future4_diff_range(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_range(k + 4);           
          end
          
          % future5
          if k + 5 <= height(T_ML)
              % diff_x
              T_ML.future5_diff_x(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_x(k + 5);
              % diff_y            
              T_ML.future5_diff_y(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_y(k + 5);
                            
              % diff_y            
              T_ML.future5_diff_vx(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vx(k + 5);
                            
              % diff_y            
              T_ML.future5_diff_vy(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_vy(k + 5);
                            
              % diff_y            
              T_ML.future5_diff_range(strcmp(T_ML.object, unique_object(i)) & ...
                                T_ML.ctsl == unique_ctsl(j) & ...
                                T_ML.time == T_ctsl.time(k)) = T_ctsl.diff_range(k + 5);           
          end
      end
   end
end

%% Run phase 1 of ML

% Run Model
[phase1, score] = phase1_boolean.predictFcn(T_ML);

% Insert model results into T_ML
T_ML.phase1 = phase1;
T_ML.score = score;

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


















