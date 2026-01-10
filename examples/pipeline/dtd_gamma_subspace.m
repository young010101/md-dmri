%%
disp('dtd gamma subspace!!!')

ps = step0_define_paths();

opt = mdm_opt;
opt.do_overwrite = 1;
opt.verbose = 1;

s = mdm_s_from_nii(fullfile(ps.op, 'FWF_mc.nii.gz'));
opt.filter_sigma = 0.6;

cyan_s = mdm_nii_read(s.nii_fn);
%% dtd gamma plot demo
cyan_s_line = squeeze(cyan_s(45,45,12,:));
fig = figure; ax1= subplot(1,2,1,'Parent', fig);ax2 = subplot(1,2,2,'Parent',fig);
dtd_gamma_plot(cyan_s_line, s.xps, ax1, ax2)

%% dti demo
i_dti = s.xps.b_delta > 0.99 & s.xps.b < 1.1e9;
s_dti = mdm_s_subsample(s, i_dti);
cyan_s_dti_line = cyan_s_line(i_dti);
dti_lls_plot(cyan_s_dti_line, s_dti.xps, ax1, ax2);

%% 
signal = cyan_s_line;
xps = s.xps;
[signal,xps] = mdm_powder_average_1d(signal, xps);
opt = dtd_gamma_opt(opt);
opt.dtd_gamma.do_multiple_s0 = 1;
ind = ones(xps.n,1);

function m = dtd_gamma_1d_data2fit2(signal, xps, opt, ind)


if (isfield(xps, 's_ind') && opt.dtd_gamma.do_multiple_s0)
    ns = numel(unique(xps.s_ind(ind))) - 1;
else
    ns = 0;
end
unit_to_SI = [max(signal+eps) 1e-9 (1e-9)^2*[1 1] ones(1,ns)];


% Convert local params to outside format.
    function m = t2m(t)
        % define model parameters
        s0          = t(1);
        d_iso       = t(2);
        mu2_iso     = t(3);
        mu2_aniso   = t(4);
        sw          = t((end-(ns - 1)):end);
        m = [s0 d_iso mu2_iso mu2_aniso sw] .* unit_to_SI;
    end

% Convert non weighted to weighted signal.
    function s = my_1d_fit2data(t,varargin)
        m = t2m(t);
        % signal
        s = dtd_gamma_1d_fit2data(m, xps);
        s = s(ind).*weight(ind);
    end

% Soft heaviside weighting function
% limit the fit to the initial slope
% sthresh: normalized signal threshold value [0.2]
% mdthresh: MD [1e-9]
% wthresh: width of transition from 1 to 0 [5]
% bthresh: b-value at transition
    function weight = weightfun(sthresh,mdthresh,wthresh)
        bthresh = -log(sthresh)/mdthresh;
        weight = .5*(1-erf(wthresh*(xps.b - bthresh)/bthresh));
    end

% Weight function that corrects for heteroscedasticity due to different number
% of images being averaged in the powder avereaged signal
    function w = calc_weight_from_signal_samples()
        if ~isfield(xps, 'pa_w')
            w = ones(size(xps.b));
        else
            w = sqrt( xps.pa_w / max(xps.pa_w) );
        end
    end

% Guess and fitting bounds
m_lb = [opt.dtd_gamma.fit_lb 0.5 * ones(1,ns)];
m_ub = [opt.dtd_gamma.fit_ub 2.0 * ones(1,ns)];

m_lb(1) = m_lb(1) * max(signal+eps);
m_ub(1) = m_ub(1) * max(signal+eps);

m_lbz     = m_lb .* (m_lb > 0); % Avoid negative guess

t_lb      = m_lb./unit_to_SI;
t_ub      = m_ub./unit_to_SI;

r_thr = inf;

