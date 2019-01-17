function res = getDlyData(dateInput)
%GETDAILYDATA
% ����momentum2��daily data(ÿ���ֻ���۵�table��ÿ�ղ����ʵ�table��ÿ�������Ե�table)
% ���������Ҫ������check����һ���͹�ȥ�����ڲ��ظ����ڶ����͹�ȥ�������м�û�жϵ�

if ~isa(dateInput, 'double')
    error('dateInput needs to be ''double''!')
end

%% �������������ж�������delStockBond�����Ľ������������ָ�ڻ��͹�ծ�ڻ�

% �ֻ���۱�������
% ֻ����һ�������ǿ���ֱ��dateFrom = dateTo = dateInput��������
dataPrem = getPremium(dateInput, dateInput);
if isempty(dataPrem)
    disp('Could''nt fetch spotData because Tdays update hanged.')
    res = table.empty(0, 5);
    return
end

dataPrem = table(transpose(dataPrem.Properties.VariableNames(2:end)), ...
    transpose(table2array(dataPrem(:, 2:end))), ...
    'VariableNames', {'Variety', 'Premium'});

% ÿ�ղ��������� ��Щ�漰���㴰�ڵı�����������dateInput��ǰ��win�������ϼ��㣬Ȼ��ֻ��������һ��
dataVol = getVolatility(90, 0.25, ...
    str2double(datestr((datenum(num2str(dateInput), 'yyyymmdd') - 200), 'yyyymmdd')), ...
    dateInput, 'sigma');
% ֻȡ���1�죬����ǰ������Ҳû��ϵ
dataVol = dataVol(end, :);
dataVol = table(transpose(dataVol.Properties.VariableNames(2:end)), ...
    transpose(table2array(dataVol(:, 2:end))), ...
    'VariableNames', {'Variety', 'Volatility'});

% ÿ�������Ա�ǩ����
dataLiq = getLiquidInfoHuatai(str2double(datestr((datenum(num2str(dateInput), 'yyyymmdd') - 200), 'yyyymmdd')), ...
    dateInput, 60, 0.4, false);
dataLiq = dataLiq(end, :);
dataLiq = table(transpose(dataLiq.Properties.VariableNames(2:end)), ...
    transpose(table2array(dataLiq(:, 2:end))), ...
    'VariableNames', {'Variety', 'Liquidity'});

% @2019.1.14����ط�merge�и����⣬ÿ��������������Ʒ�ָ���Ҫһ�����У���Ȼ��ô��֤�ʼ��ߵİ����˵���ȫ��Ʒ�֣�
res = outerjoin(dataPrem, dataVol, 'type', 'left', 'MergeKeys', true);
res = outerjoin(res, dataLiq, 'type', 'left', 'MergeKeys', true);

res.Date = repmat(dateInput, height(res), 1);

end

