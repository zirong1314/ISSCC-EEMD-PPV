function out = run_demo(signalFile,cfg)
% RUN_DEMO Read one signal and run the complete PPV identification chain.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root,'src'),fullfile(root,'config'),fullfile(root,'third_party','eemd'));
if nargin < 2 || isempty(cfg), cfg = isscc_settings(root); end
if nargin < 1 || isempty(signalFile), signalFile = cfg.exampleFile; end
out = ppv_process_record(signalFile,cfg);
if ~exist(cfg.outputRoot,'dir'), mkdir(cfg.outputRoot); end
writetable(out.Windows,fullfile(cfg.outputRoot,'window_ppv.csv'));
writetable(out.Summary,fullfile(cfg.outputRoot,'identification_result.csv'));
save(fullfile(cfg.outputRoot,'processing_result.mat'),'out','-v7');
disp(out.Summary);
fprintf('Identification: %s\n',char(out.Summary.Identification));
fprintf('Results: %s\n',cfg.outputRoot);
end
