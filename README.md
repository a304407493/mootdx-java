# MooTDX Java

[![Java 8](https://img.shields.io/badge/Java-8-blue.svg)](https://www.oracle.com/java/technologies/javase/javase8-archive-downloads.html)
[![Maven](https://img.shields.io/badge/Maven-3.8+-green.svg)](https://maven.apache.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Java implementation of [mootdx](https://github.com/bopo/mootdx) - A TongDaXin (通达信) stock data reader library.

## Overview

MooTDX Java provides a complete Java implementation of the Python mootdx library, enabling:

- **Local Data Reading**: Parse `.day`, `.lc1`, `.lc5` binary files from TDX installation
- **Online Quotes**: Connect to TDX servers via TCP for real-time data
- **Financial Reports**: Download and parse company financial statements
- **Price Adjustments**: Apply forward (前复权) and backward (后复权) adjustments

## Features

| Feature | Python (mootdx) | Java (mootdx-java) |
|---------|-----------------|-------------------|
| Local File Reader | ✅ `Reader` | ✅ `TdxFileReader` |
| TCP Quotes | ✅ `Quotes` | ✅ `TdxQuoteClient` |
| Financial Data | ✅ `Affair` | ✅ `AffairService` |
| CLI Tool | ✅ `mootdx` | ✅ `MootdxCommand` |
| Price Adjustment | ✅ Built-in | ✅ `AdjustmentUtils` |
| Caching | ✅ `lru_cache` | ✅ `CacheManager` (Caffeine) |
| DataFrame | ✅ pandas | ✅ `List<BarData>` + Tablesaw |

## Requirements

- Java 8 or higher
- Maven 3.6 or higher
- TDX installation (for local data reading)
- Internet connection (for online quotes)

## Quick Start

### 1. Build the Project

```bash
git clone https://github.com/mootdx/mootdx-java.git
cd mootdx-java
mvn clean package -DskipTests
```

### 2. Use as Library

Add to your `pom.xml`:

```xml
<dependency>
    <groupId>com.mootdx</groupId>
    <artifactId>mootdx-java</artifactId>
    <version>1.0.0</version>
</dependency>
```

### 3. Basic Usage

#### Read Local Daily Data

```java
import com.mootdx.reader.TdxFileReader;
import com.mootdx.model.BarData;
import java.nio.file.Paths;
import java.util.List;

// Create reader
TdxFileReader reader = new TdxFileReader(Paths.get("C:/new_tdx"));

// Read daily data
List<BarData> dailyData = reader.readDaily("600036");

for (BarData bar : dailyData) {
    System.out.printf("%s: Open=%s, High=%s, Low=%s, Close=%s%n",
        bar.getDateString(), bar.getOpen(), bar.getHigh(), 
        bar.getLow(), bar.getClose());
}
```

#### Get Real-Time Quote

```java
import com.mootdx.quotes.TdxQuoteClient;
import com.mootdx.model.Quote;

// Connect to server (auto-select best)
TdxQuoteClient client = TdxQuoteClient.factory("std", true, true);

// Get quote
Quote quote = client.getQuote("600036");

System.out.println("Price: " + quote.getLastPrice());
System.out.println("Change: " + quote.getChangePercent() + "%");
System.out.println("Best Bid: " + quote.getBestBidPrice());
System.out.println("Best Ask: " + quote.getBestAskPrice());
```

#### Get K-Line Data from Server

```java
// Get daily K-line (last 100 days)
List<BarData> daily = client.getDaily("600036", 100);

// Get 1-minute K-line
List<BarData> minute1 = client.getMinute1("600036", 100);

// Get 5-minute K-line
List<BarData> minute5 = client.getMinute5("600036", 100);
```

### 4. Use CLI Tool

```bash
# Read local daily data
java -jar target/mootdx-java-1.0.0.jar reader daily -s 600036 -d C:/new_tdx

# Get real-time quote
java -jar target/mootdx-java-1.0.0.jar quotes get -s 600036

# Get K-line data
java -jar target/mootdx-java-1.0.0.jar quotes bars -s 600036 -f 9 -n 100

# List available stocks
java -jar target/mootdx-java-1.0.0.jar reader list -d C:/new_tdx

# Find best server
java -jar target/mootdx-java-1.0.0.jar bestip

# List financial files
java -jar target/mootdx-java-1.0.0.jar affair list
```

## API Reference

### TdxFileReader (Local Data)

| Method | Description | Python Equivalent |
|--------|-------------|-------------------|
| `readDaily(symbol)` | Read daily K-line | `reader.daily(symbol)` |
| `readMinute(symbol, period)` | Read minute K-line | `reader.minute(symbol)` |
| `readMinute1(symbol)` | Read 1-minute data | - |
| `readMinute5(symbol)` | Read 5-minute data | - |
| `getLastNBars(symbol, n)` | Get last N bars | - |
| `getDateRange(symbol, start, end)` | Get date range | - |
| `listAvailableStocks()` | List all stocks | - |

### TdxQuoteClient (Online Data)

| Method | Description | Python Equivalent |
|--------|-------------|-------------------|
| `getQuote(symbol)` | Get real-time quote | `client.get_quote(symbol)` |
| `getQuotes(symbols)` | Get multiple quotes | `client.get_quotes(list)` |
| `getKLine(symbol, freq, offset)` | Get K-line data | `client.bars(symbol, freq, offset)` |
| `getDaily(symbol, offset)` | Get daily data | `client.daily(symbol, offset)` |
| `getMinute1(symbol, offset)` | Get 1-min data | `client.minute(symbol)` |
| `getMinuteData(symbol)` | Get intraday data | `client.minute(symbol)` |
| `getStockList(market)` | Get stock list | `client.get_stock_list(market)` |
| `selectBestServer(servers)` | Find best server | `client.best_ip()` |

### AffairService (Financial Data)

| Method | Description | Python Equivalent |
|--------|-------------|-------------------|
| `listFiles()` | List available files | `Affair.files()` |
| `listFiles(year)` | List files by year | - |
| `downloadReport(filename, dir)` | Download file | `Affair.fetch(downdir, filename)` |
| `downloadAll(dir)` | Download all files | `Affair.parse(downdir)` |
| `parseReport(zipFile)` | Parse ZIP file | `Affair.parse(downdir)` |

### AdjustmentUtils (Price Adjustments)

| Method | Description | Python Equivalent |
|--------|-------------|-------------------|
| `toQfq(bars, xdxrs)` | Forward adjustment | Built-in |
| `toQfq(bars)` | Forward (simplified) | Built-in |
| `toHfq(bars, xdxrs)` | Backward adjustment | Built-in |
| `toHfq(bars)` | Backward (simplified) | Built-in |

## Data Models

### BarData

```java
public record BarData(
    int date,           // YYYYMMDD or YYYYMMDDHHMM
    BigDecimal open,    // Opening price
    BigDecimal high,    // Highest price
    BigDecimal low,     // Lowest price
    BigDecimal close,   // Closing price
    long volume,        // Trading volume
    BigDecimal amount   // Trading amount
) {}
```

### Quote

```java
public record Quote(
    String code,              // Stock code
    String name,              // Stock name
    int market,               // Market (0=Shenzhen, 1=Shanghai)
    BigDecimal lastPrice,     // Latest price
    BigDecimal open,          // Opening price
    BigDecimal high,          // Highest price
    BigDecimal low,           // Lowest price
    BigDecimal prevClose,     // Previous close
    long volume,              // Volume
    BigDecimal amount,        // Amount
    BigDecimal[] bidPrices,   // Bid prices (5 levels)
    BigDecimal[] askPrices,   // Ask prices (5 levels)
    long[] bidVolumes,        // Bid volumes
    long[] askVolumes,        // Ask volumes
    LocalDate date,           // Trading date
    LocalTime time            // Trading time
) {}
```

### StockMeta

```java
public record StockMeta(
    String code,    // Stock code
    String name,    // Stock name (Chinese)
    int market      // Market code
) {}
```

## Python vs Java API Comparison

| Python | Java | Notes |
|--------|------|-------|
| `reader.daily('600036')` | `reader.readDaily("600036")` | Returns `List<BarData>` instead of DataFrame |
| `reader.minute('600036')` | `reader.readMinute("600036", 1)` | Period parameter required |
| `client.bars('600036', 9, 10)` | `client.getKLine("600036", 9, 10)` | Same parameters |
| `client.get_quote('600036')` | `client.getQuote("600036")` | Returns `Quote` object |
| `client.stocks(1)` | `client.getStockList(1)` | Returns `List<StockMeta>` |
| `Affair.files()` | `affair.listFiles()` | Returns `List<String>` |
| `Affair.fetch('tmp', 'file.zip')` | `affair.downloadReport("file.zip", path)` | Path object instead of string |

## Binary File Format

### .day File Structure (32 bytes/record)

```
Offset  Size  Type    Description
0       4     int     Date (YYYYMMDD)
4       4     int     Open price * 100
8       4     int     High price * 100
12      4     int     Low price * 100
16      4     int     Close price * 100
20      4     float   Amount (yuan)
24      4     int     Volume (shares)
28      4     int     Reserved / Previous close
```

### TCP Protocol

```
Packet Structure:
[0-1]   : Length (2 bytes, little-endian)
[2]     : Checksum (1 byte)
[3]     : Header (1 byte, 0x01)
[4-5]   : Command (2 bytes)
[6...]  : Payload (variable)

Commands:
0x0451  : Get stock list
0x052d  : Get K-line data
0x053e  : Get real-time quote
0x053c  : Get minute data
0x0801  : Heartbeat
```

## Configuration

### Server List

Default TDX servers (port 7709):
- 119.147.212.81
- 221.231.141.60
- 58.63.254.191
- 115.238.90.165
- 14.215.128.18

### Cache Configuration

```java
// Custom cache settings
CacheManager cache = new CacheManager(
    60,   // stock list expiry (minutes)
    60,   // quote expiry (seconds)
    30    // historical data expiry (minutes)
);
```

## Dependencies

| Library | Version | Purpose |
|---------|---------|---------|
| Netty | 4.1.100.Final | TCP communication |
| picocli | 4.7.5 | CLI framework |
| Jackson | 2.15.2 | JSON processing |
| Caffeine | 3.1.8 | Caching |
| Tablesaw | 0.43.1 | Data analysis (optional) |
| JUnit 5 | 5.10.0 | Testing |

## Project Structure

```
mootdx-java/
├── pom.xml
├── README.md
└── src/
    ├── main/java/com/mootdx/
    │   ├── reader/
    │   │   └── TdxFileReader.java
    │   ├── quotes/
    │   │   └── TdxQuoteClient.java
    │   ├── affair/
    │   │   └── AffairService.java
    │   ├── cli/
    │   │   └── MootdxCommand.java
    │   ├── model/
    │   │   ├── BarData.java
    │   │   ├── Quote.java
    │   │   ├── StockMeta.java
    │   │   ├── MinuteData.java
    │   │   └── FinancialReport.java
    │   ├── utils/
    │   │   ├── ByteUtils.java
    │   │   ├── TdxUtils.java
    │   │   └── AdjustmentUtils.java
    │   ├── cache/
    │   │   └── CacheManager.java
    │   ├── protocol/
    │   │   └── TdxProtocol.java
    │   └── exception/
    │       ├── TdxException.java
    │       ├── FileFormatException.java
    │       ├── NetworkException.java
    │       └── ProtocolException.java
    └── test/java/com/mootdx/
        ├── reader/TdxFileReaderTest.java
        ├── utils/ByteUtilsTest.java
        ├── utils/TdxUtilsTest.java
        ├── utils/AdjustmentUtilsTest.java
        └── ExampleUsage.java
```

## Testing

```bash
# Run all tests
mvn test

# Run specific test
mvn test -Dtest=TdxFileReaderTest

# Run with coverage
mvn jacoco:report
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- [mootdx](https://github.com/bopo/mootdx) - Original Python library
- [pytdx](https://github.com/rainx/pytdx) - Low-level TDX protocol implementation

## Support

- GitHub Issues: [https://github.com/mootdx/mootdx-java/issues](https://github.com/mootdx/mootdx-java/issues)
- Documentation: [https://mootdx.readthedocs.io](https://mootdx.readthedocs.io)
