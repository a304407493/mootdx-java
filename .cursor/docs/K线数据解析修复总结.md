# K线数据解析修复总结

## 问题描述

在实现K线数据获取功能时，遇到了多个关键问题，导致无法正确解析从TDX服务器返回的K线数据。

## 修复内容

### 1. BufferOverflowException错误

**问题原因**：ByteBuffer容量不足，写入数据时超出缓冲区大小。

**修复方案**：将缓冲区大小从36字节增加到40字节。

```java
// 修改前
ByteBuffer payload = ByteUtils.createBuffer(36);

// 修改后
ByteBuffer payload = ByteUtils.createBuffer(40);
```

### 2. K线记录数解析错误

**问题原因**：使用`readShortLE()`读取无符号短整数时，如果值大于32767会被解释为负数。

**修复方案**：使用`readUnsignedShortLE()`方法。

```java
// 修改前
int count = response.readShortLE();

// 修改后
int count = response.readUnsignedShortLE();
```

### 3. 响应数据解析 - 差分编码实现

**问题原因**：TDX服务器返回的K线数据使用差分编码压缩，需要按照特定格式解析。

**修复方案**：参考pytdx实现，完整解析流程如下：

#### 3.1 数据格式说明

响应数据格式（参考pytdx的`get_security_bars.py`）：

```
[2字节: 记录数]
[记录1数据]
[记录2数据]
...
```

每条记录的数据格式：

**日K线数据**（频率 >= 4）：
- 4字节：日期（YYYYMMDD格式）
- 变长：开盘价差分
- 变长：收盘价差分
- 变长：最高价差分
- 变长：最低价差分
- 4字节：成交量
- 4字节：成交额

**分钟K线数据**（频率 < 4）：
- 2字节：压缩日期
- 2字节：分钟数
- 变长：价格差分（同上）
- 4字节：成交量
- 4字节：成交额

#### 3.2 日期解析

```java
// 日K线：YYYYMMDD格式
int zipday = buf.readIntLE();
int year = zipday / 10000;
int month = (zipday % 10000) / 100;
int day = zipday % 100;

// 分钟K线：压缩格式
int zipday = buf.readUnsignedShortLE();
int tminutes = buf.readUnsignedShortLE();
int year = (zipday >> 11) + 2004;
int month = (zipday % 2048) / 100;
int day = (zipday % 2048) % 100;
int hour = tminutes / 60;
int minute = tminutes % 60;
```

#### 3.3 价格差分解码（变长编码）

参考pytdx的`get_price`函数实现：

```java
private int readPriceDiff(ByteBuf buf) {
    // 读取第一个字节
    int bdata = buf.readUnsignedByte();
    
    // 低6位是数据部分
    int intdata = bdata & 0x3f;
    
    // 第7位是符号位
    boolean sign = (bdata & 0x40) != 0;
    
    // 第8位表示是否有后续字节
    if ((bdata & 0x80) != 0) {
        int posByte = 6;
        while (true) {
            bdata = buf.readUnsignedByte();
            intdata += (bdata & 0x7f) << posByte;
            posByte += 7;
            if ((bdata & 0x80) == 0) {
                break;
            }
        }
    }
    
    // 应用符号
    if (sign) {
        intdata = -intdata;
    }
    
    return intdata;
}
```

#### 3.4 价格计算

参考pytdx的差分解码逻辑：

```java
// 读取价格差分
int priceOpenDiff = readPriceDiff(buf);
int priceCloseDiff = readPriceDiff(buf);
int priceHighDiff = readPriceDiff(buf);
int priceLowDiff = readPriceDiff(buf);

// 计算实际价格（基于前一条记录的基准值preDiffBase）
int openRaw = priceOpenDiff + preDiffBase;
int closeRaw = openRaw + priceCloseDiff;
int highRaw = openRaw + priceHighDiff;
int lowRaw = openRaw + priceLowDiff;

// 转换为实际价格（除以1000）
BigDecimal open = BigDecimal.valueOf(openRaw, 3);
BigDecimal close = BigDecimal.valueOf(closeRaw, 3);
BigDecimal high = BigDecimal.valueOf(highRaw, 3);
BigDecimal low = BigDecimal.valueOf(lowRaw, 3);
```

### 4. 价格基准值更新逻辑

**关键修复**：`preDiffBase`的更新必须使用原始的`priceCloseDiff`，而不是计算后的`closeRaw`。

```java
// 错误的做法（导致价格不断翻倍）
preDiffBase = openRaw + closeRaw;

// 正确的做法（参考pytdx实现）
preDiffBase = openRaw + priceCloseDiff;
```

## 关键代码结构

### 解析结果封装

为了避免返回多个值的问题，使用内部类封装解析结果：

```java
private static class ParseResult {
    final BarData bar;        // 解析后的K线数据
    final int openRaw;        // 更新后的price_open_diff
    final int priceCloseDiff; // 原始的price_close_diff

    ParseResult(BarData bar, int openRaw, int priceCloseDiff) {
        this.bar = bar;
        this.openRaw = openRaw;
        this.priceCloseDiff = priceCloseDiff;
    }
}
```

### 主解析流程

```java
private List<BarData> parseKLineResponse(ByteBuf response, int frequency) {
    List<BarData> bars = new ArrayList<>();
    
    // 读取记录数
    int count = response.readUnsignedShortLE();
    
    // 使用差分编码解析K线数据
    int preDiffBase = 0;
    for (int i = 0; i < count; i++) {
        ParseResult result = parseKLineBar(response, frequency, preDiffBase);
        if (result != null && result.bar != null) {
            bars.add(result.bar);
            // 更新preDiffBase用于下一条记录
            preDiffBase = result.openRaw + result.priceCloseDiff;
        }
    }
    
    return bars;
}
```

## 测试验证

API请求示例：

```
GET http://localhost:8080/api/stocks/kline/SZ/000001?freq=day&limit=10
```

返回数据示例：

```json
{
    "code": 200,
    "message": "操作成功",
    "data": {
        "code": "000001",
        "market": "SZ",
        "freq": "day",
        "data": [
            {
                "tradeDate": "2026-03-13",
                "tradeTime": null,
                "open": 10.902,
                "high": 10.972,
                "low": 10.842,
                "close": 10.902,
                "volume": 122981,
                "amount": 131462.2355
            }
            // ... 更多数据
        ]
    }
}
```

## 参考文档

- pytdx源码：`get_security_bars.py`
- TDX协议文档：`doc/K线功能实现总结.md`
