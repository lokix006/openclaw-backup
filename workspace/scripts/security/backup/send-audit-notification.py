#!/usr/bin/env python3
"""
脚本名称：巡检报告飞书通知发送器
作者：OpenClaw Assistant
创建时间：2026-03-04
用途：读取巡检通知内容并通过OpenClaw发送到飞书
"""

import os
import sys
import logging
import json
import subprocess
import time

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def send_message_via_openclaw(message, user_id):
    """通过OpenClaw发送消息到飞书"""
    try:
        # 构建OpenClaw消息命令
        # 这里我们使用openclaw CLI来发送消息
        cmd = [
            'openclaw', 'message', 'send',
            '--target', f'user:{user_id}',
            '--message', message,
            '--channel', 'feishu'
        ]
        
        logger.info(f"Sending message via OpenClaw: {user_id}")
        
        # 执行命令
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            logger.info("Message sent successfully")
            return True
        else:
            logger.error(f"Failed to send message: {result.stderr}")
            return False
            
    except subprocess.TimeoutExpired:
        logger.error("Message sending timed out")
        return False
    except Exception as e:
        logger.error(f"Error sending message: {e}")
        return False

def read_notification_content():
    """读取通知内容"""
    try:
        # 读取通知文件路径
        path_file = "/tmp/openclaw-notification-path.txt"
        if not os.path.exists(path_file):
            logger.error("Notification path file not found")
            return None
            
        with open(path_file, 'r') as f:
            notification_file = f.read().strip()
            
        if not os.path.exists(notification_file):
            logger.error(f"Notification file not found: {notification_file}")
            return None
            
        with open(notification_file, 'r', encoding='utf-8') as f:
            content = f.read()
            
        logger.info(f"Read notification content from: {notification_file}")
        return content
        
    except Exception as e:
        logger.error(f"Error reading notification content: {e}")
        return None

def main():
    """主函数"""
    logger.info("Starting audit notification sender")
    
    # 读取通知内容
    message = read_notification_content()
    if not message:
        logger.error("Failed to read notification content")
        sys.exit(1)
    
    # 目标用户ID
    user_id = "ou_570aeb8842a1cbbc0313861d2b5c128f"
    
    # 发送消息
    success = send_message_via_openclaw(message, user_id)
    
    if success:
        logger.info("Audit notification sent successfully")
        # 清理临时文件
        try:
            os.remove("/tmp/openclaw-notification-path.txt")
        except:
            pass
    else:
        logger.error("Failed to send audit notification")
        sys.exit(1)

if __name__ == "__main__":
    main()