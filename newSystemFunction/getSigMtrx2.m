function [signalMtrx,HoldingMtrx,cutMtrx,futUni] = getSigMtrx2(TargetPortfolio)
% 将TargetPortfolio改成矩阵形式：三个矩阵，一个是信号，一个是持仓，一个是止损


len = cellfun(@(x) size(x,1),TargetPortfolio(:,1)); %每个交易日交易的品种的数目
num = sum(len);
t = 1;
targetTS = cell(num,3);
targetDate = zeros(num,1);
for d = 1:size(TargetPortfolio,1)
%     tmp = TargetPortfolio{d,1};
%     if ~isempty(tmp)
%         targetTS(t:t+len(d)-1,:) = tmp(:,1:2);
%     else
%         targetTS(t:t+len(d)-1,:) = tmp;
%     end
    targetTS(t:t+len(d)-1,:) = TargetPortfolio{d,1};
    targetDate(t:t+len(d)-1) = TargetPortfolio{d,2};
    t = t+len(d);
end
targetTS = sortrows([targetTS,num2cell(targetDate)],1); %品种、手数、止损标记、日期
fut_variety = regexp(targetTS(:,1),'\D*(?=\d)','match'); %品种代码
fut_variety = reshape([fut_variety{:}],size(fut_variety));
targetHD = [cell2mat(targetTS(:,4)),sign(cell2mat(targetTS(:,2))),abs(cell2mat(targetTS(:,2))),cell2mat(targetTS(:,3))]; %date sign hands cutMark-顺序与targetTS对应
%
futUni = unique(fut_variety);
date = cell2mat(TargetPortfolio(:,2));
signalMtrx = [date,zeros(length(date),length(futUni))];
HoldingMtrx = zeros(size(signalMtrx));
HoldingMtrx(:,1) = date;
cutMtrx = zeros(size(signalMtrx));
cutMtrx(:,1) = date;
for i_fut = 1:length(futUni)
    tmp = targetHD(ismember(fut_variety,futUni{i_fut}),:);
    [~,li0,li1] = intersect(tmp(:,1),date);
    signalMtrx(li1,i_fut+1) = tmp(li0,2);
    HoldingMtrx(li1,i_fut+1) = tmp(li0,3);
    cutMtrx(li1,i_fut+1) = tmp(li0,4);
end