cd 'E:\Repository\momentum2';
addpath getdata getholding newSystem3.0 newSystem3.0\gen_for_BT2 public sampleOut

% 样本外跟踪，数据读取和历史回测数据读取不太一样，其他一样。

%% 读数据
% getBasicData得到一个面板table，包含日期，各品种主力合约每日的复权价格

% global usualPath

usualPath = '\\Cj-lmxue-dt\期货数据2.0\usualData';
dataPath = '\\Cj-lmxue-dt\期货数据2.0\dlyData';
% factorDataPath = 'E:\Repository\momentum\factorData\';

%% 计算因子
% 这种方法不需要计算因子，只是历史遗留问题，先保留了下面的参数:

factorPara.dataPath = [dataPath, '\主力合约']; % getrawprice还是会用到这个参数 计算手数时候用Close，发信号用AdjClose 从getBasicData走不需要这个参数
factorPara.priceType = 'Close';  % 海通和华泰都是复权收盘发信号，主力结算交易；

window = 90;
holdingTime = 60;

tradingPara.groupNum = 5; % 对冲比例10%，20%对应5组
tradingPara.pct = 0.25; % 高波动率筛选的标准，剔除百分位pctATR以下的
tradingPara.capital = 1e8; % 因为要均分60组分批建仓，1000万不够分
% tradePara.futUnitPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\minTickInfo.mat'; %期货最小变动单位
tradingPara.futMainContPath = '\\Cj-lmxue-dt\期货数据2.0\商品期货主力合约代码';
tradingPara.futDataPath = '\\Cj-lmxue-dt\期货数据2.0\dlyData\主力合约'; %期货主力合约数据路径
tradingPara.futUnitPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\minTickInfo.mat'; %期货最小变动单位
tradingPara.futMultiPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\PunitInfo'; %期货合约乘数
tradingPara.PType = 'open'; %交易价格，一般用open（开盘价）或者avg(日均价）
tradingPara.fixC = 0.0002; %固定成本 华泰是单边万五，海通单边万三
tradingPara.slip = 2; %滑点 两家券商都不加滑点

factorPara.dateFrom = 20180301;
% factorPara.dateTo = 20190114;
factorPara.dateTo = str2double(datestr(date(), 'yyyymmdd'));
 

tradingPara.win = window;
tradingPara.holdingTime = holdingTime; % 调仓间隔（持仓日期）
tradingPara.passway = tradingPara.holdingTime;
tradingDay = gettradingday(factorPara.dateFrom, factorPara.dateTo);
if tradingDay.Date(end) < factorPara.dateTo
    error('Stop because Tdays has not been updated.')
end
%         load([factorDataPath, factorName, '\window', num2str(window(iWin)), '.mat']);
%         %% 因子数据筛选：第一：日期
%         factorData = factorData(factorData.Date >= factorPara.dateFrom & ...
%             factorData.Date <= factorPara.dateTo, :);
% 因子数据筛选：第二：流动性
%     每次循环的liquidityInfo时间不一样，与factorData的时间保持一致
%% liquidityInfo和volatilityInfo一次性读取，每个passway从外面复制即可，不要每循环一次获取一次

run('.\sampleOut\dataBind.m')
clear fileName
if totalData.Date(end) < tradingDay.Date(end)
    error('totalData has not been updated to latest.')
end
% 往前更新了2年的数据，因为策略参数窗口比较长，存储长一点数据备用
% 流动性、现货溢价、波动率数据都来自于totalData(每日更新数据合成的)

liquidityInfo = table(totalData.Date, totalData.Variety, totalData.Liquidity, ...
    'VariableNames', {'Date', 'Variety', 'Liquidity'});
liquidityInfo = unstack(liquidityInfo, 'Liquidity', 'Variety');

% % 2019.1.15 已确认liquidityInfo数据和上版本一样
% load('E:\futureData\liquidityInfoHuatai.mat') % 用华泰的流动性筛选标准
% liquidityInfo = liquidityInfoHuatai;
liquidityInfo = liquidityInfo(...
    liquidityInfo.Date >= tradingDay.Date(1) &...
    liquidityInfo.Date <= tradingDay.Date(end), :);
% @2018.12.24 liquidityInfo也要剔除股指和国债期货
% 因子数据筛选：第三：纯商品部分
%         liquidityInfo = delStockBondIdx(liquidityInfo); %% 这一步其实不用，因为Huatai版本已经剔除了股指和国债期货

volatilityInfo = table(totalData.Date, totalData.Variety, totalData.Volatility, ...
    'VariableNames', {'Date', 'Variety', 'Volatility'});
volatilityInfo = unstack(volatilityInfo, 'Volatility', 'Variety');
volatilityInfo = volatilityInfo(...
    volatilityInfo.Date >= tradingDay.Date(1) &...
    volatilityInfo.Date <= tradingDay.Date(end), :);
% % 2019.1.15 已确认volatilityInfo数据和上版本一样
% volatilityInfo = getVolatility(tradingPara.win, tradingPara.pct, tradingDay.Date(1), tradingDay.Date(end), 'sigma');

% @2019.1.15 premium也可以写在外面，因为这是一个时点指标，当天数据计算不涉及过去
premium = table(totalData.Date, totalData.Variety, totalData.Premium, ...
    'VariableNames', {'Date', 'Variety', 'Premium'});
premium = unstack(premium, 'Premium', 'Variety');
premium = premium(...
    premium.Date >= tradingDay.Date(1) & ...
    premium.Date <= tradingDay.Date(end), :);

%% 定义回测汇总结果
testPassway = min(height(tradingDay), tradingPara.passway);

totalRes = num2cell(nan(13, testPassway + 1));
totalBacktestNV = nan(size(tradingDay, 1), testPassway + 1);
totalBacktestExposure = nan(size(tradingDay, 1), testPassway + 1);
%     回测除第一条通道外，后面的日期会缺失一些，需要补齐

totalBacktestNV(:, 1) = tradingDay.Date;
totalBacktestExposure(:, 1) = tradingDay.Date;


%% 每条通道循环测试


for jPassway = 1 : testPassway % 每条通道  比较不同通道下的结果
    
    win = window;
    passway = jPassway;
    
    posTradingDirect = getholdingSampleOut(passway); %得到iWin和jPassway下的换仓日序列持仓方向
    % 2019.1.10 posTradingDirect里面全是NaN的要去掉，不然影响后面计算持仓品种个数，每个的资金分配等
    %             posTradingDirect = delNaN(posTradingDirect);
    %             delVar = {'M', 'P', 'RM', 'ZN', 'ZC', 'MA', 'PP', 'BU', 'NI', 'L', 'RB', 'SR', 'TA', 'HC'};
    %             colIdx = ismember(posTradingDirect.Properties.VariableNames, delVar);
    %             posTradingDirect(posTradingDirect.Date == 20181019, colIdx) = array2table(nan(1, length(delVar)));
    %             % 这个地方有个潜在是问题：持仓矩阵里面的0包含了缺失数据NaN和处于中间位置不多不空两种情况
    % 现在因为不管是哪种情况，不持仓它们先不用管，后期如果需要的话再加以区分（暂时想不到什么情况是需要区分的？）
    
    % 写一个向下补全的函数，输入换仓日的持仓和目标日期序列，第一个换仓日之前的不管，下面的补齐
    %         posFullDirect = getfullholding(posTradingDirect, factorData.Date);
    % 因为后面的算法，逻辑是从因子数据的第一天开始换手，所以完整的持仓日期就是因子数据的日期
    % @2018.12.21更新了MATLAB以后可以用fillmissing了
    
    posFullDirect = tradingDay;
    posFullDirect = outerjoin(posFullDirect, posTradingDirect, 'type', 'left', 'MergeKeys', true);
    posFullDirect = varfun(@(x) fillmissing(x, 'previous'), posFullDirect);
    posFullDirect.Properties.VariableNames = posTradingDirect.Properties.VariableNames;
    
    % posFullDirect全为NaN剔除
    posFullDirect = delNaN(posFullDirect);
 
    
    posHands = getholdinghands(posTradingDirect, posFullDirect, tradingPara.capital / tradingPara.passway);
    
    targetPortfolio = getMainContName(posHands);
    
    % targetPortfolio需要做一个调整：
    % 从始至终从来没有被选中过的品种要踢掉。。（不然回测时是一个一个品种测的，测到这个品种没法弄。。）
 
    [BacktestResult,err] = CTABacktest_GeneralPlatform_3(targetPortfolio,tradingPara);
    %             %         figure
    %                     % 净值曲线
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
    % 不同进场时间（通道）结果差异很大，所以需要平均，剔除进场时间影响结果才稳定
    %         dn = datenum(num2str(BacktestResult.nv(:, 1)), 'yyyymmdd');
    %         plot(dn, (tradingPara.capital + BacktestResult.nv(:, 2)) ./ tradingPara.capital)
    %         datetick('x', 'yyyymmdd', 'keepticks', 'keeplimits')
    %         hold on
    
    % 补全回测净值序列
    
    [~, idx0, ~] = intersect(totalBacktestNV(:, 1), BacktestResult.nv(:, 1));
    totalBacktestNV(idx0, jPassway + 1) = BacktestResult.nv(:, 2);
    totalBacktestExposure(idx0, jPassway + 1) = BacktestResult.riskExposure(:, 2);

    
end


%% tradingPara.passway条通道的结果结合：
% 首先这里没有fill previous NaN，因为默认后面不会出现NaN，NaN都是由于passway在一开始造成
% 先把NaN补0  % Exposure这个没有用，回测平台里计算有问题，这里只是为了能够跑通强行加上
totalBacktestNV = arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), totalBacktestNV);
totalBacktestExposure = arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), totalBacktestExposure);

% 加总
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




