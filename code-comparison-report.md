# 接口代码对比报告

**生成时间**: 2026-05-17

---

## 对比概述

| 项目 | 源接口 (端口 8080) | 目标接口 (端口 13000) |
|------|-------------------|---------------------|
| 项目路径 | `mootdx-server` | `javaTdx` |
| Controller 路径 | `com.mootdx.server.controller.TdxDataImportController` | `com.example.tdx.controller.TdxDataImportController` |
| 接口路径 | `/api/tdx-import/scan` | `/api/tdx-import/scan` |

---

## 主要差异总结

### 1. 返回类型差异 ⚠️ 严重

**源接口 (8080)**:
```java
@GetMapping("/scan")
public ResponseEntity<List<FileInfo>> scanFiles(@RequestParam String type)
```

**目标接口 (13000)**:
```java
@GetMapping("/scan")
public ApiResponse<List<FileInfo>> scanFiles(@RequestParam String type)
```

**影响**: 前端代码需要适配不同的响应包装格式。

---

### 2. 错误处理差异

**源接口 (8080)**:
```java
default:
    return ResponseEntity.badRequest().build();
```

**目标接口 (13000)**:
```java
default:
    return ApiResponse.error(400, "未知的扫描类型: " + type);
```

---

### 3. 市场参数大小写差异

**源接口 (8080)**:
```java
case "sh-day":
    files = scanDayFiles(TDX_INSTALL_DIR + "\\vipdoc\\sh\\lday", "sh");
    break;
case "sz-day":
    files = scanDayFiles(TDX_INSTALL_DIR + "\\vipdoc\\sz\\lday", "sz");
    break;
case "bj-day":
    files = scanDayFiles(TDX_INSTALL_DIR + "\\vipdoc\\bj\\lday", "bj");
    break;
// ...
case "sh-min1":
    files = scanMinuteFiles(TDX_INSTALL_DIR + "\\vipdoc\\sh\\minline", "sh", "1min");
    break;
```

**目标接口 (13000)**:
```java
case "sh-day":
    files = scanDayFiles(TDX_INSTALL_DIR + "\\vipdoc\\sh\\lday", "SH");
    break;
case "sz-day":
    files = scanDayFiles(TDX_INSTALL_DIR + "\\vipdoc\\sz\\lday", "SZ");
    break;
case "bj-day":
    files = scanDayFiles(TDX_INSTALL_DIR + "\\vipdoc\\bj\\lday", "BJ");
    break;
// ...
case "sh-min1":
    files = scanMinuteFiles(TDX_INSTALL_DIR + "\\vipdoc\\sh\\minline", "SH", "1min");
    break;
```

**差异**: 市场代码从 `"sh"`, `"sz"`, `"bj"` 变成了 `"SH"`, `"SZ"`, `"BJ"`（大写）。

---

### 4. 日志差异

**目标接口 (13000)** 在 `getStatistics` 方法中有更详细的日志：
```java
log.info("【API调用】获取通达信数据文件统计信息 - 开始");
// ...
log.info("【API调用】获取通达信数据文件统计信息 - 完成: ...");
```

---

### 5. 缺少的接口

**源接口 (8080)** 有但 **目标接口 (13000)** 没有的接口：

| 接口路径 | 说明 |
|---------|-----|
| `GET /api/tdx-import/db-stats` | 获取数据库统计信息 |

---

### 6. 新增的辅助方法

**目标接口 (13000)** 新增了一些辅助方法：

| 方法 | 说明 |
|------|-----|
| `countFilesAndSize()` | 同时统计文件数量和大小 |
| `countBlockFiles()` | 快速统计板块文件 |

---

## 详细差异对比

### scanFiles 方法对比

