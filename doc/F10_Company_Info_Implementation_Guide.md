# F10公司信息功能实现指南

## 概述

本文档详细记录了TDX F10公司信息功能的实现过程，包括协议分析、请求/响应格式、常见问题及解决方案。按照本文档可实现一次成功获取F10数据。

## 一、F10功能流程

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   前端请求      │────▶│   后端API        │────▶│   TDX客户端     │
│  /api/stocks/   │     │  StockKline      │     │  TdxQuoteClient │
│  /company/{market} │     │  Controller      │     │                 │
│  /{code}        │     └──────────────────┘     └────────┬────────┘
└─────────────────┘              │                       │
                                 ▼                       ▼
                          ┌──────────────┐      ┌──────────────┐
                          │ TdxKline     │      │  发送0x0541  │
                          │ Service      │      │  获取分类列表 │
                          └──────────────┘      └──────────────┘
                                                       │
                                                       ▼
                                               ┌──────────────┐
                                               │  发送0x0542  │
                                               │  获取内容    │
                                               └──────────────┘
```

## 二、协议详解

### 2.1 获取分类列表 (0x0541)

#### 请求格式

```
┌─────────────────────────────────────────────────────────────┐
│  固定头部 (12字节)                                           │
├────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┤
│ 0C │ 0F │ 10 │ 9B │ 00 │ 01 │ 0E │ 00 │ 0E │ 00 │ CF │ 02 │
└────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│  参数部分 (12字节)                                           │
├────────────────┬─────────────────────┬──────────────────────┤
│ market (2字节) │ code (6字节)        │ zero (4字节)         │
│ 小端ushort     │ ASCII编码，左对齐    │ 0                    │
└────────────────┴─────────────────────┴──────────────────────┘
```

**总长度: 24字节**

#### Java实现代码

```java
private List<CompanyInfoCategory> getCompanyInfoCategoryList(int market, String code) {
    // Build request payload - 参考pytdx格式
    // 头部: 0c 0f 10 9b 00 01 0e 00 0e 00 cf 02 (12字节)
    // 参数: market(2) + code(6) + 0(4) = 12字节
    // 总共24字节
    ByteBuffer payload = ByteUtils.createBuffer(24);

    // 固定头部 (12字节)
    byte[] header = new byte[] {0x0c, 0x0f, 0x10, (byte)0x9b, 0x00, 0x01, 0x0e, 0x00, 0x0e, 0x00, (byte)0xcf, 0x02};
    payload.put(header);

    // 参数部分
    payload.putShort((short) market);
    ByteUtils.writeString(payload, code, 6);
    payload.putInt(0); // 4字节0

    ByteBuf response = sendRequest(TdxProtocol.CMD_GET_COMPANY_INFO_CATEGORY, payload.array());
    // ...
}
```

#### 响应格式

```
┌─────────────────────────────────────────────────────────────┐
│  响应头 (16字节) - 由Netty处理器自动解析                      │
├─────────────────────────────────────────────────────────────┤
│  unknown1 (4) │ unknown2 (4) │ unknown3 (4) │ zipsize (4)   │
└─────────────────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│  解压后的数据                                                │
├─────────────────────────────────────────────────────────────┤
│  count (2字节, 小端ushort)                                   │
├─────────────────────────────────────────────────────────────┤
│  分类条目1 (152字节)                                         │
│  ├─ name (64字节, GBK编码)                                   │
│  ├─ filename (80字节, GBK编码)                               │
│  ├─ start (4字节, 小端uint)                                  │
│  └─ length (4字节, 小端uint)                                 │
├─────────────────────────────────────────────────────────────┤
│  分类条目2 (152字节)                                         │
│  ...                                                         │
└─────────────────────────────────────────────────────────────┘
```

#### 响应解析代码

```java
private List<CompanyInfoCategory> parseCompanyInfoCategoryList(ByteBuf response) {
    List<CompanyInfoCategory> categories = new ArrayList<>();

    // 参考pytdx格式: 前2字节是数量(小端ushort)
    int count = response.readUnsignedShortLE();

    for (int i = 0; i < count; i++) {
        // 检查是否有足够的数据
        if (response.readableBytes() < 152) {
            break;
        }

        // Read category name (64 bytes, GBK encoding)
        String name = response.readSlice(64).toString(Charset.forName("GBK")).trim();
        // Read filename (80 bytes, GBK encoding)
        String filename = response.readSlice(80).toString(Charset.forName("GBK")).trim();
        // Read start (4 bytes) and length (4 bytes)
        int start = response.readIntLE();
        int length = response.readIntLE();

        // 去除\x00字符
        name = name.replaceAll("\\x00", "").trim();
        filename = filename.replaceAll("\\x00", "").trim();

        if (!name.isEmpty() && !filename.isEmpty()) {
            categories.add(new CompanyInfoCategory(name, filename));
        }
    }

    return categories;
}
```

### 2.2 获取公司信息内容 (0x0542)

#### 请求格式

```
┌─────────────────────────────────────────────────────────────┐
│  固定头部 (12字节)                                           │
├────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┤
│ 0C │ 07 │ 10 │ 9C │ 00 │ 01 │ 68 │ 00 │ 68 │ 00 │ D0 │ 02 │
└────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│  参数部分 (102字节)                                          │
├────────┬────────┬────────┬──────────┬────────┬────────┬─────┤
│ market │ code   │ zero   │ filename │ start  │ length │ zero│
│ (2字节) │ (6字节)│ (2字节)│ (80字节)  │ (4字节)│ (4字节)│(4字节)│
│ ushort │ ASCII  │ ushort │ GBK编码   │ uint   │ uint   │     │
│ 小端   │ 左对齐 │ 0      │ 左对齐    │ 小端   │ 小端   │ 0   │
└────────┴────────┴────────┴──────────┴────────┴────────┴─────┘
```

**总长度: 114字节**

#### Java实现代码

```java
// Build request payload
ByteBuffer payload = ByteUtils.createBuffer(114);

