function [TableData,dataType] = getTableData(codeSet,sigDataType,stDate,edDate,mainCont)
% ������������
% ��Ƶ����:�ڻ���ָ������Ʊ
% ��Ƶ���ݣ��ڻ���mainCont:������Լ����


if nargin==4 %��Ƶ����
    load Z:\baseData\indexList.mat
    if codeSet(1)>700000 %�ڻ�
        Fpath = 'Z:\baseData\TableData\futureData';
        if strcmp(sigDataType,'������Ȩ')
            adjName = 'adjfactor';
        elseif strcmp(sigDataType,'��ֵ��Ȩ')
            adjName = 'adjfactorABS';
        end
        dataType = 'future';
    elseif ismember(codeSet(1),indexList) %��Ʊָ��
        Fpath = 'Z:\baseData\TableData\indexData'; %ָ��
        adjName = '';
        dataType = 'index';
    else %��Ʊ
        Fpath = 'Z:\baseData\TableData\stkData'; %��Ʊ
        adjName = 'adjfactor';
        dataType = 'stk';
    end
    
    load([Fpath,'\TableData.mat']) %TableData
    varName = whos('-file',[Fpath,'\TableData.mat']);
    eval(['TableData = ',varName.name,';'])
    % �޳�������Ҫ��Ʒ��
    TableData(~ismember(TableData.code,codeSet),:) = [];
    % �޳�������Ҫ��ʱ������
    if isempty(stDate)
        stDate = min(TableData.date);
    end
    TableData(TableData.date<stDate | TableData.date>edDate,:) = [];
    % ��Ȩ
    if ~isempty(adjName)
        adjnames = {'open';'close';'high';'low'};
        for n = 1:length(adjnames)
            if strcmp(adjName,'adjfactor')
                eval(['TableData.adj',adjnames{n},' = TableData.',adjnames{n},'.*TableData.',adjName,';'])
            elseif strcmp(adjName,'adjfactorABS')
                eval(['TableData.adj',adjnames{n},' = TableData.',adjnames{n},'+TableData.',adjName,';'])
            end
        end
    else
        TableData.adjopen = TableData.open;
        TableData.adjclose = TableData.close;
        TableData.adjhigh = TableData.high;
        TableData.adjlow = TableData.low;
    end
    % ��data��������
    TableData = [TableData(:,{'code';'date';'time'}),TableData(:,~ismember(TableData.Properties.VariableNames,{'code';'date';'time'}))];
    TableData = sortrows(TableData,{'code';'date';'time'});
elseif nargin==5
    fut = regexp(mainCont,'\D*(?=\d)','match');
    load(['U:\�ڻ�����\K������RQ\30M\',fut{1},'\',mainCont,'.mat'])
    TableData = sortrows(TableData,{'code';'date';'time'});
    adjdata = array2table(TableData{:,{'open';'close';'high';'low'}},'VariableNames',{'adjopen';'adjclose';'adjhigh';'adjlow'});
    TableData = [TableData,adjdata];
    TableData.adjfactorABS = zeros(height(TableData),1);
    TableData.status = ones(height(TableData),1);
    TableData.prclim = zeros(height(TableData),1);
    TableData.mainCont = TableData.cont;
    TableData = TableData(TableData.date<=edDate,:);
    dataType = 'future';
end
    

% ��Ʒ�ֽ����������ж�
if TableData.code(1)>700000
    avgVol = tsmovavg(TableData.volume,'s',20,1);
    nanL = NanL_from_chgCode(TableData.code,19);
    avgVol(nanL) = 0;
    avgVol(isnan(avgVol)) = 0;
    TableData.status = ones(height(TableData),1);
    TableData.status(avgVol<10000) = 0;
end