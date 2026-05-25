#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
捕获pytdx get_security_bars请求的数据包
"""

from pytdx.hq import TdxHq_API
import struct

# 创建API实例
api = TdxHq_API(multithread=False, heartbeat=False)

# 连接到服务器
print("Connecting to TDX server 180.153.18.170:7709...")
with api.connect('180.153.18.170', 7709):
    print("Connected!")
    
    # 手动构建请求来查看数据包
    from pytdx.parser.get_security_bars import GetSecurityBarsCmd
    
    # 第一次请求
    print("\n=== 第一次请求 ===")
    cmd1 = GetSecurityBarsCmd(api.client, lock=api.lock)
    cmd1.setParams(9, 1, '600036', 0, 10)  # category=9(日线), market=1, code=600036, start=0, count=10
    
    print(f"Request packet 1 ({len(cmd1.send_pkg)} bytes):")
    print("Hex:", ' '.join(f'{b:02X}' for b in cmd1.send_pkg))
    
    # 解析头部
    header_fmt = "<HIHHHH6sHHHHIIH"
    header_len = struct.calcsize(header_fmt)
    print(f"Header length: {header_len} bytes")
    
    values = struct.unpack(header_fmt, cmd1.send_pkg[:header_len])
    print(f"\nHeader fields:")
    print(f"  [0-1]   0x{values[0]:04X}")
    print(f"  [2-5]   0x{values[1]:08X}")
    print(f"  [6-7]   {values[2]}")
    print(f"  [8-9]   {values[3]}")
    print(f"  [10-11] 0x{values[4]:04X} (cmd)")
    print(f"  [12-13] {values[5]} (market)")
    print(f"  [14-19] {values[6]} (code)")
    print(f"  [20-21] {values[7]} (category)")
    print(f"  [22-23] {values[8]}")
    print(f"  [24-25] {values[9]} (start)")
    print(f"  [26-27] {values[10]} (count)")
    
    # 发送第一次请求
    print("\nSending first request...")
    result1 = api.get_security_bars(9, 1, '600036', 0, 10)
    print(f"Got {len(result1)} bars")
    
    # 第二次请求
    print("\n=== 第二次请求 ===")
    cmd2 = GetSecurityBarsCmd(api.client, lock=api.lock)
    cmd2.setParams(9, 1, '600036', 0, 5)
    
    print(f"Request packet 2 ({len(cmd2.send_pkg)} bytes):")
    print("Hex:", ' '.join(f'{b:02X}' for b in cmd2.send_pkg))
    
    values2 = struct.unpack(header_fmt, cmd2.send_pkg[:header_len])
    print(f"\nHeader fields:")
    print(f"  [0-1]   0x{values2[0]:04X}")
    print(f"  [2-5]   0x{values2[1]:08X}")
    print(f"  [6-7]   {values2[2]}")
    print(f"  [8-9]   {values2[3]}")
    print(f"  [10-11] 0x{values2[4]:04X} (cmd)")
    print(f"  [12-13] {values2[5]} (market)")
    print(f"  [14-19] {values2[6]} (code)")
    
    # 发送第二次请求
    print("\nSending second request...")
    result2 = api.get_security_bars(9, 1, '600036', 0, 5)
    print(f"Got {len(result2)} bars")
    
    print("\n=== 两次请求都成功 ===")
