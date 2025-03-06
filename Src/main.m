    clear; clc; close all;

%% Paths (đường dẫn)
addpath('Vrep Connection');
addpath('Matlab Functions');
ReloadPy(); 
logFile = fopen('observation.txt', 'w');

%% API (kết nối môi trường vrep và matlab)
vrep = remApi('remoteApi'); % Using the prototype file (remoteApiProto.m)
vrep.simxFinish(-1); % Just in case, close all opened connections
id = vrep.simxStart('127.0.0.1', 19999, true, true, 5000, 5); % Connect to V-REP
if (id < 0)
    disp('Failed connecting to remote API server');
    vrep.delete();
    return;
end
fprintf('Connection %d to remote API server open.\n', id);

%% Objects Handle (Camera, Joints UR10, Gripper, Frame, Conveyor_sensor) -> để xử lý 
% Camera
[~, Camera] = vrep.simxGetObjectHandle(id, 'Vision_sensor', vrep.simx_opmode_blocking);

% UR10 joints
Joints = -ones(1, 6);
JointNames = {'UR10_joint1', 'UR10_joint2', 'UR10_joint3', 'UR10_joint4', 'UR10_joint5', 'UR10_joint6'};
for i = 1:6
    [~, Joints(i)] = vrep.simxGetObjectHandle(id, JointNames{i}, vrep.simx_opmode_oneshot_wait); 
end

%  Frame1
[~, Frame1] = vrep.simxGetObjectHandle(id, 'Frame1', vrep.simx_opmode_oneshot_wait);

% End Effector (EE) and Baxter sensor
[~, EE] = vrep.simxGetObjectHandle(id, 'EE', vrep.simx_opmode_oneshot_wait);
[~, BaxterSensor] = vrep.simxGetObjectHandle(id, 'BaxterVacuumCup_sensor', vrep.simx_opmode_oneshot_wait);

% conveyor sensor
[~, ConveyorSensor] = vrep.simxGetObjectHandle(id, 'conveyor__sensor', vrep.simx_opmode_oneshot_wait);

%% Start
% connect ID
vrep.simxGetPingTime(id);
% Start the simulation in V-REP
vrep.simxStartSimulation(id, vrep.simx_opmode_oneshot_wait);
% Table D-H
a = [0, -0.612, -0.5723, 0, 0, 0];
d = [0.1273, 0, 0, 0.163941, 0.1157, 0.0922];
alpha = [pi/2, 0, 0, pi/2, -pi/2, 0];
offset = [0, -pi/2, 0, -pi/2, 0, 0]; 
% Using Peter Corke robotics toolbox to define the robot
for i = 1:6
    L(i) = Link('d', d(i), 'a', a(i), 'alpha', alpha(i), 'offset', offset(i));
end
Robot = SerialLink(L);
Robot.name = 'UR10';
JointsStartingPos = [0, 0, 0, 0, 0, 0];

%% Simulation
% Khởi tạo sensors and variables
vrep.simxGetVisionSensorImage2(id, Camera, 0, vrep.simx_opmode_streaming);                      
vrep.simxReadProximitySensor(id, ConveyorSensor, vrep.simx_opmode_streaming);

%Mục đích để đánh giá hiệu suất và theo dõi tiến trình
count_red = 0;
count_blue = 0;
count_green = 0;
total_time_pickup = 0.0;
total_time_to_drop = 0.0;
total_cycle_time = 0.0;
total_cube = 0;

tic; % Start timing 
RotateJoints(id, vrep, Joints, JointsStartingPos); % Thực hiện hàm RotateJoints -> xoay góc đến vị trí khởi tạo
time_rotatejoints = toc; % End timing 
fprintf('Time to finish RotateJoints: %.2f seconds\n', time_rotatejoints);
fprintf(logFile, 'Time to finish RotateJoints: %.2f seconds\n', time_rotatejoints);
while (vrep.simxGetConnectionId(id) == 1)
    cycle_start_time = tic;  

    [~, state, ~, Cuboid, ~] = vrep.simxReadProximitySensor(id, ConveyorSensor, vrep.simx_opmode_streaming);
    if (state == 1) 
        tic;
       
        [~, ~, color] = GotoNearestCube(id, vrep, Robot, Joints, Camera, ConveyorSensor); % go to the cube
        CloseVaccum(id, vrep, Cuboid, EE); % CloseVaccum -> to pick

        time_pickup = toc;
        total_time_pickup = total_time_pickup + time_pickup;
        fprintf('Time to finish pickup: %.2f seconds\n', time_pickup);
     
        tic; 
        GotoBasket(id, vrep, Robot, Joints, color);  % go to the basket
        time_to_drop = toc; 
        total_time_to_drop = total_time_to_drop + time_to_drop;
        fprintf('Time to finish drop : %.2f seconds\n', time_to_drop);
        
        OpenVaccum(id, vrep, Cuboid); % Drop the cube
        RotateJoints(id, vrep, Joints, JointsStartingPos); % Quay lại vị trí khởi tạo
        
        cycle_end_time = toc(cycle_start_time); % End timing for the cycle
        total_cycle_time = total_cycle_time + cycle_end_time;
        fprintf('Cycle time: %.2f seconds\n', cycle_end_time);
        
        if (color =="r")
            count_red = count_red +1;
        elseif (color =="b")
            count_blue = count_blue+1;
        elseif (color == "g")
            count_green = count_green+1;
        end
        total_cube = count_red+count_blue+count_green;
        fprintf('red: %d\n',count_red);
        fprintf('blue: %d\n',count_blue);
        fprintf('green: %d\n',count_green);

        % print into file .txt
        fprintf(logFile, 'red cuboid: %d  , blue cuboid: %d  , green cuboid: %d  \n',count_red, count_blue, count_green);
        fprintf(logFile, 'total cuboid: %d\n',count_red + count_blue + count_green);
        fprintf(logFile, 'total_cycle_time: %.2f seconds\n', total_cycle_time);
        fprintf(logFile, 'average time to finish pickup: %.2f seconds\n', total_time_pickup/total_cube);
        fprintf(logFile, 'average time to finish drop: %.2f seconds\n', total_time_to_drop/total_cube);
        fprintf(logFile, 'average_cycle_time:  %.2f seconds\n\n', total_cycle_time/total_cube);
             
    end
end



%% End Simulation
% Ensure the last command sent out had time to arrive
vrep.simxGetPingTime(id);
vrep.simxFinish(id);

%% END
disp('Connection ended');
vrep.delete();
