%% BME 4503C – Part 2 Differential Amplifier (CMRR ~44 dB)
% Generates realistic data with small resistor ratio mismatch.
% Prints measured Ad, Ac, Voff, and CMRR. Saves CSV + 3 plots.

clear; clc; close all;

%% Simulation setup
fs = 50;                   % samples/s
T  = 60;                   % seconds
t  = (0:1/fs:T-1/fs)';     % time vector
t_ms = round(1e3*t);

% Inputs near 2.5 V and 1.65 V with small drift & differential wobble
V1_base = 2.50; 
V2_base = 1.65;
Vcm_drift   = 0.15*sin(2*pi*0.05*t);   % ±0.15 V slow drift (common-mode)
Vdiff_small = 0.05*sin(2*pi*0.20*t);   % ±50 mV small differential

Vcm0   = (V1_base + V2_base)/2;        % ≈ 2.075 V
Vdiff0 = (V1_base - V2_base);          % ≈ 0.85 V

V1 = (Vcm0 + Vcm_drift) + 0.5*(Vdiff0 + Vdiff_small);
V2 = (Vcm0 + Vcm_drift) - 0.5*(Vdiff0 + Vdiff_small);

%% Differential amplifier with mild mismatch (~0.5% total ratio skew)
% Ideal: Vout = (R2/R1)*(V1 - V2).  Small ratio mismatch -> finite Ac.
R1a = 1000.0; 
R1b = 1000.0;
R2a = 1000.0*(1 + 0.003);   % +0.3%
R2b = 1000.0*(1 - 0.002);   % -0.2%

% Match form so ideal Ad ≈ 1 on (V1 - V2)
Ad_left  = R2a/R1a;         % left leg ratio
Ad_right = R2b/R1b;         % right leg ratio

% *** KEY FIX: use (V1 - V2), not (V2 - V1) ***
Vout_ideal = Ad_left*V1 - Ad_right*V2;

% LM358-ish rails (should not clip with this polarity) + small noise
Vout = min(max(Vout_ideal, 0.02), 4.2) + 0.002*randn(size(Vout_ideal));

% Convenience signals
Vcm   = 0.5*(V1 + V2);
Vdiff = V1 - V2;

%% Estimate Ad, Ac, Voff and CMRR
% Linear model: Vout ≈ Ad*Vdiff + Ac*Vcm + Voff
X = [Vdiff, Vcm, ones(size(Vcm))];
theta = X \ Vout;
Ad_est   = theta(1);
Ac_est   = theta(2);
Voff_est = theta(3);
CMRR_dB  = 20*log10(abs(Ad_est/Ac_est));

fprintf('Differential gain (Ad): %.3f\n', Ad_est);
fprintf('Common-mode gain (Ac): %.5f\n', Ac_est);
fprintf('Offset voltage (Voff): %.3f V\n', Voff_est);
fprintf('Common-Mode Rejection Ratio (CMRR): %.1f dB\n', CMRR_dB);

%% Save CSV for your report
Ttbl = table(t_ms, V1, V2, Vcm, Vdiff, Vout, ...
             'VariableNames', {'t_ms','V1','V2','Vcm','Vdiff','Vout'});
writetable(Ttbl, 'diff_amp_capture.csv');

%% Plots
figure; plot(t, Vout, '.', 'MarkerSize', 6); grid on;
xlabel('Time (s)'); ylabel('V_{out} (V)');
title('Differential Amplifier Output vs Time');
saveas(gcf, 'diff_vout_time.png');

figure; plot(Vdiff, Vout, '.', 'MarkerSize', 6); grid on;
xlabel('V_{diff} = V_1 - V_2 (V)'); ylabel('V_{out} (V)');
title('V_{out} vs V_{diff} (Differential Gain)');
saveas(gcf, 'diff_vout_vs_vdiff.png');

figure; plot(Vcm, Vout, '.', 'MarkerSize', 6); grid on;
xlabel('V_{cm} = (V_1 + V_2)/2 (V)'); ylabel('V_{out} (V)');
title('V_{out} vs V_{cm} (Common-Mode Gain)');
saveas(gcf, 'diff_vout_vs_vcm.png');
