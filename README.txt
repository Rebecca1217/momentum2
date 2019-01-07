策略逻辑：华泰：CTA量化策略因子系列（七） 商品动量因子新升级 
波动率和期限结构分别作为分组变量，考察不同组别的传统动量策略表现，发现基本上都是正相关关系；以此为基础，构建新因子替代传统动量。
做多现货溢价且高波动率品种，做空期货溢价且高波动率品种。
策略核心框架涉及代码：
momStrategy.m
第一层循环：iWin，计算波动率的时间窗口
第二层循环：kHolding，换仓周期（持仓时间）
第三层循环：jPassway，建仓时间，与换仓周期一致
最内层循环计算逻辑：getholding，得到iWin和jPassway下的换仓日序列持仓方向；fillmissing填充到posFullDirect；
getholdinghands得到每日持仓方向和手数；getMainContName得到回测平台输入格式的targetPortfolio，输入回测平台即可。
