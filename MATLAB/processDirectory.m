function processDirectory(dirpath, voxelSize, minGrainSize)
% given a directory will scan for ISQ files and process
% e.g.'dirpath/*/*.ISQ'

% grab all the files to process
files = rdir(dirpath);

for file=1:size(files, 1)
    
    % get filename
    filename = files(file).name;
    % segment image initially in 2D  
    [img, masked] = cleanWheat(files(file).name);
    % perform 3D watershedding to segment any leftover data
    img = watershedSplit3D(img);
    
    % count objects
    [img, ~] = filterSmallObjs(img, minGrainSize);
    
    % count Rachis
    [rachis, top, bottom] = segmentRachis(masked); 
    
    % compute rachis stats for use when rejoining spikes
    rstats.top = top; 
    rstats.bottom = bottom; 
    % write rachis data to file
    writetable((struct2table(rstats)), strcat(filename,'-rstats.csv'));
    
    % perform grain measurement gathering!
    [stats, rawstats] = countGrain(img, files(file).name, masked, voxelSize, minGrainSize);
    
    % write stats file
    file_output_stats = strcat(filename, '.csv');
    file_output_rawstats = strcat(filename, '-raw_stats.csv');
    % clear previous stat files if they exist
    delete (file_output_stats);
    delete (file_output_rawstats);
    writetable(struct2table(stats), file_output_stats);
    writetable(struct2table(rawstats), file_output_rawstats);
    
    % Write segmented image to file
    file_output_img = strcat(filename, 'cleaned.tif');
    delete (file_output_img);
    for K=1:length(masked(1, 1, :))
        imwrite(masked(:, :, K), file_output_img, 'WriteMode', 'append','Compression','none');
    end
    
end
end