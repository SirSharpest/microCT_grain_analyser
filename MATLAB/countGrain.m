function [ grain_stats, rawstats ] = countGrain( img, imagename , conv, minGrainSize)
% countGrain takes an image, name,masked image conv size and minimum grain size, returns grain stats
% grain_stats gives metric measurements and rawstats pixel value measurements

% Structuring element to use for erosions and dilations
se = strel('disk', 5);

imerr = zeros(size(img));
for i=1:size(img, 3)
    imerr(:,:,i) = imerode(imfill(img(:,:,i), 'holes'), se);
end

l = bwlabeln(imerr);
s = regionprops(l);
idx = find([s.Area] >= minGrainSize );

% assign a 0 for if empty image given
grain_stats = [];
grain_stats.None = 0;

rawstats = [];
rawstats.None = 0;


for grain=1:size(idx,2)
    
    single_grain = ismember(l, idx(grain));
    % add removed content
    for s=1:size(single_grain, 3)
        single_grain(:,:,s) = imdilate(single_grain(:,:,s), se);
        single_grain(:,:,s) = single_grain(:,:,s) & img(:,:,s);
    end
    
    
    masked_grain=img;
    for p=1:size(single_grain, 3) 
       masked_grain(:,:,p) = bsxfun(@times, masked_grain(:,:,p), cast(single_grain(:,:,p), 'like', masked_grain(:,:,p)));
    end

    try
        single_grain = compact3DImage(masked_grain);
        
    catch e
                   fprintf(1,'The identifier was:\n%s',e.identifier);
           fprintf(1,'There was an error! The message was:\n%s',e.message);
    end
    
    [single_grain, T, B] = rotateGrain(single_grain);
    
    b = 1;
    
    if grain == 1 
        try
        mkdir(strcat(imagename, '-grain-stacks/'));
        [grain_stats, c, Im, rawstats] = extract_features(single_grain, b, imagename, grain, T, B);
        catch e
           fprintf(1,'The identifier was:\n%s',e.identifier);
           fprintf(1,'There was an error! The message was:\n%s',e.message);
        end
    else
        try        
            [grain_stats(end+1), c, Im, rawstats(end+1)] = extract_features(single_grain, b, imagename, grain, T, B);
        catch e
           fprintf('Whoops on after first\n');
           fprintf(1,'The identifier was:\n%s',e.identifier);
           fprintf(1,'There was an error! The message was:\n%s',e.message);
           continue
        end 
    end
    
    
    
    % write single pictures of grain
    %imshow(Im);
    dirname = strcat(imagename, '-grains/');
    mkdir(dirname);
    savename = strcat(dirname, 'grain-', num2str(grain), '-slice-', num2str(c) ,'.png');
    savenameGray = strcat(dirname, 'grain-', num2str(grain), '-slice-', num2str(c) ,'-gray.png');
    
    imwrite(single_grain(:,:,c), savenameGray);
    
    file_output_img = strcat(imagename, '-grain-stacks/', 'stack-grain-', num2str(grain), '.tif');
    writeTif(single_grain, file_output_img); 
    
    
end


    function [stats, c, Im, rawstats] = extract_features(A, b, imagename, grainNum, T, B)
                
        A = logical(A);
        stats.length = (size(A, 3) * conv) / 1000;
        rawstats.length = (size(A,3));
        c = floor(size(A, 3) / 2);
        Im = imfill(A(:, :, c), 'holes');
        st = regionprops(Im, 'all');
        attempts = 1;
        
        while size(st,1) ~= 1
            
            stats.length = (size(A, 3) * conv) / 1000;
            rawstats.length = (size(A,3));
            c = floor(size(A, 3) / 2) + attempts;
            Im = imfill(A(:, :, c), 'holes');%A(:, :, c);
            st = regionprops(Im, 'all');
            attempts = attempts + 1;
            
        end
        

        stats.width = (st.MajorAxisLength * conv) / 1000;
        stats.depth = st.MinorAxisLength * conv / 1000;
        stats.ratio = stats.length / stats.width;
        stats.circularity = 4 * pi * (st.Area / st.Perimeter ^ 2);
        
        rawstats.width = st.MajorAxisLength; 
        rawstats.depth = st.MinorAxisLength; 

        
        vst = regionprops(A, 'FilledArea');
        
        stats.volume = (vst.FilledArea * (conv^3)) / (1000^3); 
        rawstats.volume = vst.FilledArea;
        
        C = st.ConvexImage - st.Image;
        
        vst = regionprops(im2bw(C, 0), 'MinorAxisLength');
        
        mal = sort([vst.MinorAxisLength], 'descend');
        
        stats.crease_depth = (mal(1) * conv) / 1000;
        rawstats.crease_depth = mal(1); 
        
        stats.surface_area = (imSurface(A) * (conv^2)) / 1000^2;
        rawstats.surface_area = imSurface(A); 
        
        stats.crease_volume = (crease_depth(A) * (conv^3)) / (1000^3);
        rawstats.crease_volume = crease_depth(A);
        
        centroid = regionprops(A, 'Centroid');
        centroid = centroid.Centroid;
        
        stats.x = centroid(1);
        stats.y = centroid(2);
        stats.z = centroid(3) + b; 
        stats.grainT = T;
        stats.grainB = B;
        
    end

end
