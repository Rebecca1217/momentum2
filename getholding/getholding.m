function res = getholding(passway, tradingPara)
%得到每期持仓品种和方向
% 先得到换仓日的，然后填充到中间的每天得到完整的持仓品种和方向，
% 之后再考虑手数和合约名字的问题

%% @2019.01.04 期限结构发信号：
% 现货溢价数据
%% 确定各品种的持仓
% 所有换仓日
holdingTime = evalin('base', 'tradingPara.holdingTime');
tradingDay = evalin('base', 'tradingDay');
factorPara = evalin('base', 'factorPara');
tradingDate = tradingDay.Date;
tradingIndex = ((tradingPara.passwayInterval * (passway - 1)) + 1:holdingTime:size(tradingDay, 1));
% tradingIndex = (passway:holdingTime:size(tradingDay, 1));
tradingDate = tradingDate(tradingIndex);
% iWin = 1, passway = 1时，从因子出现的第一天就开始配置

% 换仓日的现货溢价因子数据
resTrading = getPremium(factorPara.dateFrom, factorPara.dateTo); % 现货/期货结果，如果因子>1则做多，因子<1则做空
% 换仓日的信号
resTrading = array2table([resTrading.Date, ...
    arrayfun(@(x, y, z) ifelse(isnan(x), NaN, ifelse(x > 1, 1, -1)), table2array(resTrading(:, 2:end)))], ...
    'VariableNames', resTrading.Properties.VariableNames);
resTrading = resTrading(ismember(resTrading.Date, tradingDate), :); % 这个resTrading 就已经是换仓日持仓方向结果了

% % resTrading作为参数输入getholdingdirect.m得到换仓日的持仓方向结果
% res = getholdingdirect(resTrading);

%% 剔除流动性差的品种
% @2018.12.28 发现一个大bug！！！label不能直接和数值相乘。。label要和label相乘。。
% 之前做的时候liquidityInfo直接和factorData相乘，以为是把流动性低的剔除了，实际是把factorData里流动性低的品种因子值改为0了。。
% 2个改正方案：1、把label矩阵里0都改成NaN，然后再相乘，思路和原来一样
% 2、因子先排序，选出品种标签以后，标签矩阵和标签矩阵点乘得到最后的持仓标签
liquidityInfo = evalin('base', 'liquidityInfo');
[~, idxL, ~] = intersect(liquidityInfo.Date, resTrading.Date);
liquidityInfoJ = liquidityInfo(idxL, :);
liquidityInfoJ = table2array(liquidityInfoJ(:, 2:end));
% 这里factorData因子数据是缺失第一个时间窗口的；liquidityInfo是from-to全部时间的
liquidityInfoJ = arrayfun(@(x, y, z) ifelse(x == 0, NaN, x), liquidityInfoJ); % 这步貌似不做处理也可以
res = table2array(resTrading(:, 2:end)) .* liquidityInfoJ; % 这里resTrading不是factorData已经是标签了
res = [resTrading.Date, res]; % 现货溢价发出的持仓标签


%% @2018.12.27 剔除波动率低的品种（华泰新动量因子）
% 波动率回溯时长固定14
% volatilityInfo = getVolatility(pct, factorData.Date(1), factorData.Date(end), 'ATR');
% res = res(:, 2:end) .* table2array(volatilityInfo(:, 2:end));
% res = [factorData.Date, res]; % 流动性 & 高波动率品种的每日因子数据

%% @2018.12.28 剔除波动率低的品种（华泰新动量因子）
% 波动率回溯时长与因子窗口一致
volatilityInfo = evalin('base', 'volatilityInfo');
[~, idxV, ~] = intersect(volatilityInfo.Date, resTrading.Date);
volatilityInfoJ = volatilityInfo(idxV, :);
volatilityInfoJ = arrayfun(@(x, y, z) ifelse(x == 0, NaN, x), table2array(volatilityInfoJ(:, 2:end)));

res = res(:, 2:end) .* volatilityInfoJ;
res = [resTrading.Date, res]; % 流动性 & 高波动率品种的每日因子数据

res = array2table(res, 'VariableNames', resTrading.Properties.VariableNames);

% % 现货溢价筛选
% res = premiumSelect(res); %
% premiumSelect输入参数是momRes，即纯动量策略的Res，不是各种已经筛选过的，不然会覆盖之前

% % MACD筛选  做多品种中只保留MACD最小的1/5组，做空品种不处理
% res = MACDSelect(res, 5); % MACD是倒序排的，所以选择秩最大的1/5
% 加MACD限制条件效果变差（收益变大，回撤变更大）

% % 因子绝对值筛选
% res = factorSelect(res);
end

