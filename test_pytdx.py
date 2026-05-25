#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
使用pytdx库测试连接并捕获数据包
"""

try:
    from pytdx.hq import TdxHq_API
    print("pytdx imported successfully")
except ImportError:
    print("pytdx not installed, installing...")
    import subprocess
    subprocess.check_call(['pip', 'install', 'pytdx'])
    from pytdx.hq import TdxHq_API

# 创建API实例
api = TdxHq_API()

# 连接到服务器
print("\nConnecting to TDX server...")
try:
    with api.connect('115.238.90.165', 7709):
        print("Connected!")

        # 获取股票列表
        print("\nGetting stock list...")
        stocks = api.get_security_list(0, 0)  # 上海市场，从0开始
        print(f"Got {len(stocks)} stocks")

        if stocks:
            print(f"First stock: {stocks[0]}")

        # 获取实时行情
        print("\nGetting real-time quotes...")
        quotes = api.get_security_quotes([(0, '000001'), (1, '600000')])
        print(f"Got {len(quotes)} quotes")

        if quotes:
            print(f"First quote: {quotes[0]}")

except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
