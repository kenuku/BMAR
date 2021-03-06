function [cum_ret, cumprod_ret, daily_ret, daily_portfolio]...
    = bmar2_run(fid, data, epsilon, alpha, tc, Ne, eta, opts)
% This program simulates the BMAR-2 algorithm
%
% function [cum_ret, cumprod_ret, daily_ret, daily_portfolio] ...
%    = bmar2_run(fid, data, epsilon, alpha, tc, opts)
%
% cum_ret: a number representing the final cumulative wealth.
% cumprod_ret: cumulative return until each trading period
% daily_ret: individual returns for each trading period
% daily_portfolio: individual portfolio for each trading period
%
% data: market sequence vectors
% fid: handle for write log file
% epsilon: mean reversion threshold
% alpha: trade off parameter for calculating moving average [0, 1]
% tc: transaction cost rate parameter
% Ne: number of experts
% eta: parameter for online expert weights
% opts: option parameter for behvaioral control
%
% Example: [cum_ret, cumprod_ret, daily_ret, daily_portfolio, exp_ret] ...
%           = bmar2_run(fid, data, epsilon, alpha, tc, Ne, eta, opts)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is modified from OLMAR-2 as part of OLPS: http://OLPS.stevenhoi.org/
% Original authors: Bin LI, Steven C.H. Hoi
% Contributors:
% Change log: 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Ne=5;
%eta=1;
[n, m] = size(data);
alpha_expert=1:1:Ne;
alpha_expert=alpha_expert/Ne*alpha;
losses=zeros(Ne,1);
% Return variables
cum_ret = 1;
cumprod_ret = ones(n, 1);
daily_ret = ones(n, 1);

% Portfolio weights, starting with uniform portfolio
day_weight = ones(m, 1)/m;  %#ok<*NASGU>
day_weight_o = zeros(m, 1);  % Last closing price adjusted portfolio
daily_portfolio = zeros(n, m);

% print file head
%fprintf(fid, '-------------------------------------\n');
%fprintf(fid, 'Parameters [epsilon:%.2f, alpha:%.2f, tc:%.4f]\n', ...
%    epsilon, alpha, tc);
%fprintf(fid, 'day\t Daily Return\t Total return\n');

fprintf(1, '-------------------------------------\n');
% if(~opts.quiet_mode)
%     fprintf(1, 'Parameters [epsilon:%.2f, alpha:%.2f, tc:%.4f]\n', ...
%         epsilon, alpha, tc);
%     fprintf(1, 'day\t Daily Return\t Total return\n');
% end

data_phi = ones(1, m);
    day_weight_e=zeros(Ne,m);
    data_phi_e=zeros(Ne,m);
%% Trading
% if (opts.progress)
% 	progress = waitbar(0,'Executing Algorithm...');
% end
for t = 1:1:n,
    % Step 1: Receive stock price relatives

    if (t >= 2)
        display(t);
        for i=1:Ne
            alpha_e=alpha_expert(i);
        [mid, nid] ...
            = olmar2_kernel(data(1:t-1, :), data_phi_e(i,:), day_weight, epsilon, alpha_e);
        day_weight_e(i,:)=mid';
        data_phi_e(i,:)=nid;
            daily_return = (data(t, :)*mid)*(1-tc/2*sum(abs(mid-day_weight_o)));
            losses(i)=losses(i)+exp(-daily_return);%1-daily_return;%
            display(daily_return);
        end
        %display(losses);
        day_weight=(exp(-eta*losses')/sum(exp(-eta*losses))*day_weight_e)';
    end
    
    % Normalize the constraint, always useless
    day_weight = day_weight./sum(day_weight);
    daily_portfolio(t, :) = day_weight';
    
    if or((day_weight < -0.00001+zeros(size(day_weight))), (day_weight'*ones(m, 1)>1.00001))
        fprintf(1, 'mrpa_expert: t=%d, sum(day_weight)=%d, pause', t, day_weight'*ones(m, 1));
        pause;
    end

    % Step 2: Cal t's daily return and total return
    daily_ret(t, 1) = (data(t, :)*day_weight)*(1-tc/2*sum(abs(day_weight-day_weight_o)));
    cum_ret = cum_ret * daily_ret(t, 1);
    cumprod_ret(t, 1) = cum_ret;
    
    % fprintf(1, '%d\t%.2f\t%.2f\t%.2f\n', t, day_weight(1), day_weight(2), daily_ret(t, 1));
    % Adjust weight(t, :) for the transaction cost issue
    day_weight_o = day_weight.*data(t, :)'/daily_ret(t, 1);
    
    % Debug information
    % Time consuming part, other way?
%     fprintf(fid, '%d\t%f\t%f\n', t, daily_ret(t, 1), cumprod_ret(t, 1));
%     if (~opts.quiet_mode),
%         if (~mod(t, opts.display_interval)),
%             fprintf(1, '%d\t%f\t%f\n', t, daily_ret(t, 1), cumprod_ret(t, 1));
%         end
%     end
%     if (opts.progress)
%         if mod(t, 50) == 0 
%             waitbar((t/n));
%         end
%     end
end

% Debug Information
% fprintf(fid, 'OLMAR-2(epsilon:%.2f, alpha:%.2f, tc:%.4f), Final return: %.2f\n', ...
%     epsilon, alpha, tc, cum_ret);
%fprintf(fid, '-------------------------------------\n');
fprintf(1, 'BMAR-2(epsilon:%.2f, alpha:%.2f, tc:%.4f), Final return: %.2f\n', ...
    epsilon, alpha, tc, cum_ret);
fprintf(1, '-------------------------------------\n');
%     if (opts.progress)	
%         close(progress);
%     end
end