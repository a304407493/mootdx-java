#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
捕获通达信协议数据包
用于分析pytdx发送的实际数据包格式
"""

import socket
import struct
import time

# TDX服务器
SERVER = "115.238.90.165"
PORT = 7709

def capture_connection():
    """捕获连接过程中的数据包"""
    print("=== TDX Protocol Capture ===")
    
    # 创建socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(10)
    
    try:
        # 连接服务器
        print(f"\nConnecting to {SERVER}:{PORT}...")
        sock.connect((SERVER, PORT))
        print("Connected!")
        
        # 等待一下
        time.sleep(0.5)
        
        # 尝试发送不同的数据包格式
        
        # 格式1: 尝试简单的连接请求
        print("\n--- Test 1: Simple connection request ---")
        # 尝试发送一个空包或简单的心跳
        packet1 = bytes([0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                         0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        print(f"Sending: {packet1.hex()}")
        sock.send(packet1)
        
        # 尝试接收响应
        try:
            response = sock.recv(1024)
            print(f"Response: {response.hex()}")
        except socket.timeout:
            print("No response (timeout)")
        
        # 检查连接状态
        print(f"Socket still connected")
        
        # 格式2: 尝试带命令的数据包
        print("\n--- Test 2: Command packet ---")
        # 构建一个简单的命令包
        # 长度(2) + 校验和(1) + 头(1) + 命令(2) + 数据(10)
        cmd = 0x0451  # GET_STOCK_LIST
        packet2 = struct.pack('<H', 16)  # 长度
        packet2 += bytes([0])  # 校验和占位
        packet2 += bytes([0x01])  # 头
        packet2 += struct.pack('<H', cmd)  # 命令
        packet2 += bytes(10)  # 填充
        
        # 计算校验和 (XOR)
        checksum = 0
        for b in packet2[3:]:
            checksum ^= b
        packet2 = packet2[:2] + bytes([checksum]) + packet2[3:]
        
        print(f"Sending: {packet2.hex()}")
        sock.send(packet2)
        
        try:
            response = sock.recv(1024)
            print(f"Response: {response.hex()}")
        except socket.timeout:
            print("No response (timeout)")
        
        print(f"Socket still connected")
        
        # 格式3: 尝试不同的头值
        for header in [0x00, 0x01, 0x02]:
            print(f"\n--- Test 3: Header 0x{header:02X} ---")
            packet3 = struct.pack('<H', 16)
            packet3 += bytes([0])
            packet3 += bytes([header])
            packet3 += struct.pack('<H', cmd)
            packet3 += bytes(10)
            
            checksum = 0
            for b in packet3[3:]:
                checksum ^= b
            packet3 = packet3[:2] + bytes([checksum]) + packet3[3:]
            
            print(f"Sending: {packet3.hex()}")
            sock.send(packet3)
            
            try:
                response = sock.recv(1024)
                print(f"Response: {response.hex()}")
            except socket.timeout:
                print("No response (timeout)")
            
            print(f"Socket still connected")
            time.sleep(0.5)
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        sock.close()
        print("\nConnection closed")

if __name__ == "__main__":
    capture_connection()
