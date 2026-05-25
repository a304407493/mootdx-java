# Mootdx-Java 项目数据源与Controller架构文档

> 生成日期: 2026-05-12
> 
> 本文档详细梳理了项目中的所有数据源、Controller调用入口以及策略实现，包含具体的类、方法和行号引用，便于验证和修改。

---

## 一、数据源架构总览

### 1.1 数据源类型枚举

**文件位置**: [DataSourceType.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/datasource/DataSourceType.java)

| 数据源类型 | 代码 | 名称 | 描述 | 需要积分 | 付费 |
|-----------|------|------|------|---------|------|
| FREE | FREE | 免费数据源 | 新浪+东方财富 | 0 | 否 |
| SINA | SINA | 新浪财经 | 新浪财经API | 0 | 否 |
| EASTMONEY | EASTMONEY | 东方财富 | 东方财富API | 0 | 否 |
| TENCENT | TENCENT | 腾讯财经 | 腾讯财经API | 0 | 否 |
| TUSHARE_BASIC | TUSHARE_BASIC | Tushare基础版 | Tushare Pro 120积分 | 120 | 否 |
| TUSHARE_PRO | TUSHARE_PRO | Tushare高级版 | Tushare Pro 2000积分 | 2000 | 是 |
| THS | THS | 同花顺 | 同花顺API | 0 | 否 |
| AGGREGATED | AGGREGATED | 聚合数据源 | 多源融合 | 0 | 否 |
| MOOTDX | MOOTDX | mootdx-core | 通达信实时数据接口 | 0 | 否 |

**参考代码** (DataSourceType.java:L15-L50):
```java
public enum DataSourceType {
    FREE("FREE", "免费数据源", "新浪+东方财富", false, 0),
    SINA("SINA", "新浪财经", "新浪财经API", false, 0),
    EASTMONEY("EASTMONEY", "东方财富", "东方财富API", false, 0),
    TENCENT("TENCENT", "腾讯财经", "腾讯财经API", false, 0),
    TUSHARE_BASIC("TUSHARE_BASIC", "Tushare基础版", "Tushare Pro 120积分", false, 120),
    TUSHARE_PRO("TUSHARE_PRO", "Tushare高级版", "Tushare Pro 2000积分", true, 2000),
    // ...
}
```

---

## 二、数据源实现类

### 2.1 数据源接口定义

**文件位置**: [StockDataSource.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/datasource/StockDataSource.java)

所有数据源必须实现此接口 (L8-L67):

| 方法 | 说明 | 行号 |
|------|------|------|
| `getSourceName()` | 获取数据源名称 | L13-L16 |
| `getSourceType()` | 获取数据源类型 | L18-L21 |
| `isAvailable()` | 检查数据源是否可用 | L23-L26 |
| `getPriority()` | 获取数据源优先级 | L28-L31 |
| `getCapability()` | 获取数据源能力描述 | L33-L36 |
| `collect(String)` | 采集单只股票数据 | L38-L44 |
| `collectBatch(List)` | 批量采集股票数据 | L46-L52 |
| `getHealth()` | 获取数据源健康状态 | L54-L62 |

### 2.2 免费数据源适配器

**文件位置**: [FreeDataSourceAdapter.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/datasource/FreeDataSourceAdapter.java)

实现类详情 (L16-L80):

| 属性/方法 | 实现 | 行号 |
|-----------|------|------|
| `freeDataCollectorService` | 自动注入免费数据采集服务 | L20-L21 |
| `getSourceName()` | 返回"免费数据源(新浪+东方财富)" | L24-L27 |
| `getSourceType()` | 返回 `DataSourceType.FREE` | L29-L32 |
| `isAvailable()` | 始终返回true | L34-L38 |
| `getPriority()` | 返回10（优先级较高） | L40-L43 |
| `getCapability()` | 返回免费数据源能力 | L45-L48 |
| `collect(String)` | 调用freeDataCollectorService.collectFullStockData | L50-L59 |
| `collectBatch(List)` | 调用freeDataCollectorService.collectBatchStockData | L61-L71 |

### 2.3 各数据源Service实现

#### 2.3.1 新浪财经数据服务

**文件位置**: [SinaStockDataService.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/SinaStockDataService.java)

