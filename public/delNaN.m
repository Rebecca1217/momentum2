function res = delNaN(inputTable)
%DELNAN ��һ����ʱ�䣬�������������ȫ��NaN�ģ��޳�����

nonNaN = sum(~isnan(table2array(inputTable(:, 2:end))), 2);
nonNaN = nonNaN ~= 0;
res = inputTable(nonNaN, :); % ����������Ȼ���뷱��һ�㣬���ٶȿ죬����Ҫ��arrayfun���ֱ���ѭ���Ķ���

end

