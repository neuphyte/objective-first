% DEMO_GOODFIELD
% 
% The objective of this demo is to determine a good objective to optimize on.
help demo_goodfield


    %
    % Some optimization parameters.
    %

dims = [80 80]; % Size of the grid.
N = prod(dims);

eps_lo = 1.0; % Relative permittivity of air.
eps_hi = 12.25; % Relative permittivity of silicon.

omega = 0.2; % Angular frequency of desired mode.

pml_thick = 10; % Thickness of pml.

% Set the device boundary.
dev.dims = [40 40];
dev.offset = round((dims - dev.dims)/2);


    %
    % Helper function for determining derivative matrices.
    % Also, helper global variables for prettier argument passing.
    %

global S D MY_DIMS MY_DEVICE

% Shortcut to form a derivative matrix.
S = @(sx, sy) shift_mirror(dims, -[sx sy]); % Mirror boundary conditions.

% Shortcut to make a sparse diagonal matrix.
D = @(x) spdiags(x(:), 0, numel(x), numel(x));

MY_DIMS = dims;
MY_DEVICE = dev;


    %
    % Form the initial structure.
    %

lset_grid(dims);
phi = lset_box([0 0], [10 1000]);
phi = lset_complement(phi);

% Initialize phi, and create conversion functions.
[phi, phi2p, phi2e, p2e, e2p, phi_smooth] = ...
    setup_levelset(phi, eps_lo, eps_hi, 1e-3);

% lset_plot(phi); pause % Use to visualize the initial structure.


    %
    % Find the input and output modes.
    %

dir = '-y';
input = mode_solve(mode_cutout(phi2e(phi), dir), omega, dir);
[Jx, Jy, M] = mode_insert(input, dir);
J = [Jx, Jy];


    %
    % Get the physics matrices and solve.
    %

% Obtain physics matrix.
[A, b, E2H] = setup_physics(dims, omega, pml_thick, p2e, e2p);

% Solve.
x = A(phi2e(phi)) \ b(J,M);

% Back-out field components.
Ex = reshape(x(1:N), dims);
Ey = reshape(x(N+1:end), dims);
Hz = reshape(E2H(x), dims);


    %
    % Plot results.
    %

% Plot the structure.
eps = phi2e(phi);
figure(1); plot_fields(dims, {'\epsilon_x', eps.x}, {'\epsilon_y', eps.y});

% Plot the fields.
figure(2); plot_fields(dims, ...
    {'Re(Ex)', real(Ex)}, {'Re(Ey)', real(Ey)}, {'Re(Hz)', real(Hz)}, ...
    {'Im(Ex)', imag(Ex)}, {'Im(Ey)', imag(Ey)}, {'Im(Hz)', imag(Hz)}, ...
    {'|Ex|', abs(Ex)}, {'|Ey|', abs(Ey)}, {'|Hz|', abs(Hz)});
