#!/bin/bash

# Git proxy setup script for dev container
# This script intelligently configures Git proxy settings based on network availability

echo "Setting up Git proxy configuration for dev container..."

# Function to check if a proxy is running on the host
check_proxy() {
    local host=$1
    local port=$2
    timeout 3 bash -c "</dev/tcp/$host/$port" 2>/dev/null
    return $?
}

# Function to test Git connectivity
test_git_connectivity() {
    echo "Testing Git connectivity..."
    timeout 10 git ls-remote --heads origin &>/dev/null
    return $?
}

# Step 1: Clear any existing proxy configuration
echo "Clearing existing proxy configuration..."
git config --global --unset http.proxy 2>/dev/null || true
git config --global --unset https.proxy 2>/dev/null || true

# Step 2: Test direct connection first (preferred if available)
echo "Testing direct Git connection..."
if test_git_connectivity; then
    echo "✓ Direct Git connection works - no proxy needed"
    echo "Git proxy setup completed."
    exit 0
fi

echo "❌ Direct connection failed, checking for proxy..."

# Step 3: Try to find and configure proxy if direct connection fails
PROXY_HOSTS=("host.docker.internal" "172.17.0.1" "172.18.0.1" "172.19.0.1")
PROXY_PORT=10809

PROXY_HOST=""
for host in "${PROXY_HOSTS[@]}"; do
    echo "Checking proxy at $host:$PROXY_PORT..."
    if check_proxy "$host" "$PROXY_PORT"; then
        PROXY_HOST="$host"
        echo "✓ Found working proxy at $host:$PROXY_PORT"
        break
    fi
done

if [ -n "$PROXY_HOST" ]; then
    # Configure Git proxy
    git config --global http.proxy "http://$PROXY_HOST:$PROXY_PORT"
    git config --global https.proxy "http://$PROXY_HOST:$PROXY_PORT"
    echo "✓ Git proxy configured: http://$PROXY_HOST:$PROXY_PORT"
    
    # Test the proxy configuration
    if test_git_connectivity; then
        echo "✓ Git connectivity test passed with proxy"
    else
        echo "❌ Git connectivity test failed even with proxy"
        echo "⚠ Removing proxy configuration and falling back to direct connection"
        git config --global --unset http.proxy 2>/dev/null || true
        git config --global --unset https.proxy 2>/dev/null || true
    fi
else
    echo "❌ No working proxy found and direct connection failed"
    echo "⚠ You may need to:"
    echo "  1. Start your proxy server on the host machine"
    echo "  2. Check your network connection"
    echo "  3. Verify firewall settings"
fi

echo "Git proxy setup completed."
