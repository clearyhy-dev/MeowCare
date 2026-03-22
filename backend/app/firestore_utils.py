"""Firestore 时间与 protobuf 转换（firebase_admin.firestore 无 Timestamp 属性）。"""

from __future__ import annotations

from datetime import datetime, timezone

from google.cloud.firestore_v1._helpers import _datetime_to_pb_timestamp


def datetime_to_timestamp(dt: datetime):
    """将带时区的 UTC 时间转为 Firestore 查询/写入可用的 protobuf Timestamp。"""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    else:
        dt = dt.astimezone(timezone.utc)
    return _datetime_to_pb_timestamp(dt)
