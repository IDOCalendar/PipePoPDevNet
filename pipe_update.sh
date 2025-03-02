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

# Detect system's total RAM (in GB)
TOTAL_RAM=$(free -g | awk '/^Mem:/ {print $2}')
RAM=$TOTAL_RAM  # Assign detected RAM

# Set default Disk allocation
DISK=100
PUBKEY_FILE="/root/.pubkey"
REFERRAL_CODE="4bdd5692e072c6b9"  # Default referral code

# Check if the public key file exists
if [[ -f "$PUBKEY_FILE" ]]; then
    PUBKEY=$(cat "$PUBKEY_FILE")
    echo -e "🔑 Using saved Solana wallet address: $PUBKEY"
else
    read -p "🔑 Enter your Solana wallet Address: " PUBKEY
    echo "$PUBKEY" | sudo tee "$PUBKEY_FILE" > /dev/null
    echo -e "✅ Public key saved for future use!"
fi

# Configuration Summary
echo -e "\n📌 Configuration Summary:"
echo "   🔢 RAM: ${RAM}GB (Auto-detected)"
echo "   💾 Disk: ${DISK}GB (default)"
echo "   🔑 PubKey: ${PUBKEY}"
echo "   ✅ Using Referral Code: $REFERRAL_CODE (default enforced)"
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

# Sign up using the referral code
echo -e "\n📌 Signing up for PiPe Network using referral..."
./pop --signup-by-referral-route "$REFERRAL_CODE"
if [ $? -ne 0 ]; then
    echo "❌ Error: Signup failed!"
    exit 1
fi

# Check if pop is already running
if pgrep pop > /dev/null; then
    echo -e "\n✅ PiPe node is already running!"
else
    echo -e "\n🚀 Starting PiPe Network node..."
    sudo ./pop --ram "$RAM" --max-disk "$DISK" --cache-dir /data --pubKey "$PUBKEY" &
fi

# Save node information
echo -e "\n📜 Saving node information..."
cat <<EOF > ~/node_info.json
{
    "RAM": "$RAM",
    "Disk": "$DISK",
    "PubKey": "$PUBKEY",
    "Referral": "$REFERRAL_CODE"
}
EOF

echo -e "\n✅ Node information saved! (nano ~/node_info.json to edit)"

# Add a cron job to check and restart pop every 5 minutes
CRON_JOB="*/5 * * * * pgrep pop > /dev/null || (cd ~/pipe-node && sudo ./pop --ram $RAM --max-disk $DISK --cache-dir /data --pubKey \"\$(cat /root/.pubkey)\" &)"

# Check if cron job already exists, if not, add it
(crontab -l 2>/dev/null | grep -F "$CRON_JOB") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo -e "\n⏳ Cron job added to check PiPe node every 5 minutes!"
echo -e "\n✅ PiPe Node is now running in the background."

