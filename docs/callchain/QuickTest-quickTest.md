# 调用链分析：QuickTest 快速测试类 → TdxQuoteClient.create

## 方法定义

**被调用方法**：`public static TdxQuoteClient create(String serverAddress)`

**所在类**：`com.mootdx.quotes.TdxQuoteClient`

**所在文件**：`mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java`

**方法行号**：第141-143行（简化版）→ 内部调用第123-132行（完整版）

---

## 调用方信息

**调用方类**：`com.mootdx.QuickTest`

**调用方文件**：`mootdx-core/src/test/java/com/mootdx/QuickTest.java`

**调用方法**：`void quickTest()`

**调用行号**：第72行

**调用代码**：
```java
// 第60-95行
@Test
void quickTest() {
    System.out.println("=== Quick Test ===");
    
    // 创建客户端（自动选择服务器）
    TdxQuoteClient client = TdxQuoteClient.create(null);  // 第72行
    
    try {
        // 连接服务器
        client.connect();
        System.out.println("Connected successfully!");
        
        // 获取行情数据测试
        // ...
    } finally {
        client.close();
    }
}
```

---

## 调用方用途说明

### QuickTest 类用途

**类说明**：快速测试类，用于快速验证基本功能

**主要功能**：
1. 快速测试连接功能
2. 快速测试获取行情数据
3. 作为开发调试工具

### quickTest 方法用途

**方法说明**：快速测试连接和基本功能

**测试逻辑**：
1. 使用 `create(null)` 自动选择服务器
2. 连接到TDX服务器
3. 验证连接是否成功
4. 关闭连接

**给谁用**：
- 开发人员快速验证环境是否正常
- 调试时快速测试连接
- 作为最简单的使用示例

---

## 上层调用链

```
Maven测试: mvn test -Dtest=QuickTest
    ↓
JUnit 5 测试框架
    ↓
QuickTest.quickTest() 第62行
    ↓
TdxQuoteClient.create(null) 第72行
```

---

## 数据来源

**自动选择时的服务器来源**：
- 调用 `TdxQuoteClient.factory()` 方法
- 内部调用 `selectBestServer(TdxProtocol.getDefaultServers())`
- 从 `tdx-config.properties` 读取服务器列表

---

## 参考来源验证

| 项目 | 路径 | 行号 |
|------|------|------|
| TdxQuoteClient.create | `mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java` | 141-143, 123-132 |
| QuickTest.quickTest | `mootdx-core/src/test/java/com/mootdx/QuickTest.java` | 60-95 |
| TdxProtocol.getDefaultServers | `mootdx-core/src/main/java/com/mootdx/protocol/TdxProtocol.java` | 218-220 |
| tdx-config.properties | `mootdx-core/src/main/resources/tdx-config.properties` | 1-11 |
