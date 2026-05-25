#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试pytdx的F10公司信息功能
"""

from pytdx.hq import TdxHq_API

# 创建API实例
api = TdxHq_API()

# 连接到服务器
print("Connecting to TDX server...")
try:
    with api.connect('115.238.90.165', 7709):
        print("Connected!")
        
        # 获取公司信息分类
        print("\nGetting company info category for 000001...")
        categories = api.get_company_info_category(0, '000001')  # 0=深圳
        print(f"Got {len(categories)} categories")
        
        if categories:
            print("\nAll categories:")
            for i, cat in enumerate(categories):
                print(f"  {i}: {cat['name']} - {cat['filename']} (start={cat['start']}, length={cat['length']})")
            
            # 尝试获取每个分类的内容
            for i, cat in enumerate(categories[:5]):
                print(f"\n{'='*60}")
                print(f"Getting content for: {cat['name']}")
                print(f"filename={cat['filename']}, start={cat['start']}, length={cat['length']}")
                content = api.get_company_info_content(0, '000001', cat['filename'], cat['start'], cat['length'])
                print(f"Content length: {len(content) if content else 0}")
                if content and len(content) > 0:
                    print(f"First 200 chars: {content[:200]}")
                    break  # 找到有内容的就停止
        
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