for i = 1:opt.dtd_gamma.fit_iters
    
    % initial fit with weighting using guess value of MD
    weight = ones(xps.n,1);
    
    if (opt.dtd_gamma.do_weight)
        weight = weightfun(opt.dtd_gamma.weight_sthresh,opt.dtd_gamma.weight_mdthresh,opt.dtd_gamma.weight_wthresh);
    end
    
    % Weight with 1/sqrt(n) so that LS-fit is weighted to 1/n propto 1/variance
    if (opt.dtd_gamma.do_pa_weight)
        weight = weight .* calc_weight_from_signal_samples();
    end
    
    % Create a random guess
    m_guess = msf_fit_random_guess(@dtd_gamma_1d_fit2data, signal, xps, m_lbz, m_ub, weight, opt.dtd_gamma.guess_iters);
    t_guess = m_guess./unit_to_SI;
    
    
    % Non-linear fit to data
    t = lsqcurvefit(@my_1d_fit2data, t_guess, [], signal(ind).*weight(ind), t_lb, t_ub,...
        opt.dtd_gamma.lsq_opts);
    
    m = t2m(t);
    
    % Redo the fit with weighting based on attenuation (and updated
    % estimate of MD).
    if (opt.dtd_gamma.do_weight)
        weight = weightfun(opt.dtd_gamma.weight_sthresh,m(2),opt.dtd_gamma.weight_wthresh);
        
        if opt.dtd_gamma.do_pa_weight
            weight = weight .* calc_weight_from_signal_samples();
        end
        
        t = lsqcurvefit(@my_1d_fit2data, t, [], signal(ind).*weight(ind), t_lb, t_ub,...
            opt.dtd_gamma.lsq_opts);
        
        m = t2m(t);
    end
    
    
    % Check residual
    s_fit = dtd_gamma_1d_fit2data(m, xps);
    
    res   = sum(((signal-s_fit).*weight).^2);
    
    if res < r_thr
        r_thr = res;
        m_keep = m;
    end
    
end

m = m_keep;

if (opt.dtd_gamma.do_plot)
    signal_fit = dtd_gamma_1d_fit2data(m, xps);
    semilogy(xps.b,signal,'.',xps.b,signal_fit,'o',xps.b,m(1)*weight,'x');
    set(gca,'YLim',m(1)*[.01 1.2])
    pause(0.05);
end

end


m = dtd_gamma_1d_data2fit2(signal, xps, opt, ind);

%%
fit2data_s = dtd_gamma_1d_fit2data(m, xps);

plot(fit2data_s)

%%
dtd_gamma_pipe(s,ps.op,opt)

%% 1. define real m
disp(m);
cyan_t = m./unit_to_SI;
disp(cyan_t);
%% 3. fit to fited m
fited_m = dtd_gamma_1d_data2fit2(fit2data_s, xps, opt, ind);
fit2data_again_s = dtd_gamma_1d_fit2data(fited_m, xps);
figure('Name','Step5: compare signals');
plot(fit2data_s, 'o-'); hold on;
plot(fit2data_again_s, '.-');
grid on;
xlabel('Volume index'); ylabel('Signal');
legend({'Simulated (input to fit)','Re-simulated (from fitted m)'}, 'Location','best');
title('Signal comparison');
%%
opt = dtd_codivide_opt(opt);
fited_codivide_m = dtd_codivide_1d_data2fit(fit2data_s, xps, opt, ind);
fit2data_codivide_again_s = dtd_codivide_1d_fit2data(fited_codivide_m, xps);
figure('Name','Step5: compare signals');
plot(fit2data_s, 'o-'); hold on;
plot(fit2data_codivide_again_s, '.-');
grid on;
xlabel('Volume index'); ylabel('Signal');
legend({'Simulated (input to fit)','Re-simulated (from fitted m)'}, 'Location','best');
title('Signal comparison');

%%
opt = dtd_pa_opt(opt);
fited_pa_m = dtd_codivide_1d_data2fit(fit2data_s, xps, opt, ind);
fit2data_pa_again_s = dtd_codivide_1d_fit2data(fited_pa_m, xps);
figure('Name','Step5: compare signals');
plot(fit2data_s, 'o-'); hold on;
plot(fit2data_pa_again_s, '.-');
grid on;
xlabel('Volume index'); ylabel('Signal');
legend({'Simulated (input to fit)','Re-simulated (from fitted m)'}, 'Location','best');
title('Signal comparison');
%%
root_path = '/data/users/cyang/repos/HIFIVIM/Phantom/phan_cyan/';
recon_all = load('/data/users/cyang/repos/HIFIVIM/Phantom/phan_cyan/recon_all.mat');
%%
disp(recon_all)
%%
addpath('/data/users/cyang/to_cyang/arrShow-develop/')
%%
bval_fn = [root_path, 'recon_all_30.bval'];
bvec_fn = [root_path, 'recon_all_30.bvec'];
b_delta_recon_all= reshape([zeros(1, 15) ones(1, 15)], 30, 1);
subspace_xps = mdm_xps_from_bval_bvec(bval_fn, bvec_fn, b_delta_recon_all);
% subspace_xps.b = 
%%
recon_30 = squeeze(cat(ndims(recon_all.recon_fmac3),recon_all.recon_fmac3, recon_all.recon_fmac3_b_delta_1));
disp(size(recon_30))
