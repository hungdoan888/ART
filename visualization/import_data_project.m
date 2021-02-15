function [T, T_truth, T_combined] = import_data_project ()
%% Import Data

%truth
T_truth = importfile_truth('Truth.csv');
[T_truth.x, T_truth.y, T_truth.z] = lla2ecef(T_truth.lat, T_truth.long, T_truth.alt);
T_truth.range = sqrt(T_truth.x.^2 + T_truth.y.^2 + T_truth.z.^2);
T_truth.data_type = cellstr(repmat('gps', height(T_truth), 1));

%data
T = importfile_data('UNITA_TrackMatched.csv');
[T.x, T.y, T.z] = lla2ecef(T.lat, T.long, T.alt);
T.range = sqrt(T.x.^2 + T.y.^2 + T.z.^2);
T.data_type = cellstr(repmat('radar', height(T), 1));

%combined
T_combined = [T_truth; T];
T_combined = sortrows(T_combined, 'time');

end
