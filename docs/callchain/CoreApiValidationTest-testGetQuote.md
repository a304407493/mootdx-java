# 调用链分析：CoreApiValidationTest.testGetQuote → TdxQuoteClient.create

## 方法定义

**被调用方法**：`public static TdxQuoteClient create(String serverAddress, int serverPort, boolean heartbeat)`

**所在类**：`com.mootdx.quotes.TdxQuoteClient`

**所在文件**：`mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java`

**方法行号**：第123-132行

---

## 调用方信息

**调用方类**：`com.mootdx.CoreApiValidationTest`

**调用方文件**：`mootdx-core/src/test/java/com/mootdx/CoreApiValidationTest.java`

**调用方法**：`void testGetQuote()`

**调用行号**：第203行

**调用代码**：
```java
// 第195-220行
@Test
@Order(10)
@DisplayName("验证 getQuote 实时行情接口")
void testGetQuote() {
    log.info("[testGetQuote] 验证 getQuote 接口...");

    // 使用配置文件中的测试服务器
    client = TdxQuoteClient.create(TEST_SERVER, TEST_PORT, true);  // 第203行

    try {
        client.connect();
        // ... 测试获取行情 ...
    } finally {
        client.close();
    }
}
```

---

## 调用方用途说明

### CoreApiValidationTest 类用途

**类说明**：核心API验证测试类

**主要功能**：
1. 验证 mootdx-core 模块的所有公共接口
2. 测试工具类、数据模型、协议常量、在线接口等
3. 确保核心功能正常工作

### testGetQuote 方法用途

**方法说明**：测试 `TdxQuoteClient.getQuote()` 实时行情接口

**测试逻辑**：
1. 使用测试配置中的服务器地址创建客户端
2. 连接到TDX服务器
3. 获取指定股票的实时行情
4. 验证返回数据的完整性和正确性

**给谁用**：
- 开发人员进行回归测试
- CI/CD 流程自动测试
- 验证核心接口功能是否正常

---

## 上层调用链

```
Maven测试: mvn test -Dtest=CoreApiValidationTest
    ↓
JUnit 5 测试框架
    ↓
CoreApiValidationTest.setUp() 第85行
    ↓
CoreApiValidationTest.testGetQuote() 第197行
    ↓
TdxQuoteClient.create(TEST_SERVER, TEST_PORT, true) 第203行
```

---

## 数据来源

**服务器地址来源**：
```java
// 第55-58行
private static final TdxTestConfig TEST_CONFIG = TdxTestConfig.getInstance();
private static final String TEST_SERVER = TEST_CONFIG.getHost();
private static final int TEST_PORT = TEST_CONFIG.getPort();
```

**配置文件位置**：`mootdx-core/src/test/resources/tdx-config.properties`

**配置项**：
```properties
tdx.test.server.host=119.147.212.81
tdx.test.server.port=7709
tdx.test.server.heartbeat=true
```

---

## 参考来源验证

| 项目 | 路径 | 行号 |
|------|------|------|
| TdxQuoteClient.create | `mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java` | 123-132 |
| CoreApiValidationTest.testGetQuote | `mootdx-core/src/test/java/com/mootdx/CoreApiValidationTest.java` | 197-223 |
| CoreApiValidationTest.TEST_CONFIG | `mootdx-core/src/test/java/com/mootdx/CoreApiValidationTest.java` | 55-58 |
| TdxTestConfig | `mootdx-core/src/test/java/com/mootdx/config/TdxTestConfig.java` | 1-100 |
| tdx-config.properties | `mootdx-core/src/test/resources/tdx-config.properties` | 1-10 |
