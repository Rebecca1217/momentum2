function res = MACDSelect(momRes, groupN)
%MACDSELECT momRes是动量的持仓结果，函数返回的是经过MACD调整的交易日持仓结果

%% 计算各品种MACD Standalized 排名
% getMACD
rankMACD = getMACD(momRes.Date(1), momRes.Date(end));

[~, idx, ~] = intersect(rankMACD.Date, momRes.Date);
rankMACD = rankMACD(idx, :); % 因为这里MACD是从大到小排序，所以选择rank值最大的那组做多

%% 筛选：做多（1）品种要求MACD秩位于最小组
selectNum = floor(sum(~isnan(table2array(rankMACD(:, 2:end))), 2) ./ groupN);
% rankMax = max(table2array(rankMACD(:, 2:end)),[], 2);
% selectRank = rankMax - selectNum; % 选择的秩要＞这个边界
% resRankMACD = [rankMACD.Date, table2array(rankMACD(:, 2:end)) > selectRank];
resRankMACD = [rankMACD.Date, table2array(rankMACD(:, 2:end)) <= selectNum];
resRankMACD = array2table(resRankMACD, 'VariableNames', rankMACD.Properties.VariableNames);
resRankMACD = delStockBondIdx(resRankMACD);
% ifelse 不能处理NaN，MATLAB里会把NaN参与比较并且返回false
% if sig == 1 返回sig * label 否则 返回sig 不作处理
res = arrayfun(@(x, y, z) ifelse(x == 1, x * y, x), ...
    table2array(momRes(:, 2:end)), table2array(resRankMACD(:, 2:end)));

res = array2table([momRes.Date, res], ...
    'VariableNames', momRes.Properties.VariableNames);

end



