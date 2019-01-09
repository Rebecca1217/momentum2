function [BacktestResult,err] = CTABacktest_GeneralPlatform_5(TargetPortfolio,dateMark,TradePara,cutLoss)
% ======================CTAͨ�ûز�ƽ̨2.0-20180329==============================
% -------------------------����------------------------------
% TargetPortfolio:Ŀ��ֲ֣����������ռ�¼���Ǻ�һ�������յ�Ŀ��ֲ�
% TargetPortfolio:cell,��һ��Ϊ���;�ڶ���ΪĿ����������գ�������Ϊ�����գ���¼���Ǻ�һ��������Ӧ�������ĳֲ�
% TargetPortfolio:�ڶ���cell�е�Ԫ�ذ������У���һ����Ʒ�ִ���(A0809),�ڶ�����Ŀ������(������)
% TargetPortfolio�еĽ��������������������н�����
% TradePara:���ײ���������·�������׳ɱ�
% -------------------------���------------------------------
% BacktestResult:�ز������ۼ����桢���ճ��ڡ����ڳֲ�
% 20180709:% 1.ֹӯֹ��������targetportfolio��ʱ���ǣ����ڼ��������ʱ����
% 20180823:��������ֹ������;�������ֹ��Ļ���TargetPortfolio�����У������б�ע��Ҫ����ֹ������ڣ�1,0��[]
% 20180902:�����˸�Ƶ�ļ���;dateMark:�������
% 20180914:�ı���TargetPortfolio,�ֲ�cell��������У������б����Ƿ�Ҫֹ��
% 20181008:�õĺ�Լ����������Ҫ����������ֱ��ȡ��������յĳ�����Ҫ������ʷ�ϵı仯

err = 0;
% ���ײ���ȷ��
% ��ͳһ��Ĭ�ϵĲ�����ֵ��Ȼ���TradePara�ṩ�Ĳ���ֵ�������¸�ֵ
Cost.fix = 0.0002; %�̶��ɱ�
Cost.float = 1; %����
PType = 'open'; %���׼۸�
% ��������·��
futDataPath = '\\Cj-lmxue-dt\�ڻ�����2.0\dlyData\������Լ';
futUnitPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\minTickInfo.mat';
futMultiPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\PunitInfo';
if ~isempty(TradePara)
    names = fieldnames(TradePara);
    for n = 1:length(names)
        if ismember(names{n},{'fix';'float'})
            eval(['Cost.',names{n},'=TradePara.',names{n},';'])
        else
            eval([names{n},'=TradePara.',names{n},';'])
        end
    end
end
if nargin<=3
    cutLoss = [];
end

