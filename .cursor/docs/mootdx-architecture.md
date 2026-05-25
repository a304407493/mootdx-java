# MooTDX Java 架构文档

## 1. 系统架构概览

### 1.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              前端层 (Vue 3)                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  TDX服务器   │  │   K线图表    │  │   股票列表   │  │      实时行情        │ │
│  │   管理页面   │  │   展示页面   │  │   管理页面   │  │      展示页面        │ │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘ │
│         │                │                │                    │            │
│         └────────────────┴────────────────┴────────────────────┘            │
│                                    │                                        │
│                              Axios HTTP Client                              │
└────────────────────────────────────┼────────────────────────────────────────┘
                                     │
                                     ▼ HTTP/JSON
┌─────────────────────────────────────────────────────────────────────────────┐
│                           服务层 (Spring Boot)                                │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                      REST API Controller Layer                          │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │ │
│  │  │TdxServer    │  │StockKline   │  │StockList    │  │RealTimeQuote│   │ │
│  │  │Controller   │  │Controller   │  │Controller   │  │Controller   │   │ │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │ │
│  │         └────────────────┴────────────────┴────────────────┘          │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                    │                                        │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                      Service Layer                                      │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │ │
│  │  │TdxServer    │  │TdxKline     │  │StockKline   │  │Cache        │   │ │
│  │  │Service      │  │Service      │  │Service      │  │Service      │   │ │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │ │
│  │         │                │                │                │          │ │
│  │         └────────────────┴────────────────┘                │          │ │
│  │                          │                                 │          │ │
│  │                   ┌──────┴──────┐                         │          │ │
│  │                   │  Executor   │                         │          │ │
│  │                   │  Service    │                         │          │ │
│  │                   └─────────────┘                         │          │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                    │                                        │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                      Repository Layer                                   │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                     │ │
│  │  │TdxServer    │  │StockKline   │  │StockMeta    │                     │ │
│  │  │Repository   │  │Repository   │  │Repository   │                     │ │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                     │ │
│  │         └────────────────┴────────────────┘                            │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────┼────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          核心层 (mootdx-core)                                 │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                      TdxQuoteClient (Netty)                             │ │
│  │  ┌──────────────────────────────────────────────────────────────────┐  │ │
│  │  │                         网络通信层                                 │  │ │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │  │ │
│  │  │  │Bootstrap    │  │Channel      │  │EventLoopGroup│              │  │ │
│  │  │  │(连接管理)    │  │(通道管理)    │  │(事件循环)     │              │  │ │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘              │  │ │
│  │  └──────────────────────────────────────────────────────────────────┘  │ │
│  │                                    │                                    │ │
│  │  ┌──────────────────────────────────────────────────────────────────┐  │ │
│  │  │                         协议处理层                                 │  │ │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │  │ │
│  │  │  │请求构建      │  │响应解析      │  │数据解压      │              │  │ │
│  │  │  │(Cmd Builder)│  │(Parser)     │  │(Zlib)       │              │  │ │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘              │  │ │
│  │  └──────────────────────────────────────────────────────────────────┘  │ │
│  │                                    │                                    │ │
│  │  ┌──────────────────────────────────────────────────────────────────┐  │ │
│  │  │                         数据处理层                                 │  │ │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │  │ │
│  │  │  │K线解析       │  │实时行情解析   │  │股票列表解析   │              │  │ │
│  │  │  │(差分解码)    │  │             │  │             │              │  │ │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘              │  │ │
│  │  └──────────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼ TCP Protocol
┌─────────────────────────────────────────────────────────────────────────────┐
│                          TDX 服务器集群                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  服务器1     │  │  服务器2     │  │  服务器3     │  │  服务器N     │         │
│  │ 119.147.x.x │  │ 115.238.x.x │  │  14.215.x.x │  │    ...      │         │
│  │   :7709     │  │   :7709     │  │   :7709     │  │   :7709     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 2. 模块依赖关系

### 2.1 Maven模块结构

