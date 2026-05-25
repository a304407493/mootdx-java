# 调用链分析：TdxKlineService.connectToBestServer → TdxQuoteClient.create

## 方法定义

**被调用方法**：`public static TdxQuoteClient create(String serverAddress, int serverPort, boolean heartbeat)`

**所在类**：`com.mootdx.quotes.TdxQuoteClient`

**所在文件**：`mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java`

**方法行号**：第123-132行

---

## 调用方信息

**调用方类**：`com.mootdx.server.service.TdxKlineService`

**调用方文件**：`mootdx-server/src/main/java/com/mootdx/server/service/TdxKlineService.java`

**调用方法**：`private void connectToBestServer()`

**调用行号**：第106行、第125行、第145行

**调用代码**：
```java
// 第106行 - 使用配置文件中的服务器
tdxClient = TdxQuoteClient.create(currentHost, currentPort, tdxServerProperties.isHeartbeat());

// 第125行 - 使用数据库默认服务器
tdxClient = TdxQuoteClient.create(currentHost, currentPort, tdxServerProperties.isHeartbeat());

// 第145行 - 使用最佳可用服务器
tdxClient = TdxQuoteClient.create(currentHost, currentPort, tdxServerProperties.isHeartbeat());
```

---

## 调用方用途说明

### TdxKlineService 类用途

**类说明**：TDX K线数据服务，负责从TDX服务器获取K线数据

**主要功能**：
1. 管理TDX客户端连接
2. 从TDX服务器获取各种周期的K线数据（1分钟、5分钟、日线等）
3. 数据转换和格式化

### connectToBestServer 方法用途

**方法说明**：连接到最佳可用服务器

**连接优先级**：
1. **配置文件**（第88-107行）：读取 `application.yml` 中的 `mootdx.tdx.host`
2. **数据库默认服务器**（第109-127行）：从 `TdxServerService.getDefaultServer()` 获取
3. **自动选择最佳服务器**（第129-146行）：从 `TdxServerService.getBestAvailableServer()` 获取

**给谁用**：
- 后端服务启动时自动调用（`@PostConstruct` 注解）
- 为整个后端服务提供TDX行情数据连接

---

## 上层调用链

```
Spring Boot 应用启动
    ↓
@PostConstruct init() 第86行
    ↓
connectToBestServer() 第99行
    ↓
TdxQuoteClient.create(host, port, heartbeat) 第106/125/145行
```

---

## 数据来源

**服务器地址来源**：
1. `TdxServerProperties.getHost()` - 从 `application.yml` 读取
2. `TdxServerService.getDefaultServer()` - 从数据库读取
3. `TdxServerService.getBestAvailableServer()` - 从数据库读取

**配置文件位置**：`mootdx-server/src/main/resources/application.yml`

**配置项**：
```yaml
mootdx:
  tdx:
    host: ""  # 为空时进入数据库选择逻辑
    port: 7709
    heartbeat: true
```

---

## 参考来源验证

| 项目 | 路径 | 行号 |
|------|------|------|
| TdxQuoteClient.create | `mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java` | 123-132 |
| TdxKlineService.connectToBestServer | `mootdx-server/src/main/java/com/mootdx/server/service/TdxKlineService.java` | 99-147 |
| TdxKlineService.init | `mootdx-server/src/main/java/com/mootdx/server/service/TdxKlineService.java` | 86-88 |
| application.yml | `mootdx-server/src/main/resources/application.yml` | 71-74 |
