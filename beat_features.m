function [ features ] = beat_features(beat, pre_R, post_R, local_R, global_R, statistical_intervals)
%beat_features  extracts features to represent the beat after normalization
% 1. Mean
% 2. Variance
% 3. Skewness
% 4. Kurtosis
% 5. Maximum
% 6. Minimum
% 7. Signal Energy
% 8. The previous RR Interval
% 9. The next RR Interval
% 10. The average of the previous 10 RR Intervals
% 11. The average of RR Intervals for the previous 5 minutes
    
%% Normalize the signal
% To prevent underflow/overflow in calculations
minAmp = -1024;
maxAmp = 1024;
beat_norm = (beat - minAmp) / (maxAmp - minAmp);

features = [];
window_length = round(length(beat) / statistical_intervals);
%% Statistical features
for i = 1:statistical_intervals
    window_end = window_length * i;
    window = beat_norm(window_end - window_length + 1: window_end);
    %% Mean
    features = [features; mean(window)];
    %% Variance
    features = [features; var(window)];
    if isnan(features(length(features)))
        features(length(features)) = 0.0;
    end
    %% Skewness
    features = [features; skewness(window)];
    if isnan(features(length(features)))
        features(length(features)) = 0.0;
    end
    %% Kurtosis
    features = [features; kurtosis(window)];
    if isnan(features(length(features)))
        features(length(features)) = 0.0;
    end
end
%% Maximum
features = [features; max(beat_norm)];
%% Minimum
features = [features; min(beat_norm)];
%% Signal Energy
features = [features; sum(beat_norm .* beat_norm)];
%% RR Features
RR_features = [pre_R; post_R; local_R; global_R];
features = [features; RR_features];
end