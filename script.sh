#!/bin/bash

# Capstone Project
# ASSIGNMENT 5(LinuxOS and LSP)
# Bash Scripting Suite for System Maintenance


#Objective: Write a suite of Bash scripts to automate system maintenance tasks such as backup, system updates, and log monitoring.


LOG_FILE="/var/log/system_maintenance.log"

# Logging functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
    echo "[INFO] $1"
}

error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> $LOG_FILE
    echo "[ERROR] $1"
}

# Create log file
sudo touch $LOG_FILE 2>/dev/null || touch system_maintenance.log

# Main menu
show_menu() {
    clear
    echo "=== System Maintenance Suite ==="
    echo "1. Backup System"
    echo "2. Update & Clean"
    echo "3. Monitor Logs"
    echo "4. Check Disk Space"
    echo "5. System Info"
    echo "6. Run All Tasks"
    echo "7. Exit"
    echo -n "Choose option: "
}

# Backup function
backup_system() {
    log "Starting backup"
    
    BACKUP_DIR="$HOME/backups"
    mkdir -p $BACKUP_DIR
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    echo "Backup options:"
    echo "1. Home directory"
    echo "2. Custom directory"
    echo -n "Choose: "
    read choice
    
    if [ "$choice" = "1" ]; then
        SOURCE="$HOME"
    else
        echo -n "Enter directory: "
        read SOURCE
    fi
    
    if tar -czf "$BACKUP_DIR/$BACKUP_FILE" "$SOURCE" 2>/dev/null; then
        log "Backup created: $BACKUP_FILE"
        echo "Backup successful!"
    else
        error "Backup failed"
    fi
    
    # Keep only last 3 backups
    ls -t $BACKUP_DIR/*.tar.gz 2>/dev/null | tail -n +4 | xargs rm -f
}

# Update and cleanup
update_clean() {
    log "System update started"
    
    echo "Updating system packages..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt upgrade -y
        sudo apt autoremove -y
        sudo apt clean
    elif command -v dnf &> /dev/null; then
        sudo dnf update -y
        sudo dnf autoremove -y
        sudo dnf clean all
    fi
    
    echo "Cleaning temporary files..."
    sudo rm -rf /tmp/*
    rm -rf $HOME/.cache/*
    
    log "Update completed"
}

# Log monitor
monitor_logs() {
    echo -n "Monitor logs for (seconds): "
    read time
    
    echo "Monitoring system logs for $time seconds..."
    timeout $time tail -f /var/log/syslog | grep -E "error|fail|warning" || echo "No errors found"
    log "Log monitoring completed"
}

# Disk check
check_disk() {
    echo "=== Disk Usage ==="
    df -h | grep -v tmpfs
    
    echo ""
    echo "=== Large Files (>100MB) ==="
    find /home -type f -size +100M -exec ls -lh {} \; 2>/dev/null | head -5
}

# System info
system_info() {
    echo "=== System Information ==="
    echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"')"
    echo "Kernel: $(uname -r)"
    echo "CPU: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
    echo "Memory: $(free -h | grep Mem: | awk '{print $2}')"
    echo "Uptime: $(uptime -p)"
}

# Run all tasks
run_all() {
    log "=== Starting complete maintenance ==="
    echo "Running all maintenance tasks..."
    
    echo "1. Checking disk space..."
    check_disk
    sleep 2
    
    echo "2. Creating backup..."
    backup_system
    sleep 2
    
    echo "3. Updating system..."
    update_clean
    sleep 2
    
    echo "4. Quick log check..."
    grep -i "error" /var/log/syslog | tail -3 2>/dev/null || echo "No recent errors"
    
    log "All tasks completed"
    echo "Maintenance finished!"
}

# Main program
main() {
    log "Script started by user: $(whoami)"
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1) backup_system ;;
            2) update_clean ;;
            3) monitor_logs ;;
            4) check_disk ;;
            5) system_info ;;
            6) run_all ;;
            7) 
                log "Script exited"
                echo "Goodbye!"
                exit 0 
                ;;
            *) echo "Invalid option!" ;;
        esac
        
        echo ""
        echo -n "Press Enter to continue..."
        read
    done
}

# Start the script
main
