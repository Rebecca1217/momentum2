function resMACD = getMACD(dateFrom, dateTo)
%GETMACD 从factorDataTT里获取MACD排名 注意：这个排名是从大到小排的

load('E:\Repository\factorTest\factorDataTT.mat')
resMACD = factorDataTT(:, {'date', 'code', 'MACDStdlzd'});
clear factorDataTT
codeName = getVarietyCode();

resMACD = outerjoin(resMACD, codeName, 'type', 'left', 'MergeKeys', true, ...
    'LeftKeys', 'code', 'RightKeys', 'ContCode');

resMACD = resMACD(:, {'date', 'ContName', 'MACDStdlzd'});
resMACD.Properties.VariableNames = {'Date', 'ContName', 'ReverseRank'};
resMACD.ContName = cellfun(@char, resMACD.ContName, 'UniformOutput', false);
resMACD = unstack(resMACD, 'ReverseRank', 'ContName');
end

