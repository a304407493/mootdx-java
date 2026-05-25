# K线功能实现总结与注意事项

## 一、会话中遇到的问题及解决方案

### 问题1：季K线缺失
**现象**：K线图菜单中只有1分钟、5分钟、15分钟、30分钟、60分钟、日线、周线、月线、年线，缺少季K线

**原因**：前端菜单和后端映射均未配置季K线

**解决方案**：
1. 前端 `Kline.vue` 添加 `<el-radio-button value="quarter">季线</el-radio-button>`
2. 后端 `cache_service.py` 的 `freq_map` 添加 `'quarter': 10`
3. 后端 `freq_offset_map` 添加 `'quarter': 60`
4. 前端 `xAxisConfig` 添加季K线的横坐标格式化配置

---

### 问题2：分钟K线后端映射错误
**现象**：分钟K线数据获取不正确

**原因**：`freq_map` 中的映射值与TDX接口实际要求的频率代码不匹配

**解决方案**：根据TDX官方频率参数说明修正映射：
```python
freq_map = {
    '1min': 8,    # 1分钟K线（原错误映射为0）
    '5min': 0,    # 5分钟K线（原错误映射为1）
    '15min': 1,   # 15分钟K线（原错误映射为2）
    '30min': 2,   # 30分钟K线（原错误映射为3）
    '60min': 3,   # 60分钟K线（原错误映射为4）
    'day': 9,     # 日K线
    'week': 5,    # 周K线
    'month': 6,   # 月K线
    'quarter': 10, # 季K线
    'year': 11    # 年K线（原错误映射为7）
}
```

---

### 问题3：第一次查询数据缺少日期字段
**现象**：第一次查询（从TDX接口获取）返回的数据没有日期，第二次查询（从缓存获取）才有日期

**原因**：
- 从数据库获取时：明确构建了包含 `trade_date` 字段的DataFrame
- 从TDX接口获取时：直接返回原始数据，日期列名为 `datetime`，与前端期望的 `trade_date` 不一致

**解决方案**：在从TDX接口获取数据后，统一处理数据格式：
1. 提取 `datetime` 列并解析为 `trade_date` 和 `trade_time`
2. 构建与数据库查询格式一致的DataFrame
3. 确保所有字段类型正确（open/high/low/close转为float，volume转为int）

---

### 问题4：第一次查询数据顺序不正确
**现象**：第一次查询（从TDX接口获取）的数据顺序与第二次查询（从缓存获取）不一致

**原因**：
- 从数据库获取时：使用了 `.order_by(StockKline.trade_date.desc())` 按时间倒序排序
- 从TDX接口获取时：没有进行排序

**解决方案**：在从TDX接口获取数据后，添加排序逻辑：
```python
result_df = result_df.sort_values('trade_date', ascending=False).reset_index(drop=True)
```

---

## 二、K线数据频率参数说明（TDX官方）

| 频率代码 | 含义 |
|---------|------|
| 0 | 5分钟K线 |
| 1 | 15分钟K线 |
| 2 | 30分钟K线 |
| 3 | 60分钟K线 |
| 4 | 日K线 |
| 5 | 周K线 |
| 6 | 月K线 |
| 7 | 扩展市场1分钟 |
| 8 | 1分钟K线 |
| 9 | 日K线 |
| 10 | 季K线 |
| 11 | 年K线 |

**注意**：日线有两个代码（4和9），实际使用9

---

## 三、前端实现要点

### 3.1 文件位置
- **主文件**：`frontend/src/views/Kline.vue`
- **样式文件**：`frontend/src/views/Kline.css`（如使用独立样式）
- **API接口**：`frontend/src/api/stock.js`

### 3.2 关键配置

#### 频率按钮配置
```vue
<el-radio-group v-model="selectedFreq" @change="fetchKlineData">
  <el-radio-button value="1min">1分钟</el-radio-button>
  <el-radio-button value="5min">5分钟</el-radio-button>
  <el-radio-button value="15min">15分钟</el-radio-button>
  <el-radio-button value="30min">30分钟</el-radio-button>
  <el-radio-button value="60min">60分钟</el-radio-button>
  <el-radio-button value="day">日线</el-radio-button>
  <el-radio-button value="week">周线</el-radio-button>
  <el-radio-button value="month">月线</el-radio-button>
  <el-radio-button value="quarter">季线</el-radio-button>
  <el-radio-button value="year">年线</el-radio-button>
</el-radio-group>
```

