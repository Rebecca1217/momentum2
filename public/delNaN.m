function res = delNaN(inputTable)
%DELNAN 第一列是时间，后面所有列如果全是NaN的，剔除本行

nonNaN = sum(~isnan(table2array(inputTable(:, 2:end))), 2);
nonNaN = nonNaN ~= 0;
res = inputTable(nonNaN, :); % 这样操作虽然代码繁琐一点，但速度快，不需要用arrayfun这种本质循环的东西

end

