#!/bin/bash

# Fiyuu KTDB Web Server - Ubuntu/Debian Installation Script
# Optimized for Ubuntu 20.04+ and Debian 11+

set -e

echo "🚀 Fiyuu KTDB Web Server - Ubuntu/Debian Installation"
echo "====================================================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Running as root user. Some operations will be adjusted for root execution."
    ROOT_USER=true
else
    ROOT_USER=false
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update system packages
echo "📦 Updating system packages..."
if [ "$ROOT_USER" = true ]; then
    apt-get update
    apt-get upgrade -y
else
    sudo apt-get update
    sudo apt-get upgrade -y
fi

# Install essential packages
echo "🛠️  Installing essential packages..."
if [ "$ROOT_USER" = true ]; then
    apt-get install -y \
        curl \
        wget \
        git \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        jq \
        unzip \
        htop \
        vim \
        nano
else
    sudo apt-get install -y \
        curl \
        wget \
        git \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        jq \
        unzip \
        htop \
        vim \
        nano
fi

# Install Go
echo "📦 Installing Go..."
if command_exists go; then
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    REQUIRED_VERSION="1.21"
    
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
        echo "✅ Go $GO_VERSION is already installed and meets requirements"
    else
        echo "⚠️  Go $GO_VERSION is installed but version is too old. Upgrading..."
        install_go=true
    fi
else
    echo "📥 Go is not installed. Installing..."
    install_go=true
fi

if [ "$install_go" = true ]; then
    GO_VERSION="1.21.5"
    ARCH=$(uname -m)
    
    case $ARCH in
        x86_64)
            GO_ARCH="amd64"
            ;;
        arm64|aarch64)
            GO_ARCH="arm64"
            ;;
        *)
            echo "❌ Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    echo "📥 Downloading Go $GO_VERSION for $GO_ARCH..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download Go
    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    
    # Remove old Go installation if exists
    if [ -d "/usr/local/go" ]; then
        echo "🗑️  Removing old Go installation..."
        if [ "$ROOT_USER" = true ]; then
            rm -rf /usr/local/go
        else
            sudo rm -rf /usr/local/go
        fi
    fi
    
    # Install Go
    echo "📦 Installing Go..."
    if [ "$ROOT_USER" = true ]; then
        tar -C /usr/local -xzf "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    else
        sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    fi
    
    # Add Go to PATH if not already there
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo "🔧 Adding Go to PATH..."
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        echo 'export GOPATH=$HOME/go' >> ~/.bashrc
        echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
    fi
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    echo "✅ Go installation completed!"
fi

# Install SQL Server tools
echo "🗄️  Installing SQL Server tools..."
if [ ! -f "/etc/apt/sources.list.d/mssql-release.list" ]; then
    echo "📥 Adding Microsoft SQL Server repository..."
    if [ "$ROOT_USER" = true ]; then
        curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
        curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | tee /etc/apt/sources.list.d/mssql-release.list
        apt-get update
    else
        curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
        curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
        sudo apt-get update
    fi
fi

# Install SQL Server tools
echo "📦 Installing SQL Server command line tools..."
if [ "$ROOT_USER" = true ]; then
    ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev
else
    sudo ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev
fi

# Add SQL Server tools to PATH
if ! grep -q "/opt/mssql-tools/bin" ~/.bashrc; then
    echo "🔧 Adding SQL Server tools to PATH..."
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
fi

# Install Docker (optional)
echo "🐳 Installing Docker (optional)..."
if ! command_exists docker; then
    echo "📥 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    if [ "$ROOT_USER" = true ]; then
        sh get-docker.sh
        echo "✅ Docker installation completed!"
        echo "ℹ️  Docker installed for root user"
    else
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        echo "✅ Docker installation completed!"
        echo "⚠️  Please log out and log back in to use Docker without sudo"
    fi
    rm get-docker.sh
else
    echo "✅ Docker is already installed"
fi

# Install Docker Compose (optional)
echo "🐳 Installing Docker Compose (optional)..."
if ! command_exists docker-compose; then
    echo "📥 Installing Docker Compose..."
    if [ "$ROOT_USER" = true ]; then
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    echo "✅ Docker Compose installation completed!"
else
    echo "✅ Docker Compose is already installed"
