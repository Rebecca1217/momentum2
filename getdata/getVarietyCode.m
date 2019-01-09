function codename = getVarietyCode()
%% 获取code和name 的对应表
contPath = 'Z:\baseData';
load([contPath, '\codeBet.mat']);

code = regexp(codeBet,'\w*(?=\.)','match');
code = cellfun(@str2double, code);
name = regexp(codeBet,'(?<=\_).*','match');

codename = table(code, name, 'VariableNames', {'ContCode', 'ContName'});
end