| 方面 | 源接口 (8080) | 目标接口 (13000) |
|-----|-------------|-----------------|
| 返回类型 | `ResponseEntity<List<FileInfo>>` | `ApiResponse<List<FileInfo>>` |
| 市场参数 | `"sh"`, `"sz"`, `"bj"` (小写) | `"SH"`, `"SZ"`, `"BJ"` (大写) |
| 错误处理 | `ResponseEntity.badRequest().build()` | `ApiResponse.error(400, "未知的扫描类型: " + type)` |

---

## FileInfo 类对比

两个 FileInfo 类的字段基本一致，但定义位置不同：

**源接口 (8080)**: `FileInfo` 定义在 Controller 内部（静态内部类）  
**目标接口 (13000)**: `FileInfo` 定义在独立的 DTO 包中 (`com.example.tdx.dto.FileInfo`)

---

## Repository 调用差异

| Repository 方法 | 源接口 (8080) | 目标接口 (13000) |
|--------------|--------------|----------------|
| countByBlockCode() | ✅ 使用 | ❌ 不使用 (使用 countByBlockName()) |

---

## import 语句对比

**源接口 (8080)**:
```java
import com.mootdx.localdata.TdxBlockConfigReader;
import com.mootdx.localdata.TdxBlockDataReader;
import com.mootdx.localdata.TdxLocalDataReader;
import com.mootdx.localdata.TdxMarkDataReader;
import com.mootdx.model.BarData;
import com.mootdx.server.entity.StockKline;
import com.mootdx.server.repository.StockBlockRepository;
import com.mootdx.server.repository.StockKlineRepository;
import com.mootdx.server.service.TdxDataImportService;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.sql.DataSource;
import java.io.File;
import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;
```

**目标接口 (13000)**:
```java
import com.example.tdx.dto.ApiResponse;
import com.example.tdx.dto.DataStatistics;
import com.example.tdx.dto.FileInfo;
import com.example.tdx.dto.ImportResult;
import com.example.tdx.repository.StockBlockRepository;
import com.example.tdx.repository.StockKlineRepository;
import com.example.tdx.service.TdxDataImportService;
import com.mootdx.localdata.TdxBlockDataReader;
import com.mootdx.localdata.TdxLocalDataReader;
import com.mootdx.localdata.TdxMarkDataReader;
import com.mootdx.model.BarData;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.io.IOException;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;
```

**差异**:
- 源接口: `import javax.sql.DataSource;` + `import org.springframework.http.ResponseEntity;`
- 目标接口: `import com.example.tdx.dto.*;` (多个 DTO 类)

---

## 代码对比总结

### 兼容性问题 ⚠️

| 问题 | 严重程度 | 说明 |
|-----|---------|-----|
| 返回类型不一致 | 🔴 高 | 源用 `ResponseEntity`, 目标用 `ApiResponse` |
| 市场参数大小写 | 🟡 中 | 源小写 `"sh"`, 目标大写 `"SH"` |
| 缺少 `db-stats` 接口 | 🟡 中 | 目标接口没有此功能 |

---

### 建议修复

1. **统一返回类型** - 建议都使用 `ApiResponse` 或都使用 `ResponseEntity`
2. **统一市场参数大小写** - 在 `enrichDbInfo` 中已有 `toUpperCase()` 调用，建议保持一致
3. **补充缺失的接口** - 如需要 `db-stats` 功能，需要补充

---

## 附录

### 源接口完整方法 (8080 端口)

