%% AWE NMPC SIMULATION

% Simulation Setup
clear functions  % Clears compiled functions like .mex
% important to not get stuck in NaN's for consequtive script runs
nmpc = nmpc_init();

N=nmpc.N;
Ts=nmpc.Ts;

T_Simulation  = 20;
stepwise_init = 1;

% OnlineData (Parameters)
vw                  = nmpc.p.vw;
r                   = nmpc.p.r;
r_dot               = nmpc.p.r_dot;
circle_azimut       = nmpc.p.circle_azimut;
circle_elevation    = nmpc.p.circle_elevation;
circle_angle        = nmpc.p.circle_angle;

if stepwise_init
    init = 0;
else
    init = 1;
end

% Initial Positon
% X0 = [psi theta gamma phi vt]
% X0 = [-pi/2+0.3 ,circle_angle+circle_elevation+0.1 ,pi/4 ,0.0, 20 ];
X0 = zeros(1,nmpc.x.n);
X0(nmpc.x.index.psi)    = circle_azimut;
X0(nmpc.x.index.theta)  = circle_angle+circle_elevation+0.01;
X0(nmpc.x.index.gamma)  = -pi/2;
X0(nmpc.x.index.phi)    = 0;
X0(nmpc.x.index.vt)     = 50;




%% Prepare Simulation
% Fill input vector
input.x0 = X0;
Xref = X0;
input.x = repmat(Xref,N+1,1);
%input.x(:,nmpc.x.index.phi) = repmat(-0.5,N+1,1)
%input.x(:,nmpc.x.index.phi_des) = repmat(-0.5,N+1,1)

% Initialize Parameters
input.od = zeros(N+1,nmpc.p.n)
input.od(:,nmpc.p.index.vw)                 = repmat(vw,N+1,1);
for i=1:N+1
    input.od(i,nmpc.p.index.r)              = r + (i-1)*Ts*r_dot;
end
input.od(:,nmpc.p.index.r_dot)              = repmat(r_dot,N+1,1);
input.od(:,nmpc.p.index.circle_azimut)      = repmat(circle_azimut,N+1,1);
input.od(:,nmpc.p.index.circle_elevation)   = repmat(circle_elevation,N+1,1);
input.od(:,nmpc.p.index.circle_angle)       = circle_angle*sqrt(nmpc.p.r./input.od(:,nmpc.p.index.r));  % repmat(circle_angle,N+1,1);
input.od(:,nmpc.p.index.m)                  = repmat(nmpc.p.m,N+1,1);
input.od(:,nmpc.p.index.clA)                = repmat(nmpc.p.clA,N+1,1);
input.od(:,nmpc.p.index.cdA)                = repmat(nmpc.p.cdA,N+1,1);
input.od(:,nmpc.p.index.weight_tracking)    = repmat(nmpc.p.weight_tracking,N+1,1);
input.od(end-4:end,nmpc.p.index.weight_tracking)    = input.od(end-4:end,nmpc.p.index.weight_tracking).*[2 4 6 8 10]';
input.od(:,nmpc.p.index.weight_power)       = repmat(nmpc.p.weight_power,N+1,1);


Uref = zeros(N,nmpc.u.n);
input.u = Uref; 

Yref = ones(N,1)*[0,0];

input.y = [Yref, Uref];
input.yN = [0,0];
input.yN = [0,0,0];

input.W = diag([100 0 1]);
input.WN = diag([100 0]);
input.WN = diag([100 0 0]);

% % Change last state costs to track trajectory well:
% input.od(end-6:end-1,5)=10;


% Constraints
% Control_ub=[max_roll_rate]';
% Control_lb=[-max_roll_rate]';
% 
% State_ub=[ 20  20  10  max_roll_angle*2]';
% State_lb=[-20 -20 -10 -max_roll_angle*2]';
% 
% input.ubValues = repmat(Control_ub,N,1);
% input.lbValues = repmat(Control_lb,N,1);
% 
% input.ubAValues = repmat(State_ub,N,1);
% input.lbAValues = repmat(State_lb,N,1);

[x_sphere,y_sphere,z_sphere] = sphere;
x_sphere = x_sphere(11:21,6:16);
y_sphere = y_sphere(11:21,6:16);
z_sphere = z_sphere(11:21,6:16);



kktValue = [];
objValue = [];

