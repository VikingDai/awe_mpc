function nmpc = nmpc_init()
% nmpc_init: This function sets some nmpc parameters
%
% Parameter setup of NMPC for Fixed-Wing Airborne Wind Energy
% It returns a struct "nmpc" which features information about the states,
% inputs and parameters. This includes the indeces of the order those are
% stored in Acado.
%
% Manuel Dangel, ETH Zurich, 2018
%
% Copyright: This is published under BSD licence

nmpc.N  = 80;        % Horizon Length
nmpc.Ts = 0.1;       % Sample Time
nmpc.flip = false    % Flip coordinate System

nmpc.x.n = 6;        % State size
nmpc.u.n = 3;        % Input size
nmpc.p.n = 14;       % Parameter size


% Index of states
nmpc.x.index.psi    = 1;  % Azimut Angle
nmpc.x.index.theta  = 2;  % Elevation Angle
nmpc.x.index.gamma  = 3;  % Heading Angle
nmpc.x.index.phi    = 4;  % Roll Angle
nmpc.x.index.vt     = 5;  % Tangential Path Velocity
nmpc.x.index.phi_des= 6;  % Desired (commanded) Roll Angle

% Index of control inputs
nmpc.u.index.dphi        = 1;  % Roll Rate
nmpc.u.index.phi_slack   = 2;  % Slack on Roll Constraint
nmpc.u.index.theta_slack = 3;  % Slack on Theta Constraint

% Index of parameters
nmpc.p.index.vw                 = 1;  % Wind Velocity
nmpc.p.index.r                  = 2;  % Radius / Tether Length
nmpc.p.index.r_dot              = 3;  % Tether Reel out Speed
nmpc.p.index.circle_azimut      = 4;  % Azimut of Circle Center
nmpc.p.index.circle_elevation   = 5;  % Elevation of Circle Center
nmpc.p.index.circle_angle       = 6;  % Opening Angle of Circle
nmpc.p.index.m                  = 7;  % Mass of the aircraft
nmpc.p.index.clA                = 8;  % Lift coefficient (0.5*rho*A*cl)
nmpc.p.index.cdA                = 9;  % Drag coefficient (0.5*rho*A*cd)
nmpc.p.index.phi_freq           =10;  % Roll Frequency (1st order low pass)
nmpc.p.index.wind_azimut        =11;  % Azimut the wind is blowing towards
nmpc.p.index.thrust_power       =12;  % Power of the thrust produced by a motor on the aircraft
nmpc.p.index.weight_tracking    =13;  % Weight on the tracking cost (changes along Horizon)
nmpc.p.index.weight_power       =14;  % Weight on the power cost (changes along Horizon)

% Values of parameters
nmpc.p.vw                       = 10;  % zero wind not supported in power objective
nmpc.p.r                        = 220;
nmpc.p.r_dot                    = 10*cos(30/180*pi)*1/3;
nmpc.p.circle_azimut            = 0;
nmpc.p.circle_elevation         = 30/180*pi;
nmpc.p.circle_angle             = sqrt(27.53/0.9)*sqrt(1/220); % use sqrt(m/cla)*sqrt(1/r) as best guess %atan(75/220);%atan(85/220);
nmpc.p.m                        = 27.53;
nmpc.p.clA                      = 0.9;
nmpc.p.cdA                      = 0.07;
nmpc.p.phi_freq                 = 2.7;
nmpc.p.wind_azimut              = 0;
nmpc.p.thrust_power             = 0;
nmpc.p.weight_tracking          = 1;
nmpc.p.weight_power             = 1;

if false  % set this if nmpc.flip
    nmpc.p.vw                       = 0;
    nmpc.p.r_dot                    = 0;
    nmpc.p.circle_azimut            = 90/180*pi;
    nmpc.p.circle_elevation         = 0/180*pi;
    nmpc.p.thrust_power             = 5*680*0.7*0.8;
    nmpc.p.weight_power             = 0;
end

end
