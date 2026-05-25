# Code-to-Knowledge-Graph 集成可行性分析报告

> 文档日期：2026-05-22  
> 分析对象：Bevel-Software/code-to-knowledge-graph (GitHub)  
> 目标项目：MooTDX Java 项目

---

## 一、工具简介

**Code-to-Knowledge-Graph** 是一个 Kotlin/JVM 工具包，通过 VS Code 的 Language Server Protocol (LSP) 解析源代码，构建可查询的知识图谱。

**官方描述**：
> Transform your codebase into a powerful, queryable knowledge graph!  
> Extract entities, relationships, and architecture insights from any codebase.

**核心功能**：
- 🔍 理解代码结构
- 📈 分析代码影响范围
- 🏛️ 获取架构洞察
- 🛠️ 构建自定义工具
- 🤖 增强 AI & LLM 能力

---

## 二、工具环境要求

| 要求项 | 具体规格 | 来源 |
|--------|----------|------|
| **Java 版本** | Java 17+ | build.gradle.kts 配置 |
| **构建工具** | Gradle (Kotlin DSL) | 项目结构 |
| **开发语言** | Kotlin + Java 混合 | 代码统计：Kotlin 18.4%, Java 77.2% |
| **运行时依赖** | VS Code Language Server Protocol | 核心架构设计 |
| **发布仓库** | Maven Central | `software.bevel:code-to-knowledge-graph:1.1.3` |

---

## 三、与目标项目的兼容性分析

### 3.1 目标项目现状

| 项目属性 | 当前配置 |
|----------|----------|
| Java 版本 | 1.8 (Java 8) |
| 构建工具 | Maven |
| Spring Boot | 2.7.18 |
| 项目结构 | 多模块 Maven 项目 |

### 3.2 兼容性矩阵

| 对比项 | code-to-knowledge-graph | MooTDX 项目 | 兼容性 |
|--------|------------------------|-------------|--------|
| Java 版本 | 17+ | 8 | ❌ **不兼容** |
| 构建工具 | Gradle (Kotlin DSL) | Maven | ❌ **不兼容** |
| 语言栈 | Kotlin/JVM 混合 | 纯 Java | ⚠️ 需适配 |
| LSP 依赖 | 需要 VS Code LSP | 无 | ❌ **缺失依赖** |

---

## 四、具体问题分析

### 4.1 Java 版本障碍（关键 blocker）

**问题描述**：
- `code-to-knowledge-graph` 使用了 Java 17 的现代语法特性
- 包括但不限于：`var` 局部变量类型推断、增强型 `switch` 表达式、`record` 类、密封类等

**目标项目配置**（pom.xml）：
```xml
<properties>
    <java.version>1.8</java.version>
    <maven.compiler.source>1.8</maven.compiler.source>
    <maven.compiler.target>1.8</maven.compiler.target>
</properties>
```

**升级风险**：
1. Spring Boot 2.7.x 对 Java 17 支持有限
2. 大量第三方依赖需要同步升级
3. 测试回归成本高昂
4. 生产环境 JVM 需要升级

### 4.2 构建工具冲突

**问题描述**：
- 该工具使用 `build.gradle.kts`（Kotlin DSL）管理构建
- 虽然发布到 Maven Central，但内部传递依赖复杂

**潜在风险**：
1. Maven 与 Gradle 的依赖解析机制差异
2. Kotlin 标准库传递依赖冲突
3. 版本锁定困难

### 4.3 LSP 运行时依赖（架构难题）

**问题描述**：
- 该工具核心设计依赖 **VS Code 的 Language Server Protocol**
- 需要运行时连接 LSP 服务器进行代码解析

**集成复杂度**：
```
MooTDX Spring Boot 服务
    ↓
需要内嵌或连接 LSP 服务器进程
    ↓
LSP 服务器需要访问项目源码和编译环境
    ↓
涉及进程间通信、文件系统访问、状态同步
```

