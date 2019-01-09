function BacktestResult = BacktestPlatform_Comb_2(signal,TableWeight,TableDataI,dataType,TradePara,endday,totalSize,cutLoss,cutType)
% 整合版的回测系统
% 期货、股票、指数
% 20181008：
% 1.可以对套利策略进行回测
% 2.输入的持仓信息可以为权重配比或者手数


if strcmp(dataType,'future')
    if nargin==4
        BacktestResult = portfolio_for_BacktestPlatform_4(signal,TableWeight,TableDataI);
    elseif nargin==5
        BacktestResult = portfolio_for_BacktestPlatform_4(signal,TableWeight,TableDataI,TradePara);
    else
        if strcmpi(cutType,'in')
            BacktestResult = portfolio_for_BacktestPlatform_4(signal,TableWeight,TableDataI,TradePara,endday,totalSize,cutLoss);
        elseif strcmpi(cutType,'out')
            if isempty(TradePara)
                BacktestResult = portfolio_for_BacktestPlatform_4(signal,TableWeight,TableDataI);
            else
                BacktestResult = portfolio_for_BacktestPlatform_4(signal,TableWeight,TableDataI,TradePara);
            end
        end
    end
end