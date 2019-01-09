function res = getBasicData(type)
%GETMAINCONT 得到每天各个品种的主力合约代码
% type 取future或spot，目前future的priceType都是Close，没有需求换别的价格，如有需求也比较容易调整

%% 获取code和name 的对应表
codename = getVarietyCode();
contPath = 'Z:\baseData';
if strcmp(type, 'future')
    %% 获取每天的code
    load([contPath, '\TableData\futureData\TableData.mat'])
    res = table(TableData.date, TableData.code, TableData.volume, TableData.mainCont, ...
        TableData.close, TableData.multifactor, TableData.adjfactor, TableData.atrABS, ...
        'VariableNames', {'Date', 'ContCode', 'Volume', 'MainCont', 'Close', 'MultiFactor', 'AdjFactor', 'ATRABS'});
else % 获取每天的现货数据
    load('\\Cj-lmxue-dt\期货数据2.0\SpotGoodsData_v2\spotData.mat')
    res = table(spotData.date, spotData.code, spotData.v1, ...
        'VariableNames', {'Date', 'ContCode', 'SpotPrice'});
end

%% match到每天的contname
res = outerjoin(res, codename, 'type', 'left', 'MergeKeys', true);

end

