#!/bin/bash

# OS environment setup script for dev container
# This script configures system settings and environment variables

set -euo pipefail  # Exit on error, undefined vars, pipe failures

echo "Setting up OS environment for dev container..."

# Step 1: Configure inotify watches
echo "Configuring inotify watches..."
if [ -f /proc/sys/fs/inotify/max_user_watches ]; then
    current_limit=$(cat /proc/sys/fs/inotify/max_user_watches)
    target_limit=524288
    
    echo "Current max_user_watches: $current_limit"
    
    if [ "$current_limit" -lt "$target_limit" ]; then
        echo "Setting max_user_watches to $target_limit"
        
        # Check if the setting already exists in sysctl.conf to avoid duplicates
        if ! grep -q "fs.inotify.max_user_watches" /etc/sysctl.conf 2>/dev/null; then
            echo "fs.inotify.max_user_watches=$target_limit" | sudo tee -a /etc/sysctl.conf > /dev/null
        else
            echo "inotify setting already exists in sysctl.conf, updating..."
            sudo sed -i "s/^fs.inotify.max_user_watches=.*/fs.inotify.max_user_watches=$target_limit/" /etc/sysctl.conf
        fi
        
        # Apply the setting immediately
        sudo sysctl -p > /dev/null
        
        # Verify the change
        new_limit=$(cat /proc/sys/fs/inotify/max_user_watches)
        if [ "$new_limit" -eq "$target_limit" ]; then
            echo "✅ Successfully set max_user_watches to $new_limit"
        else
            echo "❌ Failed to set max_user_watches (current: $new_limit, expected: $target_limit)"
            exit 1
        fi
    else
        echo "✅ max_user_watches already sufficient ($current_limit >= $target_limit)"
    fi
else
    echo "⚠️ inotify not available on this system"
fi

# Step 2: Configure Git safe directory (if running in container)
echo "Configuring Git safe directories..."
if command -v git >/dev/null 2>&1; then
    # Add the workspace directory as a safe directory for Git
    git config --global --add safe.directory /workspaces/daytona
    echo "✅ Added /workspaces/daytona as Git safe directory"
else
    echo "⚠️ Git not available"
fi

# Step 3: Set up environment variables for development
echo "Setting up development environment variables..."

# Create .bashrc additions for development
dev_bashrc="/tmp/dev_additions.bashrc"
cat > "$dev_bashrc" << 'EOF'
# Development environment additions
export NODE_OPTIONS="--max-old-space-size=4096"
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Add common aliases for development
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
EOF

# Append to .bashrc if not already present
if [ -f ~/.bashrc ]; then
    if ! grep -q "Development environment additions" ~/.bashrc; then
        echo "" >> ~/.bashrc
        cat "$dev_bashrc" >> ~/.bashrc
        echo "✅ Added development environment variables to .bashrc"
    else
        echo "✅ Development environment already configured in .bashrc"
    fi
fi

# Clean up temporary file
rm -f "$dev_bashrc"

echo "🎉 OS environment setup completed successfully!"
