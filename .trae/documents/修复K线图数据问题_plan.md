# 修复K线图数据问题

## 问题分析

用户反馈：
- 日线图之前可以获取500条正常的数据，现在改的都有问题了
- 其它的也没改好

原问题：
- 只有日线K线数据是正确的
- 其它时间间隔（1min/5min/15min/30min/60min/week/month/quarter/year）不能正确显示数据

我之前的错误：
- 我把非分钟级别的K线数据也改了，导致它们也不工作了
- 应该只修复分钟级别K线的tradeTime计算问题

## 修复方案

### 1. 恢复 StockKlineService 的 convertToDTO 方法
- 对于非分钟级别的K线，保持原来的行为
- 让数据库中的tradeTime字段保持原样

### 2. 只修复 TdxKlineService 的分钟级别K线时间计算
- 对于分钟级别的K线，正确计算tradeTime
- 对于非分钟级别的K线，保持原来的行为（不设置tradeTime，或者设置为null）

### 3. 移除 StockKlineService 中对非分钟级别K线的删除逻辑
- 这个逻辑会导致数据丢失

## 需要修改的文件

1. `mootdx-server/src/main/java/com/mootdx/server/service/StockKlineService.java`
   - 恢复 convertToDTO 方法
   - 修改 fetchFromTdxAndCache 方法，移除对非分钟级别K线的删除逻辑

2. `mootdx-server/src/main/java/com/mootdx/server/service/TdxKlineService.java`
   - 修复分钟级别K线的时间计算
   - 对于非分钟级别K线，保持原来的行为

## 验证步骤

1. 测试日线数据，确保可以获取500条正常数据
2. 测试5分钟K线数据，确保tradeTime正确
3. 测试周线数据，确保可以正常显示
4. 测试所有其它K线级别