| 属性/方法 | 说明 | 行号 |
|-----------|------|------|
| `SINA_API_URL` | API地址: `http://hq.sinajs.cn/list=` | L21 |
| `GBK_CHARSET` | 编码: GBK | L22 |
| `getStockInfo(List)` | 批量查询股票信息 | L32-L87 |
| `buildUrl(List)` | 构建请求URL | L89-L100 |
| `extractPureStockCode(String)` | 提取纯股票代码 | L102-L128 |
| `parseResponse(String)` | 解析响应数据 | L130-L143 |
| `parseLine(String)` | 解析单行数据 | L145-L284 |

**新浪API字段映射** (L165-L250):
- 字段0: 股票名称
- 字段1: 今日开盘价
- 字段2: 昨日收盘价
- 字段3: 当前价
- 字段4: 今日最高价
- 字段5: 今日最低价
- 字段6-7: 竞买价/竞卖价
- 字段8: 成交量（股）
- 字段9: 成交额（元）
- 字段10-27: 买一到买五、卖一到卖五

#### 2.3.2 东方财富数据服务

**文件位置**: [EastMoneyStockDataService.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/EastMoneyStockDataService.java)

API端点: `http://push2.eastmoney.com/api/qt/stock/get`

#### 2.3.3 腾讯财经数据服务

**文件位置**: [TencentStockDataService.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/TencentStockDataService.java)

API端点: `http://qt.gtimg.cn/q=`

#### 2.3.4 Mootdx-Core数据服务

**文件位置**: [MootdxStockDataService.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/MootdxStockDataService.java)

使用本地通达信数据接口

#### 2.3.5 Tushare Pro数据采集服务

**文件位置**: [TushareProCollectorService.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/TushareProCollectorService.java)

API端点: `https://api.tushare.pro`

---

## 三、数据源配置与策略

### 3.1 数据获取配置

**文件位置**: [DataFetchConfig.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/config/DataFetchConfig.java)

配置项详情 (L12-L92):

| 配置项 | 默认值 | 说明 | 行号 |
|--------|--------|------|------|
| `sina` | 200 | 新浪API批量大小 | L19-L20 |
| `eastmoney` | 50 | 东方财富API批量大小 | L22-L23 |
| `tencent` | 100 | 腾讯API批量大小 | L25-L26 |
| `delayMs` | 50 | 批次间延迟（毫秒） | L28-L29 |
| `mode` | BATCH | 查询模式: BATCH/SINGLE/AUTO | L33-L37 |
| `priority` | SINA,EASTMONEY,TENCENT | 数据源优先级 | L39-L42 |
| `enabled` | true | 是否启用降级 | L44-L45 |
| `singleDelayMs` | 100 | 单笔查询延迟 | L47-L48 |

### 3.2 数据源模式配置

**文件位置**: [DataSourceModeConfig.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/config/DataSourceModeConfig.java)

支持7种数据源模式:

#### 3.2.1 基础数据源配置 (L33-L52)

| 数据源 | 批量大小 | 延迟 | 超时 | 重试 | 启用 |
|--------|----------|------|------|------|------|
| 腾讯(TENCENT) | 100 | 50ms | 5000ms | 3 | true |
| 新浪(SINA) | 200 | 50ms | 5000ms | 3 | true |
| 东方财富(EASTMONEY) | 50 | 50ms | 8000ms | 2 | true |
| mootdx | 100 | 0ms | 10000ms | 2 | true |

#### 3.2.2 组合模式配置

**FREE模式** (L82-L111):
- 主数据源: SINA
- 补充数据源: EASTMONEY
- 批量大小: 200
- 查询模式: BATCH

**FALLBACK模式** (L113-L145):
- 优先级: SINA > TENCENT > MOOTDX > EASTMONEY
- 查询模式: BATCH
- 超时: 10000ms
- failFast: false

**AGGREGATED模式** (L147-L194):
- 采集策略: SMART
- 数据源: SINA, TENCENT, MOOTDX, EASTMONEY
- 冲突解决: priority
- 字段优先级: currentPrice->SINA, peRatio->EASTMONEY, pbRatio->EASTMONEY, volume->SINA

**FAST模式** (L196-L230):
- 超时: 3000ms
- 并行请求: true
- firstWins: true
- 数据源: SINA, TENCENT, MOOTDX

---

## 四、数据源路由与策略服务

### 4.1 数据源路由器

**文件位置**: [DataSourceRouter.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/datasource/DataSourceRouter.java)

核心方法 (L47-L500):

