# TDX服务器管理功能实现总结

## 功能概述

实现TDX行情服务器的管理和监控功能，包括：
1. 服务器配置管理（增删改查）
2. 服务器节点状态监控
3. 自动选择最佳服务器
4. 一键切换系统使用的服务器
5. 持久化默认服务器配置（重启后仍然有效）

---

## 一、后端实现

### 1. 数据模型 (backend/app/models/tdx_server.py)

```python
"""
TDX行情服务器管理模型
"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey, Enum, Text
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from ..db.database import Base


class ServerType(str, enum.Enum):
    """服务器类型"""
    STD = "std"      # 标准行情
    EXT = "ext"      # 扩展行情


class ServerStatus(str, enum.Enum):
    """服务器状态"""
    ONLINE = "online"      # 在线
    OFFLINE = "offline"    # 离线
    UNSTABLE = "unstable"  # 不稳定
    MAINTENANCE = "maintenance"  # 维护中
    UNKNOWN = "unknown"    # 未知


class TdxServerConfig(Base):
    """TDX服务器配置表"""
    __tablename__ = "tdx_server_configs"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False, comment="服务器名称")
    host = Column(String(50), nullable=False, comment="服务器IP地址")
    port = Column(Integer, default=7709, nullable=False, comment="服务器端口")
    server_type = Column(Enum(ServerType), default=ServerType.STD, comment="服务器类型")
    location = Column(String(50), comment="服务器位置")
    weight = Column(Integer, default=100, comment="权重，用于负载均衡")
    timeout = Column(Integer, default=10, comment="连接超时时间(秒)")
    max_retries = Column(Integer, default=3, comment="最大重试次数")
    description = Column(Text, comment="服务器描述")
    is_enabled = Column(Boolean, default=True, comment="是否启用")
    is_default = Column(Boolean, default=False, comment="是否为默认服务器")
    created_at = Column(DateTime, default=datetime.now, comment="创建时间")
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now, comment="更新时间")

    # 关联节点状态
    node = relationship("TdxServerNode", back_populates="server", uselist=False)
    logs = relationship("TdxServerLog", back_populates="server")


class TdxServerNode(Base):
    """TDX服务器节点状态表"""
    __tablename__ = "tdx_server_nodes"

    id = Column(Integer, primary_key=True, index=True)
    server_id = Column(Integer, ForeignKey("tdx_server_configs.id"), unique=True, nullable=False)
    status = Column(Enum(ServerStatus), default=ServerStatus.UNKNOWN, comment="节点状态")
    response_time = Column(Float, comment="响应时间(ms)")
    success_rate = Column(Float, default=0.0, comment="成功率(0-1)")
    last_check = Column(DateTime, comment="最后检查时间")
    fail_count = Column(Integer, default=0, comment="连续失败次数")
    total_requests = Column(Integer, default=0, comment="总请求数")
    success_requests = Column(Integer, default=0, comment="成功请求数")
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now, comment="更新时间")

    # 关联服务器配置
    server = relationship("TdxServerConfig", back_populates="node")


class TdxServerLog(Base):
    """TDX服务器操作日志表"""
    __tablename__ = "tdx_server_logs"

    id = Column(Integer, primary_key=True, index=True)
    server_id = Column(Integer, ForeignKey("tdx_server_configs.id"), nullable=False)
    action = Column(String(50), nullable=False, comment="操作类型")
    message = Column(Text, comment="日志消息")
    old_value = Column(Text, comment="旧值")
    new_value = Column(Text, comment="新值")
    created_at = Column(DateTime, default=datetime.now, comment="创建时间")

    # 关联服务器配置
    server = relationship("TdxServerConfig", back_populates="logs")
```

### 2. 服务层 (backend/app/services/tdx_server_service.py)

