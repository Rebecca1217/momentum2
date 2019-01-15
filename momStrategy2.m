cd 'E:\Repository\momentum2';
addpath getdata getholding newSystem3.0 newSystem3.0\gen_for_BT2 public newSystemFunction
% @2019.1.9momentum2，更新回测平台后，收益回撤比1.12
% 在新平台下，最终输入落脚点不是targetPortfolio，而是持仓方向矩阵（回测平台里会按金额等权分配）

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


factorPara.dateFrom = 20100101;
factorPara.dateTo = 20180331;

% window = [5:5:50 22 60 120 250]; % 计算动量的时间窗口
% window = [5 10 22 60 120 250]; % 华泰测试的动量时间窗口 % 感觉250这个根本没有任何道理，资金平均分成250份一天进一份连1手都买不了。。
% holdingTime = [5 10 22 60 120 250];
window = [5 10 20 30 60 90 120 200];
holdingTime = [5 10 20 30 60 90 120 200];

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

bcktstAnalysis = num2cell(nan(13, length(window) * length(holdingTime) + 1));

for iWin = 1:length(window) % 每个时间窗口
    for kHolding = 1:length(holdingTime)
        
        tradingPara.win = window(iWin);
        tradingPara.holdingTime = holdingTime(kHolding); % 调仓间隔（持仓日期）
        tradingPara.passway = tradingPara.holdingTime;
        tradingDay = gettradingday(factorPara.dateFrom, factorPara.dateTo);
        %         load([factorDataPath, factorName, '\window', num2str(window(iWin)), '.mat']);
        %         %% 因子数据筛选：第一：日期
        %         factorData = factorData(factorData.Date >= factorPara.dateFrom & ...
        %             factorData.Date <= factorPara.dateTo, :);
        % 因子数据筛选：第二：流动性
        %     每次循环的liquidityInfo时间不一样，与factorData的时间保持一致
        %% liquidityInfo和volatilityInfo一次性读取，每个passway从外面复制即可，不要每循环一次获取一次
        load('E:\futureData\liquidityInfoHuatai.mat') % 用华泰的流动性筛选标准
        liquidityInfo = liquidityInfoHuatai;
        liquidityInfo = liquidityInfo(...
            liquidityInfo.Date >= tradingDay.Date(1) &...
            liquidityInfo.Date <= tradingDay.Date(end), :);
        % @2018.12.24 liquidityInfo也要剔除股指和国债期货
        % 因子数据筛选：第三：纯商品部分
        %         liquidityInfo = delStockBondIdx(liquidityInfo); %% 这一步其实不用，因为Huatai版本已经剔除了股指和国债期货
        
        volatilityInfo = getVolatility(tradingPara.win, tradingPara.pct, tradingDay.Date(1), tradingDay.Date(end), 'sigma');
        %% 定义回测汇总结果
        totalRes = num2cell(nan(13, tradingPara.passway + 1));
        totalBacktestNV = nan(size(tradingDay, 1), tradingPara.passway + 1);
        totalBacktestExposure = nan(size(tradingDay, 1), tradingPara.passway + 1);
        %     回测除第一条通道外，后面的日期会缺失一些，需要补齐
        
        totalBacktestNV(:, 1) = tradingDay.Date;
        totalBacktestExposure(:, 1) = tradingDay.Date;
        
        %     totalBacktestNV = table(factorData.Date, 'VariableNames', {'Date'});
        %     totalBacktestExposure = totalBacktestNV;
        % @2018.12.26 不同通道结果结合，用intersect还是比outerjoin略快一点
        % 10条通道的话，intersect 22.78秒，outerjoin 23.08秒，所以还是用intersect做
        %% 每条通道循环测试

        for jPassway = 1 : tradingPara.passway % 每条通道  比较不同通道下的结果
            
            win = window(iWin);
            passway = jPassway;
            
            posTradingDirect = getholding(passway); %得到iWin和jPassway下的换仓日序列持仓方向
            
            posFullDirect = tradingDay;
            posFullDirect = outerjoin(posFullDirect, posTradingDirect, 'type', 'left', 'MergeKeys', true);
            posFullDirect = varfun(@(x) fillmissing(x, 'previous'), posFullDirect);
            posFullDirect.Properties.VariableNames = posTradingDirect.Properties.VariableNames;
           
            nonNaN = sum(~isnan(table2array(posFullDirect(:, 2:end))), 2);
            nonNaN = nonNaN ~= 0;
            posFullDirect = posFullDirect(nonNaN, :); % 这样操作虽然代码繁琐一点，但速度快，不需要用arrayfun这种本质循环的东西
          
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%以下为新回测平台%%%%%%%%%%%%%%%%%%%%%%
            % @2019.01.09修改，得到每日持仓品种和方向后，即可输入更新回测平台，获取权重，然后直接输入即可
            
            codename = getVarietyCode();
            signalSummary = sigTransform(posFullDirect, codename);
            
            load('sampleSet.mat')
            sampleSetI = eval(['sampleSet.','comF']); %样本集
            TableData = getTableData(sampleSetI,'差值后复权',[],factorPara.dateTo);
            %             TableData = getTableDataHedge(TableData,sampleType{ib});
            
            %             TableWeight = ptfWeight3(TableData,'eqSize');
            % 手数还是用自己计算的手数，调整成TableWeight的格式
            posHands = getholdinghands(posTradingDirect, posFullDirect, tradingPara.capital / tradingPara.passway);
            TableWeight = lotsTransform(posHands, codename);
            
            TradePara.PType = 'open';
            TradePara.float = 2;
            % 回测
            BacktestResult = BacktestPlatform_Comb_2(signalSummary,TableWeight,TableData,'future',TradePara,[],[],[],'out');
            BacktestResult.nv(:, 2) = [];
            BacktestAnalysis = CTAAnalysis_GeneralPlatform_2_new(BacktestResult);
            
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
        totalBacktestNV(:, tradingPara.passway + 2) = sum(totalBacktestNV(:, 2:end), 2);
        totalBacktestExposure(:, tradingPara.passway + 2) = sum(totalBacktestExposure(:, 2:end), 2);
        
        totalBacktestResult.nv = totalBacktestNV(:, [1 end]);
        totalBacktestResult.nv(:, 3) = [0; diff(totalBacktestResult.nv(:, 2))];
        totalBacktestResult.riskExposure = totalBacktestExposure(:, [1 end]);
        
        totalBacktestAnalysis = CTAAnalysis_GeneralPlatform_2(totalBacktestResult);
        
        dn = datenum(num2str(totalBacktestResult.nv(:, 1)), 'yyyymmdd');
        plot(dn, (tradingPara.capital + totalBacktestResult.nv(:, 2)) ./ tradingPara.capital)
        datetick('x', 'yyyymmdd', 'keepticks', 'keeplimits')
        hold on
        if iWin == 1 && kHolding == 1
            bcktstAnalysis(:, [1 2]) = totalBacktestAnalysis;
        else
            bcktstAnalysis(:, (iWin - 1) * length(holdingTime) + kHolding + 1) = ...
                totalBacktestAnalysis(:, 2);
        end
        
    end
end