| 方法 | 功能 | 行号 |
|------|------|------|
| `init()` | 初始化数据源映射和字段优先级 | L47-L68 |
| `initFieldPriority()` | 初始化字段优先级映射 | L73-L128 |
| `selectBestSource(List, int)` | 选择最佳数据源 | L152-L191 |
| `selectSourcesForComplement(List, int)` | 选择多数据源互补 | L196-L241 |
| `selectSourceForField(String, int)` | 为字段选择最佳数据源 | L246-L268 |
| `getAvailableSources(int)` | 获取所有可用数据源 | L270-L280 |
| `getSource(DataSourceType)` | 获取指定类型数据源 | L282-L286 |
| `calculateMatchScore(StockDataSource, List)` | 计算匹配度分数 | L291-L318 |
| `isFieldSupportedBySource(StockDataSource, String)` | 检查字段支持 | L323-L370 |
| `getRoutingReport(int)` | 获取路由报告 | L375-L410 |
| `getDataSourceProtocols()` | 获取数据源协议详情 | L415-L437 |

**路由策略枚举** (L130-L160):
```java
public enum RouteStrategy {
    SINGLE_BEST,      // 单数据源 - 使用最佳可用数据源
    MULTI_COMPLEMENT, // 多源互补 - 合并多个数据源的数据
    PRIORITY,         // 优先级路由 - 按字段优先级选择数据源
    LOAD_BALANCE,     // 负载均衡 - 分散请求到多个数据源
    FAILOVER          // 故障转移 - 主数据源失败时切换到备用
}
```

### 4.2 降级策略服务

**文件位置**: [FallbackStrategyService.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/datasource/FallbackStrategyService.java)

核心方法 (L29-L302):

| 方法 | 功能 | 行号 |
|------|------|------|
| `getStockInfo(List)` | 主入口：获取股票信息 | L46-L86 |
| `getStockInfoBatch(List, List)` | 批量查询模式 | L91-L155 |
| `getStockInfoSingle(List, List)` | 单笔查询模式 | L180-L269 |
| `fetchFromSource(String, List)` | 从指定数据源获取数据 | L271-L286 |
| `getBatchSizeForSource(String)` | 获取数据源批量大小 | L157-L171 |
| `enrichData(List, List)` | 补充缺失字段数据 | L288-L296 |

**降级策略执行流程**:
1. 根据mode选择查询方式 (BATCH/SINGLE/AUTO)
2. AUTO模式下，股票数<=10使用单笔，>10使用批量
3. 按优先级顺序尝试各数据源
4. 成功获取数据后计算派生字段
5. 所有数据源失败返回空结果

### 4.3 聚合数据采集服务

**文件位置**: [AggregatedDataCollectorService.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/datasource/AggregatedDataCollectorService.java)

采集策略枚举 (L36-L55):
```java
public enum CollectionStrategy {
    FASTEST,      // 最快优先 - 使用第一个返回的数据
    MOST_COMPLETE, // 最全优先 - 合并所有数据源的数据
    FREE_FIRST,   // 免费优先 - 优先使用免费数据源
    SMART         // 智能路由 - 根据字段需求自动选择
}
```

核心方法 (L57-L381):

| 方法 | 功能 | 行号 |
|------|------|------|
| `collect(String, CollectionStrategy)` | 单只股票采集 | L64-L90 |
| `collectBatch(List, CollectionStrategy)` | 批量采集 | L92-L114 |
| `collectFastest(String, int)` | 最快优先采集 | L119-L154 |
| `collectMostComplete(String, int)` | 最全优先采集 | L159-L204 |
| `collectFreeFirst(String, int)` | 免费优先采集 | L206-L226 |
| `collectSmart(String, int)` | 智能采集 | L228-L234 |
| `collectBatchMostComplete(List, int)` | 批量最全采集 | L239-L282 |
| `collectWithFields(String, List)` | 按需字段采集 | L287-L337 |

### 4.4 数据合并服务

**文件位置**: [DataMergeService.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/datasource/DataMergeService.java)

核心功能 (L16-L553):

| 方法 | 功能 | 行号 |
|------|------|------|
| `initFieldPriority()` | 初始化字段优先级 | L25-L165 |
| `merge(String, Map)` | 合并多数据源数据 | L170-L210 |
| `mergeBatch(Map)` | 批量合并 | L215-L232 |
| `selectBestValue(String, Map)` | 选择最佳字段值 | L237-L257 |
| `calculateDerivedFields(StockInfoDTO)` | 计算派生字段 | L308-L350 |
| `calculateVolumeDiffFields(StockInfoDTO)` | 计算成交量差值 | L352-L405 |
| `calculateVolumeRatioFields(StockInfoDTO)` | 计算成交量百分比 | L407-L453 |

