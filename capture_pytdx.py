#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
使用pytdx获取K线数据并分析数据包格式
"""

from pytdx.hq import TdxHq_API

# 创建API实例
api = TdxHq_API()

# 连接到服务器
print("Connecting to TDX server...")
with api.connect('115.238.90.165', 7709):
    print("Connected!")
    
    # 获取K线数据
    print("\nGetting K-line data...")
    # get_security_bars(category, market, code, start, count)
    # category: 9=日线, 8=1分钟, 7=5分钟, 6=15分钟, 5=30分钟, 4=60分钟
    # market: 0=深圳, 1=上海
    bars = api.get_security_bars(9, 0, '000001', 0, 10)
    print(f"Got {len(bars)} bars")
    
    if bars:
        print("\nFirst bar:")
        print(bars[0])
        print("\nLast bar:")
        print(bars[-1])