```
mootdx-java (Parent POM)
├── mootdx-core (核心模块)
│   ├── Netty (网络通信)
│   ├── SLF4J (日志)
│   └── 无Spring依赖
│
├── mootdx-server (服务端模块)
│   ├── Spring Boot 2.7.18
│   ├── Spring Data JPA
│   ├── MySQL Connector
│   ├── Caffeine (缓存)
│   └── 依赖 mootdx-core
│
└── mootdx-web (前端模块)
    ├── Vue 3
    ├── Element Plus
    ├── ECharts
    └── Axios
```

### 2.2 类依赖关系图

```
┌─────────────────────────────────────────────────────────────────┐
│                      Service Layer                               │
│                                                                  │
│   TdxKlineService ───────┐                                       │
│         │                │                                       │
│         ▼                ▼                                       │
│   TdxQuoteClient    StockKlineRepository                         │
│         │                      │                                 │
│         ▼                      ▼                                 │
│   ┌──────────┐           ┌──────────┐                           │
│   │  Cache   │           │  MySQL   │                           │
│   │  Manager │           │  Database│                           │
│   └──────────┘           └──────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

## 3. 调用关系流程

### 3.1 K线数据获取流程

```
┌─────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ 前端请求 │────▶│Controller   │────▶│TdxKline     │────▶│TdxQuote     │
│         │     │             │     │Service      │     │Client       │
└─────────┘     └─────────────┘     └──────┬──────┘     └──────┬──────┘
                                           │                    │
                                           │                    ▼
                                           │            ┌─────────────┐
                                           │            │  构建请求包  │
                                           │            │  (36 bytes) │
                                           │            └──────┬──────┘
                                           │                   │
                                           │                   ▼
                                           │            ┌─────────────┐
                                           │            │  发送请求    │
                                           │            │  TCP Send   │
                                           │            └──────┬──────┘
                                           │                   │
                                           │                   ▼
                                           │            ┌─────────────┐
                                           │            │  接收响应头  │
                                           │            │  (16 bytes) │
                                           │            └──────┬──────┘
                                           │                   │
                                           │                   ▼
                                           │            ┌─────────────┐
                                           │            │  接收响应体  │
                                           │            │  (zipsize)  │
                                           │            └──────┬──────┘
                                           │                   │
                                           │                   ▼
                                           │            ┌─────────────┐
                                           │            │  Zlib解压   │
                                           │            │ (如果需要)  │
                                           │            └──────┬──────┘
                                           │                   │
                                           │                   ▼
                                           │            ┌─────────────┐
                                           │            │  解析K线数据 │
                                           │            │ (差分解码)  │
                                           │            └──────┬──────┘
                                           │                   │
                                           ▼                   │
                                    ┌─────────────┐            │
                                    │  缓存数据    │◀───────────┘
                                    │  返回前端    │
                                    └─────────────┘
```

### 3.2 请求处理时序图

```
Frontend    Controller    Service    TdxClient    TdxServer
   │            │            │            │            │
   │ ─────────▶│            │            │            │
   │  GET /api │            │            │            │
   │            │ ─────────▶│            │            │
   │            │  getKline │            │            │
   │            │            │ ─────────▶│            │
   │            │            │ getKLine() │            │
   │            │            │            │ ─────────▶│
   │            │            │            │  TCP Req   │
   │            │            │            │            │
   │            │            │            │ ◀─────────│
   │            │            │            │  TCP Resp  │
   │            │            │ ◀─────────│            │
   │            │            │  List<Bar> │            │
   │            │ ◀─────────│            │            │
   │            │  Response  │            │            │
   │ ◀─────────│            │            │            │
   │  JSON      │            │            │            │
```

## 4. 请求和响应参数

### 4.1 K线数据请求

#### HTTP API请求

```yaml
Endpoint: GET /api/stocks/kline/{market}/{code}
Parameters:
  market: string  # 市场代码: "SZ"(深圳) 或 "SH"(上海)
  code: string    # 股票代码: 如 "000001"
  freq: string    # 频率: "1min", "5min", "15min", "30min", "60min", "day", "week", "month"
  limit: integer  # 数据条数: 1-800

