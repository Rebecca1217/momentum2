addpath E:\Repository\momentum2\sampleOut

updDate = str2double(datestr(date(), 'yyyymmdd'));
% updDate = 20180102; 
% getDlyDataÿ�θ���һ��
%% ��ȡ����

dlyData = getDlyData(updDate);

%% �洢����

savePath = 'E:\Repository\momentum2\dlyData\';

save([savePath, num2str(updDate), '.mat'], 'dlyData');


