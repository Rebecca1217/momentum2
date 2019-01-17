function res = getDlyData(dateInput)
%GETDAILYDATA
% 用于momentum2的daily data(每日现货溢价的table、每日波动率的table、每日流动性的table)
% 这个日期需要做两个check，第一，和过去的日期不重复，第二，和过去的日期中间没有断档

if ~isa(dateInput, 'double')
    error('dateInput needs to be ''double''!')
end

%% 以下三个函数中都包含了delStockBond，出的结果都不包含股指期货和国债期货

% 现货溢价比例数据
% 只有这一个函数是可以直接dateFrom = dateTo = dateInput这样操作
dataPrem = getPremium(dateInput, dateInput);
if isempty(dataPrem)
    disp('Could''nt fetch spotData because Tdays update hanged.')
    res = table.empty(0, 5);
    return
end

dataPrem = table(transpose(dataPrem.Properties.VariableNames(2:end)), ...
    transpose(table2array(dataPrem(:, 2:end))), ...
    'VariableNames', {'Variety', 'Premium'});

% 每日波动率数据 这些涉及计算窗口的变量，都必须dateInput往前推win窗口以上计算，然后只保留最新一天
dataVol = getVolatility(90, 0.25, ...
    str2double(datestr((datenum(num2str(dateInput), 'yyyymmdd') - 200), 'yyyymmdd')), ...
    dateInput, 'sigma');
% 只取最后1天，所以前面的算错也没关系
dataVol = dataVol(end, :);
dataVol = table(transpose(dataVol.Properties.VariableNames(2:end)), ...
    transpose(table2array(dataVol(:, 2:end))), ...
    'VariableNames', {'Variety', 'Volatility'});

% 每日流动性标签数据
dataLiq = getLiquidInfoHuatai(str2double(datestr((datenum(num2str(dateInput), 'yyyymmdd') - 200), 'yyyymmdd')), ...
    dateInput, 60, 0.4, false);
dataLiq = dataLiq(end, :);
dataLiq = table(transpose(dataLiq.Properties.VariableNames(2:end)), ...
    transpose(table2array(dataLiq(:, 2:end))), ...
    'VariableNames', {'Variety', 'Liquidity'});

% @2019.1.14这个地方merge有个问题，每天三个函数出的品种个数要一样才行，不然怎么保证最开始左边的包含了当天全部品种？
res = outerjoin(dataPrem, dataVol, 'type', 'left', 'MergeKeys', true);
res = outerjoin(res, dataLiq, 'type', 'left', 'MergeKeys', true);

res.Date = repmat(dateInput, height(res), 1);

end

