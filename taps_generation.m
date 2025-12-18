clc;
clear;
close all;

% Defining BLE Parameters
k = -16:1:0; % Number of Taps
OSR = 8; 
Ts = 1e-6; % 1us
BTs = 0.5;

% Generating Taps
m = sqrt(2*pi / log(2)) * (BTs / Ts);
x = ( sqrt( 2 / log(2) ) * pi * BTs * k / OSR ) .^ 2;  
h_k = m * exp(-x);

% Converting to integer Values to use it in Simulation
scale = 1e6; 
h_k_int = round(h_k * scale);


% Write to text file
fid = fopen('C:\Users\Lenovo\Downloads\University\Semester_9\Graduation_Project\Codes\taps.txt','w');
fprintf(fid, '%X\n', h_k_int);
fclose(fid);
