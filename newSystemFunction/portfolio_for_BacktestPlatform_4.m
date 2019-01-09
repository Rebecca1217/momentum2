function [BacktestResult,err] = portfolio_for_BacktestPlatform_4(signalData,TableWeight,TableData,TradePara,endday,totalSize,cutLoss)
% ���ɵ��뵽�ز�ƽ̨��Ŀ��ֲ����
% -----------------------�������---------------------------
% signalData�ǳֲ��źţ��Ѿ������˳����ڡ�{'code';'signalDirect';'signalDate';'signalTime';'signalCut'}
% TableWeight��ÿ��Ʒ��ÿ�յ�Ȩ�أ�����Ϊ{'code','time','date','weight'}��Ҳ������ÿ��Ʒ��ÿ�յĳֲ�����������Ϊcode,date,time,hand
% endday�ǻز���ֹ��,double��ȱʡֵΪsignalData��endday
% totalSize�ǿ�������ֵ��ȱʡֵΪ5000w
% TradePara�ǽ��ײ���������·�������׳ɱ�
% ----------------------�������----------------------------
% TargetPortfolio:Ŀ��ֲ֣����������ռ�¼���Ǻ�һ�������յ�Ŀ��ֲ�
% TargetPortfolio:cell,��һ��Ϊ���;�ڶ���ΪĿ����������գ�������Ϊ�����գ���¼���Ǻ�һ��������Ӧ�������ĳֲ�
% TargetPortfolio:�ڶ���cell�е�Ԫ�ذ������У���һ����Ʒ�ִ���(A0809��Ʒ�ִ������ھ�Ϊ4λ����),�ڶ�����Ŀ������(������)
% -----------------------˵��--------------------------------
% ֹ�����cutLoss�ǿգ���������ֹ�����cutLossΪ�գ������ǲ�ֹ��Ҳ�������ռ�ֹ�𣻵������������������TargetPortfolioAdj�ĳֲֶ������У���Լ��������ֹ����
% -------------------------------
% ֻ�������ڻ���ֻ��Ե�Ƶ
% ���㿪��������ʱ�������������İ취
% 20180823:����������ֹ�����������signalData����signalCut�У����������ֹ��
% 20180902:���������ڸ�Ƶ�����
% 20180914:��������������Ʒ�ֵ�ֹ�������ڴ�����ֲ��ж��Ʒ�֡���ֻ�����еĲ��ֲ�Ʒֹ��������������ʽ����TargetPortfolio���е�����ԭ��ֹ�����ڵ����У����ڽ�ֹ����ڵ�һ�еĳֲ�����

if nargin==3
    TradePara = [];
    endday = signalData{end,3};
    totalSize = 50000000;
    cutLoss = [];
elseif nargin==4
    endday = signalData{end,3};
    totalSize = 50000000;
    cutLoss = [];
elseif nargin==5
    totalSize = 50000000;
    cutLoss = [];
end
if isempty(endday)
    endday = signalData{end,3};
end
if isempty(totalSize)
    totalSize = 50000000;
end
    
