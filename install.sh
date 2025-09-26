#!/bin/bash

# Fiyuu KTDB Web Server - Installation Script
# This script installs all required packages and dependencies

set -e

echo "🚀 Fiyuu KTDB Web Server Installation Script"
echo "=============================================="

# Detect operating system
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    echo "❌ Unsupported operating system: $OSTYPE"
    exit 1
fi

echo "🖥️  Detected OS: $OS"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Go on Linux
install_go_linux() {
    echo "📦 Installing Go on Linux..."
    
    # Check if Go is already installed
    if command_exists go; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        REQUIRED_VERSION="1.21"
        
        if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
            echo "✅ Go $GO_VERSION is already installed and meets requirements"
            return 0
        else
            echo "⚠️  Go $GO_VERSION is installed but version is too old. Upgrading..."
        fi
    fi
    
    # Download and install Go
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
        sudo rm -rf /usr/local/go
    fi
    
    # Install Go
    echo "📦 Installing Go..."
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    
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
    echo "⚠️  Please run 'source ~/.bashrc' or restart your terminal to use Go"
}

# Function to install Go on macOS
install_go_macos() {
    echo "📦 Installing Go on macOS..."
    
    # Check if Homebrew is installed
    if ! command_exists brew; then
        echo "🍺 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install Go using Homebrew
    echo "📦 Installing Go using Homebrew..."
    brew install go
    
    echo "✅ Go installation completed!"
}

# Function to install SQL Server tools on Linux
install_sqlserver_tools_linux() {
    echo "🗄️  Installing SQL Server tools on Linux..."
    
    # Add Microsoft repository
    if [ ! -f "/etc/apt/sources.list.d/mssql-release.list" ]; then
        echo "📥 Adding Microsoft SQL Server repository..."
        curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
        curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
    fi
    
    # Update package list
    sudo apt-get update
    
    # Install SQL Server tools
    echo "📦 Installing SQL Server command line tools..."
    sudo ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev
    
    # Add SQL Server tools to PATH
    if ! grep -q "/opt/mssql-tools/bin" ~/.bashrc; then
        echo "🔧 Adding SQL Server tools to PATH..."
        echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
    fi
    
    echo "✅ SQL Server tools installation completed!"
}

# Function to install SQL Server tools on macOS
install_sqlserver_tools_macos() {
    echo "🗄️  Installing SQL Server tools on macOS..."
    
    # Install using Homebrew
    brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
    brew update
    brew install mssql-tools
    
    echo "✅ SQL Server tools installation completed!"
}

# Function to install additional tools
install_additional_tools() {
    echo "🛠️  Installing additional tools..."
    
    if [ "$OS" = "linux" ]; then
        # Install curl, wget, git if not present
        sudo apt-get update
        sudo apt-get install -y curl wget git build-essential
        
        # Install jq for JSON processing
        sudo apt-get install -y jq
        
    elif [ "$OS" = "macos" ]; then
        # Install using Homebrew
        brew install curl wget git jq
    fi
    
    echo "✅ Additional tools installation completed!"
}

# Function to create environment file
create_env_file() {
    echo "📄 Creating environment configuration file..."
    
    if [ ! -f ".env" ]; then
        cp env.example .env
        echo "✅ Created .env file from template"
        echo "⚠️  Please edit .env file with your database credentials"
    else
        echo "✅ .env file already exists"
    fi
}

# Function to make scripts executable
make_scripts_executable() {
    echo "🔧 Making scripts executable..."
    chmod +x run.sh
    chmod +x install.sh
    echo "✅ Scripts are now executable"
}

# Main installation process
main() {
    echo "🔍 Checking system requirements..."
    
    # Install Go
    if [ "$OS" = "linux" ]; then
        install_go_linux
    elif [ "$OS" = "macos" ]; then
        install_go_macos
    fi
    
    # Install SQL Server tools
    if [ "$OS" = "linux" ]; then
        install_sqlserver_tools_linux
    elif [ "$OS" = "macos" ]; then
        install_sqlserver_tools_macos
    fi
    
    # Install additional tools
    install_additional_tools
    
    # Create environment file
    create_env_file
    
    # Make scripts executable
    make_scripts_executable
    
    echo ""
    echo "🎉 Installation completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Edit .env file with your database credentials:"
    echo "   nano .env"
    echo ""
    echo "2. Set your database password:"
    echo "   export DB_PASSWORD='your_password_here'"
    echo ""
    echo "3. Run the application:"
    echo "   ./run.sh"
    echo ""
    echo "4. Or run manually:"
    echo "   go mod download"
    echo "   go build -o fiyuu-ktdb ."
    echo "   ./fiyuu-ktdb"
    echo ""
    echo "🔗 Useful endpoints:"
    echo "   Health Check: http://localhost:8080/api/v1/health"
    echo "   Default Query: http://localhost:8080/api/v1/query"
    echo "   Database Info: http://localhost:8080/api/v1/db/info"
    echo ""
    echo "📚 For more information, see README-SERVER.md"
}

# Run main function
main "$@"
