cd 'E:\Repository\momentum2';
addpath getdata factorFunction getholding newSystem3.0 newSystem3.0\gen_for_BT2 public

%% ������
% getBasicData�õ�һ�����table���������ڣ���Ʒ��������Լÿ�յĸ�Ȩ�۸�

% global usualPath

usualPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData';
dataPath = '\\Cj-lmxue-dt\�ڻ�����2.0\dlyData';
% factorDataPath = 'E:\Repository\momentum\factorData\';

%% ��������
% ���ַ�������Ҫ�������ӣ�ֻ����ʷ�������⣬�ȱ���������Ĳ���:

factorPara.dataPath = [dataPath, '\������Լ-������Ȩ']; % getrawprice���ǻ��õ��������
factorPara.priceType = 'Close';  % ��ͨ�ͻ�̩���Ǹ�Ȩ���̷��źţ��������㽻�ף�getBasicData�Ժ��������Ҳ�����������źŶ�ֻӰ����������������Ż��Ժ�Ͳ���Ҫ��
% ����getBasicData�Ժ���ʵgetholdinghands�����getrawprice�����Ż�������Ҫȥԭ���ĵط���ȡ�����ˣ��Ƚ���

factorPara.dateFrom = 20100101; 
factorPara.dateTo = 20180331;

% window = [5:5:50 22 60 120 250]; % ���㶯����ʱ�䴰��
% window = [5 10 22 60 120 250]; % ��̩���ԵĶ���ʱ�䴰�� % �о�250�������û���κε������ʽ�ƽ���ֳ�250��һ���һ����1�ֶ����ˡ���
% holdingTime = [5 10 22 60 120 250];
window = [6 90 120 200];
holdingTime = [6 90 120 200];

tradingPara.groupNum = 5; % �Գ����10%��20%��Ӧ5��
tradingPara.pct = 0.25; % �߲�����ɸѡ�ı�׼���޳��ٷ�λpctATR���µ�
tradingPara.capital = 1e8; % ��ΪҪ����60��������֣�1000�򲻹���
% tradePara.futUnitPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\minTickInfo.mat'; %�ڻ���С�䶯��λ
tradingPara.futMainContPath = '\\Cj-lmxue-dt\�ڻ�����2.0\��Ʒ�ڻ�������Լ����';
tradingPara.futDataPath = '\\Cj-lmxue-dt\�ڻ�����2.0\dlyData\������Լ'; %�ڻ�������Լ����·��
tradingPara.futUnitPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\minTickInfo.mat'; %�ڻ���С�䶯��λ
tradingPara.futMultiPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\PunitInfo'; %�ڻ���Լ����
tradingPara.PType = 'open'; %���׼۸�һ����open�����̼ۣ�����avg(�վ��ۣ�
tradingPara.fixC = 0.0003; %�̶��ɱ� ��̩�ǵ������壬��ͨ��������
tradingPara.slip = 0; %���� ����ȯ�̶����ӻ���

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
        load('E:\futureData\liquidityInfoHuatai.mat')
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
            % ����ط��и�Ǳ�������⣺�ֲ־��������0������ȱʧ����NaN�ʹ����м�λ�ò��಻���������
            % ������Ϊ������������������ֲ������Ȳ��ùܣ����������Ҫ�Ļ��ټ������֣���ʱ�벻��ʲô�������Ҫ���ֵģ���
            
            
            %             posTradingDirect = secondSelect(posTradingDirect1);
            
            % дһ�����²�ȫ�ĺ��������뻻���յĳֲֺ�Ŀ���������У���һ��������֮ǰ�Ĳ��ܣ�����Ĳ���
            %         posFullDirect = getfullholding(posTradingDirect, factorData.Date);
            % ��Ϊ������㷨���߼��Ǵ��������ݵĵ�һ�쿪ʼ���֣����������ĳֲ����ھ����������ݵ�����
            % @2018.12.21������MATLAB�Ժ������fillmissing��
            
            posFullDirect = tradingDay;
            posFullDirect = outerjoin(posFullDirect, posTradingDirect, 'type', 'left', 'MergeKeys', true);
            posFullDirect = varfun(@(x) fillmissing(x, 'previous'), posFullDirect);
            posFullDirect.Properties.VariableNames = posTradingDirect.Properties.VariableNames;
            
            % posFullDirectȫΪNaN�޳�
            %         tst = rowfun(@(x) ~all(isnan(x)), posFullDirect(:, 2:end)); % �������
            % ��Ϊrowfun���ǰ�table��ÿһ����Ϊһ��vectorһ�������뺯��������ÿ�е�ÿ��Ԫ��һ��һ�����ȥ��
            % ������ô������һֱ��ʾ����Ĳ������࣬�൱����������isnan(1,2,3,4)������isnan([1 2 3 4])
            % ��������ֻ��һ������x������������2:end������
            % ��varfunȷ��ÿ����Ϊһ��vectorһ��������ģ���
            %         tst = arrayfun(@(x) ~all(isnan(table2array(posFullDirect(x,
            %         2:end)))), 1 : size(posFullDirect)); % ������Ե�̫��
            nonNaN = sum(~isnan(table2array(posFullDirect(:, 2:end))), 2);
            nonNaN = nonNaN ~= 0;
            posFullDirect = posFullDirect(nonNaN, :); % ����������Ȼ���뷱��һ�㣬���ٶȿ죬����Ҫ��arrayfun���ֱ���ѭ���Ķ���
            % ���油ȫ�ֲ�������������Լ����
            % �ֲ�������������Լ����������������ʽ������
            % �ֲ����� = (Ͷ�뱾��/�ֲ�Ʒ����)/(��Լ����/ * �۸�) ƽ�����䱾��
            % ����������С�䶯��λ���µ���
            posHands = getholdinghands(posTradingDirect, posFullDirect, tradingPara.capital / tradingPara.passway);
            
            targetPortfolio = getMainContName(posHands);
            
            % targetPortfolio��Ҫ��һ��������
            % ��ʼ���մ���û�б�ѡ�й���Ʒ��Ҫ�ߵ���������Ȼ�ز�ʱ��һ��һ��Ʒ�ֲ�ģ��⵽���Ʒ��û��Ū������
            % ��Ҫ�Ļز�ƽ̨�������Լ������targetPortfolio���ϻز�ƽ̨��Ҫ����Ϊƽ̨�����Լ�д�ģ�Ϊ�˱���һ�£�
            
            [BacktestResult,err] = CTABacktest_GeneralPlatform_3(targetPortfolio,tradingPara);
            %         figure
            %         % ��ֵ����
            %                     dn = datenum(num2str(BacktestResult.nv(:, 1)), 'yyyymmdd');
            %                     plot(dn, ((tradingPara.capital / tradingPara.passway)  + ...
            %                         BacktestResult.nv(:, 2)) ./ (tradingPara.capital / tradingPara.passway))
            %                     datetick('x', 'yyyymmdd', 'keepticks', 'keeplimits')
            %                     hold on
            
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


