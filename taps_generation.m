clc;            % Clean the command window
clear;          % Remove all variables from the workspace
close all;      % Close any open figures

% ---------------- BLE Parameters ----------------
% Define the tap indices of the Gaussian filter
k = -16:1:0;

% Oversampling ratio used in the system
OSR = 8;

% Sampling time (1 microsecond)
Ts = 1e-6;

% Bandwidth–time product for BLE Gaussian filtering
BTs = 0.5;

% ---------------- Generate Gaussian Filter Taps ----------------
% Constant term used to normalize the Gaussian pulse
m = sqrt(2*pi / log(2)) * (BTs / Ts);

% Exponent part of the Gaussian equation
x = ( sqrt( 2 / log(2) ) * pi * BTs * k / OSR ) .^ 2;

% Actual Gaussian filter taps (floating-point)
h_k = m * exp(-x);

% ---------------- Convert Taps to Integer Values ----------------
% Scale the taps so they can be used later in RTL / simulation
scale = 1e6;

% Quantize the taps to integer values
h_k_int = round(h_k * scale);

% ---------------- Smooth Plot (Visualization Only) ----------------
% Create a finer index just to make the curve look smooth
k_fine = linspace(min(k), max(k), 1000);

% Interpolate between taps to get a smooth-looking curve
% (This does NOT change the actual tap values)
h_k_int_smooth = interp1(k, h_k_int, k_fine, 'spline');

% Plot the smoothed Gaussian response
plot(k_fine, h_k_int_smooth)
grid on
xlabel('Tap Index')
ylabel('Tap Value')
title('Gaussian Filter Taps (Smoothed for Visualization)')

% ---------------- Save Taps to File ----------------
% Open a text file to store the tap values
fid = fopen('C:\Users\Lenovo\Downloads\University\Semester_9\Graduation_Project\Codes\taps.txt','w');

% Write the integer taps in hexadecimal format (hardware-friendly)
fprintf(fid, '%X\n', h_k_int);

% Close the file after writing
fclose(fid);
