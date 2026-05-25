# K线接口问题总结与解决方案

## 问题概述

在测试通达信K线接口时，发现**连续K线请求会超时失败**的问题。第一次请求成功，但第二次请求永远等不到响应，最终导致 `TimeoutException`。

## 问题分析

### 根本原因

**通达信服务器在每次K线请求响应后会主动断开连接**，这是一个服务器端的特性/限制。

### 具体表现

1. **第一次请求**：连接建立 → 发送请求 → 收到响应 ✅
2. **服务器行为**：响应后立即断开连接（发送FIN包）
3. **第二次请求**：
   - 客户端调用 `isConnected()` 返回 `true`（因为channel对象还在）
   - 但实际TCP连接已断开
   - 请求发送后永远等不到响应
   - 120秒后超时

### 错误日志

```
// 第一次请求成功
[1] 成功，获取到 5 条数据
[1] 请求后连接状态: true

// 等待后连接状态仍显示为true（错误）
[2] 等待后连接状态: true

// 第二次请求超时
Caused by: java.util.concurrent.TimeoutException
    at java.util.concurrent.CompletableFuture.timedGet(CompletableFuture.java:1771)
    at com.mootdx.quotes.TdxQuoteClient.sendRawRequest(TdxQuoteClient.java:676)
```

## 解决方案

### 方案：请求后主动断开连接

在 `getKLine` 方法的 `finally` 块中主动调用 `disconnect()`，确保每次请求后都清理连接状态。

```java
public List<BarData> getKLine(String symbol, int frequency, int offset) {
    ensureConnected();
    
    // ... 构建请求 ...
    
    ByteBuf response = sendRawRequest(TdxProtocol.CMD_GET_KLINE, payload.array());
    
    try {
        List<BarData> bars = parseKLineResponse(response, frequency);
        return bars;
    } finally {
        response.release();
        // K线接口特性：服务器会在每次响应后断开连接
        // 为了确保下次请求能正常工作，主动断开并清理状态
        logger.debug("K-line request completed, disconnecting to ensure clean state for next request");
        disconnect();
    }
}
```

### 同时增强 ensureConnected() 方法

```java
private void ensureConnected() {
    boolean needReconnect = false;
    
    if (!connected || channel == null) {
        needReconnect = true;
    } else if (!channel.isActive()) {
        needReconnect = true;
    }
    
    if (needReconnect) {
        logger.info("Reconnecting to TDX server...");
        // 如果之前有连接，先断开
        if (channel != null) {
            try {
                channel.close().sync();
            } catch (Exception e) {
                logger.warn("Error closing old channel: {}", e.getMessage());
            }
        }
        connected = false;
        connect();
        // 连接后等待一段时间让服务器准备好
        try {
            Thread.sleep(500);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

## 验证结果

### 测试覆盖

所有K线类型测试通过：

| 类型 | 频率代码 | 状态 |
|------|---------|------|
| 日线 | 9 | ✅ 通过 |
| 1分钟线 | 8 | ✅ 通过 |
| 5分钟线 | 0 | ✅ 通过 |
| 15分钟线 | 1 | ✅ 通过 |
| 30分钟线 | 2 | ✅ 通过 |
| 60分钟线 | 3 | ✅ 通过 |
| 周线 | 5 | ✅ 通过 |
| 月线 | 6 | ✅ 通过 |

### 关键测试用例

- `KlineSequenceTest` - 连续K线请求测试
- `KlineReconnectTest` - 重连后K线请求测试
- `KlineMixedTest` - K线与行情混合请求测试
- `KlineAllTypesTest` - 所有K线类型测试

## 给其他AI的注意事项

### 1. K线接口的特殊性

**K线接口与行情接口不同**：
- 行情接口（getQuote）可以保持长连接，多次请求
- K线接口（getKLine）每次请求后服务器都会断开，必须重新连接

### 2. 连接状态检测的局限性

不要完全依赖 `isConnected()` 方法：
```java
// 不可靠！channelInactive是异步回调
if (client.isConnected()) {
    // 可能实际上连接已断开
}
```

### 3. 超时设置

K线数据量大时响应较慢，建议设置较长的超时时间：
```java
// 当前设置为120秒
private int readTimeout = 120000; // 120 seconds
```

### 4. 频率代码对照表

```java
// TdxProtocol.java 中定义的常量
public static final int FREQUENCY_1MIN = 8;     // 1分钟
public static final int FREQUENCY_5MIN = 0;     // 5分钟
public static final int FREQUENCY_15MIN = 1;    // 15分钟
public static final int FREQUENCY_30MIN = 2;    // 30分钟
public static final int FREQUENCY_60MIN = 3;    // 60分钟
public static final int FREQUENCY_DAILY = 9;    // 日线
public static final int FREQUENCY_WEEKLY = 5;   // 周线
public static final int FREQUENCY_MONTHLY = 6;  // 月线
```

### 5. 数据解析注意事项

K线数据使用差分编码：
- 第一条记录：开盘价 = rawOpen / 100.0
- 后续记录：
  - high = open + (rawHigh / 100.0)
  - low = open + (rawLow / 100.0)
  - close = open + (rawClose / 100.0)

### 6. 日期时间格式

- 日线：YYYYMMDD (如 20260422)
- 分钟线：YYYYMMDDHHMM (如 202604221430)

## 相关文件

- [TdxQuoteClient.java](../mootdx-core/src/main/java/com/mootdx/quotes/TdxQuoteClient.java) - K线接口实现
- [TdxProtocol.java](../mootdx-core/src/main/java/com/mootdx/protocol/TdxProtocol.java) - 协议常量定义
- [K线接口协议文档](protocol/02-K线接口协议.md) - 详细协议文档

## 总结

**核心要点**：通达信K线接口的服务器会在每次响应后主动断开连接，客户端必须在每次请求后主动清理连接状态，下次请求时重新建立连接。这是服务器的设计特性，不是客户端bug。
