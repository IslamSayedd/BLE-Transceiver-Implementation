%% ================= User Parameters =================
AMP_BITS = 12;          % Amplitude bit width
LUT_SIZE = 4096;        % Number of samples
SAVE_DIR = 'C:\Users\ThinkPad\OneDrive - Faculty of Engineering Ain Shams University\Desktop\sem 9\Grad\LUT'; 
%% ===================================================

COS_FILE = fullfile(SAVE_DIR, 'cos_lut.txt');   % 🔹 cosine file
SIN_FILE = fullfile(SAVE_DIR, 'sin_lut.txt');   % 🔹 sine file

% Create directory if it doesn't exist
if ~exist(SAVE_DIR, 'dir')
    mkdir(SAVE_DIR);
end

% Maximum signed value
AMP_MAX = 2^(AMP_BITS-1) - 1;

% Angle vector
theta = linspace(0, 2*pi, LUT_SIZE + 1);
theta(end) = [];

% Generate cosine & sine LUTs  🔹
cos_lut = round(AMP_MAX * cos(theta));
sin_lut = round(AMP_MAX * sin(theta));

% Convert to hex (two's complement)
HEX_WIDTH = ceil(AMP_BITS / 4);
hex_cos = strings(LUT_SIZE,1);   % 🔹
hex_sin = strings(LUT_SIZE,1);   % 🔹

for i = 1:LUT_SIZE
    % ----- Cosine -----
    val = cos_lut(i);
    if val < 0
        val = val + 2^AMP_BITS;
    end
    hex_cos(i) = upper(dec2hex(val, HEX_WIDTH));

    % ----- Sine -----
    val = sin_lut(i);
    if val < 0
        val = val + 2^AMP_BITS;
    end
    hex_sin(i) = upper(dec2hex(val, HEX_WIDTH));
end

% Open files (WRITE MODE)
fid_cos = fopen(COS_FILE, 'w');
fid_sin = fopen(SIN_FILE, 'w');

% --- CRITICAL CHECK ---
if fid_cos == -1
    error('Cannot open file for writing: %s', COS_FILE);
end
if fid_sin == -1
    error('Cannot open file for writing: %s', SIN_FILE);
end

% Write to files
for i = 1:LUT_SIZE
    fprintf(fid_cos, '%s\n', hex_cos(i));
    fprintf(fid_sin, '%s\n', hex_sin(i));
end

fclose(fid_cos);
fclose(fid_sin);

disp(['Cosine LUT saved successfully to: ', COS_FILE]);
disp(['Sine LUT saved successfully to:   ', SIN_FILE]);