```python
"""
TDX行情服务器管理服务
功能：管理TDX行情服务器配置、监控节点状态、自动切换服务器
"""
import time
import json
import socket
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import desc, func

from ..models.tdx_server import (
    TdxServerConfig, TdxServerNode, TdxServerLog,
    ServerType, ServerStatus
)
from ..core.logger import setup_logging

logger = setup_logging()


class TdxServerService:
    """TDX服务器管理服务类"""

    # 默认TDX服务器列表
    DEFAULT_SERVERS = [
        {"name": "电信主站1", "host": "119.147.212.81", "port": 7709, "location": "电信", "weight": 100},
        {"name": "电信主站2", "host": "180.153.18.170", "port": 7709, "location": "电信", "weight": 100},
        {"name": "电信主站3", "host": "180.153.18.171", "port": 7709, "location": "电信", "weight": 100},
        {"name": "联通主站1", "host": "202.108.253.130", "port": 7709, "location": "联通", "weight": 100},
        {"name": "联通主站2", "host": "202.108.253.131", "port": 7709, "location": "联通", "weight": 100},
        {"name": "北京电信1", "host": "61.135.142.80", "port": 7709, "location": "北京电信", "weight": 100},
        {"name": "北京电信2", "host": "61.135.142.81", "port": 7709, "location": "北京电信", "weight": 100},
        {"name": "上海电信1", "host": "116.236.187.150", "port": 7709, "location": "上海电信", "weight": 100},
        {"name": "上海电信2", "host": "116.236.187.151", "port": 7709, "location": "上海电信", "weight": 100},
        {"name": "深圳电信1", "host": "119.147.212.81", "port": 7709, "location": "深圳电信", "weight": 100},
        {"name": "广州电信1", "host": "14.215.128.18", "port": 7709, "location": "广州电信", "weight": 100},
        {"name": "杭州电信1", "host": "115.239.212.48", "port": 7709, "location": "杭州电信", "weight": 100},
    ]

    def __init__(self, db: Session):
        """
        初始化服务

        Args:
            db: 数据库会话
        """
        self.db = db
        logger.info("[方法入口] TdxServerService.__init__ - 初始化TDX服务器管理服务")

    def init_default_servers(self) -> int:
        """
        初始化默认服务器配置

        Returns:
            int: 创建的服务器数量
        """
        logger.info("[方法入口] TdxServerService.init_default_servers - 初始化默认服务器")

        created_count = 0
        for server_data in self.DEFAULT_SERVERS:
            # 检查是否已存在
            existing = self.db.query(TdxServerConfig).filter(
                TdxServerConfig.host == server_data["host"],
                TdxServerConfig.port == server_data["port"]
            ).first()

            if not existing:
                server = TdxServerConfig(**server_data)
                self.db.add(server)
                created_count += 1
                logger.info(f"[方法内日志] 创建服务器: {server.name} ({server.host}:{server.port})")

        self.db.commit()
        logger.info(f"[方法出口] 成功创建 {created_count} 个默认服务器")
        return created_count

    def get_servers(self, enabled_only: bool = False) -> List[TdxServerConfig]:
        """
        获取服务器列表

        Args:
            enabled_only: 是否只返回启用的服务器

        Returns:
            List[TdxServerConfig]: 服务器配置列表
        """
        logger.info(f"[方法入口] TdxServerService.get_servers - 获取服务器列表, enabled_only={enabled_only}")

        query = self.db.query(TdxServerConfig)
        if enabled_only:
            query = query.filter(TdxServerConfig.is_enabled == True)

        servers = query.order_by(desc(TdxServerConfig.is_default), TdxServerConfig.id).all()
        logger.info(f"[方法出口] 返回 {len(servers)} 个服务器")
        return servers

    def get_server_with_node(self, server_id: int) -> Optional[Dict[str, Any]]:
        """
        获取服务器及其节点状态

        Args:
            server_id: 服务器ID

        Returns:
            Optional[Dict]: 服务器和节点信息
        """
        logger.info(f"[方法入口] TdxServerService.get_server_with_node - 获取服务器详情, server_id={server_id}")

        server = self.db.query(TdxServerConfig).filter(TdxServerConfig.id == server_id).first()
        if not server:
            logger.warning(f"[方法内日志] 服务器不存在: {server_id}")
            return None

        result = {
            "server": server,
            "node": server.node
        }
        logger.info(f"[方法出口] 返回服务器: {server.name}")
        return result

    def get_servers_with_nodes(self, enabled_only: bool = False) -> List[Dict[str, Any]]:
        """
        获取所有服务器及其节点状态

        Args:
            enabled_only: 是否只返回启用的服务器

        Returns:
            List[Dict]: 服务器和节点信息列表
        """
        logger.info(f"[方法入口] TdxServerService.get_servers_with_nodes - 获取服务器列表, enabled_only={enabled_only}")

        servers = self.get_servers(enabled_only)
        result = []
        for server in servers:
            result.append({
                "server": server,
                "node": server.node
            })

        logger.info(f"[方法出口] 返回 {len(result)} 个服务器")
        return result

    def create_server(self, data: Dict[str, Any]) -> TdxServerConfig:
        """
        创建服务器配置

        Args:
            data: 服务器数据

        Returns:
            TdxServerConfig: 创建的服务器配置
        """
        logger.info(f"[方法入口] TdxServerService.create_server - 创建服务器, name={data.get('name')}")

        server = TdxServerConfig(**data)
        self.db.add(server)
        self.db.commit()
        self.db.refresh(server)

        # 创建对应的节点记录
        node = TdxServerNode(server_id=server.id)
        self.db.add(node)
        self.db.commit()

        # 记录日志
        self._add_log(server.id, "create", f"创建服务器: {server.name}")

        logger.info(f"[方法出口] 服务器创建成功: {server.id}")
        return server

    def update_server(self, server_id: int, data: Dict[str, Any]) -> Optional[TdxServerConfig]:
        """
        更新服务器配置

        Args:
            server_id: 服务器ID
            data: 更新数据

        Returns:
            Optional[TdxServerConfig]: 更新后的服务器配置
        """
        logger.info(f"[方法入口] TdxServerService.update_server - 更新服务器, server_id={server_id}")

        server = self.db.query(TdxServerConfig).filter(TdxServerConfig.id == server_id).first()
        if not server:
            logger.warning(f"[方法内日志] 服务器不存在: {server_id}")
            return None

        # 记录旧值
        old_value = {
            "name": server.name,
            "host": server.host,
            "port": server.port,
            "is_enabled": server.is_enabled
        }

        # 更新字段
        for key, value in data.items():
            if hasattr(server, key):
                setattr(server, key, value)

        server.updated_at = datetime.now()
        self.db.commit()
        self.db.refresh(server)

        # 记录日志
        self._add_log(server.id, "update", f"更新服务器: {server.name}",
                     old_value=json.dumps(old_value), new_value=json.dumps(data))

        logger.info(f"[方法出口] 服务器更新成功: {server_id}")
        return server

    def delete_server(self, server_id: int) -> bool:
        """
        删除服务器配置

        Args:
            server_id: 服务器ID

        Returns:
            bool: 是否删除成功
        """
        logger.info(f"[方法入口] TdxServerService.delete_server - 删除服务器, server_id={server_id}")

        server = self.db.query(TdxServerConfig).filter(TdxServerConfig.id == server_id).first()
        if not server:
            logger.warning(f"[方法内日志] 服务器不存在: {server_id}")
            return False

        # 记录日志
        self._add_log(server.id, "delete", f"删除服务器: {server.name}")

        # 删除关联的节点和日志
        self.db.query(TdxServerNode).filter(TdxServerNode.server_id == server_id).delete()
        self.db.query(TdxServerLog).filter(TdxServerLog.server_id == server_id).delete()

        # 删除服务器
        self.db.delete(server)
        self.db.commit()

        logger.info(f"[方法出口] 服务器删除成功: {server_id}")
        return True

    def set_default_server(self, server_id: int) -> bool:
        """
        设置默认服务器

        Args:
            server_id: 服务器ID

        Returns:
            bool: 是否设置成功
        """
        logger.info(f"[方法入口] TdxServerService.set_default_server - 设置默认服务器, server_id={server_id}")

        # 先将所有服务器设为非默认
        self.db.query(TdxServerConfig).update({TdxServerConfig.is_default: False})

        # 设置指定服务器为默认
        server = self.db.query(TdxServerConfig).filter(TdxServerConfig.id == server_id).first()
        if not server:
            logger.warning(f"[方法内日志] 服务器不存在: {server_id}")
            return False

        server.is_default = True
        server.updated_at = datetime.now()
        self.db.commit()

        # 记录日志
        self._add_log(server.id, "set_default", f"设置默认服务器: {server.name}")

        logger.info(f"[方法出口] 默认服务器设置成功: {server.name}")
        return True

    def check_server_status(self, server_id: int) -> Optional[TdxServerNode]:
        """
        检查服务器状态

        Args:
            server_id: 服务器ID

        Returns:
            Optional[TdxServerNode]: 节点状态
        """
        logger.info(f"[方法入口] TdxServerService.check_server_status - 检查服务器状态, server_id={server_id}")

        server = self.db.query(TdxServerConfig).filter(TdxServerConfig.id == server_id).first()
        if not server:
            logger.warning(f"[方法内日志] 服务器不存在: {server_id}")
            return None

        # 获取或创建节点记录
        node = server.node
        if not node:
            node = TdxServerNode(server_id=server.id)
            self.db.add(node)

        # 测试连接
        start_time = time.time()
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(server.timeout or 10)
            result = sock.connect_ex((server.host, server.port))
            response_time = (time.time() - start_time) * 1000  # 转换为毫秒
            sock.close()

            if result == 0:
                # 连接成功
                node.status = ServerStatus.ONLINE
                node.response_time = response_time
                node.fail_count = 0
                node.success_requests += 1
                logger.info(f"[方法内日志] 服务器在线: {server.name}, 响应时间: {response_time:.2f}ms")
            else:
                # 连接失败
                node.status = ServerStatus.OFFLINE
                node.fail_count += 1
                logger.warning(f"[方法内日志] 服务器离线: {server.name}")

        except Exception as e:
            node.status = ServerStatus.OFFLINE
            node.fail_count += 1
            logger.error(f"[方法内日志] 检查服务器异常: {server.name}, 错误: {e}")

        node.total_requests += 1
        node.last_check = datetime.now()

        # 计算成功率
        if node.total_requests > 0:
            node.success_rate = node.success_requests / node.total_requests

        # 检查是否不稳定（连续失败3次以上）
        if node.fail_count >= 3:
            node.status = ServerStatus.UNSTABLE
            logger.warning(f"[方法内日志] 服务器不稳定: {server.name}, 连续失败{node.fail_count}次")

        self.db.commit()
        self.db.refresh(node)

        logger.info(f"[方法出口] 服务器状态检查完成: {server.name}, 状态: {node.status.value}")
        return node

    def check_all_servers(self) -> List[Dict[str, Any]]:
        """
        检查所有服务器状态

        Returns:
            List[Dict]: 所有服务器的状态
        """
        logger.info("[方法入口] TdxServerService.check_all_servers - 检查所有服务器状态")

        servers = self.get_servers(enabled_only=True)
        results = []

        for server in servers:
            node = self.check_server_status(server.id)
            results.append({
                "server": server,
                "node": node
            })

        logger.info(f"[方法出口] 完成 {len(results)} 个服务器的状态检查")
        return results

    def get_best_server(self) -> Optional[TdxServerConfig]:
        """
        获取最佳服务器（在线、响应快、成功率高）

        Returns:
            Optional[TdxServerConfig]: 最佳服务器配置
        """
        logger.info("[方法入口] TdxServerService.get_best_server - 获取最佳服务器")

        # 获取在线节点
        online_nodes = self.db.query(TdxServerNode).filter(
            TdxServerNode.status == ServerStatus.ONLINE
        ).all()

        # 过滤掉禁用服务器的节点
        enabled_server_ids = [
            s.id for s in self.db.query(TdxServerConfig).filter(
                TdxServerConfig.is_enabled == True
            ).all()
        ]
        online_nodes = [n for n in online_nodes if n.server_id in enabled_server_ids]

        if not online_nodes:
            logger.warning("[方法内日志] 没有在线的服务器")
            return None

        # 按响应时间和成功率排序
        best_node = min(online_nodes, key=lambda n: (
            n.response_time if n.response_time else 999999,
            -n.success_rate if n.success_rate else 0
        ))

        best_server = self.db.query(TdxServerConfig).filter(
            TdxServerConfig.id == best_node.server_id
        ).first()

        if best_server:
            logger.info(f"[方法出口] 最佳服务器: {best_server.name}, 响应时间: {best_node.response_time:.2f}ms")
        else:
            logger.warning("[方法出口] 未找到最佳服务器")

        return best_server

    def get_statistics(self) -> Dict[str, Any]:
        """
        获取服务器统计信息

        Returns:
            Dict: 统计信息
        """
        logger.info("[方法入口] TdxServerService.get_statistics - 获取统计信息")

        total = self.db.query(TdxServerConfig).count()
        enabled = self.db.query(TdxServerConfig).filter(TdxServerConfig.is_enabled == True).count()

        online = self.db.query(TdxServerNode).filter(TdxServerNode.status == ServerStatus.ONLINE).count()
        offline = self.db.query(TdxServerNode).filter(TdxServerNode.status == ServerStatus.OFFLINE).count()
        unstable = self.db.query(TdxServerNode).filter(TdxServerNode.status == ServerStatus.UNSTABLE).count()

        # 计算平均响应时间和成功率
        avg_response = self.db.query(func.avg(TdxServerNode.response_time)).filter(
            TdxServerNode.response_time != None
        ).scalar()

        avg_success_rate = self.db.query(func.avg(TdxServerNode.success_rate)).filter(
            TdxServerNode.success_rate != None
        ).scalar()

        result = {
            "total_servers": total,
            "enabled_servers": enabled,
            "online_nodes": online,
            "offline_nodes": offline,
            "unstable_nodes": unstable,
            "avg_response_time": round(avg_response, 2) if avg_response else 0,
            "avg_success_rate": round(avg_success_rate * 100, 2) if avg_success_rate else 0
        }

        logger.info(f"[方法出口] 统计信息: 总计{total}, 在线{online}, 离线{offline}")
        return result

    def get_logs(self, server_id: int = None, action: str = None, limit: int = 100) -> List[TdxServerLog]:
        """
        获取操作日志

        Args:
            server_id: 服务器ID筛选
            action: 操作类型筛选
            limit: 返回数量限制

        Returns:
            List[TdxServerLog]: 日志列表
        """
        logger.info(f"[方法入口] TdxServerService.get_logs - 获取日志, server_id={server_id}, action={action}")

        query = self.db.query(TdxServerLog)

        if server_id:
            query = query.filter(TdxServerLog.server_id == server_id)
        if action:
            query = query.filter(TdxServerLog.action == action)

        logs = query.order_by(desc(TdxServerLog.created_at)).limit(limit).all()

        logger.info(f"[方法出口] 返回 {len(logs)} 条日志")
        return logs

    def clear_old_logs(self, days: int = 30) -> int:
        """
        清理旧日志

        Args:
            days: 保留天数

        Returns:
            int: 删除的日志数量
        """
        logger.info(f"[方法入口] TdxServerService.clear_old_logs - 清理旧日志, days={days}")

        cutoff_date = datetime.now() - timedelta(days=days)
        deleted = self.db.query(TdxServerLog).filter(
            TdxServerLog.created_at < cutoff_date
        ).delete()

        self.db.commit()

        logger.info(f"[方法出口] 清理 {deleted} 条旧日志")
        return deleted

    def _add_log(self, server_id: int, action: str, message: str,
                 old_value: str = None, new_value: str = None):
        """
        添加操作日志

        Args:
            server_id: 服务器ID
            action: 操作类型
            message: 日志消息
            old_value: 旧值
            new_value: 新值
        """
        log = TdxServerLog(
            server_id=server_id,
            action=action,
            message=message,
            old_value=old_value,
            new_value=new_value
        )
        self.db.add(log)
        self.db.commit()
```