**字段优先级配置** (L25-L165):
- 实时行情字段: FREE > TUSHARE_BASIC > TUSHARE_PRO
- 五档盘口: 仅FREE支持
- 历史涨跌幅: TUSHARE_BASIC > TUSHARE_PRO > FREE
- 财务数据: 仅TUSHARE_PRO支持

### 4.5 统一数据源服务

**文件位置**: [UnifiedDataSourceService.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/datasource/UnifiedDataSourceService.java)

核心方法 (L19-L250):

| 方法 | 功能 | 行号 |
|------|------|------|
| `getStockInfo(String, List)` | 统一入口 | L42-L71 |
| `getStockInfoBatch(String, List)` | 批量查询 | L76-L138 |
| `getStockInfoSingle(String, List)` | 单笔查询 | L165-L226 |
| `getBatchSizeForSource(String)` | 获取批量大小 | L140-L155 |

---

## 五、Controller调用入口

### 5.1 javaTdx模块Controller

#### 5.1.1 数据源模式配置控制器

**文件位置**: [DataSourceModeConfigController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/DataSourceModeConfigController.java)

**基础路径**: `/api/datasource-mode`

| 端点 | 方法 | 功能 | 行号 |
|------|------|------|------|
| `GET /overview` | `getOverview()` | 获取所有模式配置概览 | L103-L138 |
| `GET /config/{mode}` | `getModeConfig(String)` | 获取指定模式详细配置 | L143-L190 |
| `POST /global/mode` | `setGlobalMode(String)` | 更新全局查询模式 | L195-L218 |
| `POST /global/default-source` | `setDefaultSource(String)` | 更新默认数据源 | L223-L245 |
| `POST /source/{source}/config` | `updateSourceConfig(...)` | 更新基础数据源配置 | L250-L326 |
| `POST /free/config` | `updateFreeConfig(...)` | 更新FREE模式配置 | L331-L415 |
| `POST /fallback/config` | `updateFallbackConfig(...)` | 更新FALLBACK模式配置 | L420-L500+ |

#### 5.1.2 降级策略配置控制器

**文件位置**: [FallbackConfigController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/FallbackConfigController.java)

**基础路径**: `/api/fallback`

| 端点 | 方法 | 功能 | 行号 |
|------|------|------|------|
| `GET /config` | `getConfig()` | 获取当前降级策略配置 | L38-L52 |
| `POST /mode` | `setMode(String)` | 更新查询模式 | L57-L73 |
| `POST /priority` | `setPriority(String)` | 更新数据源优先级 | L78-L96 |
| `POST /batch-size` | `setBatchSize(String, int)` | 更新批量大小 | L101-L125 |
| `POST /delay` | `setDelay(Integer, Integer)` | 更新延迟配置 | L130-L146 |
| `POST /enable` | `setEnabled(boolean)` | 启用/禁用降级 | L151-L160 |
| `GET /test` | `testFallback(String)` | 测试降级策略 | L165-L200 |
| `POST /reset` | `resetConfig()` | 重置为默认配置 | L205-L221 |
| `GET /logs` | `getLogs(int)` | 获取执行日志 | L226-L232 |
| `POST /logs/clear` | `clearLogs()` | 清空执行日志 | L237-L243 |

#### 5.1.3 数据源配置控制器

**文件位置**: [DataSourceConfigController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/DataSourceConfigController.java)

**基础路径**: `/api/datasource`

| 端点 | 方法 | 功能 | 行号 |
|------|------|------|------|
| `GET /configs` | `getAllConfigs()` | 获取所有数据源配置 | L28-L38 |
| `GET /default` | `getDefaultConfig()` | 获取默认数据源配置 | L40-L50 |
| `POST /set-default/{id}` | `setDefaultConfig(Long)` | 设置默认数据源 | L52-L68 |
| `POST /toggle-active/{id}` | `toggleActive(Long)` | 切换数据源状态 | L70-L86 |
| `PUT /update/{id}` | `updateConfig(Long, DTO)` | 更新数据源配置 | L88-L104 |
| `GET /field-mapping` | `getFieldDataSourceMapping()` | 获取字段数据源映射 | L109-L157 |
| `GET /protocols` | `getDataSourceProtocols()` | 获取数据源协议详情 | L162-L178 |
| `GET /test/{sourceType}` | `testDataSource(String, String)` | 测试数据源 | L183-L197 |

#### 5.1.4 股票信息控制器

**文件位置**: [StockInfoController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/StockInfoController.java)

**基础路径**: `/api/stock`

