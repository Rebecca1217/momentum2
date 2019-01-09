function res = lotsTransform(posHands, codename)
%LOTSTRANSFORM  posHands转换为新回测平台的手数格式(纯手数，不带持仓方向)
posHands = posHands.fullHands;
stackVar = posHands.Properties.VariableNames(2:end);
res = stack(posHands, stackVar, ...
    'NewDataVariableName', 'Hands');

% 去掉手数为NaN或者0的行
res = res(arrayfun(@(x) ~isnan(x) & x ~= 0, res.Hands), :);


res = table(res.Hands_Indicator, res.Hands, res.Date, ...
    'VariableNames', {'ContName', 'Hands', 'Date'});

res.ContName = cellstr(res.ContName);
codename.ContName = cellfun(@char, codename.ContName, 'UniformOutput', false);
res = outerjoin(res, codename, 'type', 'left', 'MergeKeys', true);

res = table(res.Date, res.ContCode, res.Hands, ...
    'VariableNames', {'date', 'code', 'hand'});
res.hand = abs(res.hand);
end

