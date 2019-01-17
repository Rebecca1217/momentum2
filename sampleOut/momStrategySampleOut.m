cd 'E:\Repository\momentum2';
addpath getdata getholding newSystem3.0 newSystem3.0\gen_for_BT2 public sampleOut

% ��������٣����ݶ�ȡ����ʷ�ز����ݶ�ȡ��̫һ��������һ����

%% ������
% getBasicData�õ�һ�����table���������ڣ���Ʒ��������Լÿ�յĸ�Ȩ�۸�

% global usualPath

usualPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData';
dataPath = '\\Cj-lmxue-dt\�ڻ�����2.0\dlyData';
% factorDataPath = 'E:\Repository\momentum\factorData\';

%% ��������
% ���ַ�������Ҫ�������ӣ�ֻ����ʷ�������⣬�ȱ���������Ĳ���:

factorPara.dataPath = [dataPath, '\������Լ']; % getrawprice���ǻ��õ�������� ��������ʱ����Close�����ź���AdjClose ��getBasicData�߲���Ҫ�������
factorPara.priceType = 'Close';  % ��ͨ�ͻ�̩���Ǹ�Ȩ���̷��źţ��������㽻�ף�

window = 90;
holdingTime = 60;

tradingPara.groupNum = 5; % �Գ����10%��20%��Ӧ5��
tradingPara.pct = 0.25; % �߲�����ɸѡ�ı�׼���޳��ٷ�λpctATR���µ�
tradingPara.capital = 1e8; % ��ΪҪ����60��������֣�1000�򲻹���
% tradePara.futUnitPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\minTickInfo.mat'; %�ڻ���С�䶯��λ
tradingPara.futMainContPath = '\\Cj-lmxue-dt\�ڻ�����2.0\��Ʒ�ڻ�������Լ����';
tradingPara.futDataPath = '\\Cj-lmxue-dt\�ڻ�����2.0\dlyData\������Լ'; %�ڻ�������Լ����·��
tradingPara.futUnitPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\minTickInfo.mat'; %�ڻ���С�䶯��λ
tradingPara.futMultiPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\PunitInfo'; %�ڻ���Լ����
tradingPara.PType = 'open'; %���׼۸�һ����open�����̼ۣ�����avg(�վ��ۣ�
tradingPara.fixC = 0.0002; %�̶��ɱ� ��̩�ǵ������壬��ͨ��������
tradingPara.slip = 2; %���� ����ȯ�̶����ӻ���

factorPara.dateFrom = 20180301;
% factorPara.dateTo = 20190114;
factorPara.dateTo = str2double(datestr(date(), 'yyyymmdd'));
 

tradingPara.win = window;
tradingPara.holdingTime = holdingTime; % ���ּ�����ֲ����ڣ�
tradingPara.passway = tradingPara.holdingTime;
tradingDay = gettradingday(factorPara.dateFrom, factorPara.dateTo);
if tradingDay.Date(end) < factorPara.dateTo
    error('Stop because Tdays has not been updated.')
end
%         load([factorDataPath, factorName, '\window', num2str(window(iWin)), '.mat']);
%         %% ��������ɸѡ����һ������
%         factorData = factorData(factorData.Date >= factorPara.dateFrom & ...
%             factorData.Date <= factorPara.dateTo, :);
% ��������ɸѡ���ڶ���������
%     ÿ��ѭ����liquidityInfoʱ�䲻һ������factorData��ʱ�䱣��һ��
%% liquidityInfo��volatilityInfoһ���Զ�ȡ��ÿ��passway�����渴�Ƽ��ɣ���Ҫÿѭ��һ�λ�ȡһ��

run('.\sampleOut\dataBind.m')
clear fileName
if totalData.Date(end) < tradingDay.Date(end)
    error('totalData has not been updated to latest.')
end
% ��ǰ������2������ݣ���Ϊ���Բ������ڱȽϳ����洢��һ�����ݱ���
% �����ԡ��ֻ���ۡ����������ݶ�������totalData(ÿ�ո������ݺϳɵ�)

liquidityInfo = table(totalData.Date, totalData.Variety, totalData.Liquidity, ...
    'VariableNames', {'Date', 'Variety', 'Liquidity'});
liquidityInfo = unstack(liquidityInfo, 'Liquidity', 'Variety');

% % 2019.1.15 ��ȷ��liquidityInfo���ݺ��ϰ汾һ��
% load('E:\futureData\liquidityInfoHuatai.mat') % �û�̩��������ɸѡ��׼
% liquidityInfo = liquidityInfoHuatai;
liquidityInfo = liquidityInfo(...
    liquidityInfo.Date >= tradingDay.Date(1) &...
    liquidityInfo.Date <= tradingDay.Date(end), :);
% @2018.12.24 liquidityInfoҲҪ�޳���ָ�͹�ծ�ڻ�
% ��������ɸѡ������������Ʒ����
%         liquidityInfo = delStockBondIdx(liquidityInfo); %% ��һ����ʵ���ã���ΪHuatai�汾�Ѿ��޳��˹�ָ�͹�ծ�ڻ�

volatilityInfo = table(totalData.Date, totalData.Variety, totalData.Volatility, ...
    'VariableNames', {'Date', 'Variety', 'Volatility'});
volatilityInfo = unstack(volatilityInfo, 'Volatility', 'Variety');
volatilityInfo = volatilityInfo(...
    volatilityInfo.Date >= tradingDay.Date(1) &...
    volatilityInfo.Date <= tradingDay.Date(end), :);
% % 2019.1.15 ��ȷ��volatilityInfo���ݺ��ϰ汾һ��
% volatilityInfo = getVolatility(tradingPara.win, tradingPara.pct, tradingDay.Date(1), tradingDay.Date(end), 'sigma');

% @2019.1.15 premiumҲ����д�����棬��Ϊ����һ��ʱ��ָ�꣬�������ݼ��㲻�漰��ȥ
premium = table(totalData.Date, totalData.Variety, totalData.Premium, ...
    'VariableNames', {'Date', 'Variety', 'Premium'});
premium = unstack(premium, 'Premium', 'Variety');
premium = premium(...
    premium.Date >= tradingDay.Date(1) & ...
    premium.Date <= tradingDay.Date(end), :);

%% ����ز���ܽ��
testPassway = min(height(tradingDay), tradingPara.passway);

totalRes = num2cell(nan(13, testPassway + 1));
totalBacktestNV = nan(size(tradingDay, 1), testPassway + 1);
totalBacktestExposure = nan(size(tradingDay, 1), testPassway + 1);
%     �ز����һ��ͨ���⣬��������ڻ�ȱʧһЩ����Ҫ����

totalBacktestNV(:, 1) = tradingDay.Date;
totalBacktestExposure(:, 1) = tradingDay.Date;


%% ÿ��ͨ��ѭ������


for jPassway = 1 : testPassway % ÿ��ͨ��  �Ƚϲ�ͬͨ���µĽ��
    
    win = window;
    passway = jPassway;
    
    posTradingDirect = getholdingSampleOut(passway); %�õ�iWin��jPassway�µĻ��������гֲַ���
    % 2019.1.10 posTradingDirect����ȫ��NaN��Ҫȥ������ȻӰ��������ֲ�Ʒ�ָ�����ÿ�����ʽ�����
    %             posTradingDirect = delNaN(posTradingDirect);
    %             delVar = {'M', 'P', 'RM', 'ZN', 'ZC', 'MA', 'PP', 'BU', 'NI', 'L', 'RB', 'SR', 'TA', 'HC'};
    %             colIdx = ismember(posTradingDirect.Properties.VariableNames, delVar);
    %             posTradingDirect(posTradingDirect.Date == 20181019, colIdx) = array2table(nan(1, length(delVar)));
    %             % ����ط��и�Ǳ�������⣺�ֲ־��������0������ȱʧ����NaN�ʹ����м�λ�ò��಻���������
    % ������Ϊ������������������ֲ������Ȳ��ùܣ����������Ҫ�Ļ��ټ������֣���ʱ�벻��ʲô�������Ҫ���ֵģ���
    
    % дһ�����²�ȫ�ĺ��������뻻���յĳֲֺ�Ŀ���������У���һ��������֮ǰ�Ĳ��ܣ�����Ĳ���
    %         posFullDirect = getfullholding(posTradingDirect, factorData.Date);
    % ��Ϊ������㷨���߼��Ǵ��������ݵĵ�һ�쿪ʼ���֣����������ĳֲ����ھ����������ݵ�����
    % @2018.12.21������MATLAB�Ժ������fillmissing��
    
    posFullDirect = tradingDay;
    posFullDirect = outerjoin(posFullDirect, posTradingDirect, 'type', 'left', 'MergeKeys', true);
    posFullDirect = varfun(@(x) fillmissing(x, 'previous'), posFullDirect);
    posFullDirect.Properties.VariableNames = posTradingDirect.Properties.VariableNames;
    
    % posFullDirectȫΪNaN�޳�
    posFullDirect = delNaN(posFullDirect);
 
    
    posHands = getholdinghands(posTradingDirect, posFullDirect, tradingPara.capital / tradingPara.passway);
    
    targetPortfolio = getMainContName(posHands);
    
    % targetPortfolio��Ҫ��һ��������
    % ��ʼ���մ���û�б�ѡ�й���Ʒ��Ҫ�ߵ���������Ȼ�ز�ʱ��һ��һ��Ʒ�ֲ�ģ��⵽���Ʒ��û��Ū������
 
    [BacktestResult,err] = CTABacktest_GeneralPlatform_3(targetPortfolio,tradingPara);
    %             %         figure
    %                     % ��ֵ����
    %                                 dn = datenum(num2str(BacktestResult.nv(:, 1)), 'yyyymmdd');
    %                                 plot(dn, ((tradingPara.capital / tradingPara.passway)  + ...
    %                                     BacktestResult.nv(:, 2)) ./ (tradingPara.capital / tradingPara.passway))
    %                                 datetick('x', 'yyyymmdd', 'keepticks', 'keeplimits')
    %                                 hold on
    %
    BacktestAnalysis = CTAAnalysis_GeneralPlatform_2(BacktestResult);
    if jPassway == 1
        totalRes(:, [1 2]) = BacktestAnalysis;
    else
        totalRes(:, jPassway + 1) = BacktestAnalysis(:, 2);
    end
    % ��ͬ����ʱ�䣨ͨ�����������ܴ�������Ҫƽ�����޳�����ʱ��Ӱ�������ȶ�
    %         dn = datenum(num2str(BacktestResult.nv(:, 1)), 'yyyymmdd');
    %         plot(dn, (tradingPara.capital + BacktestResult.nv(:, 2)) ./ tradingPara.capital)
    %         datetick('x', 'yyyymmdd', 'keepticks', 'keeplimits')
    %         hold on
    
    % ��ȫ�ز⾻ֵ����
    
    [~, idx0, ~] = intersect(totalBacktestNV(:, 1), BacktestResult.nv(:, 1));
    totalBacktestNV(idx0, jPassway + 1) = BacktestResult.nv(:, 2);
    totalBacktestExposure(idx0, jPassway + 1) = BacktestResult.riskExposure(:, 2);

    
end


%% tradingPara.passway��ͨ���Ľ����ϣ�
% ��������û��fill previous NaN����ΪĬ�Ϻ��治�����NaN��NaN��������passway��һ��ʼ���
% �Ȱ�NaN��0  % Exposure���û���ã��ز�ƽ̨����������⣬����ֻ��Ϊ���ܹ���ͨǿ�м���
totalBacktestNV = arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), totalBacktestNV);
totalBacktestExposure = arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), totalBacktestExposure);

% ����
totalBacktestNV(:, testPassway + 2) = sum(totalBacktestNV(:, 2:end), 2);
totalBacktestExposure(:, testPassway + 2) = sum(totalBacktestExposure(:, 2:end), 2);

totalBacktestResult.nv = totalBacktestNV(:, [1 end]);
totalBacktestResult.nv(:, 3) = [0; diff(totalBacktestResult.nv(:, 2))];
totalBacktestResult.riskExposure = totalBacktestExposure(:, [1 end]);

totalBacktestAnalysis = CTAAnalysis_GeneralPlatform_2(totalBacktestResult);

bcktstRes.nv = totalBacktestResult.nv;
bcktstRes.Analysis = totalBacktestAnalysis;
str = ['save(''E:\Repository\momentum2\sampleOut\bktstRes\result', num2str(factorPara.dateTo), '.mat'', ''bcktstRes'')'];

% resCapital = (tradingPara.capital / tradingPara.passway) * testPassway;
% dn = datenum(num2str(totalBacktestResult.nv(:, 1)), 'yyyymmdd');
% plot(dn, (resCapital + totalBacktestResult.nv(:, 2)) ./ resCapital)
% datetick('x', 'yyyymmdd', 'keepticks', 'keeplimits')
% hold on