| 端点 | 方法 | 功能 | 行号 |
|------|------|------|------|
| `GET /info` | `getStockInfo(String)` | 获取股票信息 | L21-L36 |

**调用链路**:
```
StockInfoController.getStockInfo() 
  -> StockDataService.getStockInfo()
    -> 根据defaultSource选择策略
      -> UnifiedDataSourceService / FallbackStrategyService / AggregatedDataCollectorService
```

#### 5.1.5 免费数据采集控制器

**文件位置**: [DataCollectorController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/DataCollectorController.java)

**基础路径**: `/api/collector`

| 端点 | 方法 | 功能 | 行号 |
|------|------|------|------|
| `GET /stock/{stockCode}` | `collectStockData(String)` | 采集单只股票数据 | L28-L48 |
| `GET /stocks` | `collectBatchStockData(String)` | 批量采集股票数据 | L53-L77 |
| `GET /test` | `testCollect()` | 测试采集热门股票 | L82-L97 |

#### 5.1.6 Tushare数据采集控制器

**文件位置**: [TushareDataController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/TushareDataController.java)

**基础路径**: `/api/tushare`

| 端点 | 方法 | 功能 | 行号 |
|------|------|------|------|
| `GET /status` | `checkStatus()` | 检查Tushare配置状态 | L27-L35 |
| `GET /collect/{stockCode}` | `collectStockData(String)` | 采集单只股票数据 | L40-L58 |
| `POST /collect/batch` | `collectBatchStockData(Map)` | 批量采集股票数据 | L63-L84 |
| `GET /test` | `testCollect()` | 测试采集接口 | L89-L94 |
| `GET /coverage` | `getCoverage()` | 获取数据覆盖范围 | L99-L151 |

### 5.2 其他Controller列表

| Controller | 文件路径 | 基础路径 | 主要功能 |
|-----------|----------|----------|----------|
| TdxDataImportController | [javaTdx/.../TdxDataImportController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/TdxDataImportController.java) | `/api/tdx-import` | 通达信数据导入 |
| TdxServerController | [javaTdx/.../TdxServerController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/TdxServerController.java) | `/api/servers` | 服务器管理 |
| StockPositionController | [javaTdx/.../StockPositionController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/StockPositionController.java) | `/api/positions` | 持仓管理 |
| TradePlatformController | [javaTdx/.../TradePlatformController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/TradePlatformController.java) | `/api/platforms` | 交易平台管理 |
| StockKlineController | [javaTdx/.../StockKlineController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/StockKlineController.java) | `/api/kline` | K线数据查询 |
| DataSourceMonitorController | [javaTdx/.../DataSourceMonitorController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/DataSourceMonitorController.java) | `/api/datasource-monitor` | 数据源监控 |
| FeaturedBlockController | [javaTdx/.../FeaturedBlockController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/FeaturedBlockController.java) | `/api/featured-blocks` | 特色板块管理 |
| FeaturedBlockGroupController | [javaTdx/.../FeaturedBlockGroupController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/FeaturedBlockGroupController.java) | `/api/featured-block-groups` | 板块分组管理 |
| BlockBackupController | [javaTdx/.../BlockBackupController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/BlockBackupController.java) | `/api/block-backup` | 板块备份管理 |
| BlockController | [javaTdx/.../BlockController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/BlockController.java) | `/api/blocks` | 板块管理 |
| BlockWatchController | [javaTdx/.../BlockWatchController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/BlockWatchController.java) | `/api/block-watch` | 板块监控 |
| SystemConfigController | [javaTdx/.../SystemConfigController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/SystemConfigController.java) | `/api/system-config` | 系统配置 |
| TdxPathConfigController | [javaTdx/.../TdxPathConfigController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/TdxPathConfigConfigController.java) | `/api/tdx-path` | 通达信路径配置 |

### 5.3 mootdx-server模块Controller

