%% ===============================
%  Simulink Parameters: Microwave Link + QPSK + LDPC (DVB-S2 1/2)
%  Student: Mohammad Muslim
%  ===============================
clc; clear;

%% -------- Link / RF parameters --------
Pt_dBm   = -35;      % TX power [dBm]
f_GHz    = 18;       % Carrier [GHz]
d_km     = 30;       % Distance [km]
D        = 0.6;      % Dish diameter [m]
eta      = 0.6;      % Dish efficiency
Ltx_dB   = 2;        % Tx feeder loss [dB]
Lrx_dB   = 2;        % Rx feeder loss [dB]
Lrain_dB = 10;       % Rain attenuation [dB]
NF_dB    = 8;        % Noise figure [dB]
B        = 20e6;     % Noise bandwidth [Hz] (scenario)

%% -------- Constants --------
c = 3e8;
f = f_GHz*1e9;
lambda = c/f;

%% -------- Antenna gains --------
G_dBi  = 10*log10( eta*(pi*D/lambda)^2 );
Gt_dBi = G_dBi;
Gr_dBi = G_dBi;

%% -------- Path loss --------
FSPL_dB = 92.45 + 20*log10(f_GHz) + 20*log10(d_km);

%% -------- Received power & noise ------a--
Pr_dBm = Pt_dBm + Gt_dBi + Gr_dBi - FSPL_dB - Ltx_dB - Lrx_dB - Lrain_dB;
N_dBm  = -174 + 10*log10(B) + NF_dB;

SNR_dB = -15;

% Noise power in Watts -> use as AWGN "Variance"
Var = 10^((N_dBm - 30)/10);

%% -------- Baseband amplitude scaling --------
% Use this in Simulink Gain block (amplitude gain)
GdB      = Pr_dBm;          % same numeric value as received power in dBm
Gain_lin = 10^(GdB/20);

%% -------- LDPC (DVB-S2 rate 1/2) --------
H = dvbs2ldpc(1/2);     % sparse parity-check matrix
[M, N] = size(H);       % M = N-K
K = N - M;              % message length (input bits to encoder)

% QPSK: 2 coded bits/symbol (useful for reference)
Ns = N/2;

%% -------- Display quick check --------
disp("=== Link Budget Check ===");
disp(table(G_dBi, FSPL_dB, Pr_dBm, N_dBm, SNR_dB));

disp("=== LDPC Dimensions (DVB-S2 1/2) ===");
disp(table(K, N, Ns));

%% -------- Notes for Simulink blocks --------
% Random Integer Generator: M=2, Samples per frame = K
% LDPC Encoder: Parity-check matrix = H
% QPSK Modulator: Bit input, Gray, PhaseOffset=pi/4
% Gain block: Gain = Gain_lin
% Phase Noise (optional): Sample rate = 20e6
% AWGN Channel: Mode = Variance from mask, Variance = Var
% Carrier Synchronizer: QPSK, SamplesPerSymbol=1
% QPSK Demodulator: LLR output, Noise variance = Var
% LDPC Decoder: Parity-check matrix = H, Iterations=25..50
% Error Rate: compare Tx bits (before LDPC) vs Rx bits (after LDPC)
