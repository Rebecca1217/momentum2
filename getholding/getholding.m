function res = getholding(passway, tradingPara)
%�õ�ÿ�ڳֲ�Ʒ�ֺͷ���
% �ȵõ������յģ�Ȼ����䵽�м��ÿ��õ������ĳֲ�Ʒ�ֺͷ���
% ֮���ٿ��������ͺ�Լ���ֵ�����

%% @2019.01.04 ���޽ṹ���źţ�
% �ֻ��������
%% ȷ����Ʒ�ֵĳֲ�
% ���л�����
holdingTime = evalin('base', 'tradingPara.holdingTime');
tradingDay = evalin('base', 'tradingDay');
factorPara = evalin('base', 'factorPara');
tradingDate = tradingDay.Date;
tradingIndex = ((tradingPara.passwayInterval * (passway - 1)) + 1:holdingTime:size(tradingDay, 1));
% tradingIndex = (passway:holdingTime:size(tradingDay, 1));
tradingDate = tradingDate(tradingIndex);
% iWin = 1, passway = 1ʱ�������ӳ��ֵĵ�һ��Ϳ�ʼ����

% �����յ��ֻ������������
resTrading = getPremium(factorPara.dateFrom, factorPara.dateTo); % �ֻ�/�ڻ�������������>1�����࣬����<1������
% �����յ��ź�
resTrading = array2table([resTrading.Date, ...
    arrayfun(@(x, y, z) ifelse(isnan(x), NaN, ifelse(x > 1, 1, -1)), table2array(resTrading(:, 2:end)))], ...
    'VariableNames', resTrading.Properties.VariableNames);
resTrading = resTrading(ismember(resTrading.Date, tradingDate), :); % ���resTrading ���Ѿ��ǻ����ճֲַ�������

% % resTrading��Ϊ��������getholdingdirect.m�õ������յĳֲַ�����
% res = getholdingdirect(resTrading);

%% �޳������Բ��Ʒ��
% @2018.12.28 ����һ����bug������label����ֱ�Ӻ���ֵ��ˡ���labelҪ��label��ˡ���
% ֮ǰ����ʱ��liquidityInfoֱ�Ӻ�factorData��ˣ���Ϊ�ǰ������Ե͵��޳��ˣ�ʵ���ǰ�factorData�������Ե͵�Ʒ������ֵ��Ϊ0�ˡ���
% 2������������1����label������0���ĳ�NaN��Ȼ������ˣ�˼·��ԭ��һ��
% 2������������ѡ��Ʒ�ֱ�ǩ�Ժ󣬱�ǩ����ͱ�ǩ�����˵õ����ĳֱֲ�ǩ
liquidityInfo = evalin('base', 'liquidityInfo');
[~, idxL, ~] = intersect(liquidityInfo.Date, resTrading.Date);
liquidityInfoJ = liquidityInfo(idxL, :);
liquidityInfoJ = table2array(liquidityInfoJ(:, 2:end));
% ����factorData����������ȱʧ��һ��ʱ�䴰�ڵģ�liquidityInfo��from-toȫ��ʱ���
liquidityInfoJ = arrayfun(@(x, y, z) ifelse(x == 0, NaN, x), liquidityInfoJ); % �ⲽò�Ʋ�������Ҳ����
res = table2array(resTrading(:, 2:end)) .* liquidityInfoJ; % ����resTrading����factorData�Ѿ��Ǳ�ǩ��
res = [resTrading.Date, res]; % �ֻ���۷����ĳֱֲ�ǩ


%% @2018.12.27 �޳������ʵ͵�Ʒ�֣���̩�¶������ӣ�
% �����ʻ���ʱ���̶�14
% volatilityInfo = getVolatility(pct, factorData.Date(1), factorData.Date(end), 'ATR');
% res = res(:, 2:end) .* table2array(volatilityInfo(:, 2:end));
% res = [factorData.Date, res]; % ������ & �߲�����Ʒ�ֵ�ÿ����������

%% @2018.12.28 �޳������ʵ͵�Ʒ�֣���̩�¶������ӣ�
% �����ʻ���ʱ�������Ӵ���һ��
volatilityInfo = evalin('base', 'volatilityInfo');
[~, idxV, ~] = intersect(volatilityInfo.Date, resTrading.Date);
volatilityInfoJ = volatilityInfo(idxV, :);
volatilityInfoJ = arrayfun(@(x, y, z) ifelse(x == 0, NaN, x), table2array(volatilityInfoJ(:, 2:end)));

res = res(:, 2:end) .* volatilityInfoJ;
res = [resTrading.Date, res]; % ������ & �߲�����Ʒ�ֵ�ÿ����������

res = array2table(res, 'VariableNames', resTrading.Properties.VariableNames);

% % �ֻ����ɸѡ
% res = premiumSelect(res); %
% premiumSelect���������momRes�������������Ե�Res�����Ǹ����Ѿ�ɸѡ���ģ���Ȼ�Ḳ��֮ǰ

% % MACDɸѡ  ����Ʒ����ֻ����MACD��С��1/5�飬����Ʒ�ֲ�����
% res = MACDSelect(res, 5); % MACD�ǵ����ŵģ�����ѡ��������1/5
% ��MACD��������Ч���������󣬻س������

% % ���Ӿ���ֵɸѡ
% res = factorSelect(res);
end

