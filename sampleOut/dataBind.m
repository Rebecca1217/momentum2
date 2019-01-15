% ������ÿ�����ݺϳ� ����momStrategySampleOut��ȡ����

dataPath = 'E:\Repository\momentum2\dlyData';

dataPath = fullfile(dataPath);
dirOutput = dir(fullfile(dataPath, '*.mat'));
fileName = transpose({dirOutput.name});
% dateUniverse = regexp(fileName, '^\d+', 'match');
% dateUniverse = cellfun(@(x) str2double(x), dateUniverse);


for iDate = 1 : length(fileName)
    
    load([dataPath, '\', fileName{iDate}])
    if iDate == 1
        varNames = dlyData.Properties.VariableNames;
        totalData = array2table(nan(1, width(dlyData)), 'VariableNames', varNames);
    end
   
    totalData = vertcat(totalData, dlyData);
    
end

% �����Ҫ��һ��ʼ��NaN����ȥ��
% ��Ϊ�Լ�֪���ʼֻ����1��NaN�����Ծ�ȥ��
totalData = totalData(2:end, [end, 1:end-1]);
clear dlyData iDate