%% Initialization steps
for i=1:N+20
    
    init_step = 5;
    if stepwise_init
        if i==1
            input.od(:,nmpc.p.index.weight_tracking)    = repmat(0,N+1,1);
        end
        input.od(min(i*init_step+1,N+1):min((i+1)*init_step,N+1),nmpc.p.index.weight_tracking)    = repmat(nmpc.p.weight_tracking,min((i+1)*init_step,N+1)-min(i*init_step+1,N+1)+1,1);
    end

    tic
    output = awe_MPCstep(input); % Solve NMPC
    toc
    
    % Initialize with last output
    input.x = output.x;
    input.u = output.u;
    
    PlottingFun(output,x_sphere,y_sphere,z_sphere,circle_azimut,circle_elevation,circle_angle,r,r_dot,nmpc);  % plot current trajectory
    
    kktValue = [kktValue output.info.kktValue];
    objValue = [objValue output.info.objValue];
    
    if (i>10 && stepwise_init==0) || i>N/init_step || i>N+5
    if (abs(objValue(end)-objValue(end-1)) < 10e-2 && kktValue(end) < 10e-5)
        break
    end
    end
    
    pause(Ts-toc)
    
end

%% Run Simulation

% % Cost Weighting for Power optimization
input.W = diag([100 20 1]);
input.WN = diag([100 0 20]);
% input.od(end-4:end,nmpc.p.index.weight_tracking)    = repmat(nmpc.p.weight_tracking,5,1).*[2 4 6 8 10]';
% input.od(end-9:end,nmpc.p.index.weight_tracking)    = repmat(nmpc.p.weight_tracking,10,1).*[1 2 3 4 5 6 7 8 9 10]';
input.od(end-9:end,nmpc.p.index.weight_tracking)    = repmat(nmpc.p.weight_tracking,10,1)*5
% input.od(1:10,nmpc.p.index.weight_tracking)    = repmat(nmpc.p.weight_tracking,10,1)*0
% input.od(end-9:end,nmpc.p.index.weight_power)       = repmat(0,10,1);

% Declare Logging Variables
delta_opt = [];
cost = [];

cputime=[];
for t=0:Ts:T_Simulation  % Simulation
    
    % Set the power cost only for 1 full circle and not for more
    for i=nmpc.N+1:-1:1
        if input.x(i,nmpc.x.index.gamma) > input.x0(nmpc.x.index.gamma)+2*pi || ...
                input.x(i,nmpc.x.index.gamma) < input.x0(nmpc.x.index.gamma)-2*pi
            input.od(i,nmpc.p.index.weight_power)       = 0;
        elseif i = nmpc.N+1
            break
        else
            input.od(i,nmpc.p.index.weight_power)     = 0;%input.x(i,nmpc.x.index.gamma)
            input.od(1:i-1,nmpc.p.index.weight_power) = repmat(nmpc.p.weight_power,i-1,1);
            break
        end
    end
    
    
    tic
    output = awe_MPCstep(input); % Solve NMPC
    toc
    
    % Logging
    cputime = [cputime,output.info.cpuTime];
    delta_opt(end+1,:,:) = input.x-output.x;
    % cost(end+1,:) = [CalculateCost(output,input,nmpc), output.info.objValue];
    
    output.info
    
    
    % Propagate State
    input.x0 = output.x(2,:);%+[0,0,0,randn(1,1)*0.0, 0]+randn(1,5)*0.0;
    
    % Propagate Horizon
    input.x(1:end-1,:) = output.x(2:end,:);
    input.x(end,:) = output.x(end,:);
    input.u(1:end-1,:) = output.u(2:end,:);
    input.u(end,:) = output.u(end,:);
    
    % Wrap Heading Angle Horizon 
if input.x0(nmpc.x.index.gamma)-input.x(1,nmpc.x.index.gamma) < -pi
    input.x(:,nmpc.x.index.gamma) = input.x(:,nmpc.x.index.gamma) - 2*pi*ones(size(input.x(:,nmpc.x.index.gamma)))
end
if input.x0(nmpc.x.index.gamma)-input.x(1,nmpc.x.index.gamma) > pi
    input.x(:,nmpc.x.index.gamma) = input.x(:,nmpc.x.index.gamma) + 2*pi*ones(size(input.x(:,nmpc.x.index.gamma)))
end
    PlottingFun(output,x_sphere,y_sphere,z_sphere,circle_azimut,circle_elevation,circle_angle,r,r_dot,nmpc);  % plot current trajectory
    
    % Propagate Tether Length
    r = r + Ts * r_dot;
    for i=1:N+1
        input.od(i,nmpc.p.index.r)              = r + (i-1)*Ts*r_dot;
    end
    input.od(:,nmpc.p.index.circle_angle)       = circle_angle*sqrt(nmpc.p.r./input.od(:,nmpc.p.index.r));  % repmat(circle_angle,N+1,1);

    %pause(Ts-toc)