### 3. TDX服务扩展 (backend/app/services/tdx_service.py)

在文件末尾添加以下代码：

```python
# 全局实例 - 使用配置中的TDX服务器地址
tdx_service = TdxService.factory(
    bestip=False,
    timeout=10,
    server=(settings.TDX_HOST, settings.TDX_PORT)
)


def get_tdx_service_with_managed_server(db: Session = None):
    """
    获取使用管理系统中最佳服务器的TDX服务实例

    Args:
        db: 数据库会话，如果为None则创建新会话

    Returns:
        TdxService: 配置了最佳服务器的TDX服务实例
    """
    from ..db.database import SessionLocal

    if db is None:
        db = SessionLocal()
        close_db = True
    else:
        close_db = False

    try:
        from .tdx_server_service import TdxServerService

        server_service = TdxServerService(db)
        best_server = server_service.get_best_server()

        if best_server:
            logger.info(f"使用管理系统中的最佳服务器: {best_server.name} ({best_server.host}:{best_server.port})")
            return TdxService.factory(
                market='std',
                server=(best_server.host, best_server.port),
                bestip=False,
                timeout=best_server.timeout or 10
            )
        else:
            logger.warning("管理系统中没有可用的服务器，使用默认配置")
            return TdxService.factory(bestip=False, timeout=10)
    except Exception as e:
        logger.error(f"获取管理服务器失败: {e}，使用默认配置")
        return TdxService.factory(bestip=False, timeout=10)
    finally:
        if close_db:
            db.close()


def reconnect_with_managed_server(tdx_service_instance: TdxService, db: Session = None):
    """
    使用管理系统中的最佳服务器重新连接

    Args:
        tdx_service_instance: TDX服务实例
        db: 数据库会话

    Returns:
        bool: 是否重连成功
    """
    from ..db.database import SessionLocal

    if db is None:
        db = SessionLocal()
        close_db = True
    else:
        close_db = False

    try:
        from .tdx_server_service import TdxServerService

        server_service = TdxServerService(db)
        best_server = server_service.get_best_server()

        if best_server:
            logger.info(f"使用最佳服务器重连: {best_server.name} ({best_server.host}:{best_server.port})")
            tdx_service_instance.server = (best_server.host, best_server.port)
            tdx_service_instance.bestip = False
            tdx_service_instance.timeout = best_server.timeout or 10
            return tdx_service_instance.reconnect()
        else:
            logger.warning("没有可用的管理服务器，使用原有配置重连")
            return tdx_service_instance.reconnect()
    except Exception as e:
        logger.error(f"使用管理服务器重连失败: {e}")
        return tdx_service_instance.reconnect()
    finally:
        if close_db:
            db.close()
```

