function [ dataset ] = prep_dataset(window_l, window_t)
%prep_dataset     prepare the MIT-BIH arrythmia database and save it
%
%Samples of length (window_l - window_t) are taken of important wave-forms

%% Variables
% Dataset: MIT-BIH Arrythmia
db_path = 'mitdb/';
% Sampling rate: 360 Hz
fs = 360;
% This database contains 48 records each containing two signals
% 100 series: 100-109, 111-119, 121-124
% 200 series: 200-203, 205, 207-210, 212-215, 217, 219-223, 228, 230-234
records = [100+(0:9), 100+(11:19), 100+(21:24), ...
           200+(0:3), 205, 200+(7:10), 200+(12:15), 217, 200+(19:23), ...
           228, 200+(30:34)];
% The classes used for beats
% For a complete list of annotation types and their meanings see:
% https://physionet.org/phsyiobank/database/html/mitdbdir/intro.html#annotations
beat_classes = ['N', 'L', 'R', 'A', 'a', 'J', 'S', 'V', 'F', 'e', 'j', ...
                'E', '/', 'f', 'P', 'u', '+'];

%% Load dataset from disk
signals{2, length(records)} = [];
selected_beats{length(records)} = [];
positions{length(records)} = [];
classes{length(records)} = [];
% Features in the time domain (RR interval averages)
temporal_features{length(records)} = [];

for r = 1:length(records)
    record_path = [db_path, num2str(records(r))];
    record{2} = [];

    %% Read samples
    % each record contains two signals
    signal = rdsamp(record_path);
    for s = 1:2
        record{s} = denoise_ecg(signal(:, s), fs);
        record{s} = denoise_ecg(signal(:, s), fs);
    end
    
    %% Read annotation
    [ann, types] = rdann(record_path, 'atr');

    %% Extract waves using annotations
    global_window = 20;
    for a = 1:length(ann)
        % Originally anotiations are plased at the instant of the
        % local extremum of a QRS-complex.
        % This sets the postition to the local maximum in a [-20, 20] window
        pos = ann(a);
        if pos > global_window && pos < length(record{1})-global_window
            [~, offset] = max(record{1}(pos-global_window : pos+global_window));
            pos = (pos - global_window) + offset;
        end
        
        % Add waves with the known classes to the record signal
        if any(types(a) == beat_classes)
            if pos > window_l && pos < length(record{1}) - window_t
                for s = 1:2
                    beat = reshape(record{s}(pos-window_l : pos+window_t), 1, []);
                    signals{s, r} = [signals{s, r}; beat];
                end
                classes{r} = [classes{r}; types(a)];
                selected_beats{r} = [selected_beats{r}; 1];
            else
                selected_beats{r} = [selected_beats{r}; 0];
            end
        else
            selected_beats{r} = [selected_beats{r}; 0];
        end
        positions{r} = [positions{r}; pos];
    end
    %% Compute RR Intervals
    pre_R = 0;
    post_R = positions{r}(2) - positions{r}(1);
    local_R = []; % Average of the ten past RR intervals
    global_R = []; % Average RR interval of the last 5 minutes

    for i=2:length(positions{r})-1
        pre_R = [pre_R; positions{r}(i) - positions{r}(i-1)];
        post_R = [post_R; positions{r}(i+1) - positions{r}(i)];
    end
    
    pre_R(1) = pre_R(2);
    pre_R = [pre_R; positions{r}(length(positions{r})) - positions{r}(length(positions{r})-1)];

    post_R = [post_R; post_R(length(positions{r})-1)];

    % Local R: average RR interval length from the past 10 RR intervals
    for i=1:length(positions{r})
        local_window = i-10:i;
        local_window(local_window <= 0) = [];
        avg_val = sum(pre_R(local_window)) / length(local_window);

        local_R = [local_R; avg_val];
    end

    % Global R: average from the past 5 minutes
    %  5 minutes  with 360 Hz sampling is 108000 samples
    for i=1:length(positions{r})
        back = -1;
        back_length = 0;
        if(positions{r}(i) < 108000)
            global_window = 1:i;
        else
            while(i+back > 0 && back_length < 108000)
                back_length = positions{r}(i) - positions{r}(i+back);
                back = back - 1;
            end
            global_window = max(1,(back+i)):i;
        end
        
        avg_val = sum(pre_R(global_window)) / length(global_window);
        global_R = [global_R; avg_val];
    end

    %% Only beats of the classes in `beat_classes` (selected beats) are needed
    temporal_features{r}.pre_R = pre_R(selected_beats{r} == 1);
    temporal_features{r}.post_R = post_R(selected_beats{r} == 1);
    temporal_features{r}.local_R = local_R(selected_beats{r} == 1);
    temporal_features{r}.global_R = global_R(selected_beats{r} == 1);
    positions{r} = positions{r}(selected_beats{r} == 1);
end

dataset.signals = signals;
dataset.positions = positions;
dataset.classes = classes;
dataset.temporal_features = temporal_features;

filename = ['mitdb', '_window', num2str(window_l), '_', num2str(window_t), '.mat'];
save(filename, 'dataset');

end