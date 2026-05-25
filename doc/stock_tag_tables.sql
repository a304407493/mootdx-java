-- 股票标签管理系统数据库表结构
-- 适用于H2/MySQL/PostgreSQL等关系型数据库

-- =============================================
-- 1. 标签定义表 stock_tag
-- =============================================
CREATE TABLE IF NOT EXISTS stock_tag (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    tag_id VARCHAR(32) NOT NULL UNIQUE COMMENT '标签唯一ID',
    tag_name VARCHAR(100) NOT NULL COMMENT '标签名称',
    tag_type VARCHAR(20) NOT NULL DEFAULT 'theme' COMMENT '标签类型: theme/industry/concept/technical/region/style',
    tag_level INT DEFAULT 1 COMMENT '标签级别 1-3',
    parent_tag_id VARCHAR(32) COMMENT '父标签ID，支持层级',
    keywords VARCHAR(500) COMMENT '关键词，逗号分隔',
    description VARCHAR(2000) COMMENT '详细描述',
    color VARCHAR(20) COMMENT '显示颜色',
    icon VARCHAR(100) COMMENT '图标',
    stock_count INT DEFAULT 0 COMMENT '关联股票数量',
    source VARCHAR(50) COMMENT '数据来源',
    source_code VARCHAR(50) COMMENT '源系统编码',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 标签表索引
CREATE INDEX IF NOT EXISTS idx_tag_id ON stock_tag(tag_id);
CREATE INDEX IF NOT EXISTS idx_tag_type ON stock_tag(tag_type);
CREATE INDEX IF NOT EXISTS idx_tag_name ON stock_tag(tag_name);
CREATE INDEX IF NOT EXISTS idx_tag_type_name ON stock_tag(tag_type, tag_name);
CREATE INDEX IF NOT EXISTS idx_parent_tag ON stock_tag(parent_tag_id);

-- =============================================
-- 2. 股票-标签关联表 stock_tag_mapping
-- =============================================
CREATE TABLE IF NOT EXISTS stock_tag_mapping (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(10) NOT NULL COMMENT '股票代码',
    market VARCHAR(10) NOT NULL COMMENT '市场 SH/SZ/BJ',
    tag_id VARCHAR(32) NOT NULL COMMENT '标签ID',
    tag_type VARCHAR(20) NOT NULL COMMENT '标签类型（冗余）',
    weight INT DEFAULT 0 COMMENT '关联权重 0-100',
    valid_from TIMESTAMP COMMENT '生效开始时间',
    valid_to TIMESTAMP COMMENT '生效结束时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(code, market, tag_id)
);

-- 关联表索引
CREATE INDEX IF NOT EXISTS idx_mapping_code ON stock_tag_mapping(code, market);
CREATE INDEX IF NOT EXISTS idx_mapping_tag ON stock_tag_mapping(tag_id);
CREATE INDEX IF NOT EXISTS idx_mapping_type ON stock_tag_mapping(tag_type);
CREATE INDEX IF NOT EXISTS idx_mapping_code_type ON stock_tag_mapping(code, market, tag_type);

-- =============================================
-- 3. 技术指标标签表 stock_technical_tag
-- =============================================
CREATE TABLE IF NOT EXISTS stock_technical_tag (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(10) NOT NULL COMMENT '股票代码',
    market VARCHAR(10) NOT NULL COMMENT '市场',
    indicator_name VARCHAR(50) NOT NULL COMMENT '指标名称: MACD/KDJ/RSI/MA',
    indicator_code VARCHAR(20) COMMENT '指标代码',
    signal_type VARCHAR(30) COMMENT '信号类型: golden_cross/dead_cross/over_bought/over_sold',
    trade_date DATE NOT NULL COMMENT '交易日期',
    trade_time TIMESTAMP COMMENT '交易时间（分钟线）',
    freq VARCHAR(10) DEFAULT 'day' COMMENT '周期: 1min/5min/15min/30min/60min/day/week/month',
    indicator_value DOUBLE COMMENT '指标数值',
    signal_strength INT DEFAULT 3 COMMENT '信号强度 1-5',
    trigger_price DOUBLE COMMENT '触发价格',
    trigger_volume INT COMMENT '触发时成交量',
    description VARCHAR(500) COMMENT '信号描述',
    is_active INT DEFAULT 1 COMMENT '是否有效: 1-有效,0-失效',
    confirmed INT DEFAULT 0 COMMENT '是否确认: 0-未确认,1-已确认',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 技术指标表索引
CREATE INDEX IF NOT EXISTS idx_tech_code ON stock_technical_tag(code, market);
CREATE INDEX IF NOT EXISTS idx_tech_indicator ON stock_technical_tag(indicator_name);
CREATE INDEX IF NOT EXISTS idx_tech_signal ON stock_technical_tag(signal_type);
CREATE INDEX IF NOT EXISTS idx_tech_date ON stock_technical_tag(trade_date);
CREATE INDEX IF NOT EXISTS idx_tech_time ON stock_technical_tag(trade_time);
CREATE INDEX IF NOT EXISTS idx_tech_freq ON stock_technical_tag(freq);
CREATE INDEX IF NOT EXISTS idx_tech_code_date ON stock_technical_tag(code, market, trade_date);
CREATE INDEX IF NOT EXISTS idx_tech_indicator_date ON stock_technical_tag(indicator_name, trade_date);
CREATE INDEX IF NOT EXISTS idx_tech_active ON stock_technical_tag(is_active, confirmed);

-- =============================================
-- 4. 行业分类表 stock_industry
-- =============================================
CREATE TABLE IF NOT EXISTS stock_industry (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(10) NOT NULL COMMENT '股票代码',
    market VARCHAR(10) NOT NULL COMMENT '市场',
    standard VARCHAR(20) DEFAULT 'sw' COMMENT '分类标准: sw/citic/csrc/wind',
    industry_level1_code VARCHAR(20) COMMENT '一级行业代码',
    industry_level1_name VARCHAR(50) COMMENT '一级行业名称',
    industry_level2_code VARCHAR(20) COMMENT '二级行业代码',
    industry_level2_name VARCHAR(50) COMMENT '二级行业名称',
    industry_level3_code VARCHAR(20) COMMENT '三级行业代码',
    industry_level3_name VARCHAR(50) COMMENT '三级行业名称',
    effective_date DATE COMMENT '生效日期',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE(code, market, standard)
);

-- 行业表索引
CREATE INDEX IF NOT EXISTS idx_industry_code ON stock_industry(code, market);
CREATE INDEX IF NOT EXISTS idx_industry_std ON stock_industry(standard);
CREATE INDEX IF NOT EXISTS idx_industry_l1 ON stock_industry(industry_level1_code);
CREATE INDEX IF NOT EXISTS idx_industry_l2 ON stock_industry(industry_level2_code);
CREATE INDEX IF NOT EXISTS idx_industry_l3 ON stock_industry(industry_level3_code);

-- =============================================
-- 5. 标签操作历史表 stock_tag_history
-- =============================================
CREATE TABLE IF NOT EXISTS stock_tag_history (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(10) NOT NULL COMMENT '股票代码',
    market VARCHAR(10) NOT NULL COMMENT '市场',
    tag_id VARCHAR(32) NOT NULL COMMENT '标签ID',
    tag_type VARCHAR(20) NOT NULL COMMENT '标签类型',
    action VARCHAR(20) NOT NULL COMMENT '操作: ADD/REMOVE/UPDATE',
    old_value VARCHAR(500) COMMENT '旧值',
    new_value VARCHAR(500) COMMENT '新值',
    operator VARCHAR(50) COMMENT '操作人',
    source VARCHAR(50) COMMENT '操作来源',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 历史表索引
CREATE INDEX IF NOT EXISTS idx_history_code ON stock_tag_history(code, market);
CREATE INDEX IF NOT EXISTS idx_history_tag ON stock_tag_history(tag_id);
CREATE INDEX IF NOT EXISTS idx_history_time ON stock_tag_history(created_at);

-- =============================================
-- 初始化数据 - 示例标签
-- =============================================

-- 题材标签示例
INSERT INTO stock_tag (tag_id, tag_name, tag_type, keywords, description, color, stock_count) VALUES
('theme_ai', '人工智能', 'theme', 'AI,人工智能,ChatGPT,大模型', '人工智能相关股票', '#409EFF', 0),
('theme_new_energy', '新能源', 'theme', '新能源,光伏,风电,储能', '新能源产业链相关股票', '#67C23A', 0),
('theme_semiconductor', '半导体', 'theme', '芯片,半导体,集成电路', '半导体产业链相关股票', '#E6A23C', 0),
('theme_robot', '机器人', 'theme', '机器人,工业机器人,服务机器人', '机器人概念相关股票', '#F56C6C', 0);

-- 行业标签示例
INSERT INTO stock_tag (tag_id, tag_name, tag_type, keywords, description, color, stock_count) VALUES
('industry_bank', '银行', 'industry', '银行,商业银行,投资银行', '银行业股票', '#909399', 0),
('industry_insurance', '保险', 'industry', '保险,人寿,财险', '保险业股票', '#909399', 0),
('industry_retail', '零售', 'industry', '零售,商超,电商', '零售行业股票', '#909399', 0);

-- 概念标签示例
INSERT INTO stock_tag (tag_id, tag_name, tag_type, keywords, description, color, stock_count) VALUES
('concept_military', '军工', 'concept', '军工,国防,航空', '军工概念股', '#9254DE', 0),
('concept_vaccine', '疫苗', 'concept', '疫苗,生物制药', '疫苗概念股', '#9254DE', 0);