### 4. API路由 (backend/app/api/tdx_server.py)

```python
"""
TDX服务器管理API
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel, Field
from datetime import datetime

from ..services.tdx_server_service import TdxServerService
from ..models.tdx_server import TdxServerConfig, TdxServerNode, TdxServerLog, ServerType, ServerStatus
from ..db.database import get_db
from ..core.logger import setup_logging

logger = setup_logging()

router = APIRouter(prefix="/tdx-server", tags=["TDX服务器管理"])


# 依赖注入
def get_service(db: Session = Depends(get_db)):
    return TdxServerService(db)


# ============== Pydantic模型 ==============

class ServerConfigCreate(BaseModel):
    """创建服务器配置请求"""
    name: str = Field(..., min_length=1, max_length=100, description="服务器名称")
    host: str = Field(..., min_length=1, max_length=50, description="IP地址")
    port: int = Field(default=7709, ge=1, le=65535, description="端口")
    server_type: ServerType = Field(default=ServerType.STD, description="服务器类型")
    location: Optional[str] = Field(None, max_length=50, description="位置")
    weight: int = Field(default=100, ge=1, le=1000, description="权重")
    timeout: int = Field(default=10, ge=1, le=60, description="超时时间(秒)")
    max_retries: int = Field(default=3, ge=0, le=10, description="最大重试次数")
    description: Optional[str] = Field(None, description="描述")
    is_enabled: bool = Field(default=True, description="是否启用")


class ServerConfigUpdate(BaseModel):
    """更新服务器配置请求"""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    host: Optional[str] = Field(None, min_length=1, max_length=50)
    port: Optional[int] = Field(None, ge=1, le=65535)
    server_type: Optional[ServerType] = None
    location: Optional[str] = Field(None, max_length=50)
    weight: Optional[int] = Field(None, ge=1, le=1000)
    timeout: Optional[int] = Field(None, ge=1, le=60)
    max_retries: Optional[int] = Field(None, ge=0, le=10)
    description: Optional[str] = None
    is_enabled: Optional[bool] = None


class ServerConfigResponse(BaseModel):
    """服务器配置响应"""
    id: int
    name: str
    host: str
    port: int
    server_type: ServerType
    location: Optional[str]
    weight: int
    timeout: int
    max_retries: int
    description: Optional[str]
    is_enabled: bool
    is_default: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ServerNodeResponse(BaseModel):
    """服务器节点状态响应"""
    id: int
    server_id: int
    status: ServerStatus
    response_time: Optional[float]
    success_rate: float
    last_check: Optional[datetime]
    fail_count: int
    total_requests: int
    success_requests: int
    updated_at: datetime

    class Config:
        from_attributes = True


class ServerWithNodeResponse(BaseModel):
    """服务器及其节点状态响应"""
    server: ServerConfigResponse
    node: Optional[ServerNodeResponse]


class StatisticsResponse(BaseModel):
    """统计信息响应"""
    total_servers: int
    enabled_servers: int
    online_nodes: int
    offline_nodes: int
    unstable_nodes: int
    avg_response_time: float
    avg_success_rate: float


class MessageResponse(BaseModel):
    """通用消息响应"""
    message: str


class SwitchServerResponse(BaseModel):
    """切换服务器响应"""
    message: str = Field(..., description="消息")
    server: Optional[ServerConfigResponse] = Field(None, description="切换后的服务器")
    success: bool = Field(..., description="是否成功")


# ============== API端点 ==============

@router.post("/init-default", response_model=MessageResponse, summary="初始化默认服务器")
async def init_default_servers(service: TdxServerService = Depends(get_service)):
    """
    初始化默认的TDX服务器配置
    """
    logger.info("[API入口] POST /tdx-server/init-default - 初始化默认服务器")
    count = service.init_default_servers()
    return MessageResponse(message=f"成功初始化 {count} 个默认服务器")


@router.get("/configs", response_model=List[ServerWithNodeResponse], summary="获取服务器列表")
async def get_server_configs(
    enabled_only: bool = Query(default=False, description="仅返回启用的服务器"),
    service: TdxServerService = Depends(get_service)
):
    """
    获取所有服务器配置及其节点状态
    """
    logger.info(f"[API入口] GET /tdx-server/configs - 获取服务器列表, enabled_only={enabled_only}")
    return service.get_servers_with_nodes(enabled_only)


@router.post("/configs", response_model=ServerConfigResponse, summary="创建服务器")
async def create_server_config(
    config: ServerConfigCreate,
    service: TdxServerService = Depends(get_service)
):
    """
    创建新的服务器配置
    """
    logger.info(f"[API入口] POST /tdx-server/configs - 创建服务器, name={config.name}")
    return service.create_server(config.model_dump())


@router.put("/configs/{server_id}", response_model=ServerConfigResponse, summary="更新服务器")
async def update_server_config(
    server_id: int,
    config: ServerConfigUpdate,
    service: TdxServerService = Depends(get_service)
):
    """
    更新服务器配置
    """
    logger.info(f"[API入口] PUT /tdx-server/configs/{server_id} - 更新服务器")
    server = service.update_server(server_id, config.model_dump(exclude_unset=True))
    if not server:
        raise HTTPException(status_code=404, detail="服务器不存在")
    return server


@router.delete("/configs/{server_id}", response_model=MessageResponse, summary="删除服务器")
async def delete_server_config(
    server_id: int,
    service: TdxServerService = Depends(get_service)
):
    """
    删除服务器配置
    """
    logger.info(f"[API入口] DELETE /tdx-server/configs/{server_id} - 删除服务器")
    success = service.delete_server(server_id)
    if not success:
        raise HTTPException(status_code=404, detail="服务器不存在")
    return MessageResponse(message="删除成功")


@router.post("/configs/{server_id}/set-default", response_model=MessageResponse, summary="设置默认服务器")
async def set_default_server(
    server_id: int,
    service: TdxServerService = Depends(get_service)
):
    """
    设置默认服务器
    """
    logger.info(f"[API入口] POST /tdx-server/configs/{server_id}/set-default - 设置默认服务器")
    success = service.set_default_server(server_id)
    if not success:
        raise HTTPException(status_code=404, detail="服务器不存在")
    return MessageResponse(message="设置默认服务器成功")


@router.post("/check/{server_id}", response_model=ServerNodeResponse, summary="检查服务器状态")
async def check_server_status(
    server_id: int,
    service: TdxServerService = Depends(get_service)
):
    """
    检查指定服务器的状态
    """
    logger.info(f"[API入口] POST /tdx-server/check/{server_id} - 检查服务器状态")
    node = service.check_server_status(server_id)
    if not node:
        raise HTTPException(status_code=404, detail="服务器不存在")
    return node


@router.post("/check-all", response_model=List[ServerWithNodeResponse], summary="检查所有服务器")
async def check_all_servers(service: TdxServerService = Depends(get_service)):
    """
    检查所有服务器的状态
    """
    logger.info("[API入口] POST /tdx-server/check-all - 检查所有服务器")
    return service.check_all_servers()


@router.get("/best", response_model=Optional[ServerConfigResponse], summary="获取最佳服务器")
async def get_best_server(service: TdxServerService = Depends(get_service)):
    """
    获取当前最佳服务器（在线、响应快、成功率高）
    """
    logger.info("[API入口] GET /tdx-server/best - 获取最佳服务器")
    return service.get_best_server()


@router.get("/statistics", response_model=StatisticsResponse, summary="获取统计信息")
async def get_server_statistics(service: TdxServerService = Depends(get_service)):
    """
    获取服务器统计信息
    """
    logger.info("[API入口] GET /tdx-server/statistics - 获取统计信息")
    return service.get_statistics()


@router.get("/logs", response_model=List[dict], summary="获取操作日志")
async def get_server_logs(
    server_id: Optional[int] = Query(default=None, description="服务器ID筛选"),
    action: Optional[str] = Query(default=None, description="操作类型筛选"),
    limit: int = Query(default=100, ge=1, le=1000, description="返回数量限制"),
    service: TdxServerService = Depends(get_service)
):
    """
    获取服务器操作日志

    - server_id: 可选，按服务器ID筛选
    - action: 可选，按操作类型筛选
    - limit: 返回数量限制，默认100条
    """
    logger.info(f"[API入口] GET /tdx-server/logs - 获取日志, server_id={server_id}, action={action}")

    logs = service.get_logs(server_id=server_id, action=action, limit=limit)
    return logs


@router.delete("/logs/clear", response_model=MessageResponse, summary="清理旧日志")
async def clear_old_logs(
    days: int = Query(default=30, ge=1, le=365, description="保留天数"),
    service: TdxServerService = Depends(get_service)
):
    """
    清理指定天数之前的旧日志

    - days: 保留天数，默认30天
    """
    logger.info(f"[API入口] DELETE /tdx-server/logs/clear - 清理旧日志, days={days}")

    deleted_count = service.clear_old_logs(days)
    return MessageResponse(message=f"成功清理{deleted_count}条旧日志")


@router.post("/switch-to-best", response_model=SwitchServerResponse, summary="切换到最佳服务器")
async def switch_to_best_server(
    service: TdxServerService = Depends(get_service),
    db: Session = Depends(get_db)
):
    """
    将系统当前连接切换到管理系统中的最佳服务器，并将其设为默认服务器
    """
    logger.info("[API入口] POST /tdx-server/switch-to-best - 切换到最佳服务器")

    try:
        from ..services.tdx_service import reconnect_with_managed_server, tdx_service
        from ..core.config import settings

        best_server = service.get_best_server()
        if not best_server:
            return SwitchServerResponse(
                message="没有可用的最佳服务器",
                server=None,
                success=False
            )

        # 执行切换
        success = reconnect_with_managed_server(tdx_service, db)

        if success:
            # 将该服务器设为默认
            service.set_default_server(best_server.id)

            # 更新全局配置，使重启后仍然使用此服务器
            settings.TDX_HOST = best_server.host
            settings.TDX_PORT = best_server.port

            # 更新全局tdx_service的server配置
            tdx_service.server = (best_server.host, best_server.port)

            logger.info(f"[API] 已将服务器 {best_server.name} 设为默认，并更新系统配置")

            return SwitchServerResponse(
                message=f"成功切换到服务器: {best_server.name}，已设为默认服务器",
                server=ServerConfigResponse.model_validate(best_server),
                success=True
            )
        else:
            return SwitchServerResponse(
                message="切换服务器失败",
                server=None,
                success=False
            )
    except Exception as e:
        logger.error(f"[API错误] 切换服务器失败: {e}")
        return SwitchServerResponse(
            message=f"切换失败: {str(e)}",
            server=None,
            success=False
        )


@router.get("/current-connection", summary="获取当前连接信息")
async def get_current_connection():
    """
    获取当前TDX服务连接的服务器信息
    """
    logger.info("[API入口] GET /tdx-server/current-connection - 获取当前连接信息")

    try:
        from ..services.tdx_service import tdx_service

        return {
            "server": tdx_service.server,
            "bestip": tdx_service.bestip,
            "timeout": tdx_service.timeout,
            "closed": tdx_service.closed
        }
    except Exception as e:
        logger.error(f"[API错误] 获取连接信息失败: {e}")
        return {
            "error": str(e)
        }
```

