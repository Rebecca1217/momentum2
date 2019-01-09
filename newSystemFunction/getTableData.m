function [TableData,dataType] = getTableData(codeSet,sigDataType,stDate,edDate,mainCont)
% 生成所需数据
% 日频数据:期货、指数、股票
% 高频数据：期货，mainCont:主力合约代码


if nargin==4 %日频数据
    load Z:\baseData\indexList.mat
    if codeSet(1)>700000 %期货
        Fpath = 'Z:\baseData\TableData\futureData';
        if strcmp(sigDataType,'比例后复权')
            adjName = 'adjfactor';
        elseif strcmp(sigDataType,'差值后复权')
            adjName = 'adjfactorABS';
        end
        dataType = 'future';
    elseif ismember(codeSet(1),indexList) %股票指数
        Fpath = 'Z:\baseData\TableData\indexData'; %指数
        adjName = '';
        dataType = 'index';
    else %股票
        Fpath = 'Z:\baseData\TableData\stkData'; %股票
        adjName = 'adjfactor';
        dataType = 'stk';
    end
    
    load([Fpath,'\TableData.mat']) %TableData
    varName = whos('-file',[Fpath,'\TableData.mat']);
    eval(['TableData = ',varName.name,';'])
    % 剔除掉不需要的品种
    TableData(~ismember(TableData.code,codeSet),:) = [];
    % 剔除掉不需要的时间区间
    if isempty(stDate)
        stDate = min(TableData.date);
    end
    TableData(TableData.date<stDate | TableData.date>edDate,:) = [];
    % 复权
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
    % 对data重新排序
    TableData = [TableData(:,{'code';'date';'time'}),TableData(:,~ismember(TableData.Properties.VariableNames,{'code';'date';'time'}))];
    TableData = sortrows(TableData,{'code';'date';'time'});
elseif nargin==5
    fut = regexp(mainCont,'\D*(?=\d)','match');
    load(['U:\期货数据\K线数据RQ\30M\',fut{1},'\',mainCont,'.mat'])
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
    

% 对品种进行流动性判断
if TableData.code(1)>700000
    avgVol = tsmovavg(TableData.volume,'s',20,1);
    nanL = NanL_from_chgCode(TableData.code,19);
    avgVol(nanL) = 0;
    avgVol(isnan(avgVol)) = 0;
    TableData.status = ones(height(TableData),1);
    TableData.status(avgVol<10000) = 0;
end