cd E:\Repository\momentum2
addpath sampleOut getdata public

updDate = str2double(datestr(date(), 'yyyymmdd'));
updDate = 20190116; 
% getDlyDataÿ�θ���һ��
%% ��ȡ����

dlyData = getDlyData(updDate);
if isempty(dlyData)
    error('dlyData couldn''t be updated.')
end

%% �洢����

savePath = 'E:\Repository\momentum2\dlyData\';

save([savePath, num2str(updDate), '.mat'], 'dlyData');