### 5. 注册路由 (backend/app/main.py)

在main.py中添加路由注册：

```python
from app.api import tdx_server

# ... 其他路由注册
app.include_router(tdx_server.router)
```

### 6. 更新服务导出 (backend/app/services/__init__.py)

```python
from .tdx_service import tdx_service, get_tdx_service_with_managed_server, reconnect_with_managed_server
from .cache_service import CacheService

__all__ = ["tdx_service", "get_tdx_service_with_managed_server", "reconnect_with_managed_server", "CacheService"]
```

---

## 二、前端实现

### 1. API服务 (frontend/src/api/tdxServer.js)

```javascript
/**
 * TDX服务器管理API
 */
import request from '@/utils/request'

/**
 * 初始化默认服务器配置
 * @returns {Promise} 初始化结果
 */
export function initDefaultServers() {
  return request.post('/tdx-server/init-default')
}

/**
 * 获取服务器配置列表
 * @param {boolean} enabledOnly 是否只返回启用的服务器
 * @returns {Promise} 服务器配置列表
 */
export function getServerConfigs(enabledOnly = false) {
  return request.get('/tdx-server/configs', {
    params: { enabled_only: enabledOnly }
  })
}

/**
 * 获取服务器列表（带节点状态）
 * @param {boolean} enabledOnly 是否只返回启用的服务器
 * @returns {Promise} 服务器列表
 */
export function getServersWithNodes(enabledOnly = false) {
  return request.get('/tdx-server/configs', {
    params: { enabled_only: enabledOnly }
  })
}

/**
 * 创建服务器配置
 * @param {Object} data 服务器配置数据
 * @returns {Promise} 创建结果
 */
export function createServerConfig(data) {
  return request.post('/tdx-server/configs', data)
}

/**
 * 更新服务器配置
 * @param {number} id 服务器ID
 * @param {Object} data 更新数据
 * @returns {Promise} 更新结果
 */
export function updateServerConfig(id, data) {
  return request.put(`/tdx-server/configs/${id}`, data)
}

/**
 * 删除服务器配置
 * @param {number} id 服务器ID
 * @returns {Promise} 删除结果
 */
export function deleteServerConfig(id) {
  return request.delete(`/tdx-server/configs/${id}`)
}

/**
 * 设置默认服务器
 * @param {number} id 服务器ID
 * @returns {Promise} 设置结果
 */
export function setDefaultServer(id) {
  return request.post(`/tdx-server/configs/${id}/set-default`)
}

/**
 * 检查服务器状态
 * @param {number} id 服务器ID
 * @returns {Promise} 状态检查结果
 */
export function checkServerStatus(id) {
  return request.post(`/tdx-server/check/${id}`)
}

/**
 * 检查所有服务器状态
 * @returns {Promise} 检查结果列表
 */
export function checkAllServers() {
  return request.post('/tdx-server/check-all')
}

/**
 * 获取最佳服务器
 * @returns {Promise} 最佳服务器配置
 */
export function getBestServer() {
  return request.get('/tdx-server/best')
}

/**
 * 获取服务器统计信息
 * @returns {Promise} 统计信息
 */
export function getServerStatistics() {
  return request.get('/tdx-server/statistics')
}

/**
 * 获取操作日志
 * @param {Object} params 查询参数
 * @returns {Promise} 日志列表
 */
export function getServerLogs(params = {}) {
  return request.get('/tdx-server/logs', { params })
}

/**
 * 清理旧日志
 * @param {number} days 保留天数
 * @returns {Promise} 清理结果
 */
export function clearOldLogs(days = 30) {
  return request.delete('/tdx-server/logs/clear', {
    params: { days }
  })
}

/**
 * 切换到最佳服务器
 * @returns {Promise} 切换结果
 */
export function switchToBestServer() {
  return request.post('/tdx-server/switch-to-best')
}

/**
 * 获取当前连接信息
 * @returns {Promise} 当前连接信息
 */
export function getCurrentConnection() {
  return request.get('/tdx-server/current-connection')
}
```

