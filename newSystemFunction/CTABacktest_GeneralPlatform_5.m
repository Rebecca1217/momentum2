function [BacktestResult,err] = CTABacktest_GeneralPlatform_5(TargetPortfolio,dateMark,TradePara,cutLoss)
% ======================CTA通用回测平台2.0-20180329==============================
% -------------------------输入------------------------------
% TargetPortfolio:目标持仓，当个交易日记录的是后一个交易日的目标持仓
% TargetPortfolio:cell,第一列为组合;第二列为目标组合生成日，生成日为交易日，记录的是后一个交易日应该做到的持仓
% TargetPortfolio:第二列cell中的元素包括两列，第一列是品种代码(A0809),第二列是目标手数(带方向)
% TargetPortfolio中的交易日序列是连续的所有交易日
% TradePara:交易参数，数据路径、交易成本
% -------------------------输出------------------------------
% BacktestResult:回测结果，累计收益、风险敞口、各期持仓
% 20180709:% 1.止盈止损在生成targetportfolio的时候考虑，不在计算收益的时候考虑
% 20180823:增加日内止损的情况;如果日内止损的话，TargetPortfolio有三列，第三列标注需要日内止损的日期，1,0，[]
% 20180902:增加了高频的计算;dateMark:日期序号
% 20180914:改变了TargetPortfolio,持仓cell变成了三列，第三列标明是否要止损
% 20181008:用的合约乘数的数据要调整，不能直接取最近交易日的乘数，要考虑历史上的变化

err = 0;
% 交易参数确定
% 先统一用默认的参数赋值，然后对TradePara提供的参数值进行重新赋值
Cost.fix = 0.0002; %固定成本
Cost.float = 1; %滑点
PType = 'open'; %交易价格
% 交易数据路径
futDataPath = '\\Cj-lmxue-dt\期货数据2.0\dlyData\主力合约';
futUnitPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\minTickInfo.mat';
futMultiPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\PunitInfo';
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

load(futUnitPath) %最小变动单位数据-minTickInfo
% try
%     load([futMultiPath,'\',num2str(TargetPortfolio{end,2}),'.mat']) %合约乘数数据-导入最后一个交易日对应的合约乘数数据
% catch
%     load([futMultiPath,'\20180831.mat'])
% end

% 计算调仓日的日期序列
tradaySeries = cell2mat(TargetPortfolio(:,2)); %目标持仓生成日，交易日
if tradaySeries(1)<10000000
    nextTraday = tradaySeries+1;
else
    nextTraday = get_nextTraday(tradaySeries); %目标持仓对应的调仓日
end
if length(nextTraday)~=length(tradaySeries) %如果调仓日期的数目不等于组合生成日的数目，报错
    fprintf('日期序列有缺失，检查一下dateCalendar！！！\n')
    err = 1;
    return;
end

% 先将TargetPortfolio改成矩阵形式：两个矩阵，一个是信号，一个是持仓,日期和TargetPortfolio是对齐的
[signalMtrx,HoldingMtrx,cutMtrx,fut_variety] = getSigMtrx2(TargetPortfolio);
% 逐个品种测试
signalDate = signalMtrx(:,1);
rtnFut = zeros(size(signalMtrx));
rtnFut(:,1) = signalDate;
riskExposure = zeros(length(signalDate),2); %风险敞口序列，日期、不轧差的敞口
riskExposure(:,1) = signalDate;
for i_fut = 1:length(fut_variety)
    fut = fut_variety{i_fut};
    Cost.unit = minTickInfo{ismember(minTickInfo(:,1),fut),2};
    % 导入对应的合约乘数
    load(futMultiPath,fut)
    PunitInfo = eval([fut,'.PunitInfo']);
    Cost.multi = PunitInfo;
    % 生成所需格式的数据
    % 要将交易数据、信号数据、持仓数据的起止日期对齐
    if isempty(dateMark) %日频
        % 交易数据
        load([futDataPath,'\',fut,'.mat'])
        %%%%%%%%%%%%%%%%%@2019.01.09修改
        endDate = evalin('base', 'factorPara.dateTo');
        tradeData = getTradeData_new(futureData,signalDate(1),endDate,PType);
        % 信号数据
        sigData = getSigData2(signalMtrx(:,[1,i_fut+1]),tradeData.tdDate);
    else %高频
        futCont = TargetPortfolio{cell2mat(TargetPortfolio(:,2))==signalMtrx(1,1),1}{1};
        tradeData = getTradeData_forHFreq(futCont,dateMark,signalDate(1),signalDate(end),PType);
        sigData = getSigData2(signalMtrx(:,[1,i_fut+1]),tradeData.tdDate);
    end
    % 持仓手数数据
    HoldingHandsFut = HoldingMtrx(:,[1,i_fut+1]);
    HoldingHandsFut(HoldingHandsFut(:,2)==0,2) = nan;
    HoldingHandsFut(:,2) = [nan;HoldingHandsFut(1:end-1,2)]; %持仓手数后移了一天，当天的开仓手数与当天的日期对齐了，比如1.2的开仓手数本来记在1.1，现在改成记录在1.2
    HoldingHandsFut = HoldingHandsFut(HoldingHandsFut(:,1)>=tradeData.tdDate(1) & HoldingHandsFut(:,1)<=tradeData.tdDate(end),:);
    % 止损数据
    ctMtrx = cutMtrx(:,[1,i_fut+1]);
    ctMtrx = ctMtrx(ctMtrx(:,1)>=tradeData.tdDate(1) & ctMtrx(:,1)<=tradeData.tdDate(end),:);
    % 计算收益
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

% 日期复原
if ~isempty(dateMark)
    dateList = dateMark(ismember(dateMark(:,1),rtnFut(:,1)),2:3);
else
    dateList = [rtnFut(:,1),999999999*ones(size(rtnFut,1),1)];
end
rtnFut = [dateList,rtnFut(:,2)];
riskExposure = [dateList,riskExposure(:,2)];
nv = [dateList,nv(:,2:3)];
TargetPortfolio = [TargetPortfolio(:,1),num2cell(dateList)];
% 存储结果
BacktestResult.rtnFut = rtnFut;
BacktestResult.fut_variety = fut_variety;
BacktestResult.riskExposure = riskExposure;
BacktestResult.nv = nv;
BacktestResult.TargetPortfolio = TargetPortfolio;
    