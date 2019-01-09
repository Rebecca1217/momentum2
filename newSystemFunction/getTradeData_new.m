function tradeData = getTradeData(futureData,stDate,edDate,tradeP)
% �����õ�����-��ʵ������Լ����
% tdAdj-��¼����ʱ�Ļ��¼۸�
% adjFactor�ı�ĵ�����л��£��þɺ�Լ�Ŀ��̼�ƽ�����º�Լ�Ŀ��̽�
% �������������Լ������
% 20181017���ɽ���������һ�֣�����5���ӵ����۸�ɽ�

tdDate = futureData.Date;
stL = find(tdDate>=stDate,1,'first');
if ~isempty(edDate)
    edL = find(tdDate<=edDate,1,'last');
else
    edL = length(tdDate);
end
tdDate = tdDate(stL:edL);
try
    tmpData = [futureData.Open,futureData.Close,futureData.High,futureData.Low,futureData.Settle,futureData.high5,futureData,low5];
catch
    tmpData = [futureData.Open,futureData.Close,futureData.High,futureData.Low,futureData.Settle];
end
tmpData = tmpData(stL:edL,:);
adjFactor = futureData.adjFactor(:,2); %������Ȩ����
adjFactor = [1;tick2ret(adjFactor)+1];  %���ڵĻ��³���
adjFactor = adjFactor(stL:edL);
chgL = find(futureData.adjFactor(stL:edL,3)==1); %����������
tdAdj = zeros(length(adjFactor),1);
if ~isempty(chgL)
    tdAdj(chgL) = tmpData(chgL,1).*adjFactor(chgL); %�ɺ�Լ�ڻ��µ��յĿ��̼�
end
% ��������
if strcmpi(tradeP,'open')
    tdData = tmpData(:,1);
elseif strcmpi(tradeP,'avg')
    tdData = mean(tmpData(:,1:4),2);
elseif strcmpi(tradeP,'close')
    tdData = tmpData(:,2);
elseif strcmpi(tradeP,'High')
    tdData = tmpData(:,3);
elseif strcmpi(tradeP,'Low')
    tdData = tmpData(:,4);
elseif strcmpi(tradeP,'set')
    tdData = tmpData(:,5);
elseif strcmpi(tradeP,'worst5')
    tdData = tmpData(:,6:7); %����5���ӵ����۸���Ϊ�ɽ��ۣ����ʱ��tdData�����У���һ��Ϊ����5������߼ۣ��ڶ���Ϊ����5������ͼ�
end
ttData = tmpData;

tradeData.tdDate = tdDate;
tradeData.tdData = tdData;
tradeData.tdAdj = tdAdj;
tradeData.ttData = ttData; %���̼�����-��Ϊ���ֹӯֹ��Ҫ�ÿ��̼۳ɽ