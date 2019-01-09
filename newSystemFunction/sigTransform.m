function res = sigTransform(posFullDirect, codename)
%SIGTRANSFORM posFullDirect转换为新回测平台的信号格式signalSummary

stackVar = posFullDirect.Properties.VariableNames(2:end);
res = stack(posFullDirect, stackVar, ...
    'NewDataVariableName', 'SignalDirect');

% 去掉信号为NaN的行
res = res(arrayfun(@(x) ~isnan(x), res.SignalDirect), :);


res = table(res.SignalDirect_Indicator, res.SignalDirect, res.Date, ...
    'VariableNames', {'ContName', 'SignalDirect', 'Date'});

res.ContName = cellstr(res.ContName);
codename.ContName = cellfun(@char, codename.ContName, 'UniformOutput', false);
res = outerjoin(res, codename, 'type', 'left', 'MergeKeys', true);

res = table(res.ContCode, res.SignalDirect, res.Date, repmat(999999999, height(res), 1), zeros(height(res), 1), ...
    'VariableNames', {'code', 'signalDirect', 'signalDate', 'signalTime', 'signalCut'});
end