| Controller | 文件路径 | 基础路径 | 主要功能 |
|-----------|----------|----------|----------|
| TdxDataImportController | [mootdx-server/.../TdxDataImportController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/mootdx-server/src/main/java/com/mootdx/server/controller/TdxDataImportController.java) | `/api/tdx-import` | 通达信数据导入 |
| StockKlineController | [mootdx-server/.../StockKlineController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/mootdx-server/src/main/java/com/mootdx/server/controller/StockKlineController.java) | `/api/kline` | K线数据查询 |
| TdxServerController | [mootdx-server/.../TdxServerController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/mootdx-server/src/main/java/com/mootdx/server/controller/TdxServerController.java) | `/api/servers` | 服务器管理 |
| F10ParserController | [mootdx-server/.../F10ParserController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/mootdx-server/src/main/java/com/mootdx/server/controller/F10ParserController.java) | `/api/f10` | F10数据解析 |
| SchedulerController | [mootdx-server/.../SchedulerController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/mootdx-server/src/main/java/com/mootdx/server/controller/SchedulerController.java) | `/api/scheduler` | 定时任务管理 |
| StockThemeController | [mootdx-server/.../StockThemeController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/mootdx-server/src/main/java/com/mootdx/server/controller/StockThemeController.java) | `/api/themes` | 题材管理 |
| StockNoteController | [mootdx-server/.../StockNoteController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/mootdx-server/src/main/java/com/mootdx/server/controller/StockNoteController.java) | `/api/notes` | 笔记管理 |
| DbManagerController | [mootdx-server/.../DbManagerController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/mootdx-server/src/main/java/com/mootdx/server/controller/DbManagerController.java) | `/api/db` | 数据库管理 |
| StockTagController | [mootdx-server/.../StockTagController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/mootdx-server/src/main/java/com/mootdx/server/controller/StockTagController.java) | `/api/tags` | 标签管理 |

---

## 六、策略总结

### 6.1 数据源选择策略

**文件位置**: [StockDataService.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/StockDataService.java)

主入口方法 `getStockInfo(List)` (L44-L86):

```java
public List<StockInfoDTO> getStockInfo(List<String> stockCodes) {
    String sourceType = dataSourceModeConfig.getDefaultSource();
    
    switch (sourceType.toUpperCase()) {
        case "TENCENT":
            return unifiedDataSourceService.getStockInfo("TENCENT", stockCodes);
        case "SINA":
            return unifiedDataSourceService.getStockInfo("SINA", stockCodes);
        case "EASTMONEY":
            return unifiedDataSourceService.getStockInfo("EASTMONEY", stockCodes);
        case "MOOTDX":
            return unifiedDataSourceService.getStockInfo("MOOTDX", stockCodes);
        case "FREE":
            return getStockInfoFromFreeCollectorWithMode(stockCodes);
        case "FALLBACK":
            return fallbackStrategyService.getStockInfo(stockCodes);
        case "COMBINED":
        case "AGGREGATED":
            return getStockInfoFromAggregatedWithMode(stockCodes, CollectionStrategy.MOST_COMPLETE);
        case "FAST":
            return getStockInfoFromAggregatedWithMode(stockCodes, CollectionStrategy.FASTEST);
        default:
            return getStockInfoFromAggregatedWithMode(stockCodes, CollectionStrategy.SMART);
    }
}
```

### 6.2 查询模式策略

**AUTO模式逻辑** (DataFetchConfig.java:L74-L82):
```java
public boolean isAutoMode() {
    return "AUTO".equalsIgnoreCase(mode);
}
```

**自动选择逻辑** (StockDataService.java:L200-L210):
```java
// AUTO模式：根据股票数量自动选择
if (stockCodes.size() <= 10) {
    // 股票数量 <= 10，使用单笔查询
    return getStockInfoFromAggregatedSingle(stockCodes, strategy);
} else {
    // 股票数量 > 10，使用批量查询
    return getStockInfoFromAggregatedBatch(stockCodes, strategy);
}
```

### 6.3 降级策略执行流程

**文件位置**: [FallbackStrategyService.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/datasource/FallbackStrategyService.java)

执行流程 (L46-L86):

1. **获取配置**: 从DataFetchConfig获取mode和priority
2. **模式选择**: 
   - SINGLE -> 执行单笔查询
   - BATCH -> 执行批量查询  
   - AUTO -> 根据股票数量自动选择
3. **数据源尝试**: 按优先级顺序尝试各数据源
4. **成功返回**: 任一数据源成功即返回
5. **失败处理**: 所有数据源失败返回空结果

**批量查询流程** (L91-L155):
```
对于每个数据源:
  1. 获取批量大小配置
  2. 分批查询（批次间延迟）
  3. 成功则计算派生字段并返回
  4. 失败则尝试下一个数据源
```

**单笔查询流程** (L180-L269):
```
对于每只股票:
  1. 按优先级尝试各数据源
  2. 记录API调用次数
  3. 成功获取则跳出循环
  4. 所有数据源失败创建空对象
  5. 单笔延迟后继续下一只
```

### 6.4 多源融合策略