fi

# Install Prometheus (native)
echo "📊 Installing Prometheus (native)..."
if ! command_exists prometheus; then
    echo "📥 Downloading Prometheus..."
    PROMETHEUS_VERSION="2.47.0"
    ARCH=$(uname -m)
    
    case $ARCH in
        x86_64)
            PROMETHEUS_ARCH="amd64"
            ;;
        arm64|aarch64)
            PROMETHEUS_ARCH="arm64"
            ;;
        *)
            echo "❌ Unsupported architecture for Prometheus: $ARCH"
            exit 1
            ;;
    esac
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    wget -q "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-${PROMETHEUS_ARCH}.tar.gz"
    tar -xzf "prometheus-${PROMETHEUS_VERSION}.linux-${PROMETHEUS_ARCH}.tar.gz"
    
    # Install Prometheus
    if [ "$ROOT_USER" = true ]; then
        mkdir -p /opt/prometheus
        cp prometheus-${PROMETHEUS_VERSION}.linux-${PROMETHEUS_ARCH}/prometheus /opt/prometheus/
        cp prometheus-${PROMETHEUS_VERSION}.linux-${PROMETHEUS_ARCH}/promtool /opt/prometheus/
        cp -r prometheus-${PROMETHEUS_VERSION}.linux-${PROMETHEUS_ARCH}/consoles /opt/prometheus/
        cp -r prometheus-${PROMETHEUS_VERSION}.linux-${PROMETHEUS_ARCH}/console_libraries /opt/prometheus/
        
        # Create symlinks
        ln -sf /opt/prometheus/prometheus /usr/local/bin/prometheus
        ln -sf /opt/prometheus/promtool /usr/local/bin/promtool
        
        # Create prometheus user
        useradd --no-create-home --shell /bin/false prometheus || true
        chown -R prometheus:prometheus /opt/prometheus
    else
        sudo mkdir -p /opt/prometheus
        sudo cp prometheus-${PROMETHEUS_VERSION}.linux-${PROMETHEUS_ARCH}/prometheus /opt/prometheus/
        sudo cp prometheus-${PROMETHEUS_VERSION}.linux-${PROMETHEUS_ARCH}/promtool /opt/prometheus/
        sudo cp -r prometheus-${PROMETHEUS_VERSION}.linux-${PROMETHEUS_ARCH}/consoles /opt/prometheus/
        sudo cp -r prometheus-${PROMETHEUS_VERSION}.linux-${PROMETHEUS_ARCH}/console_libraries /opt/prometheus/
        
        # Create symlinks
        sudo ln -sf /opt/prometheus/prometheus /usr/local/bin/prometheus
        sudo ln -sf /opt/prometheus/promtool /usr/local/bin/promtool
        
        # Create prometheus user
        sudo useradd --no-create-home --shell /bin/false prometheus || true
        sudo chown -R prometheus:prometheus /opt/prometheus
    fi
    
    # Create systemd service for Prometheus
    if [ "$ROOT_USER" = true ]; then
        tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/opt/prometheus/prometheus \\
    --config.file=/etc/prometheus/prometheus.yml \\
    --storage.tsdb.path=/var/lib/prometheus/ \\
    --web.console.templates=/opt/prometheus/consoles \\
    --web.console.libraries=/opt/prometheus/console_libraries \\
    --web.listen-address=0.0.0.0:9090 \\
    --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF
    else
        sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/opt/prometheus/prometheus \\
    --config.file=/etc/prometheus/prometheus.yml \\
    --storage.tsdb.path=/var/lib/prometheus/ \\
    --web.console.templates=/opt/prometheus/consoles \\
    --web.console.libraries=/opt/prometheus/console_libraries \\
    --web.listen-address=0.0.0.0:9090 \\
    --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    # Create directories
    if [ "$ROOT_USER" = true ]; then
        mkdir -p /etc/prometheus
        mkdir -p /var/lib/prometheus
        chown -R prometheus:prometheus /var/lib/prometheus
        chown -R prometheus:prometheus /etc/prometheus
    else
        sudo mkdir -p /etc/prometheus
        sudo mkdir -p /var/lib/prometheus
        sudo chown -R prometheus:prometheus /var/lib/prometheus
        sudo chown -R prometheus:prometheus /etc/prometheus
    fi
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    echo "✅ Prometheus installation completed!"
else
    echo "✅ Prometheus is already installed"
fi

# Install Grafana (native)
echo "📈 Installing Grafana (native)..."
if ! command_exists grafana-server; then
    echo "📥 Adding Grafana repository..."
    if [ "$ROOT_USER" = true ]; then
        wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
        echo "deb https://packages.grafana.com/oss/deb stable main" | tee /etc/apt/sources.list.d/grafana.list
        apt-get update
        
        echo "📦 Installing Grafana..."
        apt-get install -y grafana
        
        # Enable and start Grafana
        systemctl enable grafana-server
        systemctl start grafana-server
    else
        wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
        echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
        sudo apt-get update
        
        echo "📦 Installing Grafana..."
        sudo apt-get install -y grafana
        
        # Enable and start Grafana
        sudo systemctl enable grafana-server
        sudo systemctl start grafana-server
    fi
    
    echo "✅ Grafana installation completed!"
else
    echo "✅ Grafana is already installed"
fi

# Create environment file
echo "📄 Creating environment configuration file..."
if [ ! -f ".env" ]; then
    cp env.example .env
    echo "✅ Created .env file from template"
    echo "⚠️  Please edit .env file with your database credentials"
else
    echo "✅ .env file already exists"
fi

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x run.sh
chmod +x install.sh
chmod +x install-ubuntu.sh

# Create systemd service file (optional)
echo "⚙️  Creating systemd service file..."
if [ "$ROOT_USER" = true ]; then
    tee /etc/systemd/system/fiyuu-ktdb.service > /dev/null <<EOF
[Unit]
Description=Fiyuu KTDB Web Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
Environment=PATH=/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=GOPATH=$HOME/go
ExecStart=$(pwd)/fiyuu-ktdb
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    echo "✅ Systemd service file created at /etc/systemd/system/fiyuu-ktdb.service"
else
    sudo tee /etc/systemd/system/fiyuu-ktdb.service > /dev/null <<EOF
[Unit]
Description=Fiyuu KTDB Web Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
Environment=PATH=/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=GOPATH=$HOME/go
ExecStart=$(pwd)/fiyuu-ktdb
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    echo "✅ Systemd service file created at /etc/systemd/system/fiyuu-ktdb.service"
fi

echo ""
echo "🎉 Installation completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Reload your shell environment:"
echo "   source ~/.bashrc"
echo ""
echo "2. Edit .env file with your database credentials:"
echo "   nano .env"
echo ""
echo "3. Set your database password:"
echo "   export DB_PASSWORD='your_password_here'"
echo ""
echo "4. Download dependencies and build:"
echo "   go mod download"
echo "   go build -o fiyuu-ktdb ."
echo ""
echo "5. Run the application:"
echo "   ./run.sh"
echo ""
echo "6. Or run manually:"
echo "   ./fiyuu-ktdb"
echo ""
echo "🔗 Useful endpoints:"
echo "   Health Check: http://localhost:8080/api/v1/health"
echo "   Default Query: http://localhost:8080/api/v1/query"
echo "   Database Info: http://localhost:8080/api/v1/db/info"
echo "   Prometheus Metrics: http://localhost:8080/metrics"
echo "   Prometheus UI: http://localhost:9090"
echo "   Grafana Dashboard: http://localhost:3000 (admin/admin)"
echo ""
echo "⚙️  Systemd service commands:"
echo "   sudo systemctl enable fiyuu-ktdb    # Enable auto-start"
echo "   sudo systemctl start fiyuu-ktdb     # Start service"
echo "   sudo systemctl status fiyuu-ktdb    # Check status"
echo "   sudo systemctl stop fiyuu-ktdb      # Stop service"
echo ""
echo "📊 Monitoring services:"
echo "   sudo systemctl enable prometheus    # Enable Prometheus"
echo "   sudo systemctl start prometheus     # Start Prometheus"
echo "   sudo systemctl enable grafana-server # Enable Grafana"
echo "   sudo systemctl start grafana-server  # Start Grafana"
echo ""
echo "📚 For more information, see README-SERVER.md"
