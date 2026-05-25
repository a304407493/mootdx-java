# K线图功能完整复刻指南

> 本文档详细描述了如何完整复刻 MooTDX 项目中的K线图功能，包括前后端实现细节、交互逻辑、配置参数等所有内容。

---

## 目录

- [一、项目概述](#一项目概述)
- [二、Maven JAR 包配置](#二maven-jar-包配置)
- [三、后端实现详解](#三后端实现详解)
- [四、前端实现详解](#四前端实现详解)
- [五、数据交互格式](#五数据交互格式)
- [六、配置文件详解](#六配置文件详解)
- [七、部署与运行](#七部署与运行)

---

## 一、项目概述

### 1.1 功能特性

K线图功能提供以下核心能力：

| 功能模块 | 详细说明 |
|---------|---------|
| **K线周期** | 支持 1min、5min、15min、30min、60min、day、week、month、quarter、year 共10种周期 |
| **复权方式** | 支持不复权、前复权(qfq)、后复权(hfq) 三种方式 |
| **技术指标** | MA均线(5/10/20/60)、MACD、KDJ、RSI、布林带 |
| **画线工具** | 趋势线、线段、矩形、清除画线 |
| **数据导出** | 支持 CSV、JSON、Excel 格式导出 |
| **缓存机制** | 后端数据库缓存，减少TDX服务器压力 |

### 1.2 技术栈

**后端：**
- Java 8
- Spring Boot 2.x
- Spring Data JPA
- H2 Database（可切换为 MySQL）
- Netty（TDX通信）
- Lombok

**前端：**
- Vue 3.3.4 + Composition API
- ECharts 6.0.0（图表库）
- Element Plus 2.3.14（UI组件）
- Axios（HTTP请求）
- Vue Router 4.2.4

---

## 二、Maven JAR 包配置

### 2.1 父POM配置

**文件路径：** `pom.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.mootdx</groupId>
    <artifactId>mootdx-parent</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging>

    <name>MooTDX Parent</name>
    <description>Parent POM for MooTDX Java project</description>

    <!-- 子模块配置 -->
    <modules>
        <module>mootdx-core</module>
        <module>mootdx-server</module>
    </modules>

    <properties>
        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>

        <!-- Dependency Versions -->
        <netty.version>4.1.100.Final</netty.version>
        <picocli.version>4.7.5</picocli.version>
        <jackson.version>2.15.2</jackson.version>
        <lombok.version>1.18.30</lombok.version>
        <slf4j.version>1.7.36</slf4j.version>
        <logback.version>1.2.12</logback.version>
        <caffeine.version>2.9.3</caffeine.version>
        <tablesaw.version>0.43.1</tablesaw.version>
        <junit.version>5.9.3</junit.version>
        <mockito.version>4.11.0</mockito.version>
        <assertj.version>3.24.2</assertj.version>
    </properties>

    <dependencyManagement>
        <dependencies>
            <!-- Netty for TCP communication -->
            <dependency>
                <groupId>io.netty</groupId>
                <artifactId>netty-all</artifactId>
                <version>${netty.version}</version>
            </dependency>

            <!-- picocli for CLI -->
            <dependency>
                <groupId>info.picocli</groupId>
                <artifactId>picocli</artifactId>
                <version>${picocli.version}</version>
            </dependency>

            <!-- Jackson for JSON processing -->
            <dependency>
                <groupId>com.fasterxml.jackson.core</groupId>
                <artifactId>jackson-databind</artifactId>
                <version>${jackson.version}</version>
            </dependency>
            <dependency>
                <groupId>com.fasterxml.jackson.core</groupId>
                <artifactId>jackson-core</artifactId>
                <version>${jackson.version}</version>
            </dependency>
            <dependency>
                <groupId>com.fasterxml.jackson.datatype</groupId>
                <artifactId>jackson-datatype-jsr310</artifactId>
                <version>${jackson.version}</version>
            </dependency>

            <!-- Lombok for code generation -->
            <dependency>
                <groupId>org.projectlombok</groupId>
                <artifactId>lombok</artifactId>
                <version>${lombok.version}</version>
                <scope>provided</scope>
            </dependency>

            <!-- SLF4J Logging -->
            <dependency>
                <groupId>org.slf4j</groupId>
                <artifactId>slf4j-api</artifactId>
                <version>${slf4j.version}</version>
            </dependency>
            <dependency>
                <groupId>ch.qos.logback</groupId>
                <artifactId>logback-classic</artifactId>
                <version>${logback.version}</version>
            </dependency>

            <!-- Caffeine for caching -->
            <dependency>
                <groupId>com.github.ben-manes.caffeine</groupId>
                <artifactId>caffeine</artifactId>
                <version>${caffeine.version}</version>
            </dependency>

            <!-- Tablesaw for data analysis -->
            <dependency>
                <groupId>tech.tablesaw</groupId>
                <artifactId>tablesaw-core</artifactId>
                <version>${tablesaw.version}</version>
            </dependency>

            <!-- JUnit 5 for testing -->
            <dependency>
                <groupId>org.junit.jupiter</groupId>
                <artifactId>junit-jupiter</artifactId>
                <version>${junit.version}</version>
                <scope>test</scope>
            </dependency>

            <!-- Mockito for mocking -->
            <dependency>
                <groupId>org.mockito</groupId>
                <artifactId>mockito-core</artifactId>
                <version>${mockito.version}</version>
                <scope>test</scope>
            </dependency>
            <dependency>
                <groupId>org.mockito</groupId>
                <artifactId>mockito-junit-jupiter</artifactId>
                <version>${mockito.version}</version>
                <scope>test</scope>
            </dependency>

            <!-- AssertJ for fluent assertions -->
            <dependency>
                <groupId>org.assertj</groupId>
                <artifactId>assertj-core</artifactId>
                <version>${assertj.version}</version>
                <scope>test</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <build>
        <plugins>
            <!-- Compiler Plugin -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
                <configuration>
                    <source>1.8</source>
                    <target>1.8</target>
                    <annotationProcessorPaths>
                        <path>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                            <version>${lombok.version}</version>
                        </path>
                    </annotationProcessorPaths>
                </configuration>
            </plugin>

            <!-- Surefire Plugin for testing -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.1.2</version>
            </plugin>
        </plugins>
    </build>

    <repositories>
        <repository>
            <id>aliyun</id>
            <url>https://maven.aliyun.com/repository/public</url>
        </repository>
        <repository>
            <id>central</id>
            <url>https://repo.maven.apache.org/maven2</url>
        </repository>
    </repositories>
</project>
```

### 2.2 核心模块POM配置

**文件路径：** `mootdx-core/pom.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.mootdx</groupId>
        <artifactId>mootdx-parent</artifactId>
        <version>1.0.0</version>
    </parent>

    <artifactId>mootdx-core</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <name>MooTDX Core</name>
    <description>Core library for MooTDX - TongDaXin stock data reader</description>

    <dependencies>
        <!-- Netty for TCP communication -->
        <dependency>
            <groupId>io.netty</groupId>
            <artifactId>netty-all</artifactId>
        </dependency>

        <!-- picocli for CLI -->
        <dependency>
            <groupId>info.picocli</groupId>
            <artifactId>picocli</artifactId>
        </dependency>

        <!-- Jackson for JSON processing -->
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
        </dependency>
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-core</artifactId>
        </dependency>

        <!-- Lombok for code generation -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <scope>provided</scope>
        </dependency>

        <!-- SLF4J Logging -->
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-api</artifactId>
        </dependency>
        <dependency>
            <groupId>ch.qos.logback</groupId>
            <artifactId>logback-classic</artifactId>
        </dependency>

        <!-- Caffeine for caching -->
        <dependency>
            <groupId>com.github.ben-manes.caffeine</groupId>
            <artifactId>caffeine</artifactId>
        </dependency>

        <!-- Tablesaw for data analysis -->
        <dependency>
            <groupId>tech.tablesaw</groupId>
            <artifactId>tablesaw-core</artifactId>
        </dependency>

        <!-- JUnit 5 for testing -->
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <scope>test</scope>
        </dependency>

        <!-- Mockito for mocking -->
        <dependency>
            <groupId>org.mockito</groupId>
            <artifactId>mockito-core</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.mockito</groupId>
            <artifactId>mockito-junit-jupiter</artifactId>
            <scope>test</scope>
        </dependency>

        <!-- AssertJ for fluent assertions -->
        <dependency>
            <groupId>org.assertj</groupId>
            <artifactId>assertj-core</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <!-- Shade Plugin for executable JAR -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-shade-plugin</artifactId>
                <version>3.5.0</version>
                <executions>
                    <execution>
                        <phase>package</phase>
                        <goals>
                            <goal>shade</goal>
                        </goals>
                        <configuration>
                            <shadedArtifactAttached>true</shadedArtifactAttached>
                            <shadedClassifierName>shaded</shadedClassifierName>
                            <transformers>
                                <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                                    <mainClass>com.mootdx.cli.MootdxCommand</mainClass>
                                </transformer>
                            </transformers>
                        </configuration>
                    </execution>
                </executions>
            </plugin>

            <!-- JAR Plugin -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-jar-plugin</artifactId>
                <version>3.3.0</version>
                <configuration>
                    <archive>
                        <manifest>
                            <addClasspath>true</addClasspath>
                            <mainClass>com.mootdx.cli.MootdxCommand</mainClass>
                        </manifest>
                    </archive>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

### 2.3 外部项目引用方式

在您的项目中，通过以下方式引用 MooTDX JAR 包：

**方式一：本地安装**

```bash
# 克隆项目后执行
cd mootdx-java
mvn clean install

# 在您的项目中添加依赖
```

```xml
<dependency>
    <groupId>com.mootdx</groupId>
    <artifactId>mootdx-core</artifactId>
    <version>1.0.0</version>
</dependency>
```

**方式二：私有Maven仓库**

```xml
<!-- 在 pom.xml 中添加仓库 -->
<repositories>
    <repository>
        <id>your-private-repo</id>
        <url>http://your-maven-repo.com/releases</url>
    </repository>
</repositories>

<dependencies>
    <dependency>
        <groupId>com.mootdx</groupId>
        <artifactId>mootdx-core</artifactId>
        <version>1.0.0</version>
    </dependency>
</dependencies>
```

---

## 三、后端实现详解

### 3.1 Controller层

**文件路径：** `mootdx-server/src/main/java/com/mootdx/server/controller/StockKlineController.java`

```java
package com.mootdx.server.controller;

import com.mootdx.model.StockMeta;
import com.mootdx.server.common.Result;
import com.mootdx.server.dto.KlineRequestDTO;
import com.mootdx.server.dto.KlineResponseDTO;
import com.mootdx.server.service.StockKlineService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

/**
 * K线数据Controller
 * 提供K线数据查询API接口
 *
 * @author MooTDX
 * @since 1.0.0
 */
@Slf4j
@RestController
@RequestMapping("/api/stocks")
@Validated
@CrossOrigin(origins = "*")
public class StockKlineController {

    @Autowired
    private StockKlineService stockKlineService;

    /**
     * 获取K线数据
     * GET /api/stocks/kline/{market}/{code}
     *
     * @param market  市场代码(SH/SZ)
     * @param code    股票代码
     * @param request 请求参数（包含freq、start、end、limit等）
     * @return K线数据响应
     */
    @GetMapping("/kline/{market}/{code}")
    public Result<KlineResponseDTO> getKlineData(
            @PathVariable String market,
            @PathVariable String code,
            @Valid KlineRequestDTO request) {

        log.info("[getKlineData] 收到K线数据请求: market={}, code={}", market, code);

        // 设置路径参数
        request.setMarket(market.toUpperCase());
        request.setCode(code);

        // 获取K线数据
        KlineResponseDTO response = stockKlineService.getKlineData(request);

        log.info("[getKlineData] 返回K线数据: {}条", response.getData().size());
        return Result.success(response);
    }

    /**
     * 清除K线缓存
     * DELETE /api/stocks/kline/{market}/{code}/cache
     *
     * @param market 市场代码(SH/SZ)
     * @param code   股票代码
     * @param freq   频率
     * @return 操作结果
     */
    @DeleteMapping("/kline/{market}/{code}/cache")
    public Result<Void> clearKlineCache(
            @PathVariable String market,
            @PathVariable String code,
            @RequestParam String freq) {

        log.info("[clearKlineCache] 清除K线缓存: market={}, code={}, freq={}", market, code, freq);

        stockKlineService.clearCache(code, market.toUpperCase(), freq);

        return Result.success(null);
    }

    /**
     * 获取公司资料(F10)
     * GET /api/stocks/company/{market}/{code}
     *
     * @param market 市场代码(SH/SZ)
     * @param code   股票代码
     * @return 公司资料
     */
    @GetMapping("/company/{market}/{code}")
    public Result<Object> getCompanyInfo(
            @PathVariable String market,
            @PathVariable String code) {

        log.info("[getCompanyInfo] 收到请求: market={}, code={}", market, code);

        try {
            String upperMarket = market.toUpperCase();
            Object companyInfo = stockKlineService.getCompanyInfo(upperMarket, code);

            if (companyInfo == null) {
                return Result.error(500, "获取公司资料失败，请检查TDX服务器连接");
            }

            return Result.success(companyInfo);
        } catch (Exception e) {
            log.error("[getCompanyInfo] 获取公司资料异常: {}", e.getMessage(), e);
            return Result.error(500, "获取公司资料失败: " + e.getMessage());
        }
    }

    /**
     * 获取股票列表
     * GET /api/stocks/list/{market}
     *
     * @param market 市场代码(0=深圳, 1=上海)
     * @return 股票列表
     */
    @GetMapping("/list/{market}")
    public Result<List<StockMeta>> getStockList(@PathVariable("market") int market) {
        log.info("[getStockList] 获取股票列表: market={}", market);

        List<StockMeta> stockList = stockKlineService.getStockList(market);

        if (stockList == null) {
            log.error("[getStockList] 获取股票列表失败，返回空列表");
            return Result.error(500, "获取股票列表失败，请检查TDX服务器连接");
        }

        return Result.success(stockList);
    }
}
```

### 3.2 Service层 - 业务服务

**文件路径：** `mootdx-server/src/main/java/com/mootdx/server/service/StockKlineService.java`

```java
package com.mootdx.server.service;

import com.mootdx.model.StockMeta;
import com.mootdx.server.dto.KlineDataDTO;
import com.mootdx.server.dto.KlineRequestDTO;
import com.mootdx.server.dto.KlineResponseDTO;
import com.mootdx.server.entity.StockKline;
import com.mootdx.server.repository.StockKlineRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

/**
 * K线数据服务
 * 负责K线数据的查询、缓存和管理
 *
 * @author MooTDX
 * @since 1.0.0
 */
@Slf4j
@Service
public class StockKlineService {

    @Autowired
    private StockKlineRepository stockKlineRepository;

    @Autowired
    private TdxKlineService tdxKlineService;

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyyMMdd");

    /**
     * 获取K线数据
     * 优先从数据库查询，如不存在则从TDX获取并缓存
     *
     * @param request 请求参数
     * @return K线数据响应
     */
    public KlineResponseDTO getKlineData(KlineRequestDTO request) {
        log.info("[getKlineData] 获取K线数据: code={}, market={}, freq={}, limit={}",
                request.getCode(), request.getMarket(), request.getFreq(), request.getLimit());

        List<KlineDataDTO> data;

        // 判断是否强制刷新
        if (Boolean.TRUE.equals(request.getForceRefresh())) {
            log.info("[getKlineData] 强制刷新，从TDX获取数据");
            data = fetchFromTdxAndCache(request);
        } else {
            // 先尝试从数据库获取
            data = fetchFromDatabase(request);

            // 如果数据库没有数据，从TDX获取
            if (data.isEmpty()) {
                log.info("[getKlineData] 数据库无数据，从TDX获取");
                data = fetchFromTdxAndCache(request);
            } else {
                log.info("[getKlineData] 从数据库获取到{}条数据", data.size());
            }
        }

        return KlineResponseDTO.builder()
                .code(request.getCode())
                .market(request.getMarket())
                .freq(request.getFreq())
                .data(data)
                .build();
    }

    /**
     * 从数据库获取K线数据
     */
    private List<KlineDataDTO> fetchFromDatabase(KlineRequestDTO request) {
        List<StockKline> entities;

        // 如果有日期范围，按日期范围查询
        if (request.getStart() != null && request.getEnd() != null) {
            LocalDate startDate = LocalDate.parse(request.getStart(), DATE_FORMATTER);
            LocalDate endDate = LocalDate.parse(request.getEnd(), DATE_FORMATTER);
            entities = stockKlineRepository.findByCodeAndMarketAndFreqAndTradeDateBetweenOrderByTradeDateDesc(
                    request.getCode(), request.getMarket(), request.getFreq(), startDate, endDate);
        } else {
            // 否则按数量限制查询
            entities = stockKlineRepository.findTop500ByCodeAndMarketAndFreqOrderByTradeDateDescTradeTimeDesc(
                    request.getCode(), request.getMarket(), request.getFreq());
        }

        return entities.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 从TDX获取数据并缓存到数据库
     */
    @Transactional
    private List<KlineDataDTO> fetchFromTdxAndCache(KlineRequestDTO request) {
        // 从TDX获取数据
        List<KlineDataDTO> data = tdxKlineService.getKlineDataFromTdx(
                request.getCode(), request.getMarket(), request.getFreq(), request.getLimit());

        if (data.isEmpty()) {
            log.warn("[fetchFromTdxAndCache] 从TDX获取数据为空");
            return data;
        }

        log.info("[fetchFromTdxAndCache] 从TDX获取到{}条数据，开始缓存", data.size());

        // 保存到数据库
        for (KlineDataDTO dto : data) {
            try {
                // 检查是否已存在
                boolean exists = stockKlineRepository.existsByCodeAndMarketAndFreqAndTradeDate(
                        request.getCode(), request.getMarket(), request.getFreq(), dto.getTradeDate());

                if (!exists) {
                    StockKline entity = convertToEntity(dto, request.getCode(), request.getMarket(), request.getFreq());
                    stockKlineRepository.save(entity);
                }
            } catch (Exception e) {
                log.warn("[fetchFromTdxAndCache] 保存K线数据失败: {}", e.getMessage());
            }
        }

        log.info("[fetchFromTdxAndCache] 数据缓存完成");
        return data;
    }

    /**
     * 将实体转换为DTO
     */
    private KlineDataDTO convertToDTO(StockKline entity) {
        return KlineDataDTO.builder()
                .tradeDate(entity.getTradeDate())
                .tradeTime(entity.getTradeTime())
                .open(entity.getOpen())
                .high(entity.getHigh())
                .low(entity.getLow())
                .close(entity.getClose())
                .volume(entity.getVolume())
                .amount(entity.getAmount())
                .build();
    }

    /**
     * 将DTO转换为实体
     */
    private StockKline convertToEntity(KlineDataDTO dto, String code, String market, String freq) {
        return StockKline.builder()
                .code(code)
                .market(market)
                .freq(freq)
                .tradeDate(dto.getTradeDate())
                .tradeTime(dto.getTradeTime())
                .open(dto.getOpen())
                .high(dto.getHigh())
                .low(dto.getLow())
                .close(dto.getClose())
                .volume(dto.getVolume())
                .amount(dto.getAmount())
                .build();
    }

    /**
     * 清除指定股票、频率的缓存数据
     *
     * @param code   股票代码
     * @param market 市场代码
     * @param freq   频率
     */
    @Transactional
    public void clearCache(String code, String market, String freq) {
        log.info("[clearCache] 清除K线缓存: code={}, market={}, freq={}", code, market, freq);
        stockKlineRepository.deleteByCodeAndMarketAndFreq(code, market, freq);
    }

    /**
     * 获取最新的K线数据
     *
     * @param code   股票代码
     * @param market 市场代码
     * @param freq   频率
     * @return 最新的K线数据
     */
    public KlineDataDTO getLatestKline(String code, String market, String freq) {
        return stockKlineRepository.findTopByCodeAndMarketAndFreqOrderByTradeDateDescTradeTimeDesc(code, market, freq)
                .map(this::convertToDTO)
                .orElse(null);
    }

    /**
     * 获取公司资料(F10)
     *
     * @param market 市场代码(SH/SZ)
     * @param code   股票代码
     * @return 公司资料
     */
    public Object getCompanyInfo(String market, String code) {
        log.info("[getCompanyInfo] 获取公司资料: market={}, code={}", market, code);
        return tdxKlineService.getCompanyInfo(market, code);
    }

    /**
     * 获取股票列表
     *
     * @param market 市场代码(0=深圳, 1=上海)
     * @return 股票列表
     */
    public List<StockMeta> getStockList(int market) {
        log.info("[getStockList] 获取股票列表: market={}", market);
        return tdxKlineService.getStockList(market);
    }
}
```

### 3.3 Service层 - TDX数据获取

**文件路径：** `mootdx-server/src/main/java/com/mootdx/server/service/TdxKlineService.java`

```java
package com.mootdx.server.service;

import com.mootdx.server.dto.KlineDataDTO;
import com.mootdx.server.entity.TdxServerConfig;
import com.mootdx.quotes.TdxQuoteClient;
import com.mootdx.model.BarData;
import com.mootdx.model.StockMeta;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.*;

/**
 * TDX K线数据服务
 * 负责从TDX服务器获取K线数据
 *
 * @author MooTDX
 * @since 1.0.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TdxKlineService {

    private final TdxServerService serverService;

    // TDX频率代码映射（根据TDX官方频率参数）
    private static final Map<String, Integer> FREQ_MAP = new HashMap<>();
    // 数据量配置
    private static final Map<String, Integer> FREQ_OFFSET_MAP = new HashMap<>();

    static {
        // 初始化频率映射（与pytdx保持一致）
        // 参考: pytdx get_security_bars 函数
        FREQ_MAP.put("1min", 8);      // 1分钟K线
        FREQ_MAP.put("5min", 0);      // 5分钟K线
        FREQ_MAP.put("15min", 1);     // 15分钟K线
        FREQ_MAP.put("30min", 2);     // 30分钟K线
        FREQ_MAP.put("60min", 3);     // 60分钟K线
        FREQ_MAP.put("day", 9);       // 日K线 (pytdx使用9，不是4)
        FREQ_MAP.put("week", 5);      // 周K线
        FREQ_MAP.put("month", 6);     // 月K线
        FREQ_MAP.put("quarter", 10);  // 季K线（3个月）
        FREQ_MAP.put("year", 11);     // 年K线

        // 初始化数据量配置
        FREQ_OFFSET_MAP.put("1min", 120);    // 2小时
        FREQ_OFFSET_MAP.put("5min", 120);    // 10小时
        FREQ_OFFSET_MAP.put("15min", 120);   // 30小时
        FREQ_OFFSET_MAP.put("30min", 120);   // 60小时
        FREQ_OFFSET_MAP.put("60min", 120);   // 120小时
        FREQ_OFFSET_MAP.put("day", 500);     // 约2年
        FREQ_OFFSET_MAP.put("week", 260);    // 约5年
        FREQ_OFFSET_MAP.put("month", 120);   // 约10年
        FREQ_OFFSET_MAP.put("quarter", 60);  // 约15年
        FREQ_OFFSET_MAP.put("year", 30);     // 约30年
    }

    // TDX客户端
    private TdxQuoteClient tdxClient;
    private String currentHost;
    private int currentPort;

    // 异步执行器
    private final ExecutorService executorService = Executors.newCachedThreadPool();
    // K线请求超时时间（秒）
    private static final int KLINE_TIMEOUT_SECONDS = 10;

    /**
     * 初始化TDX客户端
     */
    @PostConstruct
    public void init() {
        connectToBestServer();
    }

    /**
     * 连接到最佳可用服务器
     * 优先使用数据库中设置的默认服务器
     */
    private void connectToBestServer() {
        try {
            // 首先尝试获取数据库中设置的默认服务器
            TdxServerConfig defaultServer = serverService.getDefaultServer();
            if (defaultServer != null && Boolean.TRUE.equals(defaultServer.getIsEnabled())) {
                log.info("[connectToBestServer] 使用数据库中设置的默认服务器: {} ({}:{})",
                        defaultServer.getName(), defaultServer.getHost(), defaultServer.getPort());

                currentHost = defaultServer.getHost();
                currentPort = defaultServer.getPort();

                try {
                    tdxClient = new TdxQuoteClient(currentHost, currentPort, true);
                    tdxClient.connect();
                    log.info("[connectToBestServer] TDX客户端连接成功 (使用默认服务器)");
                    return;
                } catch (Exception e) {
                    log.warn("[connectToBestServer] 默认服务器连接失败: {}，尝试其他服务器", e.getMessage());
                }
            }

            // 如果默认服务器不可用，获取最佳可用服务器
            TdxServerConfig bestServer = serverService.getBestAvailableServer();
            if (bestServer == null) {
                log.error("[connectToBestServer] 没有可用的TDX服务器");
                return;
            }

            currentHost = bestServer.getHost();
            currentPort = bestServer.getPort();

            log.info("[connectToBestServer] 连接到TDX服务器: {}:{}", currentHost, currentPort);
            tdxClient = new TdxQuoteClient(currentHost, currentPort, true);
            tdxClient.connect();
            log.info("[connectToBestServer] TDX客户端连接成功");
        } catch (Exception e) {
            log.error("[connectToBestServer] TDX客户端连接失败: {}", e.getMessage(), e);
        }
    }

    /**
     * 销毁TDX客户端
     */
    @PreDestroy
    public void destroy() {
        if (tdxClient != null) {
            try {
                log.info("[destroy] 关闭TDX客户端");
                tdxClient.disconnect();
            } catch (Exception e) {
                log.error("[destroy] 关闭TDX客户端失败: {}", e.getMessage());
            }
        }

        // 关闭线程池
        if (executorService != null && !executorService.isShutdown()) {
            log.info("[destroy] 关闭线程池");
            executorService.shutdown();
            try {
                if (!executorService.awaitTermination(5, TimeUnit.SECONDS)) {
                    executorService.shutdownNow();
                }
            } catch (InterruptedException e) {
                executorService.shutdownNow();
            }
        }
    }

    /**
     * 确保客户端已连接
     */
    private void ensureConnected() {
        if (tdxClient == null) {
            // 尝试重新连接
            connectToBestServer();
            if (tdxClient == null) {
                throw new RuntimeException("TDX客户端未初始化，没有可用的服务器");
            }
        }
        // 重新连接如果需要
        try {
            tdxClient.connect();
        } catch (Exception e) {
            log.error("[ensureConnected] 重新连接失败: {}，尝试切换到其他服务器", e.getMessage());
            // 尝试连接到其他服务器
            connectToBestServer();
            if (tdxClient == null) {
                throw new RuntimeException("TDX服务器连接失败，没有可用的服务器", e);
            }
        }
    }

    /**
     * 从TDX服务器获取K线数据（带超时处理）
     *
     * @param code   股票代码
     * @param market 市场代码(SH/SZ)
     * @param freq   频率
     * @param limit  数量限制
     * @return K线数据列表
     */
    public List<KlineDataDTO> getKlineDataFromTdx(String code, String market, String freq, int limit) {
        log.info("[getKlineDataFromTdx] 从TDX获取K线数据: code={}, market={}, freq={}, limit={}", code, market, freq, limit);

        try {
            log.info("[getKlineDataFromTdx] 检查连接状态...");
            ensureConnected();
            log.info("[getKlineDataFromTdx] 连接状态正常");

            // 转换市场代码
            String symbol = code;
            log.info("[getKlineDataFromTdx] 股票代码: {}", symbol);

            // 获取频率代码
            int frequency = FREQ_MAP.getOrDefault(freq, 4);  // 默认日线
            int offset = Math.min(limit, FREQ_OFFSET_MAP.getOrDefault(freq, 500));
            log.info("[getKlineDataFromTdx] 频率代码: {}, 请求数量: {}", frequency, offset);

            // 使用异步调用并设置超时
            final int finalFrequency = frequency;
            final int finalOffset = offset;
            Future<List<BarData>> future = executorService.submit(() ->
                tdxClient.getKLine(symbol, finalFrequency, finalOffset)
            );

            log.info("[getKlineDataFromTdx] 开始调用tdxClient.getKLine（超时{}秒）...", KLINE_TIMEOUT_SECONDS);
            List<BarData> barDataList;
            try {
                barDataList = future.get(KLINE_TIMEOUT_SECONDS, TimeUnit.SECONDS);
            } catch (TimeoutException e) {
                log.error("[getKlineDataFromTdx] 获取K线数据超时（{}秒）", KLINE_TIMEOUT_SECONDS);
                future.cancel(true);
                return new ArrayList<>();
            }

            log.info("[getKlineDataFromTdx] tdxClient返回数据: {}条", barDataList != null ? barDataList.size() : "null");

            if (barDataList == null) {
                log.warn("[getKlineDataFromTdx] tdxClient返回null");
                return new ArrayList<>();
            }

            // 转换为DTO
            List<KlineDataDTO> result = convertBarDataToDTO(barDataList, freq);

            log.info("[getKlineDataFromTdx] 成功获取K线数据: {}条", result.size());
            return result;

        } catch (Exception e) {
            log.error("[getKlineDataFromTdx] 获取K线数据失败: {}", e.getMessage(), e);
            return new ArrayList<>();
        }
    }

    /**
     * 将BarData转换为KlineDataDTO
     */
    private List<KlineDataDTO> convertBarDataToDTO(List<BarData> barDataList, String freq) {
        List<KlineDataDTO> result = new ArrayList<>();

        for (BarData bar : barDataList) {
            try {
                KlineDataDTO dto = new KlineDataDTO();

                // 解析日期
                long dateInt = bar.getDate();
                LocalDateTime dateTime = parseDateTime(dateInt, freq);
                dto.setTradeDate(dateTime.toLocalDate());

                // 如果是分钟频率，设置时间
                if (isMinuteFreq(freq)) {
                    dto.setTradeTime(dateTime);
                }

                // 设置价格
                dto.setOpen(bar.getOpen());
                dto.setHigh(bar.getHigh());
                dto.setLow(bar.getLow());
                dto.setClose(bar.getClose());

                // 设置成交量和成交额
                dto.setVolume(bar.getVolume());
                dto.setAmount(bar.getAmount());

                result.add(dto);
            } catch (Exception e) {
                log.warn("[convertBarDataToDTO] 转换BarData失败: {}", e.getMessage());
            }
        }

        // 按时间倒序排序
        result.sort((a, b) -> {
            int dateCompare = b.getTradeDate().compareTo(a.getTradeDate());
            if (dateCompare != 0) {
                return dateCompare;
            }
            // 如果日期相同，比较时间
            if (a.getTradeTime() != null && b.getTradeTime() != null) {
                return b.getTradeTime().compareTo(a.getTradeTime());
            }
            return 0;
        });

        return result;
    }

    /**
     * 解析日期时间
     */
    private LocalDateTime parseDateTime(long dateInt, String freq) {
        // 根据频率解析日期格式
        // 日K线: YYYYMMDD 格式 (8位)
        // 分钟K线: YYYYMMDDHHMM 格式 (12位)

        if (isMinuteFreq(freq)) {
            // 分钟K线: YYYYMMDDHHMM
            int year = (int) (dateInt / 100000000L);
            int month = (int) ((dateInt % 100000000L) / 1000000L);
            int day = (int) ((dateInt % 1000000L) / 10000L);
            int hour = (int) ((dateInt % 10000L) / 100L);
            int minute = (int) (dateInt % 100L);
            return LocalDateTime.of(year, month, day, hour, minute);
        } else {
            // 日K线: YYYYMMDD
            int year = (int) (dateInt / 10000L);
            int month = (int) ((dateInt % 10000L) / 100L);
            int day = (int) (dateInt % 100L);
            return LocalDateTime.of(year, month, day, 0, 0);
        }
    }

    /**
     * 判断是否为分钟频率
     */
    private boolean isMinuteFreq(String freq) {
        return freq != null && (freq.contains("min") || freq.equals("1m") || freq.equals("5m") ||
                freq.equals("15m") || freq.equals("30m") || freq.equals("60m"));
    }

    /**
     * 获取公司资料(F10)
     *
     * @param market 市场代码(SH/SZ)
     * @param code   股票代码
     * @return 公司资料
     */
    public Object getCompanyInfo(String market, String code) {
        log.info("[getCompanyInfo] 获取公司资料: market={}, code={}", market, code);

        try {
            // 确保已连接
            if (tdxClient == null || !tdxClient.isConnected()) {
                log.warn("[getCompanyInfo] TDX客户端未连接，尝试重新连接");
                connectToBestServer();
            }

            // 检查连接是否成功
            if (tdxClient == null || !tdxClient.isConnected()) {
                log.error("[getCompanyInfo] TDX客户端连接失败，无法获取公司资料");
                return null;
            }

            // 转换市场代码
            int marketCode = "SH".equals(market) ? 1 : 0;

            // 获取公司信息
            return tdxClient.getCompanyInfo(marketCode, code);

        } catch (Exception e) {
            log.error("[getCompanyInfo] 获取公司资料失败: {}", e.getMessage(), e);
            return null;
        }
    }

    /**
     * 获取股票列表
     *
     * @param market 市场代码(0=深圳, 1=上海)
     * @return 股票列表
     */
    public List<StockMeta> getStockList(int market) {
        log.info("[getStockList] 获取股票列表: market={}", market);

        try {
            // 确保已连接
            if (tdxClient == null || !tdxClient.isConnected()) {
                log.warn("[getStockList] TDX客户端未连接，尝试重新连接");
                connectToBestServer();
            }

            // 检查连接是否成功
            if (tdxClient == null || !tdxClient.isConnected()) {
                log.error("[getStockList] TDX客户端连接失败，无法获取股票列表");
                return null;
            }

            // 获取股票列表
            return tdxClient.getStockList(market);

        } catch (Exception e) {
            log.error("[getStockList] 获取股票列表失败: {}", e.getMessage(), e);
            return null;
        }
    }
}
```

### 3.4 实体类

**文件路径：** `mootdx-server/src/main/java/com/mootdx/server/entity/StockKline.java`

```java
package com.mootdx.server.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * K线数据实体类
 * 存储股票K线数据，支持多种频率（1分钟到年线）
 *
 * @author MooTDX
 * @since 1.0.0
 */
@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "stock_kline",
        indexes = {
                @Index(name = "idx_stock_kline_query", columnList = "code,market,freq,trade_date"),
                @Index(name = "idx_stock_kline_unique", columnList = "code,market,freq,trade_date", unique = true)
        })
public class StockKline {

    /** 主键ID */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 股票代码 */
    @Column(name = "code", length = 10, nullable = false)
    private String code;

    /** 市场代码(SH/SZ) */
    @Column(name = "market", length = 10, nullable = false)
    private String market;

    /** 频率(1min/5min/15min/30min/60min/day/week/month/quarter/year) */
    @Column(name = "freq", length = 10, nullable = false)
    private String freq;

    /** 交易日期 */
    @Column(name = "trade_date", nullable = false)
    private LocalDate tradeDate;

    /** 交易时间(分钟K线才有) */
    @Column(name = "trade_time")
    private LocalDateTime tradeTime;

    /** 开盘价 */
    @Column(name = "open_price", nullable = false, precision = 10, scale = 4)
    private BigDecimal open;

    /** 最高价 */
    @Column(name = "high_price", nullable = false, precision = 10, scale = 4)
    private BigDecimal high;

    /** 最低价 */
    @Column(name = "low_price", nullable = false, precision = 10, scale = 4)
    private BigDecimal low;

    /** 收盘价 */
    @Column(name = "close_price", nullable = false, precision = 10, scale = 4)
    private BigDecimal close;

    /** 成交量 */
    @Column(name = "volume", nullable = false)
    private Long volume;

    /** 成交额 */
    @Column(name = "amount", nullable = false, precision = 20, scale = 4)
    private BigDecimal amount;

    /** 创建时间 */
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    /** 更新时间 */
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    /**
     * 实体保存前自动设置时间
     */
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    /**
     * 实体更新前自动设置更新时间
     */
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
```

### 3.5 DTO类

**KlineRequestDTO：**

```java
package com.mootdx.server.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

/**
 * K线数据请求DTO
 * 用于接收前端K线数据查询请求
 *
 * @author MooTDX
 * @since 1.0.0
 */
@Data
public class KlineRequestDTO {

    /** 股票代码 */
    @NotBlank(message = "股票代码不能为空")
    private String code;

    /** 市场代码(SH/SZ) */
    @NotBlank(message = "市场代码不能为空")
    @Pattern(regexp = "^(SH|SZ)$", message = "市场代码只能是SH或SZ")
    private String market;

    /** 频率(1min/5min/15min/30min/60min/day/week/month/quarter/year) */
    @NotBlank(message = "频率不能为空")
    @Pattern(regexp = "^(1min|5min|15min|30min|60min|day|week|month|quarter|year)$", message = "频率参数不正确")
    private String freq = "day";

    /** 开始日期(YYYYMMDD) */
    private String start;

    /** 结束日期(YYYYMMDD) */
    private String end;

    /** 数量限制 */
    private Integer limit = 500;

    /** 是否强制刷新 */
    private Boolean forceRefresh = false;
}
```

**KlineDataDTO：**

```java
package com.mootdx.server.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * K线数据传输对象
 * 用于前后端数据交互
 *
 * @author MooTDX
 * @since 1.0.0
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KlineDataDTO {

    /** 交易日期 */
    private LocalDate tradeDate;

    /** 交易时间(分钟K线才有) */
    private LocalDateTime tradeTime;

    /** 开盘价 */
    private BigDecimal open;

    /** 最高价 */
    private BigDecimal high;

    /** 最低价 */
    private BigDecimal low;

    /** 收盘价 */
    private BigDecimal close;

    /** 成交量 */
    private Long volume;

    /** 成交额 */
    private BigDecimal amount;
}
```

**KlineResponseDTO：**

```java
package com.mootdx.server.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * K线数据响应DTO
 *
 * @author MooTDX
 * @since 1.0.0
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KlineResponseDTO {

    /** 股票代码 */
    private String code;

    /** 市场代码 */
    private String market;

    /** 频率 */
    private String freq;

    /** K线数据列表 */
    private List<KlineDataDTO> data;
}
```

---

## 四、前端实现详解

### 4.1 K线图组件

**文件路径：** `mootdx-web/src/views/Kline.vue`

```vue
<template>
  <!-- K线图页面 -->
  <div class="kline-container">
    <!-- 页面标题 -->
    <div class="page-header">
      <h2>K线图</h2>
    </div>

    <!-- 查询条件 -->
    <el-card class="search-card">
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="市场">
          <el-select v-model="searchForm.market" placeholder="选择市场" style="width: 100px">
            <el-option label="上海" value="SH" />
            <el-option label="深圳" value="SZ" />
          </el-select>
        </el-form-item>
        <el-form-item label="股票代码">
          <el-input v-model="searchForm.code" placeholder="输入股票代码" style="width: 150px" />
        </el-form-item>
        <el-form-item label="周期">
          <el-radio-group v-model="selectedFreq" @change="handleFreqChange">
            <el-radio-button label="1min">1分钟</el-radio-button>
            <el-radio-button label="5min">5分钟</el-radio-button>
            <el-radio-button label="15min">15分钟</el-radio-button>
            <el-radio-button label="30min">30分钟</el-radio-button>
            <el-radio-button label="60min">60分钟</el-radio-button>
            <el-radio-button label="day">日线</el-radio-button>
            <el-radio-button label="week">周线</el-radio-button>
            <el-radio-button label="month">月线</el-radio-button>
            <el-radio-button label="quarter">季线</el-radio-button>
            <el-radio-button label="year">年线</el-radio-button>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="复权">
          <el-select v-model="adjustmentType" style="width: 100px" @change="handleAdjustmentChange">
            <el-option label="不复权" value="none" />
            <el-option label="前复权" value="qfq" />
            <el-option label="后复权" value="hfq" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchKlineData" :loading="loading">
            <el-icon><Search /></el-icon>查询
          </el-button>
          <el-button @click="handleRefresh" :loading="loading">
            <el-icon><Refresh /></el-icon>刷新
          </el-button>
          <el-button @click="showExportDialog">
            <el-icon><Download /></el-icon>导出
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 技术指标选择 -->
    <el-card class="indicator-card">
      <div class="indicator-bar">
        <span class="indicator-label">技术指标:</span>
        <el-checkbox-group v-model="selectedIndicators" @change="updateChart">
          <el-checkbox label="ma">MA均线</el-checkbox>
          <el-checkbox label="macd">MACD</el-checkbox>
          <el-checkbox label="kdj">KDJ</el-checkbox>
          <el-checkbox label="rsi">RSI</el-checkbox>
          <el-checkbox label="boll">布林带</el-checkbox>
        </el-checkbox-group>
        <el-divider direction="vertical" />
        <span class="indicator-label">画线工具:</span>
        <el-button-group>
          <el-button size="small" :type="drawingMode === 'line' ? 'primary' : ''" @click="setDrawingMode('line')">
            趋势线
          </el-button>
          <el-button size="small" :type="drawingMode === 'segment' ? 'primary' : ''" @click="setDrawingMode('segment')">
            线段
          </el-button>
          <el-button size="small" :type="drawingMode === 'rect' ? 'primary' : ''" @click="setDrawingMode('rect')">
            矩形
          </el-button>
          <el-button size="small" @click="clearDrawings">清除画线</el-button>
        </el-button-group>
      </div>
    </el-card>

    <!-- K线图 -->
    <el-card class="chart-card">
      <div ref="chartRef" class="kline-chart" @mousedown="handleChartMouseDown"></div>
    </el-card>

    <!-- 数据表格 -->
    <el-card class="table-card">
      <template #header>
        <div class="card-header">
          <span>K线数据</span>
          <span class="data-count">共 {{ tableData.length }} 条</span>
        </div>
      </template>
      <el-table :data="tableData" height="400" border stripe>
        <el-table-column prop="tradeDate" label="日期" width="120" sortable>
          <template #default="{ row }">
            {{ formatDate(row.tradeDate) }}
          </template>
        </el-table-column>
        <el-table-column prop="tradeTime" label="时间" width="100" v-if="isMinuteFreq">
          <template #default="{ row }">
            {{ formatTime(row.tradeTime) }}
          </template>
        </el-table-column>
        <el-table-column prop="open" label="开盘价" width="100">
          <template #default="{ row }">
            {{ formatPrice(row.open) }}
          </template>
        </el-table-column>
        <el-table-column prop="high" label="最高价" width="100">
          <template #default="{ row }">
            {{ formatPrice(row.high) }}
          </template>
        </el-table-column>
        <el-table-column prop="low" label="最低价" width="100">
          <template #default="{ row }">
            {{ formatPrice(row.low) }}
          </template>
        </el-table-column>
        <el-table-column prop="close" label="收盘价" width="100">
          <template #default="{ row }">
            {{ formatPrice(row.close) }}
          </template>
        </el-table-column>
        <el-table-column prop="volume" label="成交量" width="120">
          <template #default="{ row }">
            {{ formatVolume(row.volume) }}
          </template>
        </el-table-column>
        <el-table-column prop="amount" label="成交额" min-width="120">
          <template #default="{ row }">
            {{ formatAmount(row.amount) }}
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 导出对话框 -->
    <el-dialog v-model="exportDialogVisible" title="导出K线数据" width="400px">
      <el-form :model="exportForm" label-width="80px">
        <el-form-item label="格式">
          <el-radio-group v-model="exportForm.format">
            <el-radio label="csv">CSV</el-radio>
            <el-radio label="json">JSON</el-radio>
            <el-radio label="excel">Excel</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="数据范围">
          <el-radio-group v-model="exportForm.range">
            <el-radio label="current">当前显示</el-radio>
            <el-radio label="all">全部数据</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="exportDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmExport" :loading="exporting">导出</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { ref, reactive, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Search, Refresh, Download } from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import { getKlineData, getKlineDataQfq, getKlineDataHfq, exportKlineData } from '@/api/stock'

export default {
  name: 'KlineView',

  components: {
    Search,
    Refresh,
    Download
  },

  setup() {
    const route = useRoute()
    const chartRef = ref(null)
    let chartInstance = null

    // 搜索表单
    const searchForm = reactive({
      market: 'SZ',
      code: '000001'
    })

    // 选中的频率
    const selectedFreq = ref('day')

    // 复权类型
    const adjustmentType = ref('none')

    // 加载状态
    const loading = ref(false)

    // K线数据
    const klineData = ref([])

    // 选中的技术指标
    const selectedIndicators = ref(['ma'])

    // 画线模式
    const drawingMode = ref(null)
    const drawings = ref([])
    let isDrawing = false
    let drawStart = null

    // 导出对话框
    const exportDialogVisible = ref(false)
    const exporting = ref(false)
    const exportForm = reactive({
      format: 'csv',
      range: 'current'
    })

    // 表格数据（倒序）
    const tableData = computed(() => {
      return [...klineData.value].reverse()
    })

    // 是否为分钟频率
    const isMinuteFreq = computed(() => {
      return selectedFreq.value.endsWith('min')
    })

    // 频率对应的数据量限制
    const freqLimitMap = {
      '1min': 120,
      '5min': 120,
      '15min': 120,
      '30min': 120,
      '60min': 120,
      'day': 500,
      'week': 260,
      'month': 120,
      'quarter': 60,
      'year': 30
    }

    /**
     * 初始化图表
     */
    const initChart = () => {
      if (chartRef.value) {
        chartInstance = echarts.init(chartRef.value)
        window.addEventListener('resize', handleResize)
      }
    }

    /**
     * 处理窗口大小变化
     */
    const handleResize = () => {
      chartInstance?.resize()
    }

    /**
     * 计算MA均线
     */
    const calculateMA = (data, period) => {
      const result = []
      for (let i = 0; i < data.length; i++) {
        if (i < period - 1) {
          result.push('-')
          continue
        }
        let sum = 0
        for (let j = 0; j < period; j++) {
          sum += parseFloat(data[i - j].close)
        }
        result.push((sum / period).toFixed(2))
      }
      return result
    }

    /**
     * 计算MACD
     */
    const calculateMACD = (data) => {
      const closes = data.map(item => parseFloat(item.close))
      const ema12 = calculateEMA(closes, 12)
      const ema26 = calculateEMA(closes, 26)
      const dif = ema12.map((v, i) => v && ema26[i] ? (v - ema26[i]).toFixed(2) : '-')
      const dea = calculateEMA(dif.filter(v => v !== '-').map(v => parseFloat(v)), 9)
      const macd = dif.map((v, i) => {
        if (v === '-' || !dea[i]) return '-'
        return ((parseFloat(v) - dea[i]) * 2).toFixed(2)
      })
      return { dif, dea: dea.map(v => v ? v.toFixed(2) : '-'), macd }
    }

    /**
     * 计算EMA
     */
    const calculateEMA = (data, period) => {
      const result = []
      const multiplier = 2 / (period + 1)
      let ema = data[0]
      for (let i = 0; i < data.length; i++) {
        if (i === 0) {
          ema = data[i]
        } else {
          ema = (data[i] - ema) * multiplier + ema
        }
        result.push(ema)
      }
      return result
    }

    /**
     * 计算KDJ
     */
    const calculateKDJ = (data, n = 9, m1 = 3, m2 = 3) => {
      const k = []
      const d = []
      const j = []
      let prevK = 50
      let prevD = 50

      for (let i = 0; i < data.length; i++) {
        if (i < n - 1) {
          k.push('-')
          d.push('-')
          j.push('-')
          continue
        }

        let low = parseFloat(data[i].low)
        let high = parseFloat(data[i].high)
        for (let j = 1; j < n; j++) {
          low = Math.min(low, parseFloat(data[i - j].low))
          high = Math.max(high, parseFloat(data[i - j].high))
        }

        const close = parseFloat(data[i].close)
        const rsv = high === low ? 0 : ((close - low) / (high - low)) * 100

        const kValue = (m1 - 1) / m1 * prevK + 1 / m1 * rsv
        const dValue = (m2 - 1) / m2 * prevD + 1 / m2 * kValue
        const jValue = 3 * kValue - 2 * dValue

        k.push(kValue.toFixed(2))
        d.push(dValue.toFixed(2))
        j.push(jValue.toFixed(2))

        prevK = kValue
        prevD = dValue
      }

      return { k, d, j }
    }

    /**
     * 计算RSI
     */
    const calculateRSI = (data, period = 14) => {
      const result = []
      let gains = 0
      let losses = 0

      for (let i = 0; i < data.length; i++) {
        if (i === 0) {
          result.push('-')
          continue
        }

        const change = parseFloat(data[i].close) - parseFloat(data[i - 1].close)
        if (i < period) {
          if (change > 0) gains += change
          else losses -= change
          result.push('-')
          continue
        }

        if (change > 0) {
          gains = (gains * (period - 1) + change) / period
          losses = (losses * (period - 1)) / period
        } else {
          gains = (gains * (period - 1)) / period
          losses = (losses * (period - 1) - change) / period
        }

        const rs = losses === 0 ? 100 : gains / losses
        const rsi = 100 - (100 / (1 + rs))
        result.push(rsi.toFixed(2))
      }

      return result
    }

    /**
     * 计算布林带
     */
    const calculateBOLL = (data, period = 20, multiplier = 2) => {
      const middle = []
      const upper = []
      const lower = []

      for (let i = 0; i < data.length; i++) {
        if (i < period - 1) {
          middle.push('-')
          upper.push('-')
          lower.push('-')
          continue
        }

        let sum = 0
        for (let j = 0; j < period; j++) {
          sum += parseFloat(data[i - j].close)
        }
        const ma = sum / period

        let variance = 0
        for (let j = 0; j < period; j++) {
          variance += Math.pow(parseFloat(data[i - j].close) - ma, 2)
        }
        const std = Math.sqrt(variance / period)

        middle.push(ma.toFixed(2))
        upper.push((ma + multiplier * std).toFixed(2))
        lower.push((ma - multiplier * std).toFixed(2))
      }

      return { middle, upper, lower }
    }

    /**
     * 更新图表
     */
    const updateChart = () => {
      if (!chartInstance || klineData.value.length === 0) return

      // 图表需要正序数据（从旧到新）
      const chartData = [...klineData.value].reverse()

      const dates = chartData.map(item => {
        if (isMinuteFreq.value && item.tradeTime) {
          return formatDateTime(item.tradeTime)
        }
        return formatDate(item.tradeDate)
      })

      const values = chartData.map(item => [
        parseFloat(item.open),
        parseFloat(item.close),
        parseFloat(item.low),
        parseFloat(item.high)
      ])

      const volumes = chartData.map((item, index) => {
        const prevClose = index > 0 ? chartData[index - 1].close : item.open
        const isUp = parseFloat(item.close) >= parseFloat(prevClose)
        return {
          value: parseInt(item.volume),
          itemStyle: {
            color: isUp ? '#ef5350' : '#26a69a'
          }
        }
      })

      // 构建系列数据
      const series = [{
        name: 'K线',
        type: 'candlestick',
        data: values,
        itemStyle: {
          color: '#ef5350',
          color0: '#26a69a',
          borderColor: '#ef5350',
          borderColor0: '#26a69a'
        }
      }]

      const grid = [
        { left: '10%', right: '8%', height: '50%' },
        { left: '10%', right: '8%', top: '68%', height: '16%' }
      ]

      const xAxis = [
        {
          type: 'category',
          data: dates,
          boundaryGap: false,
          axisLine: { onZero: false, lineStyle: { color: '#777' } },
          splitLine: { show: false },
          axisLabel: { color: '#666' },
          min: 'dataMin',
          max: 'dataMax'
        },
        {
          type: 'category',
          gridIndex: 1,
          data: dates,
          boundaryGap: false,
          axisLine: { onZero: false },
          axisTick: { show: false },
          splitLine: { show: false },
          axisLabel: { show: false },
          min: 'dataMin',
          max: 'dataMax'
        }
      ]

      const yAxis = [
        {
          scale: true,
          splitArea: { show: true },
          axisLabel: { color: '#666' }
        },
        {
          scale: true,
          gridIndex: 1,
          splitNumber: 2,
          axisLabel: { show: false },
          axisLine: { show: false },
          axisTick: { show: false },
          splitLine: { show: false }
        }
      ]

      // 添加MA均线
      if (selectedIndicators.value.includes('ma')) {
        const ma5 = calculateMA(chartData, 5)
        const ma10 = calculateMA(chartData, 10)
        const ma20 = calculateMA(chartData, 20)
        const ma60 = calculateMA(chartData, 60)

        series.push(
          { name: 'MA5', type: 'line', data: ma5, smooth: true, lineStyle: { width: 1, color: '#2196F3' } },
          { name: 'MA10', type: 'line', data: ma10, smooth: true, lineStyle: { width: 1, color: '#FF9800' } },
          { name: 'MA20', type: 'line', data: ma20, smooth: true, lineStyle: { width: 1, color: '#9C27B0' } },
          { name: 'MA60', type: 'line', data: ma60, smooth: true, lineStyle: { width: 1, color: '#4CAF50' } }
        )
      }

      // 添加布林带
      if (selectedIndicators.value.includes('boll')) {
        const boll = calculateBOLL(chartData)
        series.push(
          { name: 'BOLL上轨', type: 'line', data: boll.upper, smooth: true, lineStyle: { width: 1, color: '#FF5722', type: 'dashed' } },
          { name: 'BOLL中轨', type: 'line', data: boll.middle, smooth: true, lineStyle: { width: 1, color: '#607D8B' } },
          { name: 'BOLL下轨', type: 'line', data: boll.lower, smooth: true, lineStyle: { width: 1, color: '#FF5722', type: 'dashed' } }
        )
      }

      // 添加成交量
      series.push({
        name: '成交量',
        type: 'bar',
        xAxisIndex: 1,
        yAxisIndex: 1,
        data: volumes
      })

      // 添加MACD
      if (selectedIndicators.value.includes('macd')) {
        grid.push({ left: '10%', right: '8%', top: '86%', height: '10%' })
        xAxis.push({
          type: 'category',
          gridIndex: 2,
          data: dates,
          boundaryGap: false,
          axisLine: { onZero: false },
          axisTick: { show: false },
          splitLine: { show: false },
          axisLabel: { show: false },
          min: 'dataMin',
          max: 'dataMax'
        })
        yAxis.push({
          scale: true,
          gridIndex: 2,
          splitNumber: 2,
          axisLabel: { show: false },
          axisLine: { show: false },
          axisTick: { show: false },
          splitLine: { show: false }
        })

        const macd = calculateMACD(chartData)
        series.push(
          { name: 'DIF', type: 'line', xAxisIndex: 2, yAxisIndex: 2, data: macd.dif, smooth: true, lineStyle: { width: 1, color: '#2196F3' } },
          { name: 'DEA', type: 'line', xAxisIndex: 2, yAxisIndex: 2, data: macd.dea, smooth: true, lineStyle: { width: 1, color: '#FF9800' } },
          { name: 'MACD', type: 'bar', xAxisIndex: 2, yAxisIndex: 2, data: macd.macd.map(v => parseFloat(v) || 0), itemStyle: { color: (params) => params.value >= 0 ? '#ef5350' : '#26a69a' } }
        )
      }

      // 添加KDJ
      if (selectedIndicators.value.includes('kdj')) {
        const gridIndex = grid.length
        grid.push({ left: '10%', right: '8%', top: `${86 + (grid.length - 2) * 12}%`, height: '10%' })
        xAxis.push({
          type: 'category',
          gridIndex,
          data: dates,
          boundaryGap: false,
          axisLine: { onZero: false },
          axisTick: { show: false },
          splitLine: { show: false },
          axisLabel: { show: false },
          min: 'dataMin',
          max: 'dataMax'
        })
        yAxis.push({
          scale: true,
          gridIndex,
          splitNumber: 2,
          axisLabel: { show: false },
          axisLine: { show: false },
          axisTick: { show: false },
          splitLine: { show: false }
        })

        const kdj = calculateKDJ(chartData)
        series.push(
          { name: 'K', type: 'line', xAxisIndex: gridIndex, yAxisIndex: gridIndex, data: kdj.k, smooth: true, lineStyle: { width: 1, color: '#2196F3' } },
          { name: 'D', type: 'line', xAxisIndex: gridIndex, yAxisIndex: gridIndex, data: kdj.d, smooth: true, lineStyle: { width: 1, color: '#FF9800' } },
          { name: 'J', type: 'line', xAxisIndex: gridIndex, yAxisIndex: gridIndex, data: kdj.j, smooth: true, lineStyle: { width: 1, color: '#9C27B0' } }
        )
      }

      // 添加RSI
      if (selectedIndicators.value.includes('rsi')) {
        const gridIndex = grid.length
        grid.push({ left: '10%', right: '8%', top: `${86 + (grid.length - 2) * 12}%`, height: '10%' })
        xAxis.push({
          type: 'category',
          gridIndex,
          data: dates,
          boundaryGap: false,
          axisLine: { onZero: false },
          axisTick: { show: false },
          splitLine: { show: false },
          axisLabel: { show: false },
          min: 'dataMin',
          max: 'dataMax'
        })
        yAxis.push({
          scale: true,
          gridIndex,
          splitNumber: 2,
          axisLabel: { show: false },
          axisLine: { show: false },
          axisTick: { show: false },
          splitLine: { show: false }
        })

        const rsi = calculateRSI(chartData)
        series.push({
          name: 'RSI',
          type: 'line',
          xAxisIndex: gridIndex,
          yAxisIndex: gridIndex,
          data: rsi,
          smooth: true,
          lineStyle: { width: 1, color: '#4CAF50' },
          markLine: {
            data: [{ yAxis: 70, lineStyle: { color: '#ef5350', type: 'dashed' } },
                   { yAxis: 30, lineStyle: { color: '#26a69a', type: 'dashed' } }]
          }
        })
      }

      const option = {
        backgroundColor: '#fff',
        animation: false,
        legend: {
          top: 10,
          left: 'center',
          data: series.map(s => s.name)
        },
        tooltip: {
          trigger: 'axis',
          axisPointer: { type: 'cross' },
          backgroundColor: 'rgba(255, 255, 255, 0.9)',
          borderColor: '#ccc',
          borderWidth: 1,
          textStyle: { color: '#333' }
        },
        axisPointer: {
          link: [{ xAxisIndex: 'all' }],
          label: { backgroundColor: '#777' }
        },
        toolbox: {
          feature: {
            dataZoom: { yAxisIndex: false },
            brush: { type: ['lineX', 'clear'] },
            saveAsImage: { show: true }
          }
        },
        brush: {
          xAxisIndex: 'all',
          brushLink: 'all',
          outOfBrush: { colorAlpha: 0.1 }
        },
        grid,
        xAxis,
        yAxis,
        dataZoom: [
          { type: 'inside', xAxisIndex: xAxis.map((_, i) => i), start: 50, end: 100 },
          { show: true, xAxisIndex: xAxis.map((_, i) => i), type: 'slider', top: '85%', start: 50, end: 100 }
        ],
        series
      }

      chartInstance.setOption(option, true)
    }

    /**
     * 获取K线数据
     */
    const fetchKlineData = async () => {
      if (!searchForm.code) {
        ElMessage.warning('请输入股票代码')
        return
      }

      loading.value = true
      try {
        const params = {
          freq: selectedFreq.value,
          limit: freqLimitMap[selectedFreq.value] || 500
        }

        let response
        if (adjustmentType.value === 'qfq') {
          response = await getKlineDataQfq(searchForm.market, searchForm.code, params)
        } else if (adjustmentType.value === 'hfq') {
          response = await getKlineDataHfq(searchForm.market, searchForm.code, params)
        } else {
          response = await getKlineData(searchForm.market, searchForm.code, params)
        }

        if (response.data.code === 200) {
          klineData.value = response.data.data.data || []
          nextTick(() => {
            updateChart()
          })
          ElMessage.success(`成功获取${klineData.value.length}条K线数据`)
        } else {
          ElMessage.error(response.data.message || '获取数据失败')
        }
      } catch (error) {
        console.error('获取K线数据失败:', error)
        ElMessage.error('获取K线数据失败: ' + (error.message || '未知错误'))
      } finally {
        loading.value = false
      }
    }

    /**
     * 处理频率切换
     */
    const handleFreqChange = () => {
      fetchKlineData()
    }

    /**
     * 处理复权切换
     */
    const handleAdjustmentChange = () => {
      fetchKlineData()
    }

    /**
     * 处理刷新
     */
    const handleRefresh = () => {
      fetchKlineData()
    }

    /**
     * 设置画线模式
     */
    const setDrawingMode = (mode) => {
      drawingMode.value = drawingMode.value === mode ? null : mode
    }

    /**
     * 清除画线
     */
    const clearDrawings = () => {
      drawings.value = []
      updateChart()
    }

    /**
     * 处理图表鼠标按下
     */
    const handleChartMouseDown = (e) => {
      if (!drawingMode.value) return
      isDrawing = true
      drawStart = { x: e.offsetX, y: e.offsetY }
    }

    /**
     * 显示导出对话框
     */
    const showExportDialog = () => {
      exportDialogVisible.value = true
    }

    /**
     * 确认导出
     */
    const confirmExport = async () => {
      exporting.value = true
      try {
        const params = {
          freq: selectedFreq.value,
          format: exportForm.format
        }

        const response = await exportKlineData(searchForm.market, searchForm.code, params)

        // 下载文件
        const blob = new Blob([response.data], { type: 'text/csv' })
        const link = document.createElement('a')
        link.href = URL.createObjectURL(blob)
        link.download = `${searchForm.code}_${selectedFreq.value}.${exportForm.format}`
        link.click()

        ElMessage.success('导出成功')
        exportDialogVisible.value = false
      } catch (error) {
        console.error('导出失败:', error)
        ElMessage.error('导出失败: ' + error.message)
      } finally {
        exporting.value = false
      }
    }

    /**
     * 格式化日期
     */
    const formatDate = (dateStr) => {
      if (!dateStr) return '-'
      const date = new Date(dateStr)
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
    }

    /**
     * 格式化时间
     */
    const formatTime = (dateTimeStr) => {
      if (!dateTimeStr) return '-'
      const date = new Date(dateTimeStr)
      return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
    }

    /**
     * 格式化日期时间
     */
    const formatDateTime = (dateTimeStr) => {
      if (!dateTimeStr) return '-'
      return `${formatDate(dateTimeStr)} ${formatTime(dateTimeStr)}`
    }

    /**
     * 格式化价格
     */
    const formatPrice = (price) => {
      if (price === null || price === undefined) return '-'
      return parseFloat(price).toFixed(2)
    }

    /**
     * 格式化成交量
     */
    const formatVolume = (volume) => {
      if (volume === null || volume === undefined) return '-'
      const v = parseInt(volume)
      if (v >= 100000000) {
        return (v / 100000000).toFixed(2) + '亿'
      } else if (v >= 10000) {
        return (v / 10000).toFixed(2) + '万'
      }
      return v.toString()
    }

    /**
     * 格式化成交额
     */
    const formatAmount = (amount) => {
      if (amount === null || amount === undefined) return '-'
      const a = parseFloat(amount)
      if (a >= 100000000) {
        return (a / 100000000).toFixed(2) + '亿'
      } else if (a >= 10000) {
        return (a / 10000).toFixed(2) + '万'
      }
      return a.toFixed(2)
    }

    onMounted(() => {
      initChart()
      // 如果URL中有参数，使用URL参数
      if (route.query.code) {
        searchForm.code = route.query.code
      }
      if (route.query.market) {
        searchForm.market = route.query.market
      }
      if (route.query.freq) {
        selectedFreq.value = route.query.freq
      }
      fetchKlineData()
    })

    onUnmounted(() => {
      window.removeEventListener('resize', handleResize)
      chartInstance?.dispose()
    })

    return {
      chartRef,
      searchForm,
      selectedFreq,
      adjustmentType,
      loading,
      klineData,
      tableData,
      isMinuteFreq,
      selectedIndicators,
      drawingMode,
      exportDialogVisible,
      exporting,
      exportForm,
      fetchKlineData,
      handleFreqChange,
      handleAdjustmentChange,
      handleRefresh,
      updateChart,
      setDrawingMode,
      clearDrawings,
      handleChartMouseDown,
      showExportDialog,
      confirmExport,
      formatDate,
      formatTime,
      formatPrice,
      formatVolume,
      formatAmount
    }
  }
}
</script>

<style scoped>
.kline-container {
  padding: 20px;
}

.page-header {
  margin-bottom: 20px;
}

.page-header h2 {
  margin: 0;
  color: #303133;
}

.search-card {
  margin-bottom: 10px;
}

.search-form {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
}

.indicator-card {
  margin-bottom: 10px;
}

.indicator-bar {
  display: flex;
  align-items: center;
  gap: 15px;
  flex-wrap: wrap;
}

.indicator-label {
  font-weight: bold;
  color: #606266;
}

.chart-card {
  margin-bottom: 20px;
}

.kline-chart {
  width: 100%;
  height: 600px;
}

.table-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.data-count {
  color: #909399;
  font-size: 14px;
}
</style>
```

### 4.2 API封装

**文件路径：** `mootdx-web/src/api/stock.js`

```javascript
/**
 * 股票相关API接口
 * 提供K线数据查询、实时行情、股票列表等功能
 *
 * @author MooTDX
 * @since 1.0.0
 */

import axios from 'axios'

// API基础URL
const BASE_URL = process.env.VUE_APP_API_URL || 'http://localhost:8080'

// 创建axios实例
const apiClient = axios.create({
  baseURL: BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器
apiClient.interceptors.request.use(
  config => {
    console.log(`[API请求] ${config.method.toUpperCase()} ${config.url}`)
    return config
  },
  error => {
    console.error('[API请求错误]', error)
    return Promise.reject(error)
  }
)

// 响应拦截器
apiClient.interceptors.response.use(
  response => {
    console.log(`[API响应] ${response.config.url}`, response.data)
    return response
  },
  error => {
    console.error('[API响应错误]', error)
    const message = error.response?.data?.message || '网络请求失败'
    return Promise.reject(new Error(message))
  }
)

/**
 * 获取K线数据
 * @param {string} market - 市场代码(SH/SZ)
 * @param {string} code - 股票代码
 * @param {Object} params - 查询参数
 * @param {string} params.freq - 频率(1min/5min/15min/30min/60min/day/week/month/quarter/year)
 * @param {string} params.start - 开始日期(YYYYMMDD)
 * @param {string} params.end - 结束日期(YYYYMMDD)
 * @param {number} params.limit - 数量限制
 * @param {boolean} params.forceRefresh - 是否强制刷新
 * @returns {Promise} K线数据
 */
export function getKlineData(market, code, params = {}) {
  return apiClient.get(`/api/stocks/kline/${market}/${code}`, { params })
}

/**
 * 清除K线缓存
 * @param {string} market - 市场代码(SH/SZ)
 * @param {string} code - 股票代码
 * @param {string} freq - 频率
 * @returns {Promise} 操作结果
 */
export function clearKlineCache(market, code, freq) {
  return apiClient.delete(`/api/stocks/kline/${market}/${code}/cache`, {
    params: { freq }
  })
}

/**
 * 获取实时行情
 * @param {string} market - 市场代码(SH/SZ)
 * @param {string} code - 股票代码
 * @returns {Promise} 实时行情数据
 */
export function getQuote(market, code) {
  return apiClient.get(`/api/stocks/quote/${market}/${code}`)
}

/**
 * 批量获取实时行情
 * @param {Array<string>} codes - 股票代码列表，格式: ['SH_600000', 'SZ_000001']
 * @returns {Promise} 实时行情列表
 */
export function getQuotes(codes) {
  return apiClient.post('/api/stocks/quotes', { codes })
}

/**
 * 获取股票列表
 * @param {number} market - 市场代码(0=深圳, 1=上海)
 * @returns {Promise} 股票列表
 */
export function getStockList(market) {
  return apiClient.get(`/api/stocks/list/${market}`)
}

/**
 * 搜索股票
 * @param {string} keyword - 搜索关键词(代码或名称)
 * @returns {Promise} 搜索结果
 */
export function searchStocks(keyword) {
  return apiClient.get('/api/stocks/search', { params: { keyword } })
}

/**
 * 导出K线数据
 * @param {string} market - 市场代码(SH/SZ)
 * @param {string} code - 股票代码
 * @param {Object} params - 查询参数
 * @returns {Promise} CSV文件下载
 */
export function exportKlineData(market, code, params = {}) {
  return apiClient.get(`/api/stocks/kline/${market}/${code}/export`, {
    params,
    responseType: 'blob'
  })
}

/**
 * 获取除权除息信息
 * @param {string} market - 市场代码(SH/SZ)
 * @param {string} code - 股票代码
 * @returns {Promise} 除权除息信息
 */
export function getXdxrInfo(market, code) {
  return apiClient.get(`/api/stocks/xdxr/${market}/${code}`)
}

/**
 * 获取公司资料(F10)
 * @param {string} market - 市场代码(SH/SZ)
 * @param {string} code - 股票代码
 * @returns {Promise} 公司资料
 */
export function getCompanyInfo(market, code) {
  return apiClient.get(`/api/stocks/company/${market}/${code}`)
}

/**
 * 获取前复权K线数据
 * @param {string} market - 市场代码(SH/SZ)
 * @param {string} code - 股票代码
 * @param {Object} params - 查询参数
 * @returns {Promise} 前复权K线数据
 */
export function getKlineDataQfq(market, code, params = {}) {
  return apiClient.get(`/api/stocks/kline/${market}/${code}/qfq`, { params })
}

/**
 * 获取后复权K线数据
 * @param {string} market - 市场代码(SH/SZ)
 * @param {string} code - 股票代码
 * @param {Object} params - 查询参数
 * @returns {Promise} 后复权K线数据
 */
export function getKlineDataHfq(market, code, params = {}) {
  return apiClient.get(`/api/stocks/kline/${market}/${code}/hfq`, { params })
}

export default {
  getKlineData,
  clearKlineCache,
  getQuote,
  getQuotes,
  getStockList,
  searchStocks,
  exportKlineData,
  getXdxrInfo,
  getKlineDataQfq,
  getKlineDataHfq,
  getCompanyInfo
}
```

---

## 五、数据交互格式

### 5.1 请求格式

**获取K线数据：**

```
GET /api/stocks/kline/{market}/{code}?freq={freq}&limit={limit}
```

**请求参数：**

| 参数名 | 类型 | 必填 | 说明 | 示例 |
|-------|------|------|------|------|
| market | String | 是 | 市场代码 | SH、SZ |
| code | String | 是 | 股票代码 | 000001 |
| freq | String | 否 | K线频率，默认day | 1min、5min、day、week等 |
| start | String | 否 | 开始日期(YYYYMMDD) | 20230101 |
| end | String | 否 | 结束日期(YYYYMMDD) | 20231231 |
| limit | Integer | 否 | 数量限制，默认500 | 500 |
| forceRefresh | Boolean | 否 | 是否强制刷新，默认false | true |

### 5.2 响应格式

**成功响应：**

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "code": "000001",
    "market": "SZ",
    "freq": "day",
    "data": [
      {
        "tradeDate": "2023-12-29",
        "tradeTime": null,
        "open": 10.50,
        "high": 11.20,
        "low": 10.40,
        "close": 11.00,
        "volume": 12345678,
        "amount": 135802380.00
      }
    ]
  }
}
```

**错误响应：**

```json
{
  "code": 500,
  "message": "获取K线数据失败: TDX服务器连接失败",
  "data": null
}
```

### 5.3 数据排序约定

| 场景 | 排序方式 | 说明 |
|------|---------|------|
| 后端返回 | 时间倒序 | 最新的数据在前 |
| 图表展示 | 需反转数据 | 时间正序，从旧到新 |
| 表格展示 | 直接使用 | 保持倒序 |

---

## 六、配置文件详解

### 6.1 后端配置

**文件路径：** `mootdx-server/src/main/resources/application.yml`

```yaml
spring:
  application:
    name: mootdx-server
  
  # 数据源配置
  datasource:
    url: jdbc:h2:mem:mootdxdb
    driver-class-name: org.h2.Driver
    username: sa
    password: 
    
  # H2控制台（开发环境）
  h2:
    console:
      enabled: true
      path: /h2-console
  
  # JPA配置
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
    properties:
      hibernate:
        format_sql: true
        dialect: org.hibernate.dialect.H2Dialect
  
  # Jackson配置
  jackson:
    serialization:
      write-dates-as-timestamps: false
    date-format: yyyy-MM-dd HH:mm:ss
    time-zone: GMT+8

# 服务器配置
server:
  port: 8080
  servlet:
    context-path: /

# 日志配置
logging:
  level:
    root: INFO
    com.mootdx: DEBUG
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"

# 自定义配置
mootdx:
  server:
    check-interval: 60000      # 服务器状态检查间隔(毫秒)
    connect-timeout: 10        # 连接超时时间(秒)
    max-retries: 3             # 最大重试次数
```

### 6.2 前端配置

**package.json：**

```json
{
  "name": "mootdx-web",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "serve": "vue-cli-service serve",
    "build": "vue-cli-service build",
    "lint": "vue-cli-service lint"
  },
  "dependencies": {
    "axios": "^1.5.0",
    "echarts": "^6.0.0",
    "element-plus": "^2.3.14",
    "vue": "^3.3.4",
    "vue-router": "^4.2.4"
  },
  "devDependencies": {
    "@vue/cli-plugin-babel": "~5.0.0",
    "@vue/cli-plugin-eslint": "~5.0.0",
    "@vue/cli-plugin-router": "~5.0.0",
    "@vue/cli-service": "~5.0.0",
    "@vue/compiler-sfc": "^3.3.4"
  },
  "browserslist": [
    "> 1%",
    "last 2 versions",
    "not dead",
    "not ie 11"
  ]
}
```

**环境变量：**

`.env.development:`
```
VUE_APP_API_URL=http://localhost:8080
```

`.env.production:`
```
VUE_APP_API_URL=http://your-production-server.com
```

---

## 七、部署与运行

### 7.1 构建项目

**后端构建：**

```bash
# 进入项目根目录
cd mootdx-java

# 构建所有模块
mvn clean package -DskipTests

# 构建产物位置
# mootdx-core/target/mootdx-core-1.0.0.jar
# mootdx-server/target/mootdx-server-1.0.0.jar
```

**前端构建：**

```bash
# 进入前端目录
cd mootdx-web

# 安装依赖
npm install

# 构建生产版本
npm run build

# 构建产物位置
# dist/
```

### 7.2 运行服务

**运行后端服务：**

```bash
# 方式一：直接运行JAR
java -jar mootdx-server/target/mootdx-server-1.0.0.jar

# 方式二：指定配置
java -jar mootdx-server/target/mootdx-server-1.0.0.jar \
  --server.port=8080 \
  --spring.datasource.url=jdbc:h2:file:./data/mootdxdb
```

**运行前端服务：**

```bash
# 开发环境
npm run serve

# 或使用静态服务器运行构建后的版本
npx http-server dist -p 3000
```

### 7.3 验证部署

**1. 验证后端API：**

```bash
# 获取K线数据
curl "http://localhost:8080/api/stocks/kline/SZ/000001?freq=day&limit=10"

# 获取股票列表
curl "http://localhost:8080/api/stocks/list/0"
```

**2. 验证前端页面：**

访问 `http://localhost:3000`，检查以下功能：
- [ ] 页面加载正常
- [ ] 查询表单显示正确
- [ ] K线图表渲染正常
- [ ] 数据表格显示正确
- [ ] 周期切换功能正常
- [ ] 复权切换功能正常
- [ ] 技术指标显示正确
- [ ] 数据导出功能正常

### 7.4 常见问题

**问题1：TDX服务器连接失败**

解决方案：
1. 检查TDX服务器配置是否正确
2. 确认网络连接正常
3. 尝试其他TDX服务器

**问题2：图表不显示**

解决方案：
1. 检查浏览器控制台是否有错误
2. 确认ECharts已正确安装
3. 验证数据格式是否正确

**问题3：CORS跨域问题**

解决方案：
1. 后端已配置 `@CrossOrigin(origins = "*")`
2. 确认前端API地址配置正确
3. 使用代理或Nginx转发

---

## 附录

### A. 技术指标计算公式

| 指标 | 公式说明 |
|-----|---------|
| **MA** | 简单移动平均，\( MA_n = \frac{\sum_{i=0}^{n-1} Close_{t-i}}{n} \) |
| **EMA** | 指数移动平均，\( EMA_t = \alpha \times Close_t + (1-\alpha) \times EMA_{t-1} \)，其中 \( \alpha = \frac{2}{n+1} \) |
| **MACD** | DIF = EMA(12) - EMA(26)，DEA = EMA(DIF, 9)，MACD = (DIF - DEA) × 2 |
| **KDJ** | RSV = (Close - Low_n) / (High_n - Low_n) × 100，K = 2/3 × K[-1] + 1/3 × RSV，D = 2/3 × D[-1] + 1/3 × K，J = 3K - 2D |
| **RSI** | RS = 平均涨幅 / 平均跌幅，RSI = 100 - 100/(1+RS) |
| **BOLL** | 中轨 = MA(20)，上轨 = 中轨 + 2σ，下轨 = 中轨 - 2σ |

### B. 频率映射表

| 前端参数 | TDX代码 | 数据量限制 |
|---------|---------|-----------|
| 1min | 8 | 120 |
| 5min | 0 | 120 |
| 15min | 1 | 120 |
| 30min | 2 | 120 |
| 60min | 3 | 120 |
| day | 9 | 500 |
| week | 5 | 260 |
| month | 6 | 120 |
| quarter | 10 | 60 |
| year | 11 | 30 |

### C. 颜色配置

| 元素 | 颜色代码 | 说明 |
|-----|---------|------|
| 涨/阳线 | #ef5350 | 红色 |
| 跌/阴线 | #26a69a | 绿色 |
| MA5 | #2196F3 | 蓝色 |
| MA10 | #FF9800 | 橙色 |
| MA20 | #9C27B0 | 紫色 |
| MA60 | #4CAF50 | 绿色 |
| BOLL上轨/下轨 | #FF5722 | 深橙色 |
| BOLL中轨 | #607D8B | 灰色 |

---

**文档版本：** 1.0.0  
**最后更新：** 2026-03-18  
**作者：** MooTDX Team
