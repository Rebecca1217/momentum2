function res = MACDSelect(momRes, groupN)
%MACDSELECT momRes�Ƕ����ĳֲֽ�����������ص��Ǿ���MACD�����Ľ����ճֲֽ��

%% �����Ʒ��MACD Standalized ����
% getMACD
rankMACD = getMACD(momRes.Date(1), momRes.Date(end));

[~, idx, ~] = intersect(rankMACD.Date, momRes.Date);
rankMACD = rankMACD(idx, :); % ��Ϊ����MACD�ǴӴ�С��������ѡ��rankֵ������������

%% ɸѡ�����ࣨ1��Ʒ��Ҫ��MACD��λ����С��
selectNum = floor(sum(~isnan(table2array(rankMACD(:, 2:end))), 2) ./ groupN);
% rankMax = max(table2array(rankMACD(:, 2:end)),[], 2);
% selectRank = rankMax - selectNum; % ѡ�����Ҫ������߽�
% resRankMACD = [rankMACD.Date, table2array(rankMACD(:, 2:end)) > selectRank];
resRankMACD = [rankMACD.Date, table2array(rankMACD(:, 2:end)) <= selectNum];
resRankMACD = array2table(resRankMACD, 'VariableNames', rankMACD.Properties.VariableNames);
resRankMACD = delStockBondIdx(resRankMACD);
% ifelse ���ܴ���NaN��MATLAB����NaN����Ƚϲ��ҷ���false
% if sig == 1 ����sig * label ���� ����sig ��������
res = arrayfun(@(x, y, z) ifelse(x == 1, x * y, x), ...
    table2array(momRes(:, 2:end)), table2array(resRankMACD(:, 2:end)));

res = array2table([momRes.Date, res], ...
    'VariableNames', momRes.Properties.VariableNames);

end



