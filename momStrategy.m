cd 'E:\Repository\momentum2';
addpath getdata getholding newSystem3.0 newSystem3.0\gen_for_BT2 public
% @2019.1.9momentum2���¶�������������س���1.14��90  60��
% momStrategy.m�ǵ�һ��ز�ƽ̨ momStrategy2.m�ǵڶ���ز�ƽ̨


%% ������
% getBasicData�õ�һ�����table���������ڣ���Ʒ��������Լÿ�յĸ�Ȩ�۸�

% global usualPath

usualPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData';
dataPath = '\\Cj-lmxue-dt\�ڻ�����2.0\dlyData';
% factorDataPath = 'E:\Repository\momentum\factorData\';

%% ��������
% ���ַ�������Ҫ�������ӣ�ֻ����ʷ�������⣬�ȱ���������Ĳ���:

factorPara.dataPath = [dataPath, '\������Լ']; % getrawprice���ǻ��õ�������� ��������ʱ����Close�����ź���AdjClose ��getBasicData�߲���Ҫ�������
factorPara.priceType = 'Close';  % ��ͨ�ͻ�̩���Ǹ�Ȩ���̷��źţ��������㽻�ף�


% window = [5:5:50 22 60 120 250]; % ���㶯����ʱ�䴰��
% window = [5 10 22 60 120 250]; % ��̩���ԵĶ���ʱ�䴰�� % �о�250�������û���κε����ʽ�ƽ���ֳ�250��һ���һ����1�ֶ����ˡ���
% holdingTime = [5 10 22 60 120 250];
% window = 45:5:90; % ���Ǽ��㲨���ʵĴ��ڣ��������ʶ��������޹�
% holdingTime = 50:5:60;
% window = [30 50 60 90];
% holdingTime = [30 50 60];
window = 90;
holdingTime = 60;

