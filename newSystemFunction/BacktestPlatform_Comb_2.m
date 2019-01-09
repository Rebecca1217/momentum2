function BacktestResult = BacktestPlatform_Comb_2(signal,TableWeight,TableDataI,dataType,TradePara,endday,totalSize,cutLoss,cutType)
% ���ϰ�Ļز�ϵͳ
% �ڻ�����Ʊ��ָ��
% 20181008��
% 1.���Զ��������Խ��лز�
% 2.����ĳֲ���Ϣ����ΪȨ����Ȼ�������


if strcmp(dataType,'future')
    if nargin==4
        BacktestResult = portfolio_for_BacktestPlatform_4(signal,TableWeight,TableDataI);
    elseif nargin==5
        BacktestResult = portfolio_for_BacktestPlatform_4(signal,TableWeight,TableDataI,TradePara);
    else
        if strcmpi(cutType,'in')
            BacktestResult = portfolio_for_BacktestPlatform_4(signal,TableWeight,TableDataI,TradePara,endday,totalSize,cutLoss);
        elseif strcmpi(cutType,'out')
            if isempty(TradePara)
                BacktestResult = portfolio_for_BacktestPlatform_4(signal,TableWeight,TableDataI);
            else
                BacktestResult = portfolio_for_BacktestPlatform_4(signal,TableWeight,TableDataI,TradePara);
            end
        end
    end
end