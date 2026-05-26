# MooTDX Java

[![Java](https://img.shields.io/badge/Java-8%2B-blue)](https://www.oracle.com/java/technologies/)
[![Maven](https://img.shields.io/badge/Maven-3.6%2B-green)](https://maven.apache.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-2.7%2B-brightgreen)](https://spring.io/projects/spring-boot)

> Java 实现的通达信(TDX)股票数据读取库，支持本地数据文件解析和在线实时行情获取。

## 📖 项目简介

MooTDX Java 是一个功能完整的通达信数据访问库，提供以下核心能力：

- 📁 **本地数据读取** - 解析通达信安装目录下的 `.day`, `.lc1`, `.lc5` 等二进制数据文件
- 🌐 **在线行情获取** - 通过 TCP 连接通达信服务器获取实时行情数据
- 📊 **K线数据支持** - 支持日线、分钟线、5分钟线等多种K线数据获取
- 📈 **财务数据下载** - 下载和解析上市公司财务报表数据
- 🔄 **复权计算** - 支持前复权、后复权价格计算
- 💾 **数据导入** - 支持通达信本地数据导入到数据库
- 🗄️ **数据库管理** - 内置数据库管理功能，支持SQL执行
- 🏷️ **标签管理** - 股票标签和题材管理功能
- 📝 **持仓笔记** - 股票持仓笔记记录功能

## 🏗️ 项目架构

```
mootdx-java/
├── mootdx-core/          # 核心模块 - TDX数据读取和协议实现
│   ├── reader/           # 本地文件读取器
│   ├── quotes/           # 在线行情客户端
│   ├── affair/           # 财务数据服务
│   ├── cli/              # 命令行工具
│   ├── model/            # 数据模型
│   ├── protocol/         # TDX协议实现
│   └── cache/            # 缓存管理
├── mootdx-server/        # 服务端模块 - Spring Boot Web服务
│   ├── controller/       # REST API控制器
│   ├── service/          # 业务服务层
│   ├── dto/              # 数据传输对象
│   └── config/           # 配置类
└── mootdx-web/           # 前端模块 - Vue.js管理界面
    ├── src/views/        # 页面组件
    └── src/api/          # API接口
```

## 🚀 快速开始

### 环境要求

- Java 8 或更高版本
- Maven 3.6 或更高版本
- Node.js 14+ (前端开发)
- 通达信安装目录 (用于本地数据读取)

### 构建项目

```bash
# 克隆仓库
git clone https://github.com/a304407493/mootdx-java.git
cd mootdx-java

# 构建核心模块
mvn clean install -pl mootdx-core -am

# 构建服务端
mvn clean package -pl mootdx-server -am
```

### 启动服务

```bash
# 启动后端服务
cd mootdx-server
mvn spring-boot:run

# 启动前端 (开发模式)
cd mootdx-web
npm install
npm run serve
```

访问 http://localhost:8080 查看管理界面

## 📦 核心功能

### 1. 本地数据读取

```java
import com.mootdx.reader.TdxFileReader;
import com.mootdx.model.BarData;
import java.nio.file.Paths;
import java.util.List;

// 创建读取器
TdxFileReader reader = new TdxFileReader(Paths.get("C:/new_tdx"));

// 读取日线数据
List<BarData> dailyData = reader.readDaily("600036");

// 读取1分钟数据
List<BarData> minute1Data = reader.readMinute1("600036");

// 读取5分钟数据
List<BarData> minute5Data = reader.readMinute5("600036");
```

### 2. 在线行情获取

```java
import com.mootdx.quotes.TdxQuoteClient;
import com.mootdx.model.Quote;

// 创建客户端（自动选择最优服务器）
TdxQuoteClient client = TdxQuoteClient.factory("std", true, true);

// 获取实时行情
Quote quote = client.getQuote("600036");
System.out.println("当前价格: " + quote.getLastPrice());
System.out.println("涨跌幅: " + quote.getChangePercent() + "%");

// 获取K线数据
List<BarData> kline = client.getDaily("600036", 100);  // 最近100天日线
List<BarData> minute1 = client.getMinute1("600036", 100);  // 最近100条1分钟线
```

### 3. 财务数据下载

```java
import com.mootdx.affair.AffairService;

AffairService affair = new AffairService();

// 列出可用文件
List<String> files = affair.listFiles();

// 下载财务报表
affair.downloadReport("gpcw20231231.zip", Paths.get("./downloads"));
```

### 4. 复权计算

```java
import com.mootdx.utils.AdjustmentUtils;

// 前复权
List<BarData> qfqData = AdjustmentUtils.toQfq(rawData);

// 后复权
List<BarData> hfqData = AdjustmentUtils.toHfq(rawData);
```

## 🛠️ 命令行工具

```bash
# 读取本地日线数据
java -jar mootdx-core.jar reader daily -s 600036 -d C:/new_tdx

# 获取实时行情
java -jar mootdx-core.jar quotes get -s 600036

# 获取K线数据
java -jar mootdx-core.jar quotes bars -s 600036 -f 9 -n 100

# 查找最优服务器
java -jar mootdx-core.jar bestip

# 列出财务文件
java -jar mootdx-core.jar affair list
```

## 📚 文档

- [项目概述与快速开始](docs/入门/01-项目概述与快速开始.md)
- [数据源配置详解](docs/入门/02-数据源配置详解.md)
- [查询模式与降级策略](docs/入门/03-查询模式与降级策略.md)
- [多源融合与数据合并](docs/入门/04-多源融合与数据合并.md)
- [高级配置与最佳实践](docs/入门/05-高级配置与最佳实践.md)
- [K线图功能完整复刻指南](docs/K线图功能完整复刻指南.md)
- [缓存管理功能完整复刻指南](docs/缓存管理功能完整复刻指南.md)
- [题材检索功能完整复刻指南](docs/题材检索功能完整复刻指南.md)
- [通达信本地数据导入指南](docs/通达信本地数据导入指南.md)

## 🔌 API 接口

服务端提供完整的 REST API：

| 接口 | 说明 |
|------|------|
| `GET /api/kline/{symbol}` | 获取K线数据 |
| `GET /api/quote/{symbol}` | 获取实时行情 |
| `GET /api/stock/list` | 获取股票列表 |
| `POST /api/import/tdx` | 导入通达信数据 |
| `POST /api/db/execute` | 执行SQL |
| `GET /api/server/list` | 获取服务器列表 |
| `GET /api/theme/list` | 获取题材列表 |
| `GET /api/tag/list` | 获取标签列表 |

## 📊 数据模型

### BarData (K线数据)
```java
public class BarData {
    private int date;           // 日期 (YYYYMMDD)
    private int time;           // 时间 (HHMM)
    private BigDecimal open;    // 开盘价
    private BigDecimal high;    // 最高价
    private BigDecimal low;     // 最低价
    private BigDecimal close;   // 收盘价
    private long volume;        // 成交量
    private BigDecimal amount;  // 成交额
}
```

### Quote (实时行情)
```java
public class Quote {
    private String code;              // 股票代码
    private String name;              // 股票名称
    private BigDecimal lastPrice;     // 最新价
    private BigDecimal open;          // 开盘价
    private BigDecimal high;          // 最高价
    private BigDecimal low;           // 最低价
    private BigDecimal prevClose;     // 昨收价
    private long volume;              // 成交量
    private BigDecimal amount;        // 成交额
    private BigDecimal changePercent; // 涨跌幅
}
```

## ⚙️ 配置说明

### 通达信服务器列表

默认服务器 (端口 7709):
- 119.147.212.81
- 221.231.141.60
- 58.63.254.191
- 115.238.90.165
- 14.215.128.18

### 配置文件

`mootdx-core/src/main/resources/tdx-config.properties`:
```properties
# 通达信安装路径
tdx.path=C:/new_tdx

# 服务器配置
tdx.server.host=119.147.212.81
tdx.server.port=7709

# 缓存配置
cache.expire.minutes=60
```

## 🧪 测试

```bash
# 运行所有测试
mvn test

# 运行特定测试
mvn test -Dtest=TdxFileReaderTest

# 运行集成测试
mvn test -Dtest=*IntegrationTest
```

## 📦 依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| Netty | 4.1.100.Final | TCP通信 |
| Spring Boot | 2.7.x | Web服务框架 |
| Jackson | 2.15.2 | JSON处理 |
| Caffeine | 2.9.3 | 本地缓存 |
| picocli | 4.7.5 | 命令行工具 |
| Lombok | 1.18.30 | 代码生成 |
| Tablesaw | 0.43.1 | 数据分析 |

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 [MIT](LICENSE) 许可证

## 🙏 致谢

- [mootdx](https://github.com/bopo/mootdx) - Python 版通达信数据读取库
- [pytdx](https://github.com/rainx/pytdx) - TDX 协议底层实现

## 👥 加入社区

我们有一个活跃的开发者社区，欢迎你的加入！

### 💬 微信群

扫描下方二维码加入 **akshare和mootdx** 交流群，与其他开发者一起讨论：

![微信群二维码](docs/images/wechat-group.png)

> 如果二维码过期，请添加作者微信拉你入群

### 👤 联系作者

有任何问题或建议，欢迎添加作者微信：

![个人微信二维码](docs/images/wechat-personal.png)

### 🚀 参与开发

我们非常欢迎你的贡献！无论是代码、文档、Bug 反馈还是新功能建议，都是对我们的大力支持。

查看 [COMMUNITY.md](docs/COMMUNITY.md) 了解更多参与方式。

## 📞 其他联系方式

- GitHub Issues: [https://github.com/a304407493/mootdx-java/issues](https://github.com/a304407493/mootdx-java/issues)
- 项目主页: [https://github.com/a304407493/mootdx-java](https://github.com/a304407493/mootdx-java)

---

<p align="center">如果这个项目对你有帮助，请给个 ⭐ Star 支持一下！</p>
<p align="center">期待你的加入，一起打造更好的金融数据工具！🎉</p>