**文件位置**: [AggregatedDataCollectorService.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/datasource/AggregatedDataCollectorService.java)

**最快优先策略** (L119-L154):
```
1. 并行采集所有可用数据源
2. 获取第一个成功的结果
3. 超时时间为5秒
4. 计算派生字段后返回
```

**最全优先策略** (L159-L204):
```
1. 并行采集所有可用数据源
2. 等待所有采集完成（超时10秒）
3. 使用DataMergeService合并数据
4. 按字段优先级选择最佳值
```

**免费优先策略** (L206-L226):
```
1. 首先尝试免费数据源
2. 失败则使用最快优先策略
```

**智能策略** (L228-L234):
```
默认使用最全优先策略
```

### 6.5 数据合并策略

**文件位置**: [DataMergeService.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/datasource/DataMergeService.java)

**字段优先级规则** (L25-L165):

| 字段类别 | 优先级顺序 |
|----------|-----------|
| 实时行情(currentPrice等) | FREE > TUSHARE_BASIC > TUSHARE_PRO |
| 五档盘口(buy1Price等) | 仅FREE |
| 估值指标(peRatio等) | FREE > TUSHARE_PRO |
| 历史涨跌幅(yesterdayChange等) | TUSHARE_BASIC > TUSHARE_PRO > FREE |
| 财务数据(netProfitAfterDeduction) | 仅TUSHARE_PRO |
| 行业分类(subIndustry) | TUSHARE_BASIC > TUSHARE_PRO > FREE |

**合并流程** (L170-L210):
```
1. 创建新的StockInfoDTO对象
2. 遍历所有字段
3. 根据fieldPriority选择最佳值
4. 计算派生字段
5. 返回合并后的对象
```

**派生字段计算** (L308-L350):
- 开盘涨跌幅: `(开盘价 - 昨收价) / 昨收价 × 100%`
- 涨停价: `昨收价 × 1.10`
- 跌停价: `昨收价 × 0.90`
- PE/PB字段统一
- 市值字段统一

### 6.6 免费数据源采集策略

**文件位置**: [StockDataService.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/StockDataService.java)

**免费采集方案** (L232-L276):
```
步骤1: 使用新浪API批量查询
步骤2: 补充东方财富数据
  - 分批处理（默认50只/批）
  - 批次间延迟
  - 合并PE/PB/市值等字段
步骤3: 返回合并后的结果
```

**东方财富数据补充** (L278-L342):
```
对于每批股票:
  1. 逐个查询东方财富API
  2. 合并PE、PB、总市值、流通市值、换手率
  3. 批次间延迟
  4. 记录成功/失败数量
```

---

## 七、配置持久化

### 7.1 配置存储

**文件位置**: [DataSourceModeConfigController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/DataSourceModeConfigController.java)

**持久化方法** (L95-L101):
```java
private void saveConfigToDatabase(String key, String value, String description) {
    systemConfigService.setConfigValue(CONFIG_KEY_PREFIX + key, value, description, false);
}
```

**配置键前缀**: `datasource.mode.`

**持久化的配置项**:
- `datasource.mode.globalMode` - 全局查询模式
- `datasource.mode.defaultSource` - 默认数据源
- `datasource.mode.fallback.priority` - 降级优先级
- `datasource.mode.aggregated.dataSources` - 融合数据源列表
- `datasource.mode.fast.dataSources` - 快速模式数据源
- `datasource.mode.sina.batchSize` - 新浪批量大小
- `datasource.mode.eastmoney.batchSize` - 东方财富批量大小
- `datasource.mode.tencent.batchSize` - 腾讯批量大小
- `datasource.mode.delayMs` - 批量延迟
- `datasource.mode.singleDelayMs` - 单笔延迟

### 7.2 配置加载

**初始化加载** (L55-L62):
```java
@PostConstruct
public void init() {
    loadConfigFromDatabase();
}
```

**加载流程** (L67-L145):
```
1. 加载全局模式
2. 加载默认数据源
3. 加载FALLBACK配置
4. 加载AGGREGATED配置
5. 加载FAST配置
6. 加载基础数据源batchSize
7. 加载延迟配置
```

---

## 八、数据源能力描述

### 8.1 数据源能力类

**文件位置**: [DataSourceCapability.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/service/datasource/DataSourceCapability.java)

