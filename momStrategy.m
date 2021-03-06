cd 'E:\Repository\momentum2';
addpath getdata getholding newSystem3.0 newSystem3.0\gen_for_BT2 public
% @2019.1.9momentum2，新动量单策略收益回撤比1.14（90  60）
% momStrategy.m是第一版回测平台 momStrategy2.m是第二版回测平台


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


% window = [5:5:50 22 60 120 250]; % 计算动量的时间窗口
% window = [5 10 22 60 120 250]; % 华泰测试的动量时间窗口 % 感觉250这个根本没有任何道理，资金平均分成250份一天进一份连1手都买不了。。
% holdingTime = [5 10 22 60 120 250];
% window = 45:5:90; % 这是计算波动率的窗口，和收益率动量因子无关
% holdingTime = 50:5:60;
% window = [30 50 60 90];
% holdingTime = [30 50 60];
window = 90;
holdingTime = 60;

% tradingPara.groupNum = 5; % 对冲比例10%，20%对应5组
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


% dateFromS = [20080101 20090101 20100101 20110101 20120101 20130101 20140101 20150101 20160101 20170101 20180101];
% dateToS = [20081231 20091231 20101231 20111231 20121231 20131231 20141231 20151231 20161231 20171231 20181231];
% dateBacktst = num2cell(nan(13, length(dateFromS) + 1));
% for iDate = 1 : length(dateFromS)
factorPara.dateFrom = 20100101;
factorPara.dateTo = 20181231;

bcktstAnalysis = num2cell(nan(13, length(window) * length(holdingTime) + 1));

for iWin = 1:length(window) % 每个时间窗口
    for kHolding = 1:length(holdingTime)
        
        tradingPara.win = window(iWin);
        tradingPara.holdingTime = holdingTime(kHolding); % 调仓间隔（持仓日期）
                if tradingPara.holdingTime <= 30
                    tradingPara.passwayInterval = 2;
                else
                    tradingPara.passwayInterval = 1;
                end
                tradingPara.passway = floor(tradingPara.holdingTime / tradingPara.passwayInterval); % 通道数
%         tradingPara.passway = tradingPara.holdingTime;
        tradingDay = gettradingday(factorPara.dateFrom, factorPara.dateTo);
        %         load([factorDataPath, factorName, '\ window', num2str(window(iWin)), '.mat']);
        %         %% 因子数据筛选：第一：日期
        %         factorData = factorData(factorData.Date >= factorPara.dateFrom & ...
        %             factorData.Date <= factorPara.dateTo, :);
        %% 因子数据筛选：第二：流动性
        %     每次循环的liquidityInfo时间不一样，与factorData的时间保持一致
        % liquidityInfo和volatilityInfo一次性读取，每个passway从外面复制即可，不要每循环一次获取一次
        load('E:\futureData\liquidityInfoHuatai.mat') % 用华泰的流动性筛选标准
        liquidityInfo = liquidityInfoHuatai;
        liquidityInfo = liquidityInfo(...
            liquidityInfo.Date >= tradingDay.Date(1) &...
            liquidityInfo.Date <= tradingDay.Date(end), :);
        % @2018.12.24 liquidityInfo也要剔除股指和国债期货
        %% 因子数据筛选数据：第三：纯商品部分 波动率数据
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
            
            posTradingDirect = getholding(passway, tradingPara); %得到iWin和jPassway下的换仓日序列持仓方向
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
            %         tst = rowfun(@(x) ~all(isnan(x)), posFullDirect(:, 2:end)); % 这个不行
            % 因为rowfun不是把table的每一行作为一个vector一下子输入函数，而是每行的每个元素一个一个输进去，
            % 所以这么操作会一直提示输入的参数过多，相当于你在输入isnan(1,2,3,4)而不是isnan([1 2 3 4])
            % 函数定义只有一个参数x，而你输入了2:end个参数
            % 而varfun确是每列作为一个vector一次性输入的！坑
            %         tst = arrayfun(@(x) ~all(isnan(table2array(posFullDirect(x,
            %         2:end)))), 1 : size(posFullDirect)); % 这个可以但太慢
            
            % 下面补全持仓手数和主力合约名称
            % 持仓手数和主力合约名称以两个表的形式保存吗？
            % 持仓手数 = (投入本金/持仓品种数)/(合约乘数/ * 价格) 平均分配本金
            % 手数经过最小变动单位向下调整
            
            posHands = getholdinghands(posTradingDirect, posFullDirect, tradingPara.capital / tradingPara.passway);
            
            targetPortfolio = getMainContName(posHands);
            
            % targetPortfolio需要做一个调整：
            % 从始至终从来没有被选中过的品种要踢掉。。（不然回测时是一个一个品种测的，测到这个品种没法弄。。）
            % 不要改回测平台，调整自己输入的targetPortfolio符合回测平台的要求（因为平台不是自己写的，为了保持一致）
            
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
            % 下面几行是用outerjoin做结果汇总：
            %         totalBacktestNV = outerjoin(totalBacktestNV, array2table(BacktestResult.nv(:, 1:2), 'VariableNames', {'Date', 'NV'}), ...
            %             'type', 'left', 'mergekeys', true);
            %         totalBacktestNV.Properties.VariableNames{jPassway + 1} = ['NV', num2str(jPassway)];
            %         totalBacktestExposure = outerjoin(totalBacktestExposure, array2table(BacktestResult.riskExposure(:, 1:2), 'VariableNames', {'Date', 'Exposure'}), ...
            %             'type', 'left', 'mergekeys', true);
            %         totalBacktestExposure.Properties.VariableNames{jPassway + 1} = ['Exposure', num2str(jPassway)];
            
        end
        
        % 修改getMainContName函数后，循环通道速度从1条通道38秒提升到10条通道只需要23秒
        % getpremium增加了时间
        % @2019.01.07一条通道4.41秒，6条通道22.94秒，优化getrawprice读数
        % @2019.01.07getrawprice改为getBasicData读取变慢，一条通道要6.3秒。。还是保留getrawprice
        % 发现原版手数没有按照今日手数表示明日开仓，把这一点调整过来
        
        
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
%
% if iDate == 1
%     dateBacktst(:, [1 2]) = bcktstAnalysis;
% else
%     dateBacktst(:, iDate + 1) = BacktestAnalysis(:, 2);
% end
%
% end
% % 保存新动量结果
% bctNV =  totalBacktestResult.nv;
% bctexp = totalBacktestResult.riskExposure;
% xlswrite('C:\Users\fengruiling\Desktop\bctNV.xlsx', bctNV);
% xlswrite('C:\Users\fengruiling\Desktop\bctexp.xlsx', bctexp);