#### 数据量限制配置
```javascript
const freqLimitMap = {
  '1min': 120,    // 2小时
  '5min': 120,    // 10小时
  '15min': 120,   // 30小时
  '30min': 120,   // 60小时
  '60min': 120,   // 120小时
  'day': 500,     // 约2年
  'week': 260,    // 约5年
  'month': 120,   // 约10年
  'quarter': 60,  // 约15年
  'year': 30      // 约30年
}
```

#### 横坐标格式化配置
```javascript
case 'quarter':
  return {
    axisLabel: {
      color: '#666',
      formatter: (value) => {
        const date = new Date(value)
        const year = date.getFullYear()
        const month = date.getMonth() + 1
        const quarter = Math.ceil(month / 3)
        return `${year}Q${quarter}`
      },
      interval: calculateInterval(1)
    }
  }
```

### 3.3 数据处理注意事项
1. **图表数据**：需要时间正序（从旧到新），用于K线图展示
2. **表格数据**：需要时间倒序（从新到旧），用于数据列表展示
3. **日期格式**：分钟K线需要显示时间，日K线及以上只显示日期

---

## 四、后端实现要点

### 4.1 文件位置
- **API路由**：`backend/app/api/stock.py`
- **缓存服务**：`backend/app/services/cache_service.py`
- **TDX服务**：`backend/app/services/tdx_service.py`
- **数据模型**：`backend/app/models/stock.py`

### 4.2 关键配置

#### 频率映射配置（cache_service.py）
```python
freq_map = {
    '1min': 8,     # 1分钟K线
    '5min': 0,     # 5分钟K线
    '15min': 1,    # 15分钟K线
    '30min': 2,    # 30分钟K线
    '60min': 3,    # 60分钟K线
    'day': 9,      # 日K线
    'week': 5,     # 周K线
    'month': 6,    # 月K线
    'quarter': 10, # 季K线
    'year': 11     # 年K线
}
```

#### 数据量配置（cache_service.py）
```python
freq_offset_map = {
    '1min': 120,   # 2小时
    '5min': 120,   # 10小时
    '15min': 120,  # 30小时
    '30min': 120,  # 60小时
    '60min': 120,  # 120小时
    'day': 500,    # 约2年
    'week': 260,   # 约5年
    'month': 120,  # 约10年
    'quarter': 60, # 约15年
    'year': 30     # 约30年
}
```

### 4.3 数据格式统一处理

从TDX接口获取数据后，必须统一处理为以下格式：
```python
{
    "code": str,           # 股票代码
    "market": str,         # 市场(SH/SZ)
    "freq": str,           # 频率
    "trade_date": str,     # 交易日期(YYYY-MM-DD)
    "trade_time": str,     # 交易时间(YYYY-MM-DD HH:MM)，分钟K线才有
    "open": float,         # 开盘价
    "high": float,         # 最高价
    "low": float,          # 最低价
    "close": float,        # 收盘价
    "volume": int,         # 成交量
    "amount": float        # 成交额
}
```

### 4.4 排序要求
- **数据库查询**：使用 `.order_by(StockKline.trade_date.desc())` 按时间倒序
- **接口返回**：使用 `result_df.sort_values('trade_date', ascending=False)` 按时间倒序

---

## 五、数据库模型要求

### StockKline 表结构
```python
class StockKline(Base):
    __tablename__ = "stock_kline"
    
    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(10), nullable=False, index=True)  # 股票代码
    market = Column(String(10), nullable=False, index=True) # 市场(SH/SZ)
    freq = Column(String(10), nullable=False, index=True)   # 频率
    trade_date = Column(Date, nullable=False, index=True)   # 交易日期
    trade_time = Column(DateTime, nullable=True)            # 交易时间(分钟K线)
    open = Column(Float, nullable=False)                    # 开盘价
    high = Column(Float, nullable=False)                    # 最高价
    low = Column(Float, nullable=False)                     # 最低价
    close = Column(Float, nullable=False)                   # 收盘价
    volume = Column(BigInteger, nullable=False)             # 成交量
    amount = Column(Float, nullable=False)                  # 成交额
    created_at = Column(DateTime, default=datetime.now)     # 创建时间
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)  # 更新时间
```

