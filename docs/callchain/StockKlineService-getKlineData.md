# 调用链分析：StockKlineService.getKlineData → TdxKlineService → TdxQuoteClient.create

## 方法定义

**被调用方法**：`public static TdxQuoteClient create(String serverAddress, int serverPort, boolean heartbeat)`

**所在类**：`com.mootdx.quotes.TdxQuoteClient`

**所在文件**：`mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java`

**方法行号**：第123-132行

---

## 调用链

### 第一层调用

**调用方类**：`com.mootdx.server.service.StockKlineService`

**调用方文件**：`mootdx-server/src/main/java/com/mootdx/server/service/StockKlineService.java`

**调用方法**：`public KlineResponseDTO getKlineData(KlineRequestDTO request)`

**调用行号**：第48行

**调用代码**：
```java
// 第48-76行
public KlineResponseDTO getKlineData(KlineRequestDTO request) {
    // ... 参数处理 ...
    
    // 判断是否强制刷新
    if (Boolean.TRUE.equals(request.getForceRefresh())) {
        data = fetchFromTdxAndCache(request);  // 第57行
    } else {
        // 从TDX获取数据
        data = fetchFromTdxAndCache(request);  // 第65行
    }
    
    return KlineResponseDTO.builder()...build();
}
```

### 第二层调用

**调用方类**：`com.mootdx.server.service.StockKlineService`

**调用方法**：`private List<KlineDataDTO> fetchFromTdxAndCache(KlineRequestDTO request)`

**调用行号**：第110行

**调用代码**：
```java
// 第110行
List<KlineDataDTO> data = tdxKlineService.getKlineDataFromTdx(
    request.getCode(), request.getMarket(), request.getFreq(), limit);
```

### 第三层调用

**调用方类**：`com.mootdx.server.service.TdxKlineService`

**调用方文件**：`mootdx-server/src/main/java/com/mootdx/server/service/TdxKlineService.java`

**调用方法**：`public List<KlineDataDTO> getKlineDataFromTdx(String code, String market, String freq, int limit)`

**调用行号**：第180-250行（方法内部使用 tdxClient）

**说明**：TdxKlineService 在 `connectToBestServer()` 方法中创建 TdxQuoteClient 实例并保存到成员变量 `tdxClient`

---

## 调用方用途说明

### StockKlineService 类用途

**类说明**：K线数据服务，负责K线数据的查询、缓存和管理

**主要功能**：
1. 提供K线数据查询接口
2. 优先从数据库查询，不存在则从TDX获取并缓存
3. 支持强制刷新数据

### getKlineData 方法用途

**方法说明**：获取K线数据的主入口

**处理逻辑**：
1. 接收 `KlineRequestDTO` 请求参数
2. 根据 `forceRefresh` 标志决定是否强制从TDX获取
3. 调用 `fetchFromTdxAndCache()` 从TDX获取数据
4. 返回 `KlineResponseDTO` 响应

**给谁用**：
- REST API 控制器 `StockKlineController`
- 前端/外部系统通过 HTTP 接口调用

---

## 上层调用链（HTTP接口）

```
HTTP请求: GET /api/stocks/kline/SH/600036?freq=day&limit=100
    ↓
StockKlineController.getKlineData() 第48行
    ↓
StockKlineService.getKlineData(request) 第48行
    ↓
StockKlineService.fetchFromTdxAndCache(request) 第57/65行
    ↓
TdxKlineService.getKlineDataFromTdx() 第110行
    ↓
使用 TdxKlineService.tdxClient (已在init时创建)
    ↓
TdxQuoteClient.create() 在 connectToBestServer() 第106/125/145行
```

---

## 数据来源

**请求参数来源**：
- HTTP 路径参数：`market` (SH/SZ)、`code` (股票代码)
- HTTP 查询参数：`freq` (频率)、`limit` (数量)、`forceRefresh` (是否强制刷新)

**服务器地址来源**：
- 由 `TdxKlineService.connectToBestServer()` 在应用启动时确定
- 优先级：配置文件 > 数据库默认服务器 > 自动选择

---

## 参考来源验证

| 项目 | 路径 | 行号 |
|------|------|------|
| TdxQuoteClient.create | `mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java` | 123-132 |
| StockKlineService.getKlineData | `mootdx-server/src/main/java/com/mootdx/server/service/StockKlineService.java` | 48-76 |
| StockKlineService.fetchFromTdxAndCache | `mootdx-server/src/main/java/com/mootdx/server/service/StockKlineService.java` | 100-120 |
| TdxKlineService.getKlineDataFromTdx | `mootdx-server/src/main/java/com/mootdx/server/service/TdxKlineService.java` | 180-250 |
| TdxKlineService.connectToBestServer | `mootdx-server/src/main/java/com/mootdx/server/service/TdxKlineService.java` | 99-147 |
| StockKlineController.getKlineData | `mootdx-server/src/main/java/com/mootdx/server/controller/StockKlineController.java` | 48-68 |