### 2. 管理页面 (frontend/src/views/TdxServer.vue)

```vue
<template>
  <div class="tdx-server-page">
    <!-- 页面标题 -->
    <div class="page-header">
      <div class="title-section">
        <el-icon size="32" color="#409EFF"><Monitor /></el-icon>
        <div>
          <h2>TDX行情服务器管理</h2>
          <p class="subtitle">管理通达信行情服务器配置，监控服务器节点状态</p>
        </div>
      </div>
      <div class="header-actions">
        <el-button type="success" @click="switchToBest" :loading="switching">
          <el-icon><Switch /></el-icon>切换到最佳
        </el-button>
        <el-button type="primary" @click="showAddDialog">
          <el-icon><Plus /></el-icon>添加服务器
        </el-button>
        <el-button @click="checkAllServers" :loading="checking">
          <el-icon><Refresh /></el-icon>检查全部
        </el-button>
        <el-button @click="initDefaultServers" :loading="initializing">
          <el-icon><Download /></el-icon>初始化默认
        </el-button>
      </div>
    </div>

    <!-- 统计卡片 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :span="4">
        <el-card class="stat-card">
          <div class="stat-value">{{ statistics.total_servers || 0 }}</div>
          <div class="stat-label">服务器总数</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card class="stat-card">
          <div class="stat-value success">{{ statistics.online_nodes || 0 }}</div>
          <div class="stat-label">在线节点</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card class="stat-card">
          <div class="stat-value danger">{{ statistics.offline_nodes || 0 }}</div>
          <div class="stat-label">离线节点</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card class="stat-card">
          <div class="stat-value warning">{{ statistics.unstable_nodes || 0 }}</div>
          <div class="stat-label">不稳定节点</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card class="stat-card">
          <div class="stat-value">{{ statistics.avg_response_time || 0 }}ms</div>
          <div class="stat-label">平均响应</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card class="stat-card">
          <div class="stat-value">{{ (statistics.avg_success_rate || 0).toFixed(1) }}%</div>
          <div class="stat-label">平均成功率</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 当前连接信息 -->
    <el-card v-if="currentConnection" class="current-connection-card">
      <template #header>
        <div class="card-header">
          <span>
            <el-icon><Connection /></el-icon>
            当前系统连接
          </span>
        </div>
      </template>
      <el-descriptions :column="4" border>
        <el-descriptions-item label="服务器地址">
          {{ currentConnection.server ? currentConnection.server.join(':') : '默认配置' }}
        </el-descriptions-item>
        <el-descriptions-item label="连接模式">
          {{ currentConnection.bestip ? '自动选择(bestip)' : '固定服务器' }}
        </el-descriptions-item>
        <el-descriptions-item label="超时时间">
          {{ currentConnection.timeout }}秒
        </el-descriptions-item>
        <el-descriptions-item label="连接状态">
          <el-tag :type="currentConnection.closed ? 'danger' : 'success'">
            {{ currentConnection.closed ? '已关闭' : '已连接' }}
          </el-tag>
        </el-descriptions-item>
      </el-descriptions>
    </el-card>

    <!-- 服务器列表 -->
    <el-card class="server-list-card">
      <template #header>
        <div class="card-header">
          <span>服务器列表</span>
          <div class="header-actions">
            <el-input
              v-model="searchKeyword"
              placeholder="搜索服务器名称/IP"
              style="width: 200px"
              clearable
            >
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
            <el-radio-group v-model="statusFilter" size="small">
              <el-radio-button label="">全部</el-radio-button>
              <el-radio-button label="online">在线</el-radio-button>
              <el-radio-button label="offline">离线</el-radio-button>
            </el-radio-group>
          </div>
        </div>
      </template>

      <el-table
        :data="filteredServers"
        v-loading="loading"
        stripe
        border
        style="width: 100%"
      >
        <el-table-column type="index" width="50" />
        <el-table-column prop="name" label="服务器名称" min-width="150">
          <template #default="{ row }">
            <div class="server-name">
              <span>{{ row.server.name }}</span>
              <el-tag v-if="row.server.is_default" type="success" size="small">默认</el-tag>
              <el-tag v-if="!row.server.is_enabled" type="info" size="small">禁用</el-tag>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="server.host" label="IP地址" width="140" />
        <el-table-column prop="server.port" label="端口" width="80" />
        <el-table-column prop="server.location" label="位置" width="100" />
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag
              :type="getStatusType(row.node?.status)"
              size="small"
              effect="dark"
            >
              {{ getStatusText(row.node?.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="响应时间" width="100">
          <template #default="{ row }">
            <span :class="getResponseTimeClass(row.node?.response_time)">
              {{ row.node?.response_time ? row.node.response_time.toFixed(1) + 'ms' : '-' }}
            </span>
          </template>
        </el-table-column>
        <el-table-column label="成功率" width="100">
          <template #default="{ row }">
            {{ row.node?.success_rate ? (row.node.success_rate * 100).toFixed(1) + '%' : '-' }}
          </template>
        </el-table-column>
        <el-table-column label="最后检查" width="150">
          <template #default="{ row }">
            {{ row.node?.last_check ? new Date(row.node.last_check).toLocaleString() : '-' }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="250" fixed="right">
          <template #default="{ row }">
            <el-button
              size="small"
              @click="checkServer(row.server.id)"
              :loading="checkingId === row.server.id"
            >
              <el-icon><Check /></el-icon>检查
            </el-button>
            <el-button
              size="small"
              type="primary"
              @click="editServer(row.server)"
            >
              <el-icon><Edit /></el-icon>编辑
            </el-button>
            <el-button
              v-if="!row.server.is_default"
              size="small"
              type="warning"
              @click="setDefault(row.server.id)"
            >
              <el-icon><Star /></el-icon>默认
            </el-button>
            <el-button
              size="small"
              type="danger"
              @click="deleteServer(row.server)"
            >
              <el-icon><Delete /></el-icon>删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 添加/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="isEdit ? '编辑服务器' : '添加服务器'"
      width="500px"
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="100px"
      >
        <el-form-item label="服务器名称" prop="name">
          <el-input v-model="form.name" placeholder="如：电信主站1" />
        </el-form-item>
        <el-form-item label="IP地址" prop="host">
          <el-input v-model="form.host" placeholder="如：119.147.212.81" />
        </el-form-item>
        <el-form-item label="端口" prop="port">
          <el-input-number v-model="form.port" :min="1" :max="65535" />
        </el-form-item>
        <el-form-item label="服务器类型" prop="server_type">
          <el-radio-group v-model="form.server_type">
            <el-radio label="std">标准行情</el-radio>
            <el-radio label="ext">扩展行情</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="位置">
          <el-input v-model="form.location" placeholder="如：电信/北京" />
        </el-form-item>
        <el-form-item label="权重">
          <el-input-number v-model="form.weight" :min="1" :max="1000" />
          <span class="form-tip">用于负载均衡，值越大优先级越高</span>
        </el-form-item>
        <el-form-item label="超时时间">
          <el-input-number v-model="form.timeout" :min="1" :max="60" />
          <span class="form-tip">秒</span>
        </el-form-item>
        <el-form-item label="最大重试">
          <el-input-number v-model="form.max_retries" :min="0" :max="10" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input
            v-model="form.description"
            type="textarea"
            :rows="2"
            placeholder="服务器描述信息"
          />
        </el-form-item>
        <el-form-item label="启用">
          <el-switch v-model="form.is_enabled" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitForm" :loading="submitting">
          确定
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Monitor, Plus, Refresh, Download, Search, Check, Edit, Star, Delete, Switch, Connection
} from '@element-plus/icons-vue'
import {
  getServersWithNodes, createServerConfig, updateServerConfig, deleteServerConfig,
  setDefaultServer, checkServerStatus, checkAllServers as apiCheckAllServers,
  getServerStatistics, initDefaultServers as apiInitDefaultServers,
  switchToBestServer, getCurrentConnection
} from '@/api/tdxServer'

// 响应式数据
const loading = ref(false)
const checking = ref(false)
const initializing = ref(false)
const submitting = ref(false)
const switching = ref(false)
const currentConnection = ref(null)
const servers = ref([])
const statistics = ref({})
const searchKeyword = ref('')
const statusFilter = ref('')
const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref(null)
const checkingId = ref(null)

// 表单数据
const form = ref({
  name: '',
  host: '',
  port: 7709,
  server_type: 'std',
  location: '',
  weight: 100,
  timeout: 10,
  max_retries: 3,
  description: '',
  is_enabled: true
})

// 表单验证规则
const rules = {
  name: [{ required: true, message: '请输入服务器名称', trigger: 'blur' }],
  host: [{ required: true, message: '请输入IP地址', trigger: 'blur' }],
  port: [{ required: true, message: '请输入端口', trigger: 'blur' }],
  server_type: [{ required: true, message: '请选择服务器类型', trigger: 'change' }]
}

// 过滤后的服务器列表
const filteredServers = computed(() => {
  let result = servers.value

  // 关键词过滤
  if (searchKeyword.value) {
    const keyword = searchKeyword.value.toLowerCase()
    result = result.filter(item =>
      item.server.name.toLowerCase().includes(keyword) ||
      item.server.host.includes(keyword) ||
      (item.server.location && item.server.location.toLowerCase().includes(keyword))
    )
  }

  // 状态过滤
  if (statusFilter.value) {
    result = result.filter(item => item.node?.status === statusFilter.value)
  }

  return result
})

// 获取状态类型
function getStatusType(status) {
  const map = {
    'online': 'success',
    'offline': 'danger',
    'unstable': 'warning',
    'maintenance': 'info',
    'unknown': 'info'
  }
  return map[status] || 'info'
}

// 获取状态文本
function getStatusText(status) {
  const map = {
    'online': '在线',
    'offline': '离线',
    'unstable': '不稳定',
    'maintenance': '维护中',
    'unknown': '未知'
  }
  return map[status] || status || '未知'
}

// 获取响应时间样式类
function getResponseTimeClass(time) {
  if (!time) return ''
  if (time < 50) return 'text-success'
  if (time < 100) return 'text-warning'
  return 'text-danger'
}

// 加载数据
async function loadData() {
  loading.value = true
  try {
    const [serversData, statsData] = await Promise.all([
      getServersWithNodes(),
      getServerStatistics()
    ])
    servers.value = serversData
    statistics.value = statsData
  } catch (error) {
    console.error('加载数据失败:', error)
    ElMessage.error('加载数据失败')
  } finally {
    loading.value = false
  }
}

// 检查单个服务器
async function checkServer(serverId) {
  checkingId.value = serverId
  try {
    await checkServerStatus(serverId)
    ElMessage.success('检查完成')
    loadData()
  } catch (error) {
    console.error('检查服务器失败:', error)
  } finally {
    checkingId.value = null
  }
}

// 检查所有服务器
async function checkAllServers() {
  checking.value = true
  try {
    const results = await apiCheckAllServers()
    const onlineCount = results.filter(r => r.status === 'online').length
    ElMessage.success(`检查完成，${onlineCount}/${results.length} 个服务器在线`)
    loadData()
  } catch (error) {
    console.error('检查所有服务器失败:', error)
  } finally {
    checking.value = false
  }
}

// 初始化默认服务器
async function initDefaultServers() {
  try {
    await ElMessageBox.confirm('确定要初始化默认服务器配置吗？', '提示', {
      type: 'warning'
    })
    initializing.value = true
    const result = await apiInitDefaultServers()
    ElMessage.success(result.message)
    loadData()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('初始化失败:', error)
    }
  } finally {
    initializing.value = false
  }
}

// 切换到最佳服务器
async function switchToBest() {
  switching.value = true
  try {
    const result = await switchToBestServer()
    if (result.success) {
      ElMessage.success(result.message)
      // 刷新服务器列表和当前连接信息
      await loadData()
      await loadCurrentConnection()
    } else {
      ElMessage.warning(result.message)
    }
  } catch (error) {
    console.error('切换服务器失败:', error)
    ElMessage.error('切换服务器失败')
  } finally {
    switching.value = false
  }
}

// 加载当前连接信息
async function loadCurrentConnection() {
  try {
    const result = await getCurrentConnection()
    currentConnection.value = result
  } catch (error) {
    console.error('获取当前连接失败:', error)
  }
}

// 显示添加对话框
function showAddDialog() {
  isEdit.value = false
  form.value = {
    name: '',
    host: '',
    port: 7709,
    server_type: 'std',
    location: '',
    weight: 100,
    timeout: 10,
    max_retries: 3,
    description: '',
    is_enabled: true
  }
  dialogVisible.value = true
}

// 编辑服务器
function editServer(server) {
  isEdit.value = true
  form.value = { ...server }
  dialogVisible.value = true
}

// 提交表单
async function submitForm() {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  submitting.value = true
  try {
    if (isEdit.value) {
      await updateServerConfig(form.value.id, form.value)
      ElMessage.success('更新成功')
    } else {
      await createServerConfig(form.value)
      ElMessage.success('创建成功')
    }
    dialogVisible.value = false
    loadData()
  } catch (error) {
    console.error('提交失败:', error)
    ElMessage.error('提交失败')
  } finally {
    submitting.value = false
  }
}

// 删除服务器
async function deleteServer(server) {
  try {
    await ElMessageBox.confirm(`确定要删除服务器 "${server.name}" 吗？`, '提示', {
      type: 'warning'
    })
    await deleteServerConfig(server.id)
    ElMessage.success('删除成功')
    loadData()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
    }
  }
}

// 设置默认服务器
async function setDefault(serverId) {
  try {
    await setDefaultServer(serverId)
    ElMessage.success('设置默认服务器成功')
    loadData()
  } catch (error) {
    console.error('设置默认服务器失败:', error)
  }
}

// 页面加载
onMounted(() => {
  loadData()
  loadCurrentConnection()
})
</script>

<style scoped>
.tdx-server-page {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.title-section {
  display: flex;
  align-items: center;
  gap: 15px;
}

.title-section h2 {
  margin: 0;
  font-size: 24px;
  color: #303133;
}

.subtitle {
  margin: 5px 0 0;
  color: #909399;
  font-size: 14px;
}

.header-actions {
  display: flex;
  gap: 10px;
}

.stats-row {
  margin-bottom: 20px;
}

.stat-card {
  text-align: center;
  padding: 15px;
}

.stat-value {
  font-size: 28px;
  font-weight: bold;
  color: #409EFF;
  margin-bottom: 5px;
}

.stat-value.success {
  color: #67C23A;
}

.stat-value.danger {
  color: #F56C6C;
}

.stat-value.warning {
  color: #E6A23C;
}

.stat-label {
  color: #909399;
  font-size: 14px;
}

.current-connection-card {
  margin-bottom: 20px;
}

.current-connection-card .card-header span {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: bold;
  font-size: 16px;
}

.current-connection-card .card-header span .el-icon {
  color: #409EFF;
}

.server-list-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-header span {
  font-weight: bold;
  font-size: 16px;
}

.server-name {
  display: flex;
  align-items: center;
  gap: 8px;
}

.text-success {
  color: #67C23A;
}

.text-warning {
  color: #E6A23C;
}

.text-danger {
  color: #F56C6C;
}

.form-tip {
  margin-left: 10px;
  color: #909399;
}
</style>
```

