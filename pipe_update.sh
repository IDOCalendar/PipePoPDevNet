#!/bin/bash

printf "\n"
cat <<EOF


░██████╗░░█████╗░  ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░
██╔════╝░██╔══██╗  ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗
██║░░██╗░███████║  ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║
██║░░╚██╗██╔══██║  ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║
╚██████╔╝██║░░██║  ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝
░╚═════╝░╚═╝░░╚═╝  ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░
EOF

printf "\n\n"

##########################################################################################
#                                                                                        
#                🚀 THIS SCRIPT IS PROUDLY CREATED BY **GA CRYPTO**! 🚀                  
#                                                                                        
#   🌐 Join our revolution in decentralized networks and crypto innovation!               
#                                                                                        
# 📢 Stay updated:                                                                      
#     • Follow us on Telegram: https://t.me/GaCryptOfficial                             
#     • Follow us on X: https://x.com/GACryptoO                                         
##########################################################################################

# Define colors
GREEN="\033[0;32m"
RESET="\033[0m"

# Print welcome message
printf "${GREEN}"
printf "🚀 THIS SCRIPT IS PROUDLY CREATED BY **GA CRYPTO**! 🚀\n"
printf "Stay connected for updates:\n"
printf "   • Telegram: https://t.me/GaCryptOfficial\n"
printf "   • X (formerly Twitter): https://x.com/GACryptoO\n"
printf "${RESET}"

echo "==========================================================="
echo "🚀  Welcome to the PiPe Network Node Installer 🚀"
echo "==========================================================="
echo ""
echo "🌟 Your journey to decentralized networks begins here!"
echo "✨ Follow the steps as the script runs automatically for you!"
echo ""

#!/bin/bash

# Paths
NODE_INFO_FILE=~/pipe-node/node_info.json
PUBKEY_FILE="/root/.pubkey"
REFERRAL_CODE="d95ee70dc79214c4"  # Default referral code
NODE_DIR=~/pipe-node
PIPE_STATUS_SCRIPT_URL="https://github.com/IDOCalendar/PipePoPDevNet/raw/refs/heads/main/pipe_status.sh"
PIPE_STATUS_SCRIPT="$NODE_DIR/pipe_status.sh"

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

# Function to display node_info.json for backup
backup_node_info() {
    if [[ -f "$NODE_INFO_FILE" ]]; then
        echo -e "\n📜 Contents of node_info.json (Copy and save this information):"
        cat "$NODE_INFO_FILE"
    else
        echo -e "\n❌ node_info.json not found! Please install the node first."
    fi
}

# Function to install the node
install_node() {
    echo -e "\n🔄 Updating system packages..."
    sudo apt update -y && sudo apt upgrade -y

    echo -e "\n⚙️ Installing required dependencies..."
    sudo apt install -y curl wget jq unzip screen cron

    echo -e "\n📂 Setting up PiPe node directory..."
    mkdir -p "$NODE_DIR" && cd "$NODE_DIR"

    echo -e "\n⬇️ Downloading PiPe Network node (pop)..."
    curl -L -o pop "https://dl.pipecdn.app/v0.2.8/pop"

    echo -e "\n🔧 Making binary executable..."
    chmod +x pop

    echo -e "\n🔍 Verifying pop binary..."
    ./pop --version || { echo "❌ Error: pop binary is not working!"; exit 1; }

    echo -e "\n📂 Creating download cache directory..."
    mkdir -p download_cache

    # Restore Public Key if it exists, otherwise ask user
    if [[ -f "$PUBKEY_FILE" ]]; then
        PUBKEY=$(cat "$PUBKEY_FILE")
        echo -e "🔑 Using saved Solana wallet address: $PUBKEY"
    else
        read -p "🔑 Enter your Solana wallet Address: " PUBKEY
        echo "$PUBKEY" | sudo tee "$PUBKEY_FILE" > /dev/null
        echo "✅ Public key saved for future use!"
    fi

    # Sign up using the referral code (only if no existing node_info.json)
    if [[ ! -f "$NODE_INFO_FILE" ]]; then
        echo -e "\n📌 Signing up for PiPe Network using referral..."
        ./pop --signup-by-referral-route "$REFERRAL_CODE"
        if [ $? -ne 0 ]; then
            echo "❌ Error: Signup failed!"
            exit 1
        fi
    fi

    echo -e "\n🚀 Starting PiPe Network node..."
    sudo ./pop --ram "$RAM" --max-disk "$DISK" --cache-dir /data --pubKey "$PUBKEY" &

    # Add a cron job to check and restart pop every 5 minutes
    CRON_JOB="*/2 * * * * pgrep pop > /dev/null || (cd $NODE_DIR && sudo ./pop --ram $RAM --max-disk $DISK --cache-dir /data --pubKey \"\$(cat /root/.pubkey)\" &)"
    (crontab -l 2>/dev/null | grep -F "$CRON_JOB") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

    echo -e "\n✅ PiPe Node installation and setup completed!"
}

