# 调用链分析：MootdxCommand.QuoteCommand → TdxQuoteClient.create

## 方法定义

**被调用方法**：`public static TdxQuoteClient create(String serverAddress)`  
**重载方法**：`public static TdxQuoteClient create(String serverAddress, int serverPort, boolean heartbeat)`

**所在类**：`com.mootdx.quotes.TdxQuoteClient`

**所在文件**：`mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java`

**方法行号**：第141-143行（简化版）、第123-132行（完整版）

---

## 调用方信息

**调用方类**：`com.mootdx.cli.MootdxCommand.QuoteCommand`

**调用方文件**：`mootdx-core/src/main/java/com/mootdx/cli/MootdxCommand.java`

**调用方法**：`private static TdxQuoteClient createClient(String server)`

**调用行号**：第414行、第417行

**调用代码**：
```java
// 第405-418行
private static TdxQuoteClient createClient(String server) {
    if (server != null && !server.isEmpty()) {
        String[] parts = server.split(":");
        return TdxQuoteClient.create(parts[0], 
            parts.length > 1 ? Integer.parseInt(parts[1]) : 7709, true);  // 第414行
    }
    return TdxQuoteClient.create(null);  // 第417行 - 自动选择服务器
}
```

**上层调用方法**：`public Integer call()` 第376行

---

## 调用方用途说明

### MootdxCommand 类用途

**类说明**：MooTDX CLI命令行工具主类

**主要功能**：
1. 提供命令行接口操作TDX数据
2. 支持股票查询、K线获取、财务数据下载等功能
3. 基于 picocli 框架实现

### QuoteCommand 子命令用途

**类说明**：行情数据查询子命令

**命令格式**：`mootdx quote [OPTIONS]`

**参数选项**：
- `-c, --code`：股票代码（如 000001）
- `-m, --market`：市场代码（SH/SZ）
- `-s, --server`：指定服务器地址（如 119.147.212.81:7709）
- `--kline`：获取K线数据
- `--daily`：获取日线数据
- `--minute`：获取分钟线数据

### createClient 方法用途

**方法说明**：根据用户输入创建TDX客户端

**逻辑**：
1. 如果用户指定了 `--server` 参数，使用指定服务器
2. 如果用户未指定 `--server` 参数，传入 `null` 自动选择最优服务器

**给谁用**：
- 命令行用户直接调用
- 用于快速测试TDX连接和获取行情数据

---

## 上层调用链

```
命令行输入: mootdx quote -c 000001
    ↓
MootdxCommand.main() 第45行
    ↓
picocli 解析命令
    ↓
QuoteCommand.call() 第376行
    ↓
createClient(server) 第405行
    ↓
TdxQuoteClient.create(null) 第417行 或 TdxQuoteClient.create(host, port, true) 第414行
```

---

## 数据来源

**服务器地址来源**：
- 命令行参数 `--server` 或 `-s`
- 如果未提供，传入 `null` 触发自动选择

**自动选择逻辑**：
```java
// TdxQuoteClient.create(null) 第141-143行
public static TdxQuoteClient create(String serverAddress) {
    return create(serverAddress, 7709, true);  // 默认端口7709，启用心跳
}

// 最终调用第123-132行
if (serverAddress == null || serverAddress.isEmpty()) {
    return factory("std", true, heartbeat);  // 自动选择服务器
}
```

---

## 参考来源验证

| 项目 | 路径 | 行号 |
|------|------|------|
| TdxQuoteClient.create | `mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java` | 141-143, 123-132 |
| MootdxCommand.createClient | `mootdx-core/src/main/java/com/mootdx/cli/MootdxCommand.java` | 405-418 |
| MootdxCommand.QuoteCommand.call | `mootdx-core/src/main/java/com/mootdx/cli/MootdxCommand.java` | 376-400 |
| MootdxCommand.main | `mootdx-core/src/main/java/com/mootdx/cli/MootdxCommand.java` | 45-50 |
