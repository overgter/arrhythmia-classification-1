function [ samples, labels ] = extract_features(dataset, statistical_intervals, max_samples_per_class)
%extract_features  Perform feature extraction and assign labels

samples = [];
labels = [];
samples_per_class = zeros(12, 1);
for r = 1:size(dataset.signals, 2)
    for s = 1:size(dataset.signals, 1)
        for b = 1:size(dataset.signals{s,r}, 1)
            %% Labels
            % Using binary classification (normal & abnormal)
            num_classes = 12;
            selected = 0;
            % class 1 : normal beats
            subclasses{1} = {'N'};
            subclasses{2} = {'L'};
            subclasses{3} = {'R'};
            subclasses{4} = {'A'};
            subclasses{5} = {'a'};
            subclasses{6} = {'J'};
            subclasses{8} = {'S'};
            subclasses{9} = {'j'};
            subclasses{10} = {'V'};
            subclasses{11} = {'E'};
            subclasses{12} = {'F'};
            for c = 1:num_classes
                if any(strcmp(dataset.classes{r}(b), subclasses{c}))
                    if samples_per_class(c) < max_samples_per_class
                        labels = [labels; c];
                        selected = 1;
                        samples_per_class(c) = samples_per_class(c) + 1;
                    end
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
dataset_path = [dataset_name '_interv' num2str(statistical_intervals) '_max_per_class' num2str(max_samples_per_class) '.mat'];
save(dataset_path, 'samples', 'labels');
end