# Function to stop the node
stop_node() {
    if pgrep pop > /dev/null; then
        echo -e "\n🛑 Stopping PiPe Network node..."
        sudo pkill pop
        echo "✅ PiPe Node stopped!"
    else
        echo -e "\n✅ PiPe Node is not running."
    fi
}

# Function to restart the node
restart_node() {
    stop_node
    echo -e "\n🔄 Restarting PiPe Network node..."
    cd "$NODE_DIR"
    sudo ./pop --ram "$RAM" --max-disk "$DISK" --cache-dir /data --pubKey "$PUBKEY" &
    echo "✅ PiPe Node restarted!"
}

# Function to check node status using pipe_status.sh
check_node_status() {
    echo -e "\n⬇️ Downloading pipe_status.sh script..."
    curl -L -o "$PIPE_STATUS_SCRIPT" "$PIPE_STATUS_SCRIPT_URL" || { echo "❌ Failed to download pipe_status.sh"; return 1; }
    chmod +x "$PIPE_STATUS_SCRIPT"

    echo -e "\n🔍 Checking PiPe Node status..."
    "$PIPE_STATUS_SCRIPT"
}

# Function to uninstall the node
uninstall_node() {
    echo -e "\n⚠️ Uninstalling PiPe Node..."
    stop_node
    rm -rf "$NODE_DIR"
    crontab -l | grep -v "pgrep pop" | crontab -
    echo "✅ PiPe Node uninstalled!"
}

# Main menu
while true; do

    echo "==============================================================="
    echo -e "\e[1;36m🚀🚀 PIPE NODE INSTALLER Tool-Kit BY GA-CRYPTO 🚀🚀\e[0m"
    echo "==============================================================="
    echo -e "\e[1;85m📢 Stay updated:\e[0m"
    echo -e "\e[1;85m🔹 Telegram: https://t.me/GaCryptOfficial\e[0m"
    echo -e "\e[1;85m🔹 X (Twitter): https://x.com/GACryptoO\e[0m"
    echo "==============================================================="

    echo -e "\n📋 PiPe Node Management Menu:"
    echo "1. Install PiPe Node"
    echo "2. Check Node Status"
    echo "3. Backup your Node Info"
    echo "4. Restore Your Node Info"
    echo "5. Uninstall PiPe Node"
    echo "6. Exit"
    read -p "🔢 Choose an option (1-6): " CHOICE

    case $CHOICE in
        1)
            install_node
            ;;
        2)
            check_node_status
            ;;
        3)
            backup_node_info
            ;;
        4)
            restore_node_info
            ;;
        5)
            check_node_status
            ;;
        6)
            echo -e "\n👋 Exiting..."
            exit 0
            ;;
        *)
            echo -e "\n❌ Invalid choice. Please try again."
            ;;
    esac
done
