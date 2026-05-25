# 调用链分析：ExampleUsage 示例类 → TdxQuoteClient.create

## 方法定义

**被调用方法**：`public static TdxQuoteClient create(String serverAddress)`  
**重载方法**：`public static TdxQuoteClient create(String serverAddress, int serverPort, boolean heartbeat)`

**所在类**：`com.mootdx.quotes.TdxQuoteClient`

**所在文件**：`mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java`

**方法行号**：第141-143行（简化版）、第123-132行（完整版）

---

## 调用方信息

**调用方类**：`com.mootdx.ExampleUsage`

**调用方文件**：`mootdx-core/src/test/java/com/mootdx/ExampleUsage.java`

**调用方法**：多个示例方法

| 方法名 | 行号 | 调用方式 | 说明 |
|--------|------|----------|------|
| `example1_BasicConnection()` | 第148行 | `create(null)` | 自动选择服务器 |
| `example3_GetKLineData()` | 第186行 | `create(null)` | 自动选择服务器 |
| `example4_GetBatchQuotes()` | 第220行 | `create(null)` | 自动选择服务器 |
| `example8_SelectBestServer()` | 第365行 | `create(parts[0], parts[1], true)` | 指定服务器 |

**调用代码示例**：
```java
// 第148行 - 基本连接示例
client = TdxQuoteClient.create(null);

// 第365行 - 选择最佳服务器后连接
String bestServer = TdxQuoteClient.selectBestServer(
    com.mootdx.protocol.TdxProtocol.getDefaultServers());  // 第356-357行
String[] parts = bestServer.split(":");
client = TdxQuoteClient.create(parts[0], 
    Integer.parseInt(parts[1]), true);  // 第365行
```

---

## 调用方用途说明

### ExampleUsage 类用途

**类说明**：使用示例类，展示如何使用 mootdx-core 库

**主要功能**：
1. 提供各种使用场景的代码示例
2. 演示基本连接、获取行情、获取K线等功能
3. 作为开发人员的参考文档

### 各示例方法用途

| 方法名 | 用途 | 调用方式 |
|--------|------|----------|
| `example1_BasicConnection` | 演示基本连接和断开 | 自动选择服务器 |
| `example3_GetKLineData` | 演示获取K线数据 | 自动选择服务器 |
| `example4_GetBatchQuotes` | 演示批量获取行情 | 自动选择服务器 |
| `example8_SelectBestServer` | 演示选择最佳服务器 | 先选择再指定连接 |

**给谁用**：
- 开发人员学习如何使用库
- 新用户快速上手参考
- 作为API文档的补充

---

## 上层调用链

```
运行 ExampleUsage.main()
    ↓
依次调用各个示例方法
    ↓
TdxQuoteClient.create(null) 或 TdxQuoteClient.create(host, port, true)
```

---

## 数据来源

**自动选择时的服务器来源**：
```java
// 第356-357行
String bestServer = TdxQuoteClient.selectBestServer(
    com.mootdx.protocol.TdxProtocol.getDefaultServers());
```

**配置来源**：
- 主配置：`mootdx-core/src/main/resources/tdx-config.properties`
- 测试配置：`mootdx-core/src/test/resources/tdx-config.properties`

---

## 参考来源验证

| 项目 | 路径 | 行号 |
|------|------|------|
| TdxQuoteClient.create | `mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java` | 141-143, 123-132 |
| ExampleUsage.example1_BasicConnection | `mootdx-core/src/test/java/com/mootdx/ExampleUsage.java` | 135-165 |
| ExampleUsage.example3_GetKLineData | `mootdx-core/src/test/java/com/mootdx/ExampleUsage.java` | 175-200 |
| ExampleUsage.example4_GetBatchQuotes | `mootdx-core/src/test/java/com/mootdx/ExampleUsage.java` | 208-235 |
| ExampleUsage.example8_SelectBestServer | `mootdx-core/src/test/java/com/mootdx/ExampleUsage.java` | 348-385 |
| TdxProtocol.getDefaultServers | `mootdx-core/src/main/java/com/mootdx/protocol/TdxProtocol.java` | 218-220 |
