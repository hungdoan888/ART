function T_interp = interp_T_ctsl_2(T_ctsl, T)

T_ctsl_data = T(strcmp(T.object, T_ctsl.object(1)) & T.ctsl == T_ctsl.ctsl(1), :);
T_ctsl_data = sortrows(T_ctsl_data, "time");

%% Remove points with duplicate times

dupValue = [];
for i = 2:height(T_ctsl_data)
   if T_ctsl_data.time(i) == T_ctsl_data.time(i - 1)
       dupValue = [dupValue; i];
   end
end
T_ctsl_data(dupValue, :) = [];

%% Remove points with duplicate times

T_ctsl = sortrows(T_ctsl, 'time');

dupValue = [];
for i = 2:height(T_ctsl)
   if T_ctsl.time(i) == T_ctsl.time(i - 1)
       dupValue = [dupValue; i];
   end
end
T_ctsl(dupValue, :) = [];

%% Interpolate

time = T_ctsl_data.time;
x = interp1(T_ctsl.time, T_ctsl.x, time);
y = interp1(T_ctsl.time, T_ctsl.y, time);
vx = interp1(T_ctsl.time, T_ctsl.vx, time);
vy = interp1(T_ctsl.time, T_ctsl.vy, time);
range = interp1(T_ctsl.time, T_ctsl.range, time);

%% Add ctsl and object

object = cellstr(repmat(T_ctsl.object(1), length(time), 1));
ctsl = ones(length(time), 1) * T_ctsl.ctsl(1);

%% Create new interpolated table

T_interp = table(object, ctsl, time, x, y, vx, vy, range);

end