Example: GET /api/stocks/kline/SZ/000001?freq=day&limit=50
```

#### TDX协议请求包 (36 bytes)

```c
struct KLineRequest {
    uint16_t  cmd_prefix;     // 0x010c  [0-1]
    uint32_t  magic;          // 0x01016408 [2-5]
    uint16_t  field1;         // 0x001c  [6-7]
    uint16_t  field2;         // 0x001c  [8-9]
    uint16_t  cmd;            // 0x052d  [10-11] (CMD_GET_KLINE)
    uint16_t  market;         // 0(深圳) 或 1(上海) [12-13]
    char      code[6];        // 股票代码, 如 "000001" [14-19]
    uint16_t  category;       // 频率代码 [20-21]
    uint16_t  unknown1;       // 1 [22-23]
    uint16_t  start;          // 起始位置 [24-25]
    uint16_t  count;          // 请求数量 [26-27]
    uint32_t  unknown2;       // 0 [28-31]
    uint32_t  unknown3;       // 0 [32-35]
    uint16_t  unknown4;       // 0 [36-37]
};
```

#### 频率代码映射

| 频率    | 代码 | 说明     |
|---------|------|----------|
| 1分钟   | 8    | 1min     |
| 5分钟   | 0    | 5min     |
| 15分钟  | 1    | 15min    |
| 30分钟  | 2    | 30min    |
| 60分钟  | 3    | 60min    |
| 日线    | 9    | day      |
| 周线    | 5    | week     |
| 月线    | 6    | month    |
| 季线    | 10   | quarter  |
| 年线    | 11   | year     |

### 4.2 K线数据响应

#### HTTP API响应

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
        "tradeDate": "2024-03-15",
        "tradeTime": null,
        "open": 10.50,
        "high": 10.80,
        "low": 10.40,
        "close": 10.65,
        "volume": 1250000,
        "amount": 13200000.00
      }
    ]
  },
  "timestamp": "2024-03-16T10:30:00.000"
}
```

#### TDX协议响应

```c
// 响应头 (16 bytes)
struct ResponseHeader {
    uint32_t  unknown1;       // [0-3]
    uint32_t  unknown2;       // [4-7]
    uint32_t  unknown3;       // [8-11]
    uint16_t  zipsize;        // 压缩后大小 [12-13]
    uint16_t  unzipsize;      // 解压后大小 [14-15]
};

// 响应体 (解压后)
struct KLineBody {
    uint16_t  count;          // K线数量 [0-1]
    //  followed by KLineRecord[count]
};

// K线记录 (变长)
struct KLineRecord {
    // 日线数据:
    uint32_t  date;           // YYYYMMDD格式
    
    // 分钟数据:
    uint16_t  zipday;         // 压缩日期
    uint16_t  tminutes;       // 时间(分钟数)
    
    // 价格数据 (变长编码)
    varint    price_open_diff;   // 开盘价差分
    varint    price_close_diff;  // 收盘价差分
    varint    price_high_diff;   // 最高价差分
    varint    price_low_diff;    // 最低价差分
    
    // 成交量和成交额
    uint32_t  volume_raw;     // 原始成交量
    uint32_t  amount_raw;     // 原始成交额
};
```

## 5. 详细处理过程

### 5.1 数据包构建过程

```java
// 1. 创建缓冲区
ByteBuffer payload = ByteUtils.createBuffer(40);

// 2. 写入请求头
payload.putShort((short) 0x010c);           // 命令前缀
payload.putInt(0x01016408);                 // 魔数
payload.putShort((short) 0x001c);           // 字段1
payload.putShort((short) 0x001c);           // 字段2
payload.putShort(TdxProtocol.CMD_GET_KLINE); // 命令码 0x052d

// 3. 写入股票信息
payload.putShort((short) market);           // 市场代码
ByteUtils.writeString(payload, code, 6);    // 股票代码(6字节)

// 4. 写入查询参数
payload.putShort((short) frequency);        // 频率
payload.putShort((short) 1);                // 未知字段1
payload.putShort((short) start);            // 起始位置
payload.putShort((short) count);            // 请求数量

// 5. 填充保留字段
payload.putInt(0);                          // 保留字段1
payload.putInt(0);                          // 保留字段2
payload.putShort((short) 0);                // 保留字段3
```