// 固定头部 (12字节)
byte[] header = new byte[] {0x0c, 0x07, 0x10, (byte)0x9c, 0x00, 0x01, 0x68, 0x00, 0x68, 0x00, (byte)0xd0, 0x02};
payload.put(header);

// 参数部分
payload.putShort((short) market);

// 股票代码左对齐，不足补空格
byte[] codeBytes = new byte[6];
byte[] inputCode = cleanCode.getBytes(java.nio.charset.Charset.forName("GBK"));
System.arraycopy(inputCode, 0, codeBytes, 0, Math.min(inputCode.length, 6));
payload.put(codeBytes);

payload.putShort((short) 0); // 2字节0

// 文件名左对齐，不足补0
byte[] filenameBytes = new byte[80];
byte[] inputFilename = firstCategory.getFilename().getBytes(java.nio.charset.Charset.forName("GBK"));
System.arraycopy(inputFilename, 0, filenameBytes, 0, Math.min(inputFilename.length, 80));
payload.put(filenameBytes);

payload.putInt(0); // start position
payload.putInt(10000); // length (最大10000字节)
payload.putInt(0); // 4字节0

ByteBuf response = sendRequest(TdxProtocol.CMD_GET_COMPANY_INFO, payload.array());
```

#### 响应格式

```
┌─────────────────────────────────────────────────────────────┐
│  解压后的数据                                                │
├─────────────────────────────────────────────────────────────┤
│  skip (10字节)                                               │
├─────────────────────────────────────────────────────────────┤
│  content_length (2字节, 小端ushort)                          │
├─────────────────────────────────────────────────────────────┤
│  content (content_length字节, GBK编码)                       │
└─────────────────────────────────────────────────────────────┘
```

#### 响应解析代码

```java
private CompanyInfo parseCompanyInfo(ByteBuf response, int market, String code, String categoryName) {
    // 参考pytdx格式: 前10字节跳过，接下来2字节是内容长度
    // struct.unpack(u'<10sH', body_buf[:12])
    response.skipBytes(10);
    int length = response.readUnsignedShortLE();

    // 检查长度是否合理
    if (length <= 0 || length > response.readableBytes()) {
        return null;
    }

    // Read content (GBK encoding)
    byte[] contentBytes = new byte[length];
    response.readBytes(contentBytes);
    String content = new String(contentBytes, Charset.forName("GBK"));

    // 解析内容...
}
```

## 三、关键要点总结

### 3.1 字节序

- 所有数值类型均为**小端序** (Little-Endian)
- 使用 `readUnsignedShortLE()`、`readIntLE()` 等方法读取

### 3.2 编码方式

- **股票代码**: ASCII编码，左对齐，不足补空格
- **文件名**: GBK编码，左对齐，不足补\0
- **分类名称**: GBK编码
- **内容**: GBK编码

### 3.3 固定头部

两个命令的固定头部不同，必须严格按照pytdx的格式：

- **0x0541**: `0c 0f 10 9b 00 01 0e 00 0e 00 cf 02`
- **0x0542**: `0c 07 10 9c 00 01 68 00 68 00 d0 02`

### 3.4 响应解析

- **分类列表**: 前2字节是数量（小端ushort），每个条目152字节
- **内容**: 前10字节跳过，接下来2字节是内容长度

## 四、常见问题及解决方案

### 4.1 请求超时

**原因**: 请求包格式不正确，服务器无法识别

**解决**: 严格按照本文档的请求格式构建payload，特别是固定头部

### 4.2 分类数量解析错误

**原因**: 使用 `readUnsignedByte()` 读取数量，但格式是2字节ushort

**解决**: 使用 `readUnsignedShortLE()`

### 4.3 内容长度解析错误

**原因**: 直接读取4字节作为长度，但格式是跳过10字节后读取2字节ushort

**解决**: 先 `skipBytes(10)`，然后 `readUnsignedShortLE()`

### 4.4 中文乱码

**原因**: 编码方式不正确

**解决**: 分类名称和内容使用GBK编码解析

## 五、完整调用示例

```java
// 1. 获取分类列表
List<CompanyInfoCategory> categories = getCompanyInfoCategoryList(market, code);
if (categories == null || categories.isEmpty()) {
    return null;
}

// 2. 获取第一个分类的内容（通常是"公司概况"）
CompanyInfoCategory firstCategory = categories.get(0);
CompanyInfo info = getCompanyInfoContent(market, code, firstCategory);

// 3. 解析内容
// content包含公司信息的文本内容，可以进一步解析提取具体字段
```

## 六、参考资料

- pytdx源码: `pytdx/parser/get_company_info_category.py`
- pytdx源码: `pytdx/parser/get_company_info_content.py`
- TDX协议文档

## 七、版本记录

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0 | 2026-03-18 | 初始版本，完整实现F10公司信息获取 |