---

## 三、路由和菜单配置

### 1. 前端路由 (frontend/src/router/index.js)

```javascript
{
  path: '/tdx-server',
  name: 'TdxServer',
  component: () => import('@/views/TdxServer.vue'),
  meta: { title: 'TDX服务器管理' }
}
```

### 2. 顶部菜单 (frontend/src/App.vue)

在导航菜单中添加：

```vue
<el-menu-item index="/tdx-server">
  <el-icon><Monitor /></el-icon>
  <span>TDX服务器</span>
</el-menu-item>
```

### 3. 控制台快捷入口 (frontend/src/views/Console.vue)

在快捷入口卡片中添加：

```vue
<el-button size="large" type="primary" @click="$router.push('/tdx-server')">
  <el-icon><Monitor /></el-icon>
  TDX服务器管理
</el-button>
```

---

## 四、数据库初始化

确保在应用启动时创建表结构。在 `backend/app/db/database.py` 中：

```python
from app.models.tdx_server import TdxServerConfig, TdxServerNode, TdxServerLog

# 在 init_db() 函数中确保这些表被创建
Base.metadata.create_all(bind=engine)
```

---

## 五、功能说明

### 核心功能

1. **服务器管理**
   - 添加、编辑、删除服务器配置
   - 设置默认服务器
   - 启用/禁用服务器

