function tdList = calRtnByRealData3(sigLi,tradeData,HoldingHandsFut,Cost,cutMtrx,cutLoss)
% sig�Ǿ���ֹӯֹ���������ź�
% ����ʵ���׺�Լ�����ݼ���
% ���µ�ʱ��ͳһ�ÿ��̼۽��л���
% ������ֹӯֹ������
% 20180710:
% 1.����ʱ������ƽ�ɺ�Լ��������
% 2.������ֹӯֹ�����������������targetportfolio��ʱ���ǣ��ı�targetportfolio
% 3.�ı����ÿ������ķ�ʽ
% 20180823:
% ��������ֹ��������ֹ������������
% 1.���̼�ֱ��������ֹ������⣬����ֹ��
% 2.���д�����ֹ��ۣ�����ʱֹ��
% 20181017��
% ������һ���µĳɽ��ۣ�����5���ӵ����۸�
% ��������£�tdDataΪ���У���һ������߼ۣ��ڶ�������ͼ�

% ��ʵ��Լ����
tdDate = tradeData.tdDate;
tdData = tradeData.tdData;
if size(tdData,2)==1
    tdData = [tdData,tdData];
end
tdAdj = tradeData.tdAdj; %���µ�ʱ��ɺ�Լ�Ŀ��̼�����
ttData = tradeData.ttData; %������Լ�ļ۸����ݣ�ochls

% ���׳ɱ�
fixC = Cost.fix;
slip = Cost.float;
unit = Cost.unit;
%
HoldingHandsFut = HoldingHandsFut(:,2);

