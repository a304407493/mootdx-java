#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试pytdx的F10公司信息功能 - 调试版本
"""

import struct

# 模拟pytdx的请求包构建
market = 0
code = b'000001'

pkg = bytearray.fromhex(u'0c 0f 10 9b 00 01 0e 00 0e 00 cf 02')
print(f"Header: {pkg.hex()}")
print(f"Header length: {len(pkg)}")

params = struct.pack(u"<H6sI", market, code, 0)
print(f"Params: {params.hex()}")
print(f"Params length: {len(params)}")

pkg.extend(params)
print(f"Full package: {pkg.hex()}")
print(f"Full package length: {len(pkg)}")

# 解析头部
print("\n=== Header Analysis ===")
print(f"Byte 0-1: {pkg[0]:02x} {pkg[1]:02x} = {pkg[0] + pkg[1]*256} (little endian)")
print(f"Byte 2: {pkg[2]:02x}")
print(f"Byte 3: {pkg[3]:02x}")
print(f"Byte 4-5: {pkg[4]:02x} {pkg[5]:02x}")
print(f"Byte 6-7: {pkg[6]:02x} {pkg[7]:02x}")
print(f"Byte 8-9: {pkg[8]:02x} {pkg[9]:02x}")
print(f"Byte 10-11: {pkg[10]:02x} {pkg[11]:02x} = {pkg[10] + pkg[11]*256} (little endian)")

# 解析参数
print("\n=== Params Analysis ===")
params_start = 12
market_val = pkg[params_start] + pkg[params_start+1]*256
print(f"Market: {market_val}")
print(f"Code: {pkg[params_start+2:params_start+8]}")
zero_val = pkg[params_start+8] + pkg[params_start+9]*256 + pkg[params_start+10]*65536 + pkg[params_start+11]*16777216
print(f"Zero: {zero_val}")