end

%% Plot Final Data

% figure(4)  % Plot Solver CPU Time
% histogram(cputime)
% 
% figure(5)  % Plot Solver Prediction error
% % boxplot(sqrt(delta_opt(10:end,:,1).^2+delta_opt(10:end,:,2).^2))
% boxplot(sqrt(delta_opt(10:end,1:end-1,1).^2+delta_opt(10:end,1:end-1,2).^2))
% grid on
% xlabel('Deviation from initial guess [rad]')
% ylabel('Horizon Points')

% figure(6)  % Plot Costs at each Timestep
% plot(repmat([0:nmpc.Ts:(size(cost,1)-1)*nmpc.Ts]',1,size(cost,2)),cost)
% legend('Tracking Cost','Power Cost','Control Cost','Total Cost')
% xlabel('time [s]')
% ylabel('Least Squares Objective Cost [-]')
% title('Objective Cost over Time')

disp('------------------------------------')
disp(['Mean Computation Time: ',num2str(mean(cputime))])
disp(['Max  Computation Time: ',num2str(max(cputime))])
disp(['Min  Computation Time: ',num2str(min(cputime))])
disp('------------------------------------')


function step_cost = CalculateCost(output,input,nmpc)
%     state_output = [...
%     (sqrt((psi-circle_azimut)*(psi-circle_azimut)+(theta-circle_elevation)*(theta-circle_elevation))-circle_angle) * weight_tracking...
%     (force_limit*2 - cos(phi)*cos(epsilon)*clA*v*v)/force_limit * weight_power...
%     ];
%     control_output = [dphi];

    stage_cost = zeros(nmpc.N+1,length(input.W));
    for i=1:nmpc.N+1
        % Intermediate States
        psi   = output.x(i,nmpc.x.index.psi);
        theta = output.x(i,nmpc.x.index.theta);
        phi   = output.x(i,nmpc.x.index.phi);
        
        circle_azimut    = input.od(i,nmpc.p.index.circle_azimut);
        circle_elevation = input.od(i,nmpc.p.index.circle_elevation);
        circle_angle     = input.od(i,nmpc.p.index.circle_angle);
        weight_tracking  = input.od(i,nmpc.p.index.weight_tracking);
        weight_power     = input.od(i,nmpc.p.index.weight_power);
        clA              = input.od(i,nmpc.p.index.clA);
        cdA              = input.od(i,nmpc.p.index.cdA);
        vw               = input.od(i,nmpc.p.index.vw);
        r_dot            = input.od(i,nmpc.p.index.r_dot);
        
        spsi   = sin(output.x(i,nmpc.x.index.psi));
        cpsi   = cos(output.x(i,nmpc.x.index.psi));
        stheta = sin(output.x(i,nmpc.x.index.theta));
        ctheta = cos(output.x(i,nmpc.x.index.theta));
        sgamma = sin(output.x(i,nmpc.x.index.gamma));
        cgamma = cos(output.x(i,nmpc.x.index.gamma));

        % Rotation Matrix from Sphere Local Plane body axis x',y',z' to x,y,z
        R_mat = [cpsi -spsi 0 ; spsi cpsi 0 ; 0 0 1]*[-stheta 0 -ctheta ; 0 1 0 ; ctheta 0 -stheta]*[cgamma -sgamma 0 ; sgamma cgamma 0 ; 0 0 1];

        vw_xyz = [vw;0;0];  % wind velocity in xyz coordinates

        vw_local = R_mat'*vw_xyz;
        v_local = [output.x(i,nmpc.x.index.vt) ; 0 ; -nmpc.p.r_dot] - vw_local;
        v = sqrt(v_local'*v_local);
        epsilon = asin(v_local(3)/v);
        % beta = atan(v_local(2)/vt);
        force_limit = clA*(clA/cdA*(vw-r_dot))^2;

        state_output = [...
        (sqrt((psi-circle_azimut)*(psi-circle_azimut)+(theta-circle_elevation)*(theta-circle_elevation))-circle_angle) * weight_tracking...
        (force_limit - cos(phi)*cos(epsilon)*clA*v*v)/force_limit * weight_power...
        ];
        % state_output
        if i<=nmpc.N
            control_output = [output.u(i)];
            stage_cost(i,:) = 0.5*[state_output, control_output]*input.W.*[state_output, control_output];
        else
            stage_cost(i,:) = [0.5 * state_output * input.WN .* state_output, 0];
        end
    end
    if 1  % Plotting Cost
        figure(3)
        % set(gcf, 'Position', [1 screensize(4)*0.3 screensize(3)*0.5 screensize(4)*0.7]);
        subplot(4,1,1); 
        stairs(stage_cost(:,1));
        grid on; 
        title('Tracking Cost');
        xlim([0,nmpc.N+1])
        subplot(4,1,2); 
        stairs(stage_cost(:,2));
        grid on; 
        title('Power Cost');
        xlim([0,nmpc.N+1])
        subplot(4,1,3); 
        stairs(stage_cost(:,3));
        grid on; 
        title('Control Cost');
        xlim([0,nmpc.N+1])
        subplot(4,1,4); 
        stairs(sum(stage_cost,2));
        grid on; 
        title('Total Cost');
        xlim([0,nmpc.N+1])
    end
    stage_cost
    step_cost = sum(stage_cost,1);
end

function PlottingFun(output,x_sphere,y_sphere,z_sphere,circle_azimut,circle_elevation,circle_angle,r,r_dot,nmpc)
    % plots current trajectory
    
    % Data to draw reference circle
    theta_ref = circle_elevation+circle_angle*sqrt(nmpc.p.r/r)*sin([0:0.01*pi:2*pi]);
    psi_ref = circle_azimut+circle_angle*sqrt(nmpc.p.r/r)*cos([0:0.01*pi:2*pi]);

    x_ref = r*cos(psi_ref).*cos(theta_ref);
    y_ref = r*sin(psi_ref).*cos(theta_ref);
    z_ref = r*sin(theta_ref);
    
    r_traj = zeros(nmpc.N+1,1);
    for i=1:nmpc.N+1  % Calculate the expanding trajectory r
        r_traj(i) = r + (i-1)*nmpc.Ts*r_dot;
    end

    x_pos = r_traj.*cos(output.x(:,nmpc.x.index.psi)).*cos(output.x(:,nmpc.x.index.theta));
    y_pos = r_traj.*sin(output.x(:,nmpc.x.index.psi)).*cos(output.x(:,nmpc.x.index.theta));
    z_pos = r_traj.*sin(output.x(:,nmpc.x.index.theta));
    
    screensize=get(0,'Screensize');
    
    figure(1)
    clf
    % set(gcf, 'Position', [screensize(3)*0.5 screensize(4)*0.3 screensize(3)*0.5 screensize(4)*0.7]);
    surf(r*x_sphere,r*y_sphere,r*z_sphere,'FaceAlpha',0.5,'FaceColor','interp')
    % plot(cos([0:0.01*pi:2*pi])*circle_angle,sin([0:0.01*pi:2*pi])*circle_angle,'r')
    hold on
    % plot(output.x(:,1),output.x(:,2),'b')
    % plot(output.x(1,1),output.x(1,2),'o')
    plot3(x_ref,y_ref,z_ref,'r');
    plot3(x_pos,y_pos,z_pos,'b');
    plot3(x_pos(1),y_pos(1),z_pos(1),'o');
    %trajectory_MFILE(x_pos,y_pos,z_pos,zeros(size(x_pos)),zeros(size(x_pos)),zeros(size(x_pos)),1,0)
    %trajectory_MFILE(x_pos(1),y_pos(1),z_pos(1),0,0,0,1,0)
    axis equal
    xlabel('x [m]')
    ylabel('y [m]')
    zlabel('z [m]')
    view(60,30)  % Azimut, Elevation of viewpoint
    
    figure(2)
    % set(gcf, 'Position', [1 screensize(4)*0.3 screensize(3)*0.5 screensize(4)*0.7]);
    subplot(3,1,1); 
    stairs(output.u(:,nmpc.u.index.dphi)*180/pi);
    grid on; 
    title('Roll Rate [�/s]');
    xlim([0,nmpc.N+1])
    subplot(3,1,2); 
    stairs(output.x(:,nmpc.x.index.phi)*180/pi);
    grid on; 
    title('Roll Angle [�]');
    xlim([0,nmpc.N+1])
    subplot(3,1,3); 
    stairs(output.x(:,nmpc.x.index.vt));
    grid on; 
    title('V tangetial [m/s]');
    xlim([0,nmpc.N+1])

end
