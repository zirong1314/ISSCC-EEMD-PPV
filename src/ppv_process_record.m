function out = ppv_process_record(filename,cfg)
% PPV_PROCESS_RECORD Low-pass -> EEMD -> IMF4 -> PPV maximum -> identification.
assert(isfile(filename),'PPV:MissingSignal','Signal file not found: %s',filename);
assert(cfg.eemdSiftsPerIMF==15,'PPV:Sifting','The supplied EEMD uses 15 sifts per IMF.');
validateattributes(cfg.randomSeed,{'numeric'},{'scalar','integer','>=',0,'<=',2^32-1});
validateattributes(cfg.samplingHz,{'numeric'},{'scalar','finite','positive'});
validateattributes(cfg.speedKmh,{'numeric'},{'scalar','finite','positive'});
validateattributes(cfg.signalColumn,{'numeric'},{'scalar','integer','positive'});
validateattributes(cfg.threshold,{'numeric'},{'scalar','finite','positive'});
validateattributes(cfg.lowpassOrder,{'numeric'},{'scalar','integer','positive'});
validateattributes(cfg.lowpassCutoffHz,{'numeric'}, ...
    {'scalar','finite','positive','<',cfg.samplingHz/2});
validateattributes(cfg.eemdNoiseRatio,{'numeric'},{'scalar','finite','nonnegative'});
validateattributes(cfg.eemdEnsembles,{'numeric'},{'scalar','integer','positive'});
validateattributes(cfg.imfNumber,{'numeric'},{'scalar','integer','positive'});
validateattributes(cfg.windowLengthM,{'numeric'},{'scalar','finite','positive'});
validateattributes(cfg.windowStepM,{'numeric'},{'scalar','finite','positive'});

root = fileparts(fileparts(mfilename('fullpath')));
dependencyFolder = fullfile(root,'third_party','eemd');
assert(strcmpi(which('eemd_x'),fullfile(dependencyFolder,'eemd_x.m')), ...
    'PPV:EEMDPath','Use the bundled eemd_x.m.');
assert(strcmpi(which('extrema'),fullfile(dependencyFolder,'extrema.m')), ...
    'PPV:ExtremaPath','Use the bundled extrema.m.');

% The supplied TXT is already cropped; read its entire acceleration column.
matrix = readmatrix(filename);
assert(size(matrix,2)>=cfg.signalColumn,'PPV:Column','Acceleration column is missing.');
signal = double(matrix(:,cfg.signalColumn));
signal = signal(:);
assert(isreal(signal)&&all(isfinite(signal)),'PPV:Values','Acceleration must be finite and real.');
dx = (cfg.speedKmh/3.6)/cfg.samplingHz;
windowSamples = round(cfg.windowLengthM/dx)+1;
assert(numel(signal)>=windowSamples,'PPV:Length','Signal is shorter than one complete window.');

coefficients = fir1(cfg.lowpassOrder,cfg.lowpassCutoffHz/(cfg.samplingHz/2), ...
    'low',hann(cfg.lowpassOrder+1));
filtered = filter(coefficients,1,signal);
assert(std(filtered)>0,'PPV:ConstantSignal','The filtered signal is constant.');
previousState = rng;
restoreState = onCleanup(@()rng(previousState)); %#ok<NASGU>
rng(cfg.randomSeed,'twister');
components = eemd_x(filtered,cfg.eemdNoiseRatio,cfg.eemdEnsembles);
imfCount = size(components,2)-2;
assert(cfg.imfNumber<=imfCount,'PPV:IMF','Requested IMF is unavailable.');
component = components(:,cfg.imfNumber+1);
assert(all(isfinite(component)),'PPV:IMFValues','Selected IMF contains nonfinite values.');

stepSamples = cfg.windowStepM/dx;
assert(stepSamples>=1,'PPV:Step','Window step must be at least one sample.');
lastStep = floor((numel(signal)-windowSamples)/stepSamples);
starts = 1+round((0:lastStep)'*stepSamples);
ends = starts+windowSamples-1;
peakSum = zeros(numel(starts),1); valleySum = peakSum;
peakCount = peakSum; valleyCount = peakSum;
for k = 1:numel(starts)
    segment = component(starts(k):ends(k));
    peaks = findpeaks(segment);
    invertedValleys = findpeaks(-segment);
    peakSum(k) = sum(peaks);
    valleySum(k) = sum(invertedValleys);
    peakCount(k) = numel(peaks);
    valleyCount(k) = numel(invertedValleys);
end
ppv = peakSum.*valleySum;
[maximumPPV,bestWindow] = max(ppv);
predictedLabel = double(maximumPPV>cfg.threshold);
identification = "No ISSCC detected";
if predictedLabel==1, identification = "ISSCC detected"; end
distance = (0:numel(signal)-1)'*dx;
time = (0:numel(signal)-1)'/cfg.samplingHz;
out.Windows = table((1:numel(starts))',starts,ends,distance(starts),distance(ends), ...
    peakSum,valleySum,peakCount,valleyCount,ppv,'VariableNames', ...
    {'WindowIndex','StartSample','EndSample','StartDistanceM','EndDistanceM', ...
    'PeakSum','InvertedValleySum','PeakCount','ValleyCount','PPV'});
out.Summary = table(numel(signal),imfCount,cfg.imfNumber,windowSamples,numel(starts), ...
    maximumPPV,bestWindow,cfg.threshold,predictedLabel,identification, ...
    'VariableNames',{'InputSamples','IMFCount','SelectedIMF','WindowSamples', ...
    'WindowCount','MaxPPV','BestWindowIndex','Threshold','PredictedLabel','Identification'});
out.Stages = table(time,distance,signal,filtered,component,'VariableNames', ...
    {'TimeS','DistanceM','Acceleration','LowpassAcceleration','SelectedIMF'});
out.Components = components;
out.FilterCoefficients = coefficients;
out.Config = cfg;
end