load(futUnitPath) %��С�䶯��λ����-minTickInfo
% try
%     load([futMultiPath,'\',num2str(TargetPortfolio{end,2}),'.mat']) %��Լ��������-�������һ�������ն�Ӧ�ĺ�Լ��������
% catch
%     load([futMultiPath,'\20180831.mat'])
% end

% ��������յ���������
tradaySeries = cell2mat(TargetPortfolio(:,2)); %Ŀ��ֲ������գ�������
if tradaySeries(1)<10000000
    nextTraday = tradaySeries+1;
else
    nextTraday = get_nextTraday(tradaySeries); %Ŀ��ֲֶ�Ӧ�ĵ�����
end
if length(nextTraday)~=length(tradaySeries) %����������ڵ���Ŀ��������������յ���Ŀ������
    fprintf('����������ȱʧ�����һ��dateCalendar������\n')
    err = 1;
    return;
end

% �Ƚ�TargetPortfolio�ĳɾ�����ʽ����������һ�����źţ�һ���ǳֲ�,���ں�TargetPortfolio�Ƕ����
[signalMtrx,HoldingMtrx,cutMtrx,fut_variety] = getSigMtrx2(TargetPortfolio);
% ���Ʒ�ֲ���
signalDate = signalMtrx(:,1);
rtnFut = zeros(size(signalMtrx));
rtnFut(:,1) = signalDate;
riskExposure = zeros(length(signalDate),2); %���ճ������У����ڡ�������ĳ���
riskExposure(:,1) = signalDate;
for i_fut = 1:length(fut_variety)
    fut = fut_variety{i_fut};
    Cost.unit = minTickInfo{ismember(minTickInfo(:,1),fut),2};
    % �����Ӧ�ĺ�Լ����
    load(futMultiPath,fut)
    PunitInfo = eval([fut,'.PunitInfo']);
    Cost.multi = PunitInfo;
    % ���������ʽ������
    % Ҫ���������ݡ��ź����ݡ��ֲ����ݵ���ֹ���ڶ���
    if isempty(dateMark) %��Ƶ
        % ��������
        load([futDataPath,'\',fut,'.mat'])
        %%%%%%%%%%%%%%%%%@2019.01.09�޸�
        endDate = evalin('base', 'factorPara.dateTo');
        tradeData = getTradeData_new(futureData,signalDate(1),endDate,PType);
        % �ź�����
        sigData = getSigData2(signalMtrx(:,[1,i_fut+1]),tradeData.tdDate);
    else %��Ƶ
        futCont = TargetPortfolio{cell2mat(TargetPortfolio(:,2))==signalMtrx(1,1),1}{1};
        tradeData = getTradeData_forHFreq(futCont,dateMark,signalDate(1),signalDate(end),PType);
        sigData = getSigData2(signalMtrx(:,[1,i_fut+1]),tradeData.tdDate);
    end
    % �ֲ���������
    HoldingHandsFut = HoldingMtrx(:,[1,i_fut+1]);
    HoldingHandsFut(HoldingHandsFut(:,2)==0,2) = nan;
    HoldingHandsFut(:,2) = [nan;HoldingHandsFut(1:end-1,2)]; %�ֲ�����������һ�죬����Ŀ��������뵱������ڶ����ˣ�����1.2�Ŀ���������������1.1�����ڸĳɼ�¼��1.2
    HoldingHandsFut = HoldingHandsFut(HoldingHandsFut(:,1)>=tradeData.tdDate(1) & HoldingHandsFut(:,1)<=tradeData.tdDate(end),:);
    % ֹ������
    ctMtrx = cutMtrx(:,[1,i_fut+1]);
    ctMtrx = ctMtrx(ctMtrx(:,1)>=tradeData.tdDate(1) & ctMtrx(:,1)<=tradeData.tdDate(end),:);
    % ��������
%     if ~isempty(cutLoss)
%         tdList = calRtnByRealData3(sigData,tradeData,HoldingHandsFut,Cost,ctMtrx,cutLoss);
%     else 
%         tdList = calRtnByRealData2(sigData,tradeData,HoldingHandsFut,Cost);
%     end
    tdList = calRtnByRealData3(sigData,tradeData,HoldingHandsFut,Cost,ctMtrx,cutLoss);
    %
    [~,li0,li1] = intersect(signalDate,tradeData.tdDate);
    rtnFut(li0,i_fut+1) = tdList(li1,5);
    %
    riskExposure(li0,2) = riskExposure(li0,2)+tdList(li1,4).*tradeData.ttData(li1,2);
end

nv = [rtnFut(:,1),cumsum(sum(rtnFut(:,2:end),2)),sum(rtnFut(:,2:end),2)];

% ���ڸ�ԭ
if ~isempty(dateMark)
    dateList = dateMark(ismember(dateMark(:,1),rtnFut(:,1)),2:3);
else
    dateList = [rtnFut(:,1),999999999*ones(size(rtnFut,1),1)];
end
rtnFut = [dateList,rtnFut(:,2)];
riskExposure = [dateList,riskExposure(:,2)];
nv = [dateList,nv(:,2:3)];
TargetPortfolio = [TargetPortfolio(:,1),num2cell(dateList)];
% �洢���
BacktestResult.rtnFut = rtnFut;
BacktestResult.fut_variety = fut_variety;
BacktestResult.riskExposure = riskExposure;
BacktestResult.nv = nv;
BacktestResult.TargetPortfolio = TargetPortfolio;
    