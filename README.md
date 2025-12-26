# LXC/LXD Auto Installer 🚀

A beautiful, feature-rich bash script for automated LXC and LXD installation on Ubuntu and Debian systems. This installer provides an exceptional user experience with advanced animations, comprehensive error handling, and professional output.

[![LXC-LXD](https://img.shields.io/badge/LXC-LXD-blue)](https://img.shields.io/badge/LXC-LXD-blue)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green)](https://img.shields.io/badge/Bash-4.0%252B-green)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-orange)](https://img.shields.io/badge/Platform-Ubuntu%2520%257C%2520Debian-orange)
[![License](https://img.shields.io/badge/License-MIT-lightgrey)](https://img.shields.io/badge/License-MIT-lightgrey)

## ✨ Features

### 🎨 Visual Enhancements

* 8 Different Spinner Styles - Dots, circle, pulse, bounce, arrow, moon, triangle, clock
* Multiple Progress Bars - Block, dot, arrow, pulse styles with smooth animations
* Rainbow Color Effects - Beautiful color transitions in headers
* Dynamic Box Drawing - Multiple border styles (single, double, round, bold)
* Typewriter Text Effects - Animated text display
* Responsive Design - Adapts to terminal size

### 🛡️ Robust Error Handling

* Comprehensive Logging - Detailed logs at `/tmp/lxd_installer.log`
* Retry Mechanism - Automatic retries with configurable attempts
* System Validation - Checks memory, disk space, and dependencies
* Graceful Interruption - Proper handling of Ctrl+C
* Detailed Error Messages - Line numbers, commands, and solutions

### 🔧 Technical Features

* Automatic Dependency Resolution - Handles all required packages
* Existing Installation Detection - Skips already installed components
* System Requirement Checks - Validates minimum resources
* Privilege Verification - Ensures proper sudo access
* Post-Installation Validation - Verifies LXD functionality

## 🚀 Quick Start

### Prerequisites

* Ubuntu 18.04+ or Debian 10+
* Bash 4.0 or higher
* Sudo privileges
* Minimum 2GB RAM (recommended)
* Stable internet connection

### Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/hopingboyz/lxc-installer/main/lxc-installer.sh)
```