**实际场景**：
- 在 Docker 容器中运行时需要额外配置 LSP 环境
- 需要处理 LSP 服务器的生命周期管理
- 错误处理和故障恢复复杂

---

## 五、结论

### 5.1 可行性结论

**直接集成 `code-to-knowledge-graph` 到 MooTDX 项目不可行**

除非满足以下全部条件：
1. ✅ 将整个项目升级至 Java 17+
2. ✅ 处理 Maven/Gradle 混用的依赖冲突
3. ✅ 搭建并维护 LSP 运行时环境
4. ✅ 承担上述改动的测试和运维成本

### 5.2 成本评估

| 改动项 | 预估工作量 | 风险等级 |
|--------|-----------|----------|
| Java 8 → 17 升级 | 2-3 周 | 高 |
| 构建工具适配 | 3-5 天 | 中 |
| LSP 环境搭建 | 1-2 周 | 高 |
| 全量回归测试 | 1-2 周 | 高 |
| **总计** | **5-8 周** | **高** |

---

## 六、替代方案推荐

### 6.1 方案对比

| 评估维度 | code-to-knowledge-graph | JavaParser 自研 | Spoon 自研 |
|----------|------------------------|-----------------|------------|
| Java 版本 | 17+ | 8+ ✅ | 8+ ✅ |
| 构建工具 | Gradle | Maven ✅ | Maven ✅ |
| 外部依赖 | VS Code LSP | 无 ✅ | 无 ✅ |
| 解析能力 | 多语言（LSP） | Java 专用 | Java 专用 |
| 集成难度 | 高 | 低 ✅ | 低 ✅ |
| 功能定制 | 受限 | 完全可控 ✅ | 完全可控 ✅ |
| 社区活跃度 | 较新（2025年开源） | 成熟稳定 ✅ | 学术背景 |

### 6.2 推荐方案：JavaParser 自研

**选择理由**：
1. **完全兼容**：支持 Java 8，与现有技术栈无缝集成
2. **成熟稳定**：GitHub 4k+ stars，广泛应用于代码分析工具
3. **功能足够**：专注 Java 代码解析，满足项目需求
4. **可控性强**：自研代码可根据需求定制扩展

**Maven 依赖**：
```xml
<dependency>
    <groupId>com.github.javaparser</groupId>
    <artifactId>javaparser-symbol-solver-core</artifactId>
    <version>3.25.8</version>
</dependency>
```

**备选方案：Spoon**
```xml
<dependency>
    <groupId>fr.inria.gforge.spoon</groupId>
    <artifactId>spoon-core</artifactId>
    <version>10.4.2</version>
</dependency>
```

### 6.3 自研方案功能规划

| 功能模块 | 技术方案 | 工作量 |
|----------|----------|--------|
| 代码扫描服务 | JavaParser AST 解析 | 3-5 天 |
| 图谱存储 | JSON 文件 + 可选 Neo4j | 2-3 天 |
| REST API | Spring Boot Controller | 2-3 天 |
| 可视化前端 | ECharts Graph | 3-5 天 |
| AI RAG 集成 | OpenAI API + 向量检索 | 3-5 天 |
| **总计** | | **2-3 周** |

---

## 七、建议决策

| 方案 | 适用场景 | 建议 |
|------|----------|------|
| **A. 升级 Java 17 + 集成原工具** | 公司有统一升级计划，且急需多语言支持 | 暂缓，待技术栈升级后评估 |
| **B. JavaParser 自研（推荐）** | 当前技术栈，专注 Java 代码分析 | ✅ **采纳** |
| **C. 暂缓集成** | 优先级不高，资源有限 | 列入技术债，后续评估 |

---

## 八、参考资料

1. [Bevel-Software/code-to-knowledge-graph GitHub](https://github.com/Bevel-Software/code-to-knowledge-graph)
2. [JavaParser 官方文档](https://javaparser.org/)
3. [Spoon 官方文档](https://spoon.gforge.inria.fr/)
4. MooTDX 项目 pom.xml 配置

---

**文档编制**：AI Assistant  
**评审状态**：待架构组评审
