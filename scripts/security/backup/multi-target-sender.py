#!/usr/bin/env python3
"""
脚本名称：多目标通知发送器  
作者：OpenClaw Assistant
创建时间：2026-03-04
用途：读取通知配置并向多个目标发送巡检报告
"""

import os
import sys
import json
import logging
from datetime import datetime
from pathlib import Path

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/openclaw/multi-target-sender.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class NotificationSender:
    def __init__(self):
        self.notification_queue = "/tmp/openclaw-notification-queue.txt"
        self.targets_file = f"/tmp/openclaw-notification-targets-{datetime.now().strftime('%Y%m%d')}.txt"
        self.sent_flag = f"/tmp/openclaw-notification-sent-{datetime.now().strftime('%Y%m%d')}.flag"
        
    def read_notification_content(self):
        """读取通知内容"""
        try:
            if not os.path.exists(self.notification_queue):
                return None
                
            with open(self.notification_queue, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # 移除目标信息部分（如果存在）
            if "TARGETS:" in content:
                content = content.split("TARGETS:")[0].strip()
                
            return content.strip()
            
        except Exception as e:
            logger.error(f"Error reading notification content: {e}")
            return None
    
    def read_targets(self):
        """读取目标列表"""
        try:
            if not os.path.exists(self.targets_file):
                # 使用默认目标
                return ["user:ou_570aeb8842a1cbbc0313861d2b5c128f"]
                
            with open(self.targets_file, 'r') as f:
                targets = [line.strip() for line in f if line.strip()]
                
            return targets if targets else ["user:ou_570aeb8842a1cbbc0313861d2b5c128f"]
            
        except Exception as e:
            logger.error(f"Error reading targets: {e}")
            return ["user:ou_570aeb8842a1cbbc0313861d2b5c128f"]
    
    def create_message_request(self, content, targets):
        """创建消息发送请求文件"""
        try:
            request_file = f"/tmp/openclaw-message-request-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
            
            message_data = {
                "action": "send_notifications",
                "timestamp": datetime.now().isoformat(),
                "message": content,
                "targets": targets
            }
            
            with open(request_file, 'w', encoding='utf-8') as f:
                json.dump(message_data, f, indent=2, ensure_ascii=False)
                
            logger.info(f"Message request created: {request_file}")
            return request_file
            
        except Exception as e:
            logger.error(f"Error creating message request: {e}")
            return None
    
    def cleanup(self):
        """清理临时文件"""
        files_to_clean = [
            self.notification_queue,
            self.targets_file,
            "/tmp/openclaw-notification-path.txt"
        ]
        
        for file_path in files_to_clean:
            try:
                if os.path.exists(file_path):
                    os.remove(file_path)
                    logger.info(f"Cleaned up: {file_path}")
            except Exception as e:
                logger.warning(f"Failed to cleanup {file_path}: {e}")
        
        # 创建发送完成标记
        try:
            Path(self.sent_flag).touch()
            logger.info(f"Created sent flag: {self.sent_flag}")
        except Exception as e:
            logger.warning(f"Failed to create sent flag: {e}")
    
    def process_notification(self):
        """处理通知发送"""
        # 检查是否已发送
        if os.path.exists(self.sent_flag):
            logger.info("Notification already sent today")
            return True
            
        # 检查是否有待发送的通知
        if not os.path.exists(self.notification_queue):
            logger.info("No pending notifications")
            return True
            
        logger.info("Processing pending notification")
        
        # 读取通知内容和目标
        content = self.read_notification_content()
        if not content:
            logger.error("Failed to read notification content")
            return False
            
        targets = self.read_targets()
        logger.info(f"Found {len(targets)} notification targets")
        
        # 创建消息请求
        request_file = self.create_message_request(content, targets)
        if not request_file:
            logger.error("Failed to create message request")
            return False
            
        # 清理文件
        self.cleanup()
        
        logger.info("Notification processing completed")
        return True

def main():
    """主函数"""
    logger.info("Starting multi-target notification sender")
    
    sender = NotificationSender()
    
    try:
        success = sender.process_notification()
        if success:
            logger.info("Notification sender completed successfully")
        else:
            logger.error("Notification sender failed")
            sys.exit(1)
            
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()