2. **状态监控**
   - 实时检查服务器在线状态
   - 监控响应时间和成功率
   - 统计在线/离线/不稳定节点数量

3. **智能切换**
   - 自动选择最佳服务器（响应快、成功率高）
   - 一键切换到最佳服务器
   - 切换后自动设为默认，重启后仍然有效

4. **当前连接信息**
   - 显示系统当前使用的服务器地址
   - 显示连接模式和超时时间
   - 显示连接状态

### API端点列表

| 方法 | 端点 | 说明 |
|------|------|------|
| POST | /tdx-server/init-default | 初始化默认服务器 |
| GET | /tdx-server/configs | 获取服务器列表 |
| POST | /tdx-server/configs | 创建服务器 |
| PUT | /tdx-server/configs/{id} | 更新服务器 |
| DELETE | /tdx-server/configs/{id} | 删除服务器 |
| POST | /tdx-server/configs/{id}/set-default | 设置默认服务器 |
| POST | /tdx-server/check/{id} | 检查服务器状态 |
| POST | /tdx-server/check-all | 检查所有服务器 |
| GET | /tdx-server/best | 获取最佳服务器 |
| GET | /tdx-server/statistics | 获取统计信息 |
| GET | /tdx-server/logs | 获取操作日志 |
| DELETE | /tdx-server/logs/clear | 清理旧日志 |
| POST | /tdx-server/switch-to-best | 切换到最佳服务器 |
| GET | /tdx-server/current-connection | 获取当前连接信息 |

---

## 六、使用流程

1. **首次使用**
   - 访问 TDX服务器管理 页面
   - 点击"初始化默认"按钮加载预设服务器

2. **日常管理**
   - 查看统计卡片了解整体状态
   - 查看当前连接信息了解系统使用的服务器
   - 点击"检查全部"更新所有服务器状态

3. **切换服务器**
   - 点击"切换到最佳"按钮
   - 系统会自动选择最佳服务器并切换
   - 切换后的服务器会被设为默认，重启后仍然有效

4. **自定义服务器**
   - 点击"添加服务器"添加自定义服务器
   - 可以设置服务器名称、IP、端口、权重等
   - 可以禁用不需要的服务器