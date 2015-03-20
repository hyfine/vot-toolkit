function selectors = create_sequence_selectors(experiment, sequences) %#ok<INUSL>

    selectors = cellfun(@(sequence, i) struct('name', sprintf('sequence_%s', sequence.name), ...
        'title', sequence.name, ...
        'aggregate', @(experiment, tracker, sequences) ...
        aggregate_for_sequence(experiment, tracker, sequence), ...
        'practical', @(sequences) get_frame_value(sequence, 'practical'), 'length', @(sequences) count_frames(sequences, i)), ...
        sequences, num2cell(1:length(sequences)), 'UniformOutput', false);        

end

function [aggregated_overlap, aggregated_failures] = aggregate_for_sequence(experiment, tracker, sequence)

    aggregated_overlap = [];
    aggregated_failures = [];

    repeat = get_global_variable('repeat', 1);
    burnin = get_global_variable('burnin', 0);    

    if ~exist(fullfile(tracker.directory, experiment.name), 'dir')
        print_debug('Warning: Results not available %s', tracker.identifier);
        return;
    end;

    groundtruth = sequence.groundtruth;

    directory = fullfile(tracker.directory, experiment.name, sequence.name);

    accuracy = nan(repeat, sequence.length);
    failures = nan(repeat, 1);

    for j = 1:repeat

        result_file = fullfile(directory, sprintf('%s_%03d.txt', sequence.name, j));

        try 
            trajectory = read_trajectory(result_file);
        catch
            continue;
        end;

        if (size(trajectory, 1) < size(groundtruth, 1))
            trajectory{end+1:length(groundtruth)} = 0;
        end;

        [~, frames] = estimate_accuracy(trajectory, groundtruth, 'burnin', burnin);

        accuracy(j, :) = frames;

        failures(j) = estimate_failures(trajectory, sequence);

    end;

    frames = num2cell(accuracy, 1);
    sequence_overlaps = cellfun(@(frame) mean(frame(~isnan(frame))), frames);

    failures(isnan(failures)) = mean(failures(~isnan(failures)));

    sequence_failures = failures;
    
    if ~isempty(sequence_overlaps)
        aggregated_overlap = [aggregated_overlap sequence_overlaps];
    end;

    if ~isempty(sequence_failures)
        aggregated_failures = [aggregated_failures sequence_failures];
    end;
    
end

function [count, partial] = count_frames(sequences, i)

	count = sequences{i}.length;

    partial = zeros(1, length(sequences));
    
    partial(i) = count;

end