### 5.2 响应数据解析过程

#### 5.2.1 响应头解析

```java
// 读取16字节响应头
byte[] headerBuf = recv(16);

// 解析zipsize和unzipsize
int zipsize = (headerBuf[12] & 0xFF) | ((headerBuf[13] & 0xFF) << 8);
int unzipsize = (headerBuf[14] & 0xFF) | ((headerBuf[15] & 0xFF) << 8);
```

#### 5.2.2 数据解压

```java
// 读取zipsize字节的压缩数据
byte[] bodyBuf = recv(zipsize);

// 如果需要解压
if (zipsize != unzipsize) {
    // 使用Zlib解压
    bodyBuf = zlibDecompress(bodyBuf);
}
```

#### 5.2.3 K线记录解析

```java
// 读取记录数
int count = bodyBuf.readUnsignedShortLE();

// 逐条解析
int preDiffBase = 0;
for (int i = 0; i < count; i++) {
    // 1. 解析日期
    long zipday = buf.readUnsignedIntLE();
    year = (int) (zipday / 10000);
    month = (int) ((zipday % 10000) / 100);
    day = (int) (zipday % 100);
    
    // 2. 解析价格差分 (变长编码)
    int priceOpenDiff = readPriceDiff(buf);
    int priceCloseDiff = readPriceDiff(buf);
    int priceHighDiff = readPriceDiff(buf);
    int priceLowDiff = readPriceDiff(buf);
    
    // 3. 计算实际价格
    int openRaw = priceOpenDiff + preDiffBase;
    int closeRaw = openRaw + priceCloseDiff;
    int highRaw = openRaw + priceHighDiff;
    int lowRaw = openRaw + priceLowDiff;
    
    // 4. 更新差分基准
    preDiffBase = openRaw + priceCloseDiff;
    
    // 5. 读取成交量和成交额
    long volume = buf.readUnsignedIntLE();
    long amount = buf.readUnsignedIntLE();
    
    // 6. 创建BarData对象
    BarData bar = BarData.builder()
        .date(year * 10000L + month * 100 + day)
        .open(BigDecimal.valueOf(openRaw, 3))
        .high(BigDecimal.valueOf(highRaw, 3))
        .low(BigDecimal.valueOf(lowRaw, 3))
        .close(BigDecimal.valueOf(closeRaw, 3))
        .volume(volume)
        .amount(BigDecimal.valueOf(amount))
        .build();
}
```

#### 5.2.4 价格差分变长编码解码

```java
private int readPriceDiff(ByteBuf buf) {
    int bdata = buf.readUnsignedByte();
    int intdata = bdata & 0x3f;  // 低6位是数据
    boolean sign = (bdata & 0x40) != 0;  // 第7位是符号位
    
    // 如果第8位为1，表示还有后续字节
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
    
    return sign ? -intdata : intdata;
}
```

### 5.3 成交量/成交额解码

```java
// pytdx的get_volume函数实现
private double decodeVolume(long ivol) {
    int logpoint = (int) (ivol >> 24);
    int hleax = (int) ((ivol >> 16) & 0xff);
    int lheax = (int) ((ivol >> 8) & 0xff);
    int lleax = (int) (ivol & 0xff);
    
    double dwEcx = logpoint * 2 - 0x7f;
    double dbl_xmm6 = Math.pow(2.0, Math.abs(dwEcx));
    if (dwEcx < 0) {
        dbl_xmm6 = 1.0 / dbl_xmm6;
    }
    
    // ... 复杂的解码逻辑
    return dbl_xmm6 + dbl_xmm4 + dbl_xmm3 + dbl_xmm1;
}
```

