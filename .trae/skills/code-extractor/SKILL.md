---
name: "code-extractor"
description: "从 Java 项目中提取完整后端代码并提供 MD5 校验。当用户需要复制 API 接口代码并验证完整性时调用此技能。"
---

# 代码提取器 (带 MD5 校验)

本技能帮助您从 Java 后端项目中完整提取 API 接口代码，并提供 MD5 校验值以确保代码完整性。

## 功能概述

1. **精准定位代码** - 根据 API URL 找到对应的 Controller 和方法
2. **完整依赖提取** - 按依赖顺序提取：DTO → Repository → Service → Controller
3. **MD5 校验生成** - 为每个代码块生成 MD5 哈希值
4. **完整性验证** - 提供校验脚本和说明

## 何时调用

- 用户要求复制某个 API 接口的后端代码时
- 需要验证代码复制是否完整无误时
- 需要按依赖关系提取完整功能模块时

## 使用方法

### 1. 标准提示词模板

```markdown
请使用 code-extractor 技能提取以下接口的完整代码：

- **接口 URL**: http://localhost:8080/api/tdx-import/scan
- **项目目录**: mootdx-server

要求：
1. 按依赖顺序提取（DTO → Repository → Service → Controller）
2. 为每个代码块提供 MD5 校验值
3. 包含所有相关的私有方法和辅助类
```

### 2. 提取步骤

当调用此技能时，请按以下顺序执行：

#### 第一步：定位 Controller
- 根据 URL 路径找到对应的 Controller 类
- 定位到具体的 handler 方法

#### 第二步：分析依赖关系
- 识别该方法使用的所有 DTO/Entity 类
- 识别该方法调用的 Repository 接口
- 识别该方法调用的 Service 方法

#### 第三步：按顺序提取代码
1. **DTO/Entity 类** - 数据传输对象
2. **Repository 接口** - 数据访问层
3. **Service 方法** - 业务逻辑层
4. **Controller 方法** - 控制器层（包含所有私有辅助方法）

#### 第四步：生成 MD5 校验
- 为每个提取的代码块计算 MD5 值
- 提供验证方法

### 3. 输出格式要求

请严格按以下格式输出：

```markdown
---
# 代码提取结果

## 📦 1. DTO/Entity 类

### FileInfo.java
```java
package com.mootdx.server.dto;

import lombok.Data;

@Data
public class FileInfo {
    // 完整代码...
}
```
**MD5 校验值**: `a1b2c3d4e5f6g7h8`

---

## 📦 2. Repository 接口

### StockKlineRepository.java
```java
package com.mootdx.server.repository;

import com.mootdx.server.entity.StockKline;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StockKlineRepository extends JpaRepository<StockKline, Long> {
    // 完整代码...
}
```
**MD5 校验值**: `b2c3d4e5f6g7h8i9`

---

## 📦 3. Service 方法

### TdxDataImportService.java
```java
package com.mootdx.server.service;

@Service
public class TdxDataImportService {
    // 完整代码...
}
```
**MD5 校验值**: `c3d4e5f6g7h8i9j0`

---

## 📦 4. Controller 方法

### TdxDataImportController.java - scanFiles
```java
/**
 * 扫描数据文件
 */
@GetMapping("/scan")
public ResponseEntity<List<FileInfo>> scanFiles(@RequestParam String type) {
    // 完整代码...
}

// 包含所有私有辅助方法
```
**MD5 校验值**: `d4e5f6g7h8i9j0k1`

---

## 🔍 验证方法

### Windows PowerShell 验证
```powershell
# 方法一：保存为文件验证
$code = @'
// 粘贴 AI 输出的完整代码到这里
'@

$code | Out-File -FilePath "temp.java" -Encoding UTF8
Get-FileHash -Path "temp.java" -Algorithm MD5

# 方法二：直接计算（不保存文件）
$bytes = [System.Text.Encoding]::UTF8.GetBytes($code)
$md5 = [System.Security.Cryptography.MD5]::Create()
$hash = [BitConverter]::ToString($md5.ComputeHash($bytes)).Replace("-", "").ToLower()
Write-Host "MD5: $hash"
```

### 在线验证工具
访问：https://www.md5hashgenerator.com/

---

## ✅ 检查清单

- [ ] 所有 DTO 类已完整提取
- [ ] 所有 Repository 方法已包含
- [ ] Service 层代码完整
- [ ] Controller 包含所有私有辅助方法
- [ ] 每个代码块都有 MD5 校验值
```

## MD5 校验说明

### 为什么需要 MD5？
- 确保 AI 输出的代码与原代码完全一致
- 防止代码复制过程中出现遗漏或修改
- 便于后续验证代码完整性

### 校验原理
- MD5 是一种哈希算法，相同内容一定会生成相同的哈希值
- 即使只有一个字符不同，MD5 值也会完全不同
- 哈希值长度固定为 32 个十六进制字符

## 重要提示

⚠️ **注意事项**：
1. 请确保按依赖顺序提取代码（DTO → Repository → Service → Controller）
2. Controller 必须包含所有被调用的私有辅助方法
3. 所有类的完整包路径和 import 语句都要保留
4. 如果代码太长需要分段，请确保每段都有独立的 MD5 值