tradingPara.groupNum = 5; % �Գ����10%��20%��Ӧ5��
tradingPara.pct = 0.25; % �߲�����ɸѡ�ı�׼���޳��ٷ�λpctATR���µ�
tradingPara.capital = 1e8; % ��ΪҪ����60��������֣�1000�򲻹���
% tradePara.futUnitPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\minTickInfo.mat'; %�ڻ���С�䶯��λ
tradingPara.futMainContPath = '\\Cj-lmxue-dt\�ڻ�����2.0\��Ʒ�ڻ�������Լ����';
tradingPara.futDataPath = '\\Cj-lmxue-dt\�ڻ�����2.0\dlyData\������Լ'; %�ڻ�������Լ����·��
tradingPara.futUnitPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\minTickInfo.mat'; %�ڻ���С�䶯��λ
tradingPara.futMultiPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\PunitInfo'; %�ڻ���Լ����
tradingPara.PType = 'open'; %���׼۸�һ����open�����̼ۣ�����avg(�վ��ۣ�
tradingPara.fixC = 0.0002; %�̶��ɱ� ��̩�ǵ������壬��ͨ��������
tradingPara.slip = 2; %���� ����ȯ�̶����ӻ���


% dateFromS = [20080101 20090101 20100101 20110101 20120101 20130101 20140101 20150101 20160101 20170101 20180101];
% dateToS = [20081231 20091231 20101231 20111231 20121231 20131231 20141231 20151231 20161231 20171231 20181231];
% dateBacktst = num2cell(nan(13, length(dateFromS) + 1));
% for iDate = 1 : length(dateFromS)
factorPara.dateFrom = 20180301; 
factorPara.dateTo = 20190114;

bcktstAnalysis = num2cell(nan(13, length(window) * length(holdingTime) + 1));

for iWin = 1:length(window) % ÿ��ʱ�䴰��
    for kHolding = 1:length(holdingTime)
    
        tradingPara.win = window(iWin);
        tradingPara.holdingTime = holdingTime(kHolding); % ���ּ�����ֲ����ڣ�
        tradingPara.passway = tradingPara.holdingTime;
        tradingDay = gettradingday(factorPara.dateFrom, factorPara.dateTo);
        %         load([factorDataPath, factorName, '\window', num2str(window(iWin)), '.mat']);
        %         %% ��������ɸѡ����һ������
        %         factorData = factorData(factorData.Date >= factorPara.dateFrom & ...
        %             factorData.Date <= factorPara.dateTo, :);
        % ��������ɸѡ���ڶ���������
        %     ÿ��ѭ����liquidityInfoʱ�䲻һ������factorData��ʱ�䱣��һ��
        %% liquidityInfo��volatilityInfoһ���Զ�ȡ��ÿ��passway�����渴�Ƽ��ɣ���Ҫÿѭ��һ�λ�ȡһ��
        load('E:\futureData\liquidityInfoHuatai.mat') % �û�̩��������ɸѡ��׼
        liquidityInfo = liquidityInfoHuatai;
        liquidityInfo = liquidityInfo(...
            liquidityInfo.Date >= tradingDay.Date(1) &...
            liquidityInfo.Date <= tradingDay.Date(end), :);
        % @2018.12.24 liquidityInfoҲҪ�޳���ָ�͹�ծ�ڻ�
        % ��������ɸѡ������������Ʒ����
        %         liquidityInfo = delStockBondIdx(liquidityInfo); %% ��һ����ʵ���ã���ΪHuatai�汾�Ѿ��޳��˹�ָ�͹�ծ�ڻ�
        
        volatilityInfo = getVolatility(tradingPara.win, tradingPara.pct, tradingDay.Date(1), tradingDay.Date(end), 'sigma');
        %% ����ز���ܽ��
        totalRes = num2cell(nan(13, tradingPara.passway + 1));
        totalBacktestNV = nan(size(tradingDay, 1), tradingPara.passway + 1);
        totalBacktestExposure = nan(size(tradingDay, 1), tradingPara.passway + 1);
        %     �ز����һ��ͨ���⣬��������ڻ�ȱʧһЩ����Ҫ����
        
        totalBacktestNV(:, 1) = tradingDay.Date;
        totalBacktestExposure(:, 1) = tradingDay.Date;
        
        %     totalBacktestNV = table(factorData.Date, 'VariableNames', {'Date'});
        %     totalBacktestExposure = totalBacktestNV;
        % @2018.12.26 ��ͬͨ�������ϣ���intersect���Ǳ�outerjoin�Կ�һ��
        % 10��ͨ���Ļ���intersect 22.78�룬outerjoin 23.08�룬���Ի�����intersect��
        %% ÿ��ͨ��ѭ������
        
        for jPassway = 1 : tradingPara.passway % ÿ��ͨ��  �Ƚϲ�ͬͨ���µĽ��
          
            win = window(iWin);
            passway = jPassway;
        
            posTradingDirect = getholding(passway); %�õ�iWin��jPassway�µĻ��������гֲַ���
            % 2019.1.10 posTradingDirect����ȫ��NaN��Ҫȥ������ȻӰ��������ֲ�Ʒ�ָ�����ÿ�����ʽ�����
%             posTradingDirect = delNaN(posTradingDirect);
%             delVar = {'M', 'P', 'RM', 'ZN', 'ZC', 'MA', 'PP', 'BU', 'NI', 'L', 'RB', 'SR', 'TA', 'HC'};
%             colIdx = ismember(posTradingDirect.Properties.VariableNames, delVar);
%             posTradingDirect(posTradingDirect.Date == 20181019, colIdx) = array2table(nan(1, length(delVar)));
%             % ����ط��и�Ǳ�������⣺�ֲ־��������0������ȱʧ����NaN�ʹ����м�λ�ò��಻���������
            % ������Ϊ������������������ֲ������Ȳ��ùܣ����������Ҫ�Ļ��ټ������֣���ʱ�벻��ʲô�������Ҫ���ֵģ���
            
            % дһ�����²�ȫ�ĺ��������뻻���յĳֲֺ�Ŀ���������У���һ��������֮ǰ�Ĳ��ܣ�����Ĳ���
            %         posFullDirect = getfullholding(posTradingDirect, factorData.Date);
            % ��Ϊ������㷨���߼��Ǵ��������ݵĵ�һ�쿪ʼ���֣����������ĳֲ����ھ����������ݵ�����
            % @2018.12.21������MATLAB�Ժ������fillmissing��
            
            posFullDirect = tradingDay;
            posFullDirect = outerjoin(posFullDirect, posTradingDirect, 'type', 'left', 'MergeKeys', true);
            posFullDirect = varfun(@(x) fillmissing(x, 'previous'), posFullDirect);
            posFullDirect.Properties.VariableNames = posTradingDirect.Properties.VariableNames;
            
            % posFullDirectȫΪNaN�޳�
            posFullDirect = delNaN(posFullDirect);
            %         tst = rowfun(@(x) ~all(isnan(x)), posFullDirect(:, 2:end)); % �������
            % ��Ϊrowfun���ǰ�table��ÿһ����Ϊһ��vectorһ�������뺯��������ÿ�е�ÿ��Ԫ��һ��һ�����ȥ��
            % ������ô������һֱ��ʾ����Ĳ������࣬�൱����������isnan(1,2,3,4)������isnan([1 2 3 4])
            % ��������ֻ��һ������x������������2:end������
            % ��varfunȷ��ÿ����Ϊһ��vectorһ��������ģ���
            %         tst = arrayfun(@(x) ~all(isnan(table2array(posFullDirect(x,
            %         2:end)))), 1 : size(posFullDirect)); % ������Ե�̫��
            
            % ���油ȫ�ֲ�������������Լ����
            % �ֲ�������������Լ���������������ʽ������
            % �ֲ����� = (Ͷ�뱾��/�ֲ�Ʒ����)/(��Լ����/ * �۸�) ƽ�����䱾��
            % ����������С�䶯��λ���µ���
  
            posHands = getholdinghands(posTradingDirect, posFullDirect, tradingPara.capital / tradingPara.passway);
       
            targetPortfolio = getMainContName(posHands);
           
            % targetPortfolio��Ҫ��һ��������
            % ��ʼ���մ���û�б�ѡ�й���Ʒ��Ҫ�ߵ���������Ȼ�ز�ʱ��һ��һ��Ʒ�ֲ�ģ��⵽���Ʒ��û��Ū������
            % ��Ҫ�Ļز�ƽ̨�������Լ������targetPortfolio���ϻز�ƽ̨��Ҫ����Ϊƽ̨�����Լ�д�ģ�Ϊ�˱���һ�£�
            
            [BacktestResult,err] = CTABacktest_GeneralPlatform_3(targetPortfolio,tradingPara);
%             %         figure
%                     % ��ֵ����
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
            % ��ͬ����ʱ�䣨ͨ�����������ܴ�������Ҫƽ�����޳�����ʱ��Ӱ�������ȶ�
            %         dn = datenum(num2str(BacktestResult.nv(:, 1)), 'yyyymmdd');
            %         plot(dn, (tradingPara.capital + BacktestResult.nv(:, 2)) ./ tradingPara.capital)
            %         datetick('x', 'yyyymmdd', 'keepticks', 'keeplimits')
            %         hold on
            
            % ��ȫ�ز⾻ֵ����
            
            [~, idx0, ~] = intersect(totalBacktestNV(:, 1), BacktestResult.nv(:, 1));
            totalBacktestNV(idx0, jPassway + 1) = BacktestResult.nv(:, 2);
            totalBacktestExposure(idx0, jPassway + 1) = BacktestResult.riskExposure(:, 2);
            % ���漸������outerjoin��������ܣ�
            %         totalBacktestNV = outerjoin(totalBacktestNV, array2table(BacktestResult.nv(:, 1:2), 'VariableNames', {'Date', 'NV'}), ...
            %             'type', 'left', 'mergekeys', true);
            %         totalBacktestNV.Properties.VariableNames{jPassway + 1} = ['NV', num2str(jPassway)];
            %         totalBacktestExposure = outerjoin(totalBacktestExposure, array2table(BacktestResult.riskExposure(:, 1:2), 'VariableNames', {'Date', 'Exposure'}), ...
            %             'type', 'left', 'mergekeys', true);
            %         totalBacktestExposure.Properties.VariableNames{jPassway + 1} = ['Exposure', num2str(jPassway)];
      
        end
        
        % �޸�getMainContName������ѭ��ͨ���ٶȴ�1��ͨ��38��������10��ͨ��ֻ��Ҫ23��
        % getpremium������ʱ��
        % @2019.01.07һ��ͨ��4.41�룬6��ͨ��22.94�룬�Ż�getrawprice����
        % @2019.01.07getrawprice��ΪgetBasicData��ȡ������һ��ͨ��Ҫ6.3�롣�����Ǳ���getrawprice
        % ����ԭ������û�а��ս���������ʾ���տ��֣�����һ���������
        
        
        %% tradingPara.passway��ͨ���Ľ����ϣ�
        % ��������û��fill previous NaN����ΪĬ�Ϻ��治�����NaN��NaN��������passway��һ��ʼ���
        % �Ȱ�NaN��0  % Exposure���û���ã��ز�ƽ̨����������⣬����ֻ��Ϊ���ܹ���ͨǿ�м���
        totalBacktestNV = arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), totalBacktestNV);
        totalBacktestExposure = arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), totalBacktestExposure);
        
        % ����
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
% % �����¶������
% bctNV =  totalBacktestResult.nv;
% bctexp = totalBacktestResult.riskExposure;
% xlswrite('C:\Users\fengruiling\Desktop\bctNV.xlsx', bctNV);
% xlswrite('C:\Users\fengruiling\Desktop\bctexp.xlsx', bctexp);