## 6. 封装关系

### 6.1 核心类封装结构

```
TdxQuoteClient (Netty客户端)
├── Connection Management
│   ├── connect()
│   ├── disconnect()
│   └── reconnect()
│
├── Request Methods
│   ├── getKLine()        → List<BarData>
│   ├── getQuote()        → Quote
│   ├── getQuotes()       → List<Quote>
│   ├── getStockList()    → List<StockMeta>
│   └── getMinuteData()   → List<MinuteData>
│
├── Protocol Handlers
│   ├── sendRequest()     → ByteBuf
│   ├── parseKLineResponse()    → List<BarData>
│   ├── parseQuoteResponse()    → List<Quote>
│   └── parseStockListResponse() → List<StockMeta>
│
└── Data Parsers
    ├── parseKLineBar()   → ParseResult
    ├── readPriceDiff()   → int
    └── readPrice()       → BigDecimal
```

### 6.2 数据模型封装

```
BarData (K线数据)
├── long date          // 日期 (YYYYMMDD 或 YYYYMMDDHHMM)
├── BigDecimal open    // 开盘价
├── BigDecimal high    // 最高价
├── BigDecimal low     // 最低价
├── BigDecimal close   // 收盘价
├── long volume        // 成交量
└── BigDecimal amount  // 成交额

Quote (实时行情)
├── String code        // 股票代码
├── String name        // 股票名称
├── int market         // 市场代码
├── BigDecimal lastPrice   // 最新价
├── BigDecimal open    // 开盘价
├── BigDecimal high    // 最高价
├── BigDecimal low     // 最低价
├── BigDecimal prevClose   // 昨收价
├── long volume        // 成交量
├── BigDecimal amount  // 成交额
├── BigDecimal[] bidPrices // 买1-5价
├── BigDecimal[] askPrices // 卖1-5价
├── long[] bidVolumes  // 买1-5量
└── long[] askVolumes  // 卖1-5量

StockMeta (股票元数据)
├── String code        // 股票代码
├── String name        // 股票名称
└── int market         // 市场代码
```

## 7. 关键问题分析

### 7.1 当前存在的问题

1. **响应数据解压问题**
   - 问题：没有正确处理zlib压缩的响应数据
   - 原因：Java实现缺少16字节响应头的解析
   - 影响：解析出的数据完全错误

2. **日期解析错误**
   - 问题：使用`readIntLE()`读取有符号整数，导致日期为负数
   - 修复：改为`readUnsignedIntLE()`

3. **成交量/成交额解码**
   - 问题：未实现pytdx的get_volume函数
   - 影响：成交量数据不准确

### 7.2 修复方案

1. **添加响应头解析**
```java
// 读取16字节响应头
byte[] header = new byte[16];
channel.read(header);

// 解析zipsize和unzipsize
int zipsize = (header[12] & 0xFF) | ((header[13] & 0xFF) << 8);
int unzipsize = (header[14] & 0xFF) | ((header[15] & 0xFF) << 8);

// 读取压缩数据
byte[] compressed = new byte[zipsize];
channel.read(compressed);

// 解压数据
byte[] body;
if (zipsize != unzipsize) {
    body = decompressZlib(compressed);
} else {
    body = compressed;
}
```

2. **修正日期读取**
```java
// 错误
int zipday = buf.readIntLE();

// 正确
long zipday = buf.readUnsignedIntLE();
```

3. **实现成交量解码**
```java
// 需要完整实现pytdx的get_volume函数
private double decodeVolume(long ivol) {
    // 实现复杂的浮点解码逻辑
}
```

## 8. 参考文档

- pytdx源码: https://github.com/rainx/pytdx
- TDX协议分析: https://github.com/rainx/pytdx/tree/master/pytdx/parser
- Netty文档: https://netty.io/wiki/
