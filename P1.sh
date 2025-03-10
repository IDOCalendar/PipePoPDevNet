#!/bin/bash

# 🛠 Check if cron is installed; if not, install it
if ! command -v cron &> /dev/null; then
    echo "⚙️ Cron is not installed! Installing now..."
    sudo apt update -y && sudo apt install -y cron
    echo "✅ Cron installed successfully!"
else
    echo "✅ Cron is already installed."
fi

# 🛠 Check & Start Cron Manually If Not Running
if ! pgrep cron > /dev/null; then
    echo "🔄 Cron is not running! Starting cron..."
    sudo service cron start || sudo cron &
    echo "✅ Cron started successfully!"
else
    echo "✅ Cron is already running."
fi

# 🛠 Update & Upgrade System
echo "🔄 Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt list --upgradable
sudo apt-get update && sudo apt-get upgrade -y
echo "✅ System update and upgrade completed!"

# Paths
NODE_INFO_FILE=~/pipe-node/node_info.json
PUBKEY_FILE="/root/.pubkey"
REFERRAL_CODE="4bdd5692e072c6b9"  # Default referral code

# Detect system's total RAM (in GB)
TOTAL_RAM=$(free -g | awk '/^Mem:/ {print $2}')
RAM=$TOTAL_RAM  # Assign detected RAM
DISK=100        # Default Disk allocation

# Function to create node_info.json if it doesn't exist
create_node_info_file() {
    if [[ ! -f "$NODE_INFO_FILE" ]]; then
        echo "🔄 Creating node_info.json file..."
        mkdir -p "$(dirname "$NODE_INFO_FILE")"  # Ensure the directory exists
        cat <<EOF > "$NODE_INFO_FILE"
{
    "node_id": "",
    "registered": false,
    "token": ""
}
EOF
        echo "✅ node_info.json created!"
    else
        echo "✅ node_info.json already exists."
    fi
}

# Function to restore node_info.json from backup
restore_node_info() {
    read -p "🔄 Do you have a backup of node_info.json? (y/n): " RESTORE_CHOICE
    if [[ "$RESTORE_CHOICE" == "y" ]]; then
        read -p "📌 Enter your previous Node ID: " NODE_ID
        read -p "🔑 Enter your authentication token: " TOKEN

        # Save the restored info
        cat <<EOF > "$NODE_INFO_FILE"
{
    "node_id": "$NODE_ID",
    "registered": true,
    "token": "$TOKEN"
}
EOF
        echo "✅ Node info restored!"
    else
        echo "⏩ Skipping restoration. Using existing or empty node_info.json."
    fi
}

# Create node_info.json if it doesn't exist
create_node_info_file

# Check if node_info.json is empty or not configured
if [[ $(jq -e '.node_id == "" or .token == ""' "$NODE_INFO_FILE") == "true" ]]; then
    echo "⚙️ node_info.json is empty or not fully configured."
    restore_node_info  # Ask to restore from backup
else
    echo "✅ node_info.json is already configured."
fi

# Restore Public Key if it exists, otherwise ask user
if [[ -f "$PUBKEY_FILE" ]]; then
    PUBKEY=$(cat "$PUBKEY_FILE")
    echo -e "🔑 Using saved Solana wallet address: $PUBKEY"
else
    read -p "🔑 Enter your Solana wallet Address: " PUBKEY
    echo "$PUBKEY" | sudo tee "$PUBKEY_FILE" > /dev/null
    echo "✅ Public key saved for future use!"
fi

# Configuration Summary
echo -e "\n📌 Configuration Summary:"
echo "   🔢 RAM: ${RAM}GB (Auto-detected)"
echo "   💾 Disk: ${DISK}GB (default)"
echo "   🔑 PubKey: ${PUBKEY}"
echo -e "\n⚡ Proceeding with installation..."

# Update system
echo -e "\n🔄 Updating system packages..."
sudo apt update -y && sudo apt upgrade -y

# Install dependencies
echo -e "\n⚙️ Installing required dependencies..."
sudo apt install -y curl wget jq unzip screen cron

# Enable and start cron service (if not already running)
sudo systemctl enable cron
sudo systemctl start cron

# Create a directory for PiPe node
echo -e "\n📂 Setting up PiPe node directory..."
mkdir -p ~/pipe-node && cd ~/pipe-node

# Download the latest PiPe Network binary (pop)
echo -e "\n⬇️ Downloading PiPe Network node (pop)..."
curl -L -o pop "https://dl.pipecdn.app/v0.2.8/pop"

# Make binary executable
chmod +x pop

# Verify installation
echo -e "\n🔍 Verifying pop binary..."
./pop --version || { echo "❌ Error: pop binary is not working!"; exit 1; }

# Create download cache directory
echo -e "\n📂 Creating download cache directory..."
mkdir -p download_cache

# Sign up using the referral code (only if no existing node_info.json)
if [[ ! -f "$NODE_INFO_FILE" ]]; then
    echo -e "\n📌 Signing up for PiPe Network using referral..."
    ./pop --signup-by-referral-route "$REFERRAL_CODE"
    if [ $? -ne 0 ]; then
        echo "❌ Error: Signup failed!"
        exit 1
    fi
fi

# Check if pop is already running
if pgrep pop > /dev/null; then
    echo -e "\n✅ PiPe node is already running!"
else
    echo -e "\n🚀 Starting PiPe Network node..."
    sudo ./pop --ram "$RAM" --max-disk "$DISK" --cache-dir /data --pubKey "$PUBKEY" &
fi

# Save node information (if restored, it will keep previous values)
if [[ ! -f "$NODE_INFO_FILE" ]]; then
    echo -e "\n📜 Saving node information..."
    cat <<EOF > "$NODE_INFO_FILE"
{
    "node_id": "$(uuidgen)",
    "registered": true,
    "token": "your-generated-token"
}
EOF
    echo "✅ Node information saved! (nano ~/pipe-node/node_info.json to edit)"
fi

# Add a cron job to check and restart pop every 5 minutes
CRON_JOB="*/2 * * * * pgrep pop > /dev/null || (cd ~/pipe-node && sudo ./pop --ram $RAM --max-disk $DISK --cache-dir /data --pubKey \"\$(cat /root/.pubkey)\" &)"

# Check if cron job already exists, if not, add it
(crontab -l 2>/dev/null | grep -F "$CRON_JOB") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

# 📜 Display Node ID
if [[ -f "$NODE_INFO_FILE" ]]; then
    NODE_ID=$(jq -r '.node_id' "$NODE_INFO_FILE")
    echo -e "\n🎯 Your Node ID: $NODE_ID"
fi

# 🔄 Ask user if they want to backup their node_info.json
if [[ -f "$NODE_INFO_FILE" ]]; then
    read -p "💾 Do you want to back up your node_info.json? (y/n): " BACKUP_CHOICE
    if [[ "$BACKUP_CHOICE" == "y" ]]; then
        echo -e "\n📜 node_info.json Backup:"
        cat "$NODE_INFO_FILE"
        echo -e "\n✅ Backup completed! Save this information safely."
    fi
fi

echo -e "\n⏳ Checking PiPe node every 5 minutes!"
echo -e "\n✅ PiPe Node is now running in the background."