能力属性:
- `supportRealTimeQuote` - 支持实时行情
- `supportHistoricalData` - 支持历史数据
- `supportOrderBook` - 支持五档盘口
- `supportFinancialData` - 支持财务数据
- `supportIndustry` - 支持行业分类
- `supportConcept` - 支持概念板块
- `supportValuation` - 支持估值指标
- `supportMarketCap` - 支持市值数据
- `supportTurnoverRate` - 支持换手率
- `supportLimitUpStats` - 支持涨停统计
- `updateFrequency` - 更新频率(秒)
- `dailyLimit` - 日调用限制
- `minuteLimit` - 分钟调用限制
- `supportedFields` - 支持的字段集合

### 8.2 各数据源能力对比

| 能力 | FREE | SINA | EASTMONEY | TENCENT | TUSHARE_BASIC | TUSHARE_PRO | MOOTDX |
|------|------|------|-----------|---------|---------------|-------------|--------|
| 实时行情 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 五档盘口 | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | ✓ |
| 历史数据 | ✓ | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ |
| 财务数据 | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✗ |
| 行业分类 | ✓ | ✗ | ✗ | ✗ | ✓ | ✓ | ✗ |
| 估值指标 | ✓ | ✗ | ✓ | ✗ | ✗ | ✓ | ✗ |
| 市值数据 | ✓ | ✗ | ✓ | ✗ | ✗ | ✓ | ✗ |
| 涨停统计 | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ | ✗ |

---

## 九、参考验证

### 9.1 关键文件清单

| 类别 | 文件名 | 路径 |
|------|--------|------|
| 数据源类型 | DataSourceType.java | javaTdx/src/main/java/com/example/tdx/service/datasource/DataSourceType.java |
| 数据源接口 | StockDataSource.java | javaTdx/src/main/java/com/example/tdx/service/datasource/StockDataSource.java |
| 免费适配器 | FreeDataSourceAdapter.java | javaTdx/src/main/java/com/example/tdx/service/datasource/FreeDataSourceAdapter.java |
| 新浪服务 | SinaStockDataService.java | javaTdx/src/main/java/com/example/tdx/service/SinaStockDataService.java |
| 路由服务 | DataSourceRouter.java | javaTdx/src/main/java/com/example/tdx/service/datasource/DataSourceRouter.java |
| 降级服务 | FallbackStrategyService.java | javaTdx/src/main/java/com/example/tdx/service/datasource/FallbackStrategyService.java |
| 聚合服务 | AggregatedDataCollectorService.java | javaTdx/src/main/java/com/example/tdx/service/datasource/AggregatedDataCollectorService.java |
| 合并服务 | DataMergeService.java | javaTdx/src/main/java/com/example/tdx/service/datasource/DataMergeService.java |
| 统一服务 | UnifiedDataSourceService.java | javaTdx/src/main/java/com/example/tdx/service/datasource/UnifiedDataSourceService.java |
| 主数据服务 | StockDataService.java | javaTdx/src/main/java/com/example/tdx/service/StockDataService.java |
| 模式配置 | DataSourceModeConfig.java | javaTdx/src/main/java/com/example/tdx/config/DataSourceModeConfig.java |
| 获取配置 | DataFetchConfig.java | javaTdx/src/main/java/com/example/tdx/config/DataFetchConfig.java |
| 模式控制器 | DataSourceModeConfigController.java | javaTdx/src/main/java/com/example/tdx/controller/DataSourceModeConfigController.java |
| 降级控制器 | FallbackConfigController.java | javaTdx/src/main/java/com/example/tdx/controller/FallbackConfigController.java |
| 数据源控制器 | DataSourceConfigController.java | javaTdx/src/main/java/com/example/tdx/controller/DataSourceConfigController.java |
| 股票控制器 | StockInfoController.java | javaTdx/src/main/java/com/example/tdx/controller/StockInfoController.java |
| 采集控制器 | DataCollectorController.java | javaTdx/src/main/java/com/example/tdx/controller/DataCollectorController.java |
| Tushare控制器 | TushareDataController.java | javaTdx/src/main/java/com/example/tdx/controller/TushareDataController.java |

### 9.2 验证建议

1. **数据源类型验证**: 查看 DataSourceType.java 枚举定义
2. **Controller端点验证**: 使用IDE搜索`@RestController`和`@RequestMapping`注解
3. **策略逻辑验证**: 查看 StockDataService.getStockInfo() 方法
4. **降级流程验证**: 查看 FallbackStrategyService.getStockInfo() 方法
5. **合并逻辑验证**: 查看 DataMergeService.merge() 方法
6. **配置持久化验证**: 查看 DataSourceModeConfigController.loadConfigFromDatabase() 方法

---

*文档生成完成*
