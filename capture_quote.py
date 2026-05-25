#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
捕获pytdx get_security_quotes请求的数据包
"""

from pytdx.hq import TdxHq_API
import struct

# 创建API实例
api = TdxHq_API(multithread=False, heartbeat=False)

# 连接到服务器
print("Connecting to TDX server 180.153.18.170:7709...")
with api.connect('180.153.18.170', 7709):
    print("Connected!")
    
    # 获取实时行情
    print("\nGetting real-time quotes for 600036...")
    
    # 手动构建请求来查看数据包
    from pytdx.parser.get_security_quotes import GetSecurityQuotesCmd
    
    cmd = GetSecurityQuotesCmd(api.client, lock=api.lock)
    cmd.setParams([(1, '600036')])  # 上海市场，600036
    
    print(f"\nRequest packet ({len(cmd.send_pkg)} bytes):")
    print("Hex:", ' '.join(f'{b:02X}' for b in cmd.send_pkg))
    
    # 解析头部 - 使用22字节，因为Python的struct.calcsize('<HIHHIIHH') = 22
    header_len = struct.calcsize('<HIHHIIHH')
    header = cmd.send_pkg[:header_len]
    values = struct.unpack("<HIHHIIHH", header)
    print(f"\nHeader fields ({header_len} bytes):")
    print(f"  [0-1]   0x{values[0]:04X} (should be 0x010C)")
    print(f"  [2-5]   0x{values[1]:08X} (should be 0x02006320)")
    print(f"  [6-7]   {values[2]} (pkgdatalen)")
    print(f"  [8-9]   {values[3]} (pkgdatalen)")
    print(f"  [10-13] 0x{values[4]:05X} (cmd)")
    print(f"  [14-15] {values[5]} (reserved)")
    print(f"  [16-17] {values[6]} (reserved)")
    print(f"  [18-21] {values[7]} (stock_count - at offset 20-21 due to padding)")
    
    # 股票数据
    stock_data = cmd.send_pkg[header_len:]
    print(f"\nStock data ({len(stock_data)} bytes):")
    print("Hex:", ' '.join(f'{b:02X}' for b in stock_data))
    if len(stock_data) >= 7:
        market = stock_data[0]
        code = stock_data[1:7].decode('ascii', errors='ignore').strip('\x00')
        print(f"  Market: {market}")
        print(f"  Code: {code}")
    
    # 实际发送请求
    print("\nSending request...")
    result = api.get_security_quotes([(1, '600036')])
    print(f"Got {len(result)} quotes")
    if result:
        print(f"First quote: {result[0]}")
