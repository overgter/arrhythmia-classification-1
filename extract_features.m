function [ samples, labels ] = extract_features(dataset, statistical_intervals)
%extract_features  Perform feature extraction and assign labels

samples = [];
labels = [];
for r = 1:size(dataset.signals, 2)
    for s = 1:size(dataset.signals, 1)
        for b = 1:size(dataset.signals{s,r}, 1)
            %% Labels
            % Using binary classification (normal & abnormal)
            num_classes = 2;
            selected = 0;
            % class 1 : normal beats
            subclasses{1} = {'N', 'L', 'R'};
            subclasses{2} = {'A', 'a', 'J', 'S', 'V', 'E', 'F',  'e', 'j'};
            for c = 1:num_classes
                if any(strcmp(dataset.classes{r}(b), subclasses{c}))
                    labels = [labels; c];
                    selected = 1;
                    break;
                end
            end
            if selected
                %% Feature extraction
                beat = dataset.signals{s,r}(b, :);
                pre_R = dataset.temporal_features{r}.pre_R(b);
                post_R = dataset.temporal_features{r}.post_R(b);
                local_R = dataset.temporal_features{r}.local_R(b);
                global_R = dataset.temporal_features{r}.global_R(b);
                samples = [samples, [beat_features(beat, pre_R, post_R, local_R, global_R, statistical_intervals)]]; 
            end
        end
    end
end

dataset_name = 'mitdb_dataset';
dataset_path = [dataset_name '_interv' num2str(statistical_intervals) '.mat'];
save(dataset_path, 'samples', 'labels');
end