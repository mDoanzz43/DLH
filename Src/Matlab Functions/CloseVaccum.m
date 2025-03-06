function CloseVaccum(id,vrep,Cuboid,EE)
    vrep.simxSetObjectIntParameter(id,Cuboid,3004,0,vrep.simx_opmode_oneshot); %0:đối tượng static (tĩnh), không thể di chuyển
    vrep.simxSetObjectIntParameter(id,Cuboid,3003,1,vrep.simx_opmode_oneshot); %1: đối tượng dynamic : động , có thể di chuyển
    vrep.simxSetObjectParent(id,Cuboid,EE,true,vrep.simx_opmode_oneshot);
end
% to gripper 