function [ powz ] = tf_transform(type, pow, baseline, fdim, tdim, cdim, sdim, bslAsIs, verbosity)
%TF_TRANSFORM normalizes tf-power to z, dB, div or percent-change
%   pow needs to be at least 2D (frequencybands & time)
%   By default, this function assumes that dimensions are in the following
%   order: freqband*time*channels*subjects
%       or:freqband*time*channels
%       or:freqband*time
%   If any of the above is the case, you don't need to specify any the *dim
%   arguments. These are only necessary if you're matrix is ordered in a
%   different way.
%   When a single subject is used as input, sdim can be used for trials
%   (i.e., single trial baseline).
%
%   baseline: This function is time agnostic. So baseline should be given
%   in indeces. Can be 'minmax' to us the whole time as baseline.
%
%   type can be one of: 'z', 'dB', 'div' or 'percent', 'sub'
%   if bslAsIs is 1 [default: 0]; the function does assume, that 'baseline'
%   is not indeces but data. It then simply uses this data.
%
% Wanja Moessing, moessing@wwu.de, Nov 2017

% check input arguments
if nargin < 9
    verbosity = 1;
end
if nargin < 8
    bslAsIs = 0;
end
if nargin < 7
    sdim = 4;
end
if nargin < 6
    cdim = 3;
end
if nargin < 5
    tdim = 2;
end
if nargin < 4
    fdim = 1;
end

if verbosity
    disp(['Converting data to ', type]);
end


% make sure data is in double precision
if ~isa(pow, 'double')
    pow = double(pow);
end

% check baseline
if strcmp('minmax', baseline)
    baseline = [1, size(pow, tdim)];
end

% depending on the number of dimensions, loop over subjects/channels or not
switch ndims(pow)
    case 2 % 1-channel & 1 subject
        %reorder dimensions for our purpose
        pow = permute(pow, [fdim, tdim]);
        if bslAsIs
            baseline = permute(baseline, [fdim, tdim]);
            bl_pow = mean(baseline, 2);
        else
            bl_pow = mean(pow(:, baseline(1):baseline(2)), 2);
        end
        switch type
            case 'z'
                if bslAsIs
                    bl_powA = baseline;
                else
                    bl_powA = pow(:, baseline(1):baseline(2));
                end
                powz = (pow - repmat(bl_pow, 1, size(pow,2))) ./...
                    repmat(std(bl_powA, [], 2), 1, size(pow, 2));
            case 'dB'
                powz = 10*log10( bsxfun(@rdivide, pow, bl_pow));
            case 'percent'
                powz = ...
                    100 * (pow - repmat(bl_pow, 1, size(pow, 2))./...
                    repmat(bl_pow, 1, size(pow, 2)));
            case 'div'
                powz = ...
                    pow ./ repmat(bl_pow, 1, size(pow, 2));
            case 'sub'
                powz = pow - repmat(bl_pow, 1, size(pow, 2));
            case 'none'
                powz = pow;
        end
    case 3 % Multiple channels or subjects (not AND!)
        %reorder dimensions for our purpose
        if isempty(cdim) %1chan+MultSub
            pow = permute(pow, [fdim, tdim, sdim]);
        else
            pow = permute(pow, [fdim, tdim, cdim]);
        end
        if bslAsIs
            if isempty(cdim) %1chan+MultSub
                baseline = permute(baseline, [fdim, tdim, sdim]);
            else
                baseline = permute(baseline, [fdim, tdim, cdim]);
            end
        end
        for i = 1:size(pow, 3) %loop over dim 3 (chans OR subjs)
            if bslAsIs
                bl_pow = mean(baseline(:, :, i), 2);
            else
                bl_pow = mean(pow(:, baseline(1):baseline(2), i), 2);
            end
            switch type
                case 'z'
                    if bslAsIs
                        bl_powA = baseline(:, :, i);
                    else
                        bl_powA = pow(:, baseline(1):baseline(2), i);
                    end
                    powz(:,:,i) = (pow(:,:,i) - repmat(bl_pow, 1,...
                        size(pow(:,:,i),2))) ./...
                        repmat(std(bl_powA, [], 2), 1, size(pow(:,:,i), 2));
                case 'dB'
                    powz(:,:,i) = 10*log10( bsxfun(@rdivide, pow(:,:,i), bl_pow));
                case 'percent'
                    powz(:,:,i) = ...
                        100 * (pow(:,:,i) - repmat(bl_pow, 1, size(pow, 2))./...
                        repmat(bl_pow, 1, size(pow, 2)));
                case 'div'
                    powz(:,:,i) = ...
                        pow(:,:,i) ./ repmat(bl_pow, 1, size(pow, 2));
                case 'sub'
                    powz(:,:,i) = pow(:,:,i) - repmat(bl_pow, 1, size(pow, 2));
                case 'none'
                    powz(:,:,i) = pow(:,:,i);
            end
        end
    case 4 % Multiple channel and Multiple subjects
        %reorder dimensions for our purpose
        pow = permute(pow, [fdim, tdim, cdim, sdim]);
        for isub = 1:size(pow, 4) %loop over subs
            for ichan = 1:size(pow, 3)% & chans
                if bslAsIs
                    bl_pow = ...
                        mean(baseline(:,:, ichan, isub), 2);
                else
                    bl_pow = ...
                        mean(pow(:,baseline(1):baseline(2), ichan, isub), 2);
                end
                switch type
                    case 'z'
                        if bslAsIs
                            bl_powA = baseline(:, :, ichan, isub);
                        else
                            bl_powA = pow(:, baseline(1):baseline(2),...
                                ichan, isub);
                        end
                        powz(:,:,ichan,isub) = ...
                            (pow(:, :, ichan, isub) - ...
                            repmat(bl_pow, 1, size(pow, 2))) ./...
                            repmat(std(bl_powA, [], 2), 1, size(pow, 2));
                    case 'dB'
                        powz(:,:,ichan,isub) = ...
                            10 * log10( bsxfun(@rdivide,...
                            pow(:,:,ichan,isub), bl_pow));
                    case 'percent'
                        powz(:,:,ichan,isub) = ...
                            100 * (pow(:,:,ichan,isub) - ...
                            repmat(bl_pow, 1, size(pow, 2))./...
                            repmat(bl_pow, 1, size(pow, 2)));
                    case 'div'
                        powz(:,:,ichan,isub) = ...
                            pow(:,:,ichan,isub) ./ repmat(bl_pow, 1, size(pow, 2));
                    case 'sub'
                        powz(:,:,ichan,isub) = pow(:,:,ichan,isub) - ...
                            repmat(bl_pow, 1, size(pow, 2));
                    case 'none'
                        powz(:,:,ichan,isub) = pow(:,:,ichan,isub);
                end
            end
        end
end
end