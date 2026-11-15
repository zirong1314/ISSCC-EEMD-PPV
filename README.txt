RUN
Set the MATLAB current folder to this directory and enter: run_demo
Requires MATLAB R2020b or later and Signal Processing Toolbox.

PROGRAMS
run_demo.m: Main entry; runs identification and saves the results.
config/isscc_settings.m: Sampling, speed, filter, EEMD, window and threshold settings.
src/ppv_process_record.m: Read -> 500 Hz low-pass -> EEMD -> IMF4 -> window PPV -> maximum PPV -> threshold decision.
third_party/eemd/eemd_x.m: EEMD decomposition; 3712 input samples produce 11 IMFs.
third_party/eemd/extrema.m: Extrema detection and endpoint treatment for EEMD envelopes.

DATA
data/example/demo_signal.txt: Original rows 2189-5900, already cropped to 3712 samples. Read the entire file without further cropping. Column 1: time (s); column 2: acceleration (m/s^2).
data/example/README.txt: Operating-condition description of the example signal.
data/scores/test_ppv.csv: Maximum PPV scores of the 160 records. Label 0: without ISSCC; label 1: with ISSCC. SourceFigurePoint identifies the original figure point.

DECISION
The previously calibrated threshold is 4557.24 m^2/s^4. MaxPPV > threshold gives PredictedLabel = 1; otherwise PredictedLabel = 0.

OUTPUTS
results/identification_result.csv: Record maximum, threshold and identification result.
results/window_ppv.csv: Window positions, peak/valley sums, extrema counts and PPV.
results/processing_result.mat: MATLAB structure named out, containing:
  out.Summary: Record-level identification results.
  out.Windows: Complete per-window PPV calculation table.
  out.Stages: Time, distance, input acceleration, low-pass acceleration and selected IMF.
  out.Components: EEMD output; column 1 is the low-pass input, columns 2-12 are IMF1-IMF11, and column 13 is the residual for this 3712-sample example. IMF4 is column 5.
  out.FilterCoefficients: The 61 FIR filter coefficients.
  out.Config: Processing parameters, random seed and input/output paths used in the run.
