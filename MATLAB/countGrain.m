function [ grain_stats, rawstats ] = countGrain( img, imagename, immask , conv, minGrainSize)
% countGrain takes an image, name,masked image conv size and minimum grain size, returns grain stats
% grain_stats gives metric measurements and rawstats pixel value measurements

% Structuring element to use for erosions and ilations
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
    
    
    b = 1;
    t = size(single_grain, 3);
    
    % find bottom
    for slice=1:size(single_grain,3)
        if sum(sum(single_grain(:,:,slice))) == 0
            b = slice;
        else
            break
        end
    end
    
    % find top
    for slice=1:size(single_grain,3)
        reverse_idx = size(single_grain, 3) - slice;
        if sum(sum(single_grain(:,:,reverse_idx))) == 0
            t = reverse_idx;
        else
            break
        end
    end
    
    single_grain = single_grain(:,:,b:t);
    masked_grain = immask(:,:,b:t);
    
    
    if grain == 1 
        try
        mkdir(strcat(imagename, '-grain-stacks/'));
        [grain_stats, c, Im, rawstats] = extract_features(single_grain, b, imagename, grain);
        catch 
            sprintf('Whoops'); 
            continue
        end
    else
        try
        [grain_stats(end+1), c, Im, rawstats(end+1)] = extract_features(single_grain, b, imagename, grain);
        catch
           sprintf('Whoops');
           continue
        end 
    end
    
    
    masked_grain = bsxfun(@times, masked_grain(:,:,c), cast(single_grain(:,:,c), 'like', masked_grain(:,:,c)));
    
    % write single pictures of grain
    %imshow(Im);
    dirname = strcat(imagename, '-grains/');
    mkdir(dirname);
    savename = strcat(dirname, 'grain-', num2str(grain), '-slice-', num2str(c) ,'.png');
    savenameGray = strcat(dirname, 'grain-', num2str(grain), '-slice-', num2str(c) ,'-gray.png');
    
    %imwrite(Im, savename);
    imwrite(masked_grain, savenameGray);
    
end




    function [stats, c, Im, rawstats] = extract_features(A, b, imagename, grainNum)
                
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
        
        stats.volume = (vst.FilledArea * (conv^3)) / 100000000; 
        rawstats.volume = vst.FilledArea;
        
        C = st.ConvexImage - st.Image;
        
        vst = regionprops(im2bw(C, 0), 'MinorAxisLength');
        
        mal = sort([vst.MinorAxisLength], 'descend');
        
        stats.crease_depth = (mal(1) * conv) / 1000;
        rawstats.crease_depth = mal(1); 
        
        stats.surface_area = (imSurface(A) * (conv^2)) / 100000000;
        rawstats.surface_area = imSurface(A); 
        
        stats.crease_volume = (crease_depth(A) * (conv^3)) / 100000000;
        rawstats.crease_volume = crease_depth(A);
        
        centroid = regionprops(A, 'Centroid');
        centroid = centroid.Centroid;
        
        stats.x = centroid(1);
        stats.y = centroid(2);
        stats.z = centroid(3) + b; 
        
        % Write single grain as a tif
        file_output_img = strcat(imagename, '-grain-stacks/', 'stack-grain-', num2str(grainNum), '.tif');
        delete (file_output_img);
        
        for K=1:length(A(1, 1, :))
            imwrite(A(:, :, K), file_output_img, 'WriteMode', 'append','Compression','none');
        end
        
    end

end

% function [ grain_stats ] = countGrain( img, imagename, immask )
% 
% 
% min = 20000; %(generally I use 50k)
% l = bwlabeln(img);
% s = regionprops(l);
% idx = find([s.Area] >= min );
% 
% % assign a 0 for if empty image given
% grain_stats = [];
% grain_stats.None = 0;
% 
% for grain=1:size(idx,2)
%     grain
%     
%     single_grain = ismember(l, idx(grain));
%     
%     b = 1;
%     t = 100000;
%     
%     % find bottom
%     for slice=1:size(single_grain,3)
%         if sum(sum(single_grain(:,:,slice))) == 0
%             b = slice;
%         else
%             break
%         end
%     end
%     
%     % find top
%     for slice=1:size(single_grain,3)
%         reverse_idx = size(single_grain, 3) - slice;
%         if sum(sum(single_grain(:,:,reverse_idx))) == 0
%             t = reverse_idx;
%         else
%             break
%         end
%     end
% 
%     single_grain = single_grain(:,:,b:t);
%     masked_grain = immask(:,:,b:t);
%     
%     if grain == 1
%         [grain_stats, c, Im] = extract_features(single_grain);
%     else
%         [grain_stats(end+1), c, Im] = extract_features(single_grain);
%         
%     end
%     
%     
%     masked_grain = bsxfun(@times, masked_grain(:,:,c), cast(single_grain(:,:,c), 'like', masked_grain(:,:,c)));
%     
%     % write single pictures of grain
%     imshow(Im)
%     dirname = strcat(imagename, '-grains/');
%     mkdir(dirname)
%     savename = strcat(dirname, 'grain-', num2str(grain), '-slice-', num2str(c) ,'.png');
%     savenameGray = strcat(dirname, 'grain-', num2str(grain), '-slice-', num2str(c) ,'-gray.png');
% 
%     imwrite(Im, savename);
%     imwrite(masked_grain, savenameGray);
%     
% end
% 
% 
% 
% 
%     function [stats, c, Im] = extract_features(A)
%         
%         conv = 21/2100;
% 
%         stats.length = size(A, 3) * conv;
%         c = floor(size(A, 3) / 2);
%         Im = imfill(A(:, :, c), 'holes');%A(:, :, c);
%         %Im = A(:,:,c);
%         st = regionprops(Im, 'all');
%         
%         attempts = 1;
%         
%         %% TODO FLIP BETWEEN UP AND DOWN SEARCH
%         while size(st,1) ~= 1
%             
%             stats.length = size(A, 3) * conv;
%             c = floor(size(A, 3) / 2) + attempts;
%             Im = imfill(A(:, :, c), 'holes');%A(:, :, c);
%             st = regionprops(Im, 'all');
%             attempts = attempts + 1;
%             
%         end
%         
%         stats.width = st.MajorAxisLength * conv;
%         stats.depth = st.MinorAxisLength * conv;
%         stats.ratio = stats.length / stats.width;
%         
%         stats.circularity = 4 * pi * (st.Area / st.Perimeter ^ 2);
%         
%         vst = regionprops(A, 'FilledArea');
%         
%         stats.volume = vst.FilledArea * conv;
%         
%         C = st.ConvexImage - st.Image;
%         
%         vst = regionprops(im2bw(C, 0), 'MinorAxisLength');
%         
%         mal = sort([vst.MinorAxisLength], 'descend');
%         
%         stats.crease_depth = mal(1) * conv;
%         
%         stats.surface_area = imSurface(A) * conv;
%         
%         stats.crease_volume = crease_depth(A) * conv;
%     end
% 
% end
% 
% 