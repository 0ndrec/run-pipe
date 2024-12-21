#!/bin/bash

# Function to prompt for user input with a default value
prompt() {
    local PROMPT_TEXT=$1
    local DEFAULT_VALUE=$2
    read -p "$PROMPT_TEXT [$DEFAULT_VALUE]: " INPUT
    echo "${INPUT:-$DEFAULT_VALUE}"
}

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (e.g., use 'sudo')."
    exit 1
fi

# Default installation directory
DCDN_DIR="/opt/dcdn"
VERSION="v0.1.3"
PIPE_URL="https://dl.pipecdn.app/$VERSION/pipe-tool"
DCDND_URL="https://dl.pipecdn.app/$VERSION/dcdnd"


create_directory() {
    DCDN_DIR=$(prompt "Enter the directory to install dcdn" "$DCDN_DIR")
    if [ -d "$DCDN_DIR" ]; then
        echo "Directory $DCDN_DIR already exists."
        return
    fi
    mkdir -p "$DCDN_DIR"
    echo "Directory $DCDN_DIR created."
}

# Function to download pipe-tool binary
download_binaries() {

    if [ -f "$DCDN_DIR/pipe-tool" ]; then
        mv "$DCDN_DIR/pipe-tool" "$DCDN_DIR/pipe-tool.old"
    fi

    if [ -f "$DCDN_DIR/dcdnd" ]; then
        mv "$DCDN_DIR/dcdnd" "$DCDN_DIR/dcdnd.old"
    fi

    curl -L "$PIPE_URL" -o "$DCDN_DIR/pipe-tool"
    curl -L "$DCDND_URL" -o "$DCDN_DIR/dcdnd"

    chmod +x "$DCDN_DIR/pipe-tool"
    chmod +x "$DCDN_DIR/dcdnd"
    echo "pipe-tool and dcdnd downloaded."
}


# Function to set up systemd service
setup_systemd_service() {
    SERVICE_FILE="/etc/systemd/system/dcdnd.service"
    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Pipe Network dcdnd Node
After=network.target

[Service]
ExecStart=$DCDN_DIR/dcdnd
Restart=always
User=$(whoami)
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable dcdnd
    systemctl start dcdnd
    echo "dcdnd service started and enabled on boot."
}

# Function to configure firewall
configure_firewall() {
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 8600/tcp
    ufw allow 8600/udp
    echo "Ports 80, 443, and 8600 opened for TCP and UDP."
}

add_to_path() {
    # permanently add to path two binaries
    PATH="$DCDN_DIR:$PATH"
    echo "export PATH=$PATH" >> ~/.profile
    source ~/.profile
}

# Main menu function
main_menu() {
    while true; do
        echo "----------------------------------"
        echo "Pipe Network DevNet CDN Setup Menu"
        echo "----------------------------------"
        echo "1. Create Installation Directory"
        echo "2. Download Binaries"
        echo "3. Configure Firewall"
        echo "4. Add to Path"
        echo "5. Setup systemd service"
        echo "6. Exit"
        read -p "Enter your choice (1-6): " choice

        case $choice in
            1) create_directory ;;
            2) download_binaries ;;
            3) configure_firewall ;;
            4) add_to_path ;;
            5) setup_systemd_service ;;
            6) break ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}

# Call the main menu function
main_menu