```java
@GetMapping("/scan")
public ResponseEntity<List<FileInfo>> scanFiles(@RequestParam String type) {
    log.info("扫描数据文件: type={}", type);

    List<FileInfo> files = new ArrayList<>();
    TdxLocalDataReader reader = new TdxLocalDataReader();

    switch (type) {
        case "sh-day":
            files = scanDayFiles(TDX_INSTALL_DIR + "\\vipdoc\\sh\\lday", "sh");
            break;
        case "sz-day":
            files = scanDayFiles(TDX_INSTALL_DIR + "\\vipdoc\\sz\\lday", "sz");
            break;
        case "bj-day":
            files = scanDayFiles(TDX_INSTALL_DIR + "\\vipdoc\\bj\\lday", "bj");
            break;
        case "block":
            files = scanBlockFiles(TDX_INSTALL_DIR + "\\T0002\\blocknew");
            break;
        case "system-block":
            files = scanBlockFiles(TDX_INSTALL_DIR + "\\T0002\\blocknew").stream()
                .filter(f -> "system".equals(f.getBlockType()))
                .collect(Collectors.toList());
            break;
        case "custom-block":
            files = scanBlockFiles(TDX_INSTALL_DIR + "\\T0002\\blocknew").stream()
                .filter(f -> "custom".equals(f.getBlockType()))
                .collect(Collectors.toList());
            break;
        case "mark":
            files = scanMarkFile(TDX_INSTALL_DIR + "\\T0002\\mark.dat");
            break;
        case "sh-min1":
            files = scanMinuteFiles(TDX_INSTALL_DIR + "\\vipdoc\\sh\\minline", "sh", "1min");
            break;
        case "sz-min1":
            files = scanMinuteFiles(TDX_INSTALL_DIR + "\\vipdoc\\sz\\minline", "sz", "1min");
            break;
        case "sh-min5":
            files = scanMinuteFiles(TDX_INSTALL_DIR + "\\vipdoc\\sh\\fzline", "sh", "5min");
            break;
        case "sz-min5":
            files = scanMinuteFiles(TDX_INSTALL_DIR + "\\vipdoc\\sz\\fzline", "sz", "5min");
            break;
        default:
            return ResponseEntity.badRequest().build();
    }

    return ResponseEntity.ok(files);
}
```

### 目标接口完整方法 (13000 端口)

```java
@GetMapping("/scan")
public ApiResponse<List<FileInfo>> scanFiles(@RequestParam String type) {
    log.info("扫描数据文件: type={}", type);

    List<FileInfo> files = new ArrayList<>();
    TdxLocalDataReader reader = new TdxLocalDataReader();

    switch (type) {
        case "sh-day":
            files = scanDayFiles(TDX_INSTALL_DIR + "\\vipdoc\\sh\\lday", "SH");
            break;
        case "sz-day":
            files = scanDayFiles(TDX_INSTALL_DIR + "\\vipdoc\\sz\\lday", "SZ");
            break;
        case "bj-day":
            files = scanDayFiles(TDX_INSTALL_DIR + "\\vipdoc\\bj\\lday", "BJ");
            break;
        case "block":
            files = scanBlockFiles(TDX_INSTALL_DIR + "\\T0002\\blocknew");
            break;
        case "system-block":
            files = scanBlockFiles(TDX_INSTALL_DIR + "\\T0002\\blocknew").stream()
                .filter(f -> "system".equals(f.getBlockType()))
                .collect(Collectors.toList());
            break;
        case "custom-block":
            files = scanBlockFiles(TDX_INSTALL_DIR + "\\T0002\\blocknew").stream()
                .filter(f -> "custom".equals(f.getBlockType()))
                .collect(Collectors.toList());
            break;
        case "mark":
            files = scanMarkFile(TDX_INSTALL_DIR + "\\T0002\\mark.dat");
            break;
        case "sh-min1":
            files = scanMinuteFiles(TDX_INSTALL_DIR + "\\vipdoc\\sh\\minline", "SH", "1min");
            break;
        case "sz-min1":
            files = scanMinuteFiles(TDX_INSTALL_DIR + "\\vipdoc\\sz\\minline", "SZ", "1min");
            break;
        case "sh-min5":
            files = scanMinuteFiles(TDX_INSTALL_DIR + "\\vipdoc\\sh\\fzline", "SH", "5min");
            break;
        case "sz-min5":
            files = scanMinuteFiles(TDX_INSTALL_DIR + "\\vipdoc\\sz\\fzline", "SZ", "5min");
            break;
        default:
            return ApiResponse.error(400, "未知的扫描类型: " + type);
    }

    return ApiResponse.success(files);
}
```