### 索引要求
- `code` + `market` + `freq` + `trade_date`：联合唯一索引
- `code` + `market` + `freq`：联合索引（用于查询）

---

## 六、API接口规范

### 获取K线数据
```
GET /api/stocks/kline/{market}/{code}
```

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| market | string | 是 | 市场代码(SH/SZ) |
| code | string | 是 | 股票代码 |
| freq | string | 否 | 周期，默认day |
| start | string | 否 | 开始日期(YYYYMMDD) |
| end | string | 否 | 结束日期(YYYYMMDD) |
| limit | int | 否 | 数量限制，默认500 |
| force_refresh | bool | 否 | 强制刷新，默认false |

**freq可选值**：`1min`, `5min`, `15min`, `30min`, `60min`, `day`, `week`, `month`, `quarter`, `year`

**响应格式**：
```json
{
  "code": "000001",
  "market": "SZ",
  "freq": "day",
  "data": [
    {
      "trade_date": "2024-01-01",
      "trade_time": null,
      "open": 10.0,
      "high": 11.0,
      "low": 9.5,
      "close": 10.5,
      "volume": 1000000,
      "amount": 10500000.0
    }
  ]
}
```

---

## 七、开发注意事项

### 7.1 前端注意事项
1. **图表数据排序**：图表需要正序数据（从旧到新），表格需要倒序数据（从新到旧）
2. **时间显示**：分钟K线需要显示时间，其他频率只显示日期
3. **数据格式化**：价格保留2位小数，成交量使用万/亿单位转换
4. **缓存处理**：前端不需要额外缓存，后端已处理缓存逻辑

### 7.2 后端注意事项
1. **数据格式统一**：无论从接口还是数据库获取，返回格式必须一致
2. **排序一致**：接口和数据库查询都必须按时间倒序排序
3. **日期解析**：TDX返回的日期格式可能不同，需要兼容处理
4. **异常处理**：TDX接口可能返回空数据，需要做好空值判断
5. **缓存更新**：保存到数据库后必须更新缓存记录

### 7.3 常见问题排查

| 问题 | 排查方向 |
|-----|---------|
| 数据无日期 | 检查数据格式处理逻辑，确保trade_date字段正确生成 |
| 数据顺序不对 | 检查排序逻辑，确保接口和数据库都按时间倒序 |
| 分钟K线数据异常 | 检查freq_map映射是否正确 |
| 季K线/年K线无数据 | 检查freq_map是否包含quarter/year配置 |
| 缓存不更新 | 检查force_refresh参数和缓存过期时间 |

---

## 八、复现检查清单

### 前端检查项
- [ ] Kline.vue 包含所有10个频率按钮（1min到year）
- [ ] freqLimitMap 配置所有频率的数据量限制
- [ ] xAxisConfig 包含所有频率的横坐标格式化
- [ ] 图表数据和表格数据分别处理排序（正序/倒序）
- [ ] 分钟K线显示时间，其他频率只显示日期

### 后端检查项
- [ ] cache_service.py 的 freq_map 包含所有10个频率的正确映射
- [ ] cache_service.py 的 freq_offset_map 包含所有频率的数据量配置
- [ ] 从TDX接口获取数据后统一处理数据格式（包含trade_date字段）
- [ ] 从TDX接口获取数据后按时间倒序排序
- [ ] 从数据库查询按时间倒序排序
- [ ] API文档包含所有频率参数说明
- [ ] 数据库模型包含StockKline表的所有必需字段

### 测试检查项
- [ ] 每个频率都能正常获取数据
- [ ] 第一次查询和第二次查询数据格式一致
- [ ] 第一次查询和第二次查询数据顺序一致
- [ ] 分钟K线正确显示时间
- [ ] 日K线及以上正确显示日期
- [ ] 季K线显示格式为"2024Q1"
- [ ] 图表和表格数据显示正确