% �Ը�Ƶ�����ݣ������ڱ�һ�£���һ�������в���
% TableData\TableWeight\signalData��Ӧ�Ÿı�
if TableData.time(1)~=999999999
    dateMark = [(1:height(TableData))',TableData{:,{'date';'time'}}];
    TableData.date = dateMark(:,1);
    TableWeight.date = dateMark(:,1);
    [~,li0] = intersect(dateMark(:,2:3),signalData{:,{'signalDate';'signalTime'}},'rows');
    signalData.signalDate = dateMark(li0,1);
else
    dateMark = [];
end
% �޳������������Ե�Ʒ��
if ~isempty(cutLoss)
    signalData = signalData{:,{'signalDate';'code';'signalDirect';'signalCut'}};
else
    signalData = signalData{:,{'signalDate';'code';'signalDirect'}}; %date,code,direct
end
TableData.tradestatus = TableData.status==1 & TableData.prclim==0; %����������Ļ���Ĭ��Ʒ��ÿ�춼�ǿɽ��׵�״̬
[~,~,li1] = intersect(signalData(:,1:2),[TableData.date,TableData.code],'rows','stable');
signalData(TableData.tradestatus(li1)==0,:) = [];
try %TableWeight������Ȩ�ػ�������
    TableWeight = TableWeight{:,{'date';'code';'weight'}}; %date,code,weight
    wtType = 'weight';
catch
    TableWeight = TableWeight{:,{'date';'code';'hand'}};
    wtType = 'hand';
end
% ��ȡʱ���
signalData(signalData(:,1)>endday,:) = [];
TableWeight(TableWeight(:,1)>endday,:) = [];
% �޳���û���źŷ�����û�з����λ�Ĳ���
signalData(signalData(:,3)==0,:) = [];
TableWeight(TableWeight(:,3)==0,:) = [];
% 
if isempty(signalData)
    BacktestResult = [];
    err =0;
    return;
end
% �Ƚ�Ȩ�ػ���ɿ�������
if strcmp(wtType,'weight')
    if sum(TableWeight(:,3)==1)==size(TableWeight,1)
        TableWeight(:,3) = 1;
    else
        % Ȩ�ػ���ɿ�����ֵ
        TableWeight(:,3) = totalSize.*TableWeight(:,3); 
        % ������ֵ���������
        info = [TableData.date,TableData.code,TableData.multifactor,TableData.close]; %��Լ����,���̼�
        [~,~,interL] = intersect(TableWeight(:,1:2),info(:,1:2),'rows','stable');
        info = info(interL,:);
        TableWeight(:,3) = round(TableWeight(:,3)./(info(:,3).*info(:,4)));
    end
end
% ����Ͽ�����Ϣ
[interD,li0,li1] = intersect(TableWeight(:,1:2),signalData(:,1:2),'rows');
portfolioTmp = [interD,TableWeight(li0,3),signalData(li1,3)]; %date,code,hands,direct
signalData = signalData(li1,:);
% ���ڻ����ִ���ת��ʵ�ʽ��׵ĺ�Լ����
info = [TableData.date,TableData.code];
[~,~,li1] = intersect(portfolioTmp(:,1:2),info,'rows','stable');
mainCont = TableData.mainCont(li1);
% ���ֹ�𣬰�ֹ����Ϣ��ӵ�portfolioTmp�����һ��
if ~isempty(cutLoss)
    [~,li0,li1] = intersect(signalData(:,1:2),portfolioTmp(:,1:2),'rows');
    portfolioTmp(li1,end+1) = signalData(li0,4);
else
    portfolioTmp(:,end+1) = zeros(size(portfolioTmp,1),1);
end

% �����Targetportfolio��ָ����ʽ
% �����Ҫ����ֹ������Ҫ��TargetPortfolio��һ�У��������ֹ����---X
% �ĳɣ������Ҫ����ֹ��ֹ���б����Targetportfolio(:,1)�У������е�Ԫ������һ������ʶ
dateUni = unique(portfolioTmp(:,1));
TargetPortfolio = cell(length(dateUni),2);
TargetPortfolio(:,2) = num2cell(dateUni);
for d = 1:length(dateUni)
    locs = portfolioTmp(:,1)==dateUni(d);
    tmp = portfolioTmp(locs,:);
    hands = tmp(:,3).*tmp(:,4);
    TargetPortfolio{d,1} = [mainCont(locs),num2cell(hands),num2cell(tmp(:,5))];
    portfolioTmp(locs,:) = [];
    mainCont(locs) = [];
end


if TableData.time(1)==999999999
    load Z:\baseData\Tdays\future\Tdays_dly.mat
    dateCalendar = Tdays(:,1);
else
    dateCalendar = dateMark(:,1);
end
totalDate = dateCalendar(find(dateCalendar==dateUni(1),1):find(dateCalendar==dateUni(end)));
TargetPortfolioAdj = cell(length(totalDate),2);
TargetPortfolioAdj(:,2) = num2cell(totalDate);
[~,li0] = intersect(totalDate,cell2mat(TargetPortfolio(:,2)),'stable');
TargetPortfolioAdj(li0,1) = TargetPortfolio(:,1);
if isempty(TradePara)
    if isempty(cutLoss)
        [BacktestResult,err] = CTABacktest_GeneralPlatform_5(TargetPortfolioAdj,dateMark);
    else
        [BacktestResult,err] = CTABacktest_GeneralPlatform_5(TargetPortfolioAdj,dateMark,[],cutLoss);
    end
else
    if isempty(cutLoss)
        [BacktestResult,err] = CTABacktest_GeneralPlatform_5(TargetPortfolioAdj,dateMark,TradePara);
    else
        [BacktestResult,err] = CTABacktest_GeneralPlatform_5(TargetPortfolioAdj,dateMark,TradePara,cutLoss);
    end
end







