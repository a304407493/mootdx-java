# TdxQuoteClient.create() 调用链分析文档

本文档梳理了 `TdxQuoteClient.create(String serverAddress, int serverPort, boolean heartbeat)` 方法的所有调用链路。

## 方法定义

**方法签名**：`public static TdxQuoteClient create(String serverAddress, int serverPort, boolean heartbeat)`

**所在类**：`com.mootdx.quotes.TdxQuoteClient`

**所在文件**：`mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java`

**方法行号**：第123-132行

**方法功能**：
- 如果提供了 `serverAddress`，使用指定IP创建客户端
- 如果 `serverAddress` 为 null 或空字符串，自动选择最优服务器

---

## 调用链路汇总

### 一、生产环境调用

| 调用方 | 文件路径 | 调用方式 | 用途 |
|--------|----------|----------|------|
| TdxKlineService.connectToBestServer | `mootdx-server/.../TdxKlineService.java` | `create(host, port, heartbeat)` | 后端服务启动时连接TDX服务器 |
| MootdxCommand.QuoteCommand | `mootdx-core/.../MootdxCommand.java` | `create(null)` 或 `create(host, port, true)` | CLI命令行工具 |
| StockKlineService → TdxKlineService | `mootdx-server/.../StockKlineService.java` | 间接调用 | HTTP API接口获取K线数据 |

### 二、测试环境调用

| 调用方 | 文件路径 | 调用方式 | 用途 |
|--------|----------|----------|------|
| CoreApiValidationTest.testGetQuote | `mootdx-core/.../CoreApiValidationTest.java` | `create(TEST_SERVER, TEST_PORT, true)` | 核心API验证测试 |
| ExampleUsage | `mootdx-core/.../ExampleUsage.java` | `create(null)` 或 `create(host, port, true)` | 使用示例 |
| DemoTests | `mootdx-core/.../DemoTests.java` | `create(null)` | 演示测试 |
| QuickTest.quickTest | `mootdx-core/.../QuickTest.java` | `create(null)` | 快速测试 |

---

## 详细文档列表

### 生产环境

1. [TdxKlineService.connectToBestServer → TdxQuoteClient.create](./TdxKlineService-connectToBestServer.md)
   - 后端服务启动时连接TDX服务器
   - 优先级：配置文件 > 数据库 > 自动选择

2. [MootdxCommand.QuoteCommand → TdxQuoteClient.create](./MootdxCommand-QuoteCommand-call.md)
   - CLI命令行工具
   - 支持用户指定服务器或自动选择

3. [StockKlineService.getKlineData → TdxKlineService → TdxQuoteClient.create](./StockKlineService-getKlineData.md)
   - HTTP REST API接口
   - 为前端/外部系统提供K线数据

### 测试环境

4. [CoreApiValidationTest.testGetQuote → TdxQuoteClient.create](./CoreApiValidationTest-testGetQuote.md)
   - 核心API验证测试
   - 使用测试配置文件

5. [ExampleUsage → TdxQuoteClient.create](./ExampleUsage-examples.md)
   - 使用示例类
   - 展示各种使用场景

6. [DemoTests → TdxQuoteClient.create](./DemoTests-testMethods.md)
   - 演示测试类
   - 展示核心功能用法

7. [QuickTest.quickTest → TdxQuoteClient.create](./QuickTest-quickTest.md)
   - 快速测试类
   - 最简单的使用示例

---

## 服务器地址来源

### 1. 指定服务器

- **配置文件**：`application.yml` (后端) / `tdx-config.properties` (核心库)
- **数据库**：`TdxServerConfig` 表中的服务器配置
- **命令行参数**：`--server` 参数
- **硬编码**：测试代码中的服务器地址

### 2. 自动选择

当传入 `null` 或空字符串时：

```java
TdxQuoteClient.create(null)  // 自动选择最优服务器
```

**自动选择流程**：
1. 调用 `factory("std", true, heartbeat)` 方法
2. 调用 `selectBestServer(TdxProtocol.getDefaultServers())`
3. 从 `tdx-config.properties` 读取服务器列表
4. 测试每个服务器的连接延迟
5. 返回延迟最低的服务器

---

## 配置文件位置

| 配置文件 | 用途 | 路径 |
|----------|------|------|
| `tdx-config.properties` | 核心库服务器列表 | `mootdx-core/src/main/resources/` |
| `tdx-config.properties` | 测试服务器配置 | `mootdx-core/src/test/resources/` |
| `application.yml` | 后端服务配置 | `mootdx-server/src/main/resources/` |
| `affair-config.properties` | 财务数据服务器 | `mootdx-core/src/main/resources/` |

---

## 验证方法

如需验证文档准确性，可按以下步骤：

1. **验证方法定义**：
   ```bash
   grep -n "public static TdxQuoteClient create" mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java
   ```

2. **验证调用位置**：
   ```bash
   grep -rn "TdxQuoteClient.create(" mootdx-java --include="*.java"
   ```

3. **验证配置文件**：
   ```bash
   cat mootdx-core/src/main/resources/tdx-config.properties
   cat mootdx-server/src/main/resources/application.yml | grep -A 20 "tdx:"
   ```
