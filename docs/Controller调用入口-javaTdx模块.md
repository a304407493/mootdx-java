# Mootdx-Java Controller调用入口 - javaTdx模块

> 生成日期: 2026-05-12

---

## 一、数据源配置相关Controller

### 1.1 数据源模式配置控制器

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

### 1.2 降级策略配置控制器

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

### 1.3 数据源配置控制器

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

---

## 二、股票数据相关Controller

### 2.1 股票信息控制器

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

### 2.2 免费数据采集控制器

**文件位置**: [DataCollectorController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/DataCollectorController.java)

**基础路径**: `/api/collector`

| 端点 | 方法 | 功能 | 行号 |
|------|------|------|------|
| `GET /stock/{stockCode}` | `collectStockData(String)` | 采集单只股票数据 | L28-L48 |
| `GET /stocks` | `collectBatchStockData(String)` | 批量采集股票数据 | L53-L77 |
| `GET /test` | `testCollect()` | 测试采集热门股票 | L82-L97 |

### 2.3 Tushare数据采集控制器

**文件位置**: [TushareDataController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/TushareDataController.java)

**基础路径**: `/api/tushare`

| 端点 | 方法 | 功能 | 行号 |
|------|------|------|------|
| `GET /status` | `checkStatus()` | 检查Tushare配置状态 | L27-L35 |
| `GET /collect/{stockCode}` | `collectStockData(String)` | 采集单只股票数据 | L40-L58 |
| `POST /collect/batch` | `collectBatchStockData(Map)` | 批量采集股票数据 | L63-L84 |
| `GET /test` | `testCollect()` | 测试采集接口 | L89-L94 |
| `GET /coverage` | `getCoverage()` | 获取数据覆盖范围 | L99-L151 |

### 2.4 K线数据控制器

**文件位置**: [StockKlineController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/StockKlineController.java)

**基础路径**: `/api/kline`

---

## 三、板块管理相关Controller

### 3.1 板块控制器

**文件位置**: [BlockController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/BlockController.java)

**基础路径**: `/api/blocks`

### 3.2 特色板块控制器

**文件位置**: [FeaturedBlockController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/FeaturedBlockController.java)

**基础路径**: `/api/featured-blocks`

### 3.3 板块分组控制器

**文件位置**: [FeaturedBlockGroupController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/FeaturedBlockGroupController.java)

**基础路径**: `/api/featured-block-groups`

### 3.4 板块备份控制器

**文件位置**: [BlockBackupController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/BlockBackupController.java)

**基础路径**: `/api/block-backup`

### 3.5 板块监控控制器

**文件位置**: [BlockWatchController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/BlockWatchController.java)

**基础路径**: `/api/block-watch`

---

## 四、服务器与配置相关Controller

### 4.1 通达信服务器控制器

**文件位置**: [TdxServerController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/TdxServerController.java)

**基础路径**: `/api/servers`

### 4.2 通达信数据导入控制器

**文件位置**: [TdxDataImportController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/TdxDataImportController.java)

**基础路径**: `/api/tdx-import`

### 4.3 通达信路径配置控制器

**文件位置**: [TdxPathConfigController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/TdxPathConfigController.java)

**基础路径**: `/api/tdx-path`

### 4.4 系统配置控制器

**文件位置**: [SystemConfigController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/SystemConfigController.java)

**基础路径**: `/api/system-config`

### 4.5 数据源监控控制器

**文件位置**: [DataSourceMonitorController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/DataSourceMonitorController.java)

**基础路径**: `/api/datasource-monitor`

---

## 五、持仓与交易相关Controller

### 5.1 持仓控制器

**文件位置**: [StockPositionController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/StockPositionController.java)

**基础路径**: `/api/positions`

### 5.2 交易平台控制器

**文件位置**: [TradePlatformController.java](file:///d:/BaiduNetdiskDownload/mootdx-java/javaTdx/src/main/java/com/example/tdx/controller/TradePlatformController.java)

**基础路径**: `/api/platforms`

---

## 六、参考文件清单

| Controller | 文件路径 | 基础路径 |
|-----------|----------|----------|
| DataSourceModeConfigController | javaTdx/.../DataSourceModeConfigController.java | `/api/datasource-mode` |
| FallbackConfigController | javaTdx/.../FallbackConfigController.java | `/api/fallback` |
| DataSourceConfigController | javaTdx/.../DataSourceConfigController.java | `/api/datasource` |
| StockInfoController | javaTdx/.../StockInfoController.java | `/api/stock` |
| DataCollectorController | javaTdx/.../DataCollectorController.java | `/api/collector` |
| TushareDataController | javaTdx/.../TushareDataController.java | `/api/tushare` |
| StockKlineController | javaTdx/.../StockKlineController.java | `/api/kline` |
| BlockController | javaTdx/.../BlockController.java | `/api/blocks` |
| FeaturedBlockController | javaTdx/.../FeaturedBlockController.java | `/api/featured-blocks` |
| FeaturedBlockGroupController | javaTdx/.../FeaturedBlockGroupController.java | `/api/featured-block-groups` |
| BlockBackupController | javaTdx/.../BlockBackupController.java | `/api/block-backup` |
| BlockWatchController | javaTdx/.../BlockWatchController.java | `/api/block-watch` |
| TdxServerController | javaTdx/.../TdxServerController.java | `/api/servers` |
| TdxDataImportController | javaTdx/.../TdxDataImportController.java | `/api/tdx-import` |
| TdxPathConfigController | javaTdx/.../TdxPathConfigController.java | `/api/tdx-path` |
| SystemConfigController | javaTdx/.../SystemConfigController.java | `/api/system-config` |
| DataSourceMonitorController | javaTdx/.../DataSourceMonitorController.java | `/api/datasource-monitor` |
| StockPositionController | javaTdx/.../StockPositionController.java | `/api/positions` |
| TradePlatformController | javaTdx/.../TradePlatformController.java | `/api/platforms` |

---

*文档生成完成*
