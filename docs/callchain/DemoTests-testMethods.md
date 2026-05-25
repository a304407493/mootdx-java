# 调用链分析：DemoTests 测试类 → TdxQuoteClient.create

## 方法定义

**被调用方法**：`public static TdxQuoteClient create(String serverAddress)`

**所在类**：`com.mootdx.quotes.TdxQuoteClient`

**所在文件**：`mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java`

**方法行号**：第141-143行（简化版）→ 内部调用第123-132行（完整版）

---

## 调用方信息

**调用方类**：`com.mootdx.DemoTests`

**调用方文件**：`mootdx-core/src/test/java/com/mootdx/DemoTests.java`

**调用方法**：多个测试方法

| 方法名 | 行号 | 调用方式 | 说明 |
|--------|------|----------|------|
| `testConnection()` | 第161行 | `create(null)` | 自动选择服务器 |
| `testGetQuote()` | 第217行 | `create(null)` | 自动选择服务器 |
| `testGetQuotes()` | 第270行 | `create(null)` | 自动选择服务器 |
| `testSelectBestServer()` | 第327行 | `selectBestServer(servers)` | 先选择再连接 |
| `testGetKLine()` | 第448行 | `create(null)` | 自动选择服务器 |

**调用代码示例**：
```java
// 第161行 - 测试连接
client = TdxQuoteClient.create(null);

// 第327行 - 测试选择最佳服务器
String bestServer = TdxQuoteClient.selectBestServer(servers);  // 第327行
String[] parts = bestServer.split(":");
client = TdxQuoteClient.create(parts[0], 
    Integer.parseInt(parts[1]), true);
```

---

## 调用方用途说明

### DemoTests 类用途

**类说明**：演示测试类，展示 mootdx-core 的核心功能

**主要功能**：
1. 演示如何连接到TDX服务器
2. 演示获取实时行情数据
3. 演示获取K线数据
4. 演示选择最佳服务器

### 各测试方法用途

| 方法名 | 用途 | 调用方式 |
|--------|------|----------|
| `testConnection` | 测试基本连接功能 | 自动选择服务器 |
| `testGetQuote` | 测试获取单只股票行情 | 自动选择服务器 |
| `testGetQuotes` | 测试批量获取行情 | 自动选择服务器 |
| `testSelectBestServer` | 测试服务器选择功能 | 先选择再指定连接 |
| `testGetKLine` | 测试获取K线数据 | 自动选择服务器 |

**给谁用**：
- 开发人员了解库的基本用法
- 作为功能演示和验证
- 测试核心功能是否正常工作

---

## 上层调用链

```
Maven测试: mvn test -Dtest=DemoTests
    ↓
JUnit 5 测试框架
    ↓
依次执行各个测试方法
    ↓
TdxQuoteClient.create(null) 或 TdxQuoteClient.create(host, port, true)
```

---

## 数据来源

**自动选择时的服务器来源**：
```java
// 第327行
List<String> servers = Arrays.asList(
    "119.147.212.81:7709",
    "221.231.141.60:7709",
    "58.63.254.191:7709"
);
String bestServer = TdxQuoteClient.selectBestServer(servers);
```

**注意**：DemoTests 中硬编码了服务器列表，实际应从配置文件读取

---

## 参考来源验证

| 项目 | 路径 | 行号 |
|------|------|------|
| TdxQuoteClient.create | `mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java` | 141-143, 123-132 |
| DemoTests.testConnection | `mootdx-core/src/test/java/com/mootdx/DemoTests.java` | 150-180 |
| DemoTests.testGetQuote | `mootdx-core/src/test/java/com/mootdx/DemoTests.java` | 200-230 |
| DemoTests.testGetQuotes | `mootdx-core/src/test/java/com/mootdx/DemoTests.java` | 250-290 |
| DemoTests.testSelectBestServer | `mootdx-core/src/test/java/com/mootdx/DemoTests.java` | 310-345 |
| DemoTests.testGetKLine | `mootdx-core/src/test/java/com/mootdx/DemoTests.java` | 430-470 |
