
%% Import Data

% truth
T_truth = importfile_truth('Truth.csv');
T_truth.range = sqrt(T_truth.x.^2 + T_truth.y.^2 + T_truth.z.^2);
T_truth.data_type = cellstr(repmat('gps', height(T_truth), 1));

% data
T = importfile_data('UNITA_TrackMatched.csv');

% combined
T_combined = [T_truth; T];
T_combined = sortrows(T_combined, 'time');

%% Create a color map
unique_object = unique(T_combined.object);
cmap = colorcube(length(unique_object));
t_color = table();
t_color.object = unique_object;
t_color.cmap = cmap;

%% Plot Truth

unique_object = unique(T_truth.object);
for i = 1:1:length(unique_object)
    
    T_object = T_truth(strcmp(T_truth.object, unique_object(i)),:);
    
    %Lat-Long
    figure(1)
    plot(T_object.long, T_object.lat, '-', 'color', ...
         t_color.cmap(strcmp(t_color.object, unique_object(i)), :));
    set(gca,'Color','black')
    hold on;
    text(T_object.long(1), T_object.lat(1), T_object.object(i), 'color', 'white')
    
    %Range-time
    figure(2)
    plot(T_object.time, T_object.range, '-', 'color', ...
         t_color.cmap(strcmp(t_color.object, unique_object(i)), :));
    set(gca,'Color','black')
    hold on; 
end

%% Plot data

unique_object = unique(T.object);
for i = 1:length(unique_object)
    
    T_object = T(strcmp(T.object, unique_object(i)),:);
    
    %Lat-Long
    figure(1)
    p1 = plot(T_object.long, T_object.lat, '.', 'color', ...
              t_color.cmap(strcmp(t_color.object, unique_object(i)), :));
    hold on;
    text(T_object.long(1), T_object.lat(1), T_object.object(i), 'color', 'white')
    
    %Range-time
    figure(2)
    plot(T_object.time, T_object.range, '.', 'color',  ...
         t_color.cmap(strcmp(t_color.object, unique_object(i)), :));
    hold on; 
end







