cd E:\Repository\momentum2
addpath sampleOut getdata public

updDate = str2double(datestr(date(), 'yyyymmdd'));
updDate = 20190116; 
% getDlyData每次更新一天
%% 获取数据

dlyData = getDlyData(updDate);
if isempty(dlyData)
    error('dlyData couldn''t be updated.')
end

%% 存储数据

savePath = 'E:\Repository\momentum2\dlyData\';

save([savePath, num2str(updDate), '.mat'], 'dlyData');


