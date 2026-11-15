function cfg = isscc_settings(repositoryRoot)
% ISSCC_SETTINGS Parameters of the core PPV identification method.
if nargin == 0
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
end
cfg.samplingHz = 10000;
cfg.speedKmh = 350;
cfg.signalColumn = 2;
cfg.lowpassOrder = 60;
cfg.lowpassCutoffHz = 500;
cfg.eemdNoiseRatio = 0.05;
cfg.eemdEnsembles = 40;
cfg.eemdSiftsPerIMF = 15;
cfg.imfNumber = 4;
cfg.windowLengthM = 5.6;
cfg.windowStepM = 1;
cfg.threshold = 4557.24;        % Previously calibrated decision threshold, m^2/s^4.
cfg.randomSeed = 20261115;      % Reproducible EEMD noise realization.
cfg.exampleFile = fullfile(repositoryRoot,'data','example','demo_signal.txt');
cfg.outputRoot = fullfile(repositoryRoot,'results');
end
