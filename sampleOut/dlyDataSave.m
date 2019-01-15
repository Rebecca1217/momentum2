addpath E:\Repository\momentum2\sampleOut

updDate = str2double(datestr(date(), 'yyyymmdd'));
% updDate = 20180102; 
% getDlyData每次更新一天
%% 获取数据

dlyData = getDlyData(updDate);

%% 存储数据

savePath = 'E:\Repository\momentum2\dlyData\';

save([savePath, num2str(updDate), '.mat'], 'dlyData');


