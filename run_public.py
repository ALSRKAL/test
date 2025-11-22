#!/usr/bin/env python3
"""
سكريبت تشغيل المشروع مع وصول عام (عبر الإنترنت)
يستخدم localtunnel لإنشاء رابط عام مجاني
"""

import subprocess
import sys
import os
import time
import signal
import platform
import re
from pathlib import Path

class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'

class PublicManager:
    def __init__(self):
        self.processes = []
        self.root_dir = Path(__file__).parent.absolute()
        self.public_url = None
        
    def print_header(self, text):
        print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*70}{Colors.END}")
        print(f"{Colors.HEADER}{Colors.BOLD}{text.center(70)}{Colors.END}")
        print(f"{Colors.HEADER}{Colors.BOLD}{'='*70}{Colors.END}\n")
    
    def print_success(self, text):
        print(f"{Colors.GREEN}✓ {text}{Colors.END}")
    
    def print_error(self, text):
        print(f"{Colors.RED}✗ {text}{Colors.END}")
    
    def print_info(self, text):
        print(f"{Colors.CYAN}ℹ {text}{Colors.END}")
    
    def print_warning(self, text):
        print(f"{Colors.YELLOW}⚠ {text}{Colors.END}")
    
    def check_localtunnel(self):
        """فحص وتثبيت localtunnel"""
        try:
            result = subprocess.run(['npx', 'localtunnel', '--version'], 
                                  capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                return True
        except:
            pass
        
        self.print_info("localtunnel غير مثبت، سيتم استخدامه عبر npx")
        return True
    
    def kill_port(self, port):
        """إيقاف أي عملية على منفذ معين"""
        try: