function [BacktestResult,err] = portfolio_for_BacktestPlatform_4(signalData,TableWeight,TableData,TradePara,endday,totalSize,cutLoss)
% 生成导入到回测平台的目标持仓组合
% -----------------------输入参数---------------------------
% signalData是持仓信号，已经考虑了持有期。{'code';'signalDirect';'signalDate';'signalTime';'signalCut'}
% TableWeight是每个品种每日的权重，列名为{'code','time','date','weight'}；也可能是每个品种每日的持仓手数，列名为code,date,time,hand
% endday是回测终止日,double，缺省值为signalData的endday
% totalSize是开仓总市值，缺省值为5000w
% TradePara是交易参数，数据路径、交易成本
% ----------------------输出参数----------------------------
% TargetPortfolio:目标持仓，当个交易日记录的是后一个交易日的目标持仓
% TargetPortfolio:cell,第一列为组合;第二列为目标组合生成日，生成日为交易日，记录的是后一个交易日应该做到的持仓
% TargetPortfolio:第二列cell中的元素包括两列，第一列是品种代码(A0809，品种代码日期均为4位数字),第二列是目标手数(带方向)
% -----------------------说明--------------------------------
% 止损：如果cutLoss非空，进行日内止损；如果cutLoss为空，可能是不止损也可能是日间止损；但是无论是那种情况，TargetPortfolioAdj的持仓都是三列：合约、手数、止损标记
% -------------------------------
% 只适用于期货，只针对低频
% 计算开仓手数的时候采用四舍五入的办法
% 20180823:增加了日内止损的情况，如果signalData包含signalCut列，则进行日内止损
% 20180902:增加上日内高频的情况
% 20180914:增加上针对组合内品种的止损处理，用于处理当天持仓有多个品种、但只有其中的部分产品止损的情况；调整方式：对TargetPortfolio进行调整，原来止损标记在第三列，现在将止损标在第一列的持仓里面

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
    
% 对高频的数据，将日期变一下，看一下这样行不行
% TableData\TableWeight\signalData对应着改变
if TableData.time(1)~=999999999
    dateMark = [(1:height(TableData))',TableData{:,{'date';'time'}}];
    TableData.date = dateMark(:,1);
    TableWeight.date = dateMark(:,1);
    [~,li0] = intersect(dateMark(:,2:3),signalData{:,{'signalDate';'signalTime'}},'rows');
    signalData.signalDate = dateMark(li0,1);
else
    dateMark = [];
end
% 剔除不满足流动性的品种
if ~isempty(cutLoss)
    signalData = signalData{:,{'signalDate';'code';'signalDirect';'signalCut'}};
else
    signalData = signalData{:,{'signalDate';'code';'signalDirect'}}; %date,code,direct
end
TableData.tradestatus = TableData.status==1 & TableData.prclim==0; %如果是套利的话，默认品种每天都是可交易的状态
[~,~,li1] = intersect(signalData(:,1:2),[TableData.date,TableData.code],'rows','stable');
signalData(TableData.tradestatus(li1)==0,:) = [];
try %TableWeight可能是权重或者手数
    TableWeight = TableWeight{:,{'date';'code';'weight'}}; %date,code,weight
    wtType = 'weight';
catch
    TableWeight = TableWeight{:,{'date';'code';'hand'}};
    wtType = 'hand';
end
% 截取时间戳
signalData(signalData(:,1)>endday,:) = [];
TableWeight(TableWeight(:,1)>endday,:) = [];
% 剔除掉没有信号发出和没有分配仓位的部分
signalData(signalData(:,3)==0,:) = [];
TableWeight(TableWeight(:,3)==0,:) = [];
% 
if isempty(signalData)
    BacktestResult = [];
    err =0;
    return;
end
% 先将权重换算成开仓手数
if strcmp(wtType,'weight')
    if sum(TableWeight(:,3)==1)==size(TableWeight,1)
        TableWeight(:,3) = 1;
    else
        % 权重换算成开仓市值
        TableWeight(:,3) = totalSize.*TableWeight(:,3); 
        % 开仓市值换算成手数
        info = [TableData.date,TableData.code,TableData.multifactor,TableData.close]; %合约乘数,收盘价
        [~,~,interL] = intersect(TableWeight(:,1:2),info(:,1:2),'rows','stable');
        info = info(interL,:);
        TableWeight(:,3) = round(TableWeight(:,3)./(info(:,3).*info(:,4)));
    end
end
% 添加上开仓信息
[interD,li0,li1] = intersect(TableWeight(:,1:2),signalData(:,1:2),'rows');
portfolioTmp = [interD,TableWeight(li0,3),signalData(li1,3)]; %date,code,hands,direct
signalData = signalData(li1,:);
% 把期货数字代码转成实际交易的合约代码
info = [TableData.date,TableData.code];
[~,~,li1] = intersect(portfolioTmp(:,1:2),info,'rows','stable');
mainCont = TableData.mainCont(li1);
% 如果止损，把止损信息添加到portfolioTmp的最后一列
if ~isempty(cutLoss)
    [~,li0,li1] = intersect(signalData(:,1:2),portfolioTmp(:,1:2),'rows');
    portfolioTmp(li1,end+1) = signalData(li0,4);
else
    portfolioTmp(:,end+1) = zeros(size(portfolioTmp,1),1);
end

% 整理成Targetportfolio的指定格式
% 如果需要日内止损，则需要对TargetPortfolio加一列，用来标记止损日---X
% 改成：如果需要日内止损，止损列标记在Targetportfolio(:,1)中，对其中的元素增加一列来标识
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







