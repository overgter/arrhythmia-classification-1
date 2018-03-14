function [ out_signal ] = denoise_ecg( signal, fs )
%denoise_ecg Denoises an ECG signal by removing powerline noise and baseline drift

%% Remove Baseline Drift
% Apply a 200ms median filter to remove QRS complexes and P-waves
% and then a 600ms one to remove T-waves
% The resulting signal is the baseline, subtracting it from the origianl
% signal should remove the drift

% 200ms with 360Hz sampling is 72 samples
baseline = medfilt1(signal, 72);
% 600ms with 360Hz sampling is 216 samples
baseline = medfilt1(baseline, 216);
out_signal = signal - baseline; 

%% Remove powerline and high frequency
% Using a Butterworth lowpass filter
% 12th Order
n = 12;
% Cutoff at 35Hz
w = 35 * 2 / fs;
[b, a] = butter(n, w);
out_signal = filter(b, a, out_signal);
end