% ��ֹ��������ӵ�sigLi��
% ֹ������sigLi(:,3)�����ж�Ӧ���Ǹ�K�ߣ�������
sigLi(ismember(sigLi(:,3),find(cutMtrx(:,2)==1)+1),4) = 1;
%----------------------------------------------------------------------%
% �ز����
% ��ƽ�֣��󿪲�
% ÿ���ý���۽���
tdList = zeros(length(tdDate),5); %����(������ճֲ֣������б�ǣ������ֲ�����ƽ�ֲ������ֲ�����������ӯ��
if isempty(sigLi) %û�н����ź�
    return;
end
num = sum(sigLi(:,3)<length(tdDate));
if num~=0 %num=0�������ֻ��һ���źţ��Ҹ��źŵ���ֹʱ�仹δ�������߸��ź������һ�з���
    for i = 1:num %����źż���
        opL = sigLi(i,2); %�����ź�������
        clL = sigLi(i,3); %ƽ���ź�������,opL�����һ��sig=0����
        sgn = sigLi(i,1); %���ַ���
        cutIF = sigLi(i,4); %�Ƿ�ֹ��
        HandsI = HoldingHandsFut(opL+1:clL); %ÿ��Ӧ��������
        tdDataI = tdData(opL+1:clL+1,:); %���׼۸�
        tdAdjI = tdAdj(opL+1:clL+1); %�������
        ttDataI = ttData(opL+1:clL+1,:); %������Լ����
        if clL-opL>1 %���ǵ��������¸�ƽ�����
            tdList(opL+1:clL,1) = sgn; %��¼���ַ���������ճ��У����ձ��Ϊ��Ӧ�Ŀ��ַ���
            tdList(opL+1,2) = 2-sgn; %��տ����Ե���Ŀ��̼ۿ���
            tdList(clL,3) = 3-sgn; %���ƽ���Ժ�һ��Ŀ��̼�ƽ��
            tdList(opL+1:clL,4) = HandsI; %ÿ�ճֲ�����
            %
            opP = (tdDataI(1,1.5-0.5*sgn)+sgn*slip*unit)*(1+sgn*fixC); %���ּ�
            HandsAdd = [0;diff(HandsI)]; %�ֲ������ĸı�
            tdList(opL+1,5) = sgn*(ttDataI(1,5)-opP)*tdList(opL+1,4); %������
            setP = ttDataI(1,5); %�����
            cutFail = 0; %�Ƿ�ֹ��ʧ��
            cumProfit = tdList(opL+1,5);
            for d = 2:clL-opL %�������ӯ��
                if cutIF==1 && d==clL-opL %��������Ҫֹ�����һ��
                    lossThr = opP*0.008; %�������ֵ
                    % ���㿪�̵�ʱ����ۼ����棬���жϿ����Ƿ�������ֹ���
                    if tdAdjI(d)~=0 %���ջ��£�ƽ�ɺ�Լ���º�Լ������º�Լ����ʱ���������ֹ��ۣ��Ͳ�����
                        % ƽ�ɺ�Լ��ӯ��
                        clOld = sgn*((tdAdjI(d)-sgn*slip*unit)*(1-sgn*fixC)-setP); %����һ�ֵ����
                        if cumProfit+clOld<-lossThr 
                            pftDly = clOld*tdList(opL+d-1,4); %�����º�Լ
                        else %�ж��Ƿ��º�Լ
                            %��ȷ������ֹ����ֵ���ж���
                            Thrleft = lossThr+cumProfit+clOld;
                            % ����ʣ��Ķ��ȷ��ֹ���
                            cutPrice = tdAdjI(d)-sgn*Thrleft;
                            if sgn*(tdDataI(d,1.5-0.5*sgn)-cutPrice)<=0 %���̼�������ֹ���
                                pftDly = clOld*tdList(opL+d-1,4);
                            else %���º�Լ
                                if sgn==1
                                    spread = cutPrice-ttDataI(d,4);
                                else
                                    spread = cutPrice-ttDataI(d,3);
                                end
                                if sgn*spread<=0 %ֹ��ʧ��
                                    cutFail = 1;
                                    pftDly = 0;
                                else
                                    opNew = sgn*((cutPrice-sgn*slip*unit)*(1-sgn*fixC)-(tdDataI(d,1.5-0.5*sgn)+sgn*slip*unit)*(1+sgn*fixC))*tdList(opL+d,4);
                                    pftDly =clOld*tdList(opL+d-1,4)+opNew;
                                end
                            end
                        end
                    else %���ղ�����
                        % ������
                        Thrleft = lossThr+cumProfit;
                        % ֹ���
                        cutPrice = setP-sgn*Thrleft;
                        if sgn*(tdDataI(d,1.5-0.5*sgn)-cutPrice)<=0 %���̼�������ֹ���
                            % ����ƽ��
                            pftDly = sgn*((tdDataI(d,1.5+0.5*sgn)-sgn*slip*unit)*(1-sgn*fixC)-setP)*tdList(opL+d-1,4);
                        else %����δ����
                            if sgn==1
                                spread = cutPrice-ttDataI(d,4);
                            else
                                spread = cutPrice-ttDataI(d,3);
                            end
                            if sgn*spread<=0 %ֹ��ʧ��
                                cutFail = 1;
                                pftDly = 0;
                            else
                                leaveP = (cutPrice-sgn*slip*unit)*(1-sgn*fixC);
                                if  HandsAdd(d)==0 %����ֲ�����û�б�
                                    pftDly = sgn*(leaveP-setP)*tdList(opL+d-1,4);
                                elseif HandsAdd(d)>0 %��������
                                    pftDly = sgn*(leaveP-setP)*tdList(opL+d-1,4)+sgn*(leaveP-(tdDataI(d,1.5-0.5*sgn)+sgn*slip*unit)*(1+sgn*fixC))*HandsAdd(d);
                                elseif HandsAdd(d)<0 %��������
                                    pftDly = sgn*(leaveP-setP)*tdList(opL+d,4)+sgn*((tdDataI(d,1.5+0.5*sgn)-sgn*slip*unit)*(1-sgn*fixC)-setP)*abs(HandsAdd(d));
                                end
                            end
                        end
                    end     
                    tdList(clL,5) = pftDly;
                end
                if cutIF==0 || (cutIF==1 && d<clL-opL) ||  cutFail==1
                    if tdAdjI(d)~=0 %���ջ��£��Ѿɺ�Լȫ��ƽ����Ȼ�����º�Լ�Ͽ���Ӧ������
                        % ƽ�ɺ�Լ
                        clOld = sgn*((tdAdjI(d)-sgn*slip*unit)*(1-sgn*fixC)-setP)*tdList(opL+d-1,4);
                        % ���º�Լ
                        opNew = sgn*(ttDataI(d,5)-(tdDataI(d,1.5-0.5*sgn)+sgn*slip*unit)*(1+sgn*fixC))*tdList(opL+d,4);
                        pftDly = clOld+opNew;
                        cumProfit = cumProfit+clOld/tdList(opL+d-1,4)+opNew/tdList(opL+d,4);
                    else %���շǻ���
                        if HandsAdd(d)==0 %����ֲ�����û�б�
                            pftDly = sgn*(ttDataI(d,5)-setP)*tdList(opL+d-1,4);
                        elseif HandsAdd(d)>0 %��������
                            pftDly = sgn*(ttDataI(d,5)-setP)*tdList(opL+d-1,4)+sgn*(ttDataI(d,5)-(tdDataI(d,1.5-0.5*sgn)+sgn*slip*unit)*(1+sgn*fixC))*HandsAdd(d);
                        elseif HandsAdd(d)<0 %��������
                            pftDly = sgn*(ttDataI(d,5)-setP)*tdList(opL+d,4)+sgn*((tdDataI(d,1.5+0.5*sgn)-sgn*slip*unit)*(1-sgn*fixC)-setP)*abs(HandsAdd(d));
                        end
                        cumProfit = cumProfit+sgn*(ttDataI(d,5)-setP);
                    end
                    setP = ttDataI(d,5);
                    tdList(opL+d,5) = pftDly; %����ӯ��
                end
            end
            % ƽ��ӯ��
            if cutIF==0 || (cutIF==1 && cutFail==1)
                % ƽ�ּ�
                if tdAdjI(end)~=0 %ƽ���ոպ��ǻ�����,���þ�������Լ�Ŀ��̼�ƽ���������������ƽ�ּ�ƽ
                    clP = (tdAdjI(end)-sgn*slip*unit)*(1-sgn*fixC);
                else
                    clP = (tdDataI(end,1.5+0.5*sgn)-sgn*slip*unit)*(1-sgn*fixC); %��Լ���׼�ƽ
                end
                tdList(clL,5) = tdList(clL,5)+sgn*(clP-setP)*tdList(clL,4); %���һ���¼�˵�������������һ�쿪�̼�ƽ�ֲ�����ƽ������
            end
        elseif clL-opL==1 %���쿪������ƽ���ֲ�ֻ��һ��
            tdList(opL+1,1) = sgn;
            tdList(opL+1,2) = 2-sgn;
            tdList(opL+1,3) = 5.5-0.5*sgn;
            tdList(opL+1,4) = HandsI; %�ֲ�����
            cutFail = 0; 
            %
            opP = (tdDataI(1,1.5-0.5*sgn)+sgn*slip*unit)*(1+sgn*fixC); %���ּ�
            if cutIF==1 %����ֹ��
                cutPrice = opP*(1-sgn*cutLoss);
                tdList(opL+1,5) = sgn*((cutPrice-sgn*slip*unit)*(1-sgn*fixC)-opP)*tdList(opL+1,4); %����
            end
            if cutIF==0 || cutFail==1
                if tdAdjI(end)~=0 %ƽ���ոպ��ǻ�����,���þ�������Լ�Ŀ��̼�ƽ���������������ƽ�ּ�ƽ
                    clP = (tdAdjI(end)-sgn*slip*unit)*(1-sgn*fixC);
                else
                    clP = (tdDataI(end,1.5+0.5*sgn)-sgn*slip*unit)*(1-sgn*fixC); %��Լ���׼�ƽ
                end
                tdList(opL+1,5) = sgn*(clP-opP)*tdList(opL+1,4); %����
            end
        end
    end
end

% ��δ������ź������������
% 1.�����ݽ�β������ƽ���źţ�sigLi�ĵ�����=length(tdDate)
% 2.��ֹ�����ݽ�β��û�з���ƽ���źţ�sigLi�ĵ�����=nan & sigLi�ĵڶ���~=length(tdDate)
% 3.���ݵ����һ�췢���˿����źţ�sigLi�ĵ�����=nan & sigLi�ĵڶ���=length(tdDate)
%
% ��ȷ��һ����û�е������������������У�����ֱ��ɾ�����ź�
sigLi(sigLi(:,2)==length(tdDate) & isnan(sigLi(:,3)),:) = [];
% ��һ��������Ĵ���ʽ��ͬ������û��ƽ��
Locs = find(sigLi(:,3)==length(tdDate) | (isnan(sigLi(:,3)) & sigLi(:,2)~=length(tdDate)));
if ~isempty(Locs)
    opL = sigLi(Locs,2); %�����ź�������
    clL = length(tdDate); %�����ƽ���ź�������
    sgn = sigLi(Locs,1); %���ַ���
    HandsI = HoldingHandsFut(opL+1:clL); %ÿ��Ӧ��������
    tdDataI = tdData(opL+1:clL,:); 
    tdAdjI = tdAdj(opL+1:clL); %�������
    ttDataI = ttData(opL+1:clL,:); %������Լ����
    if clL-opL>1 %���ǵ��������¸�ƽ�����
        tdList(opL+1:clL,1) = sgn; %��¼���ַ���������ճ��У����ձ��Ϊ��Ӧ�Ŀ��ַ���
        tdList(opL+1,2) = 2-sgn; %��տ����Ե���Ŀ��̼ۿ���
        tdList(opL+1:clL,4) = HandsI; %ÿ�ճֲ�����
        %
        opP = (tdDataI(1,1.5-0.5*sgn)+sgn*slip*unit)*(1+sgn*fixC); %���ּ�
        HandsAdd = [0;diff(HandsI)]; %�ֲ������ĸı�
        tdList(opL+1,5) = sgn*(ttDataI(1,5)-opP)*tdList(opL+1,4); %������
        setP = ttDataI(1,5); %�����
        for d = 2:clL-opL %�������ӯ��
            if tdAdjI(d)~=0 %���ջ��£��Ѿɺ�Լȫ��ƽ����Ȼ�����º�Լ�Ͽ���Ӧ������
                % ƽ�ɺ�Լ
                clOld = sgn*((tdAdjI(d)-sgn*slip*unit)*(1-sgn*fixC)-setP)*tdList(opL+d-1,4);
                % ���º�Լ
                opNew = sgn*(ttDataI(d,5)-(tdDataI(d,1.5-0.5*sgn)+sgn*slip*unit)*(1+sgn*fixC))*tdList(opL+d,4);
                pftDly = clOld+opNew;
            else %���շǻ���
                if HandsAdd(d)==0 %����ֲ�����û�б�
                    pftDly = sgn*(ttDataI(d,5)-setP)*tdList(opL+d-1,4);
                elseif HandsAdd(d)>0 %��������
                    pftDly = sgn*(ttDataI(d,5)-setP)*tdList(opL+d-1,4)+sgn*(ttDataI(d,5)-(tdDataI(d,1.5-0.5*sgn)+sgn*slip*unit)*(1+sgn*fixC))*HandsAdd(d);
                elseif HandsAdd(d)<0 %��������
                    pftDly = sgn*(ttDataI(d,5)-setP)*tdList(opL+d,4)+sgn*((tdDataI(d,1.5+0.5*sgn)-sgn*slip*unit)*(1-sgn*fixC)-setP)*abs(HandsAdd(d));
                end
            end
            tdList(opL+d,5) = pftDly; %����ӯ��
            setP = ttDataI(d,5);
        end
    elseif clL-opL==1 %���쿪������ƽ���ֲ�ֻ��һ��,����û��ƽ�ֵ�����
        tdList(opL+1,1) = sgn;
        tdList(opL+1,2) = 2-sgn;
        tdList(opL+1,4) = HandsI; %�ֲ�����
        %
        opP = (tdDataI(1,1.5-0.5*sgn)+sgn*slip*unit)*(1+sgn*fixC); %���ּ�
        tdList(opL+1,5) = sgn*(ttDataI(end,5)-opP)*tdList(opL+1,4); %����
    end
end

% ���Ժ�Լ����
multi = Cost.multi;
[~,~,li1] = intersect(tdDate,multi(:,1),'stable');
multi = multi(li1,:);
tdList(:,5) = tdList(:,5).*multi(:,2);


   



