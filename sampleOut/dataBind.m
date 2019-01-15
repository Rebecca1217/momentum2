% 样本外每日数据合成 用于momStrategySampleOut读取操作

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

% 最后需要把一开始的NaN空行去掉
% 因为自己知道最开始只加了1行NaN，所以就去掉
totalData = totalData(2:end, [end, 1:end-1]);
clear dlyData iDate

