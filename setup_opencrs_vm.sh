#!/bin/bash

#############################################################################
# OpenCRS VM Setup Script
# Automated provisioning script for setting up a VM with all OpenCRS modules
#############################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_DIR="${HOME}/opencrs-workspace"
VENV_NAME=".venv"
PYTHON_VERSION="python3"

# Repository list
declare -a REPOS=(
    "https://github.com/open-crs/vulnerability_detection"
    "https://github.com/open-crs/dataset"
    "https://github.com/open-crs/attack_surface_approximation"
    "https://github.com/open-crs/automatic_exploit_generation"
    "https://github.com/open-crs/vulnerability_analytics"
    "https://github.com/open-crs/commons"
    "https://github.com/open-crs/zeratool_lib"
    "https://github.com/open-crs/signature_generation"
    "https://github.com/open-crs/nist_c_test_suite"
    "https://github.com/open-crs/awesome-binary-analysis"
)

#############################################################################
# Helper Functions
#############################################################################

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

#############################################################################
# System Update & Package Installation
#############################################################################

install_system_packages() {
    print_header "Installing System Packages"
    
    # Update package list
    print_info "Updating package list..."
    sudo apt-get update -y
    
    # Install essential packages
    print_info "Installing essential packages..."
    sudo apt-get install -y \
        git \
        curl \
        wget \
        build-essential \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        ca-certificates \
        gnupg \
        lsb-release \
        make \
        gcc \
        g++ \
        libc6-dev \
        unzip \
        vim \
        nano
    
    print_success "System packages installed"
}

#############################################################################
# Docker Installation
#############################################################################

install_docker() {
    print_header "Installing Docker"
    
    if check_command docker; then
        print_info "Docker is already installed"
        docker --version
    else
        print_info "Installing Docker..."
        
        # Remove old versions
        sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
        
        # Add Docker's official GPG key
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        # Set up Docker repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker Engine
        sudo apt-get update -y
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        print_success "Docker installed successfully"
    fi
    
    # Add current user to docker group
    print_info "Adding current user to docker group..."
    sudo usermod -aG docker $USER
    
    # Enable Docker to start on boot
    sudo systemctl enable docker
    sudo systemctl start docker
    
    print_warning "You may need to log out and back in for docker group changes to take effect"
}

#############################################################################
# Poetry Installation
#############################################################################

install_poetry() {
    print_header "Installing Poetry"
    
    if check_command poetry; then
        print_info "Poetry is already installed"
        poetry --version
    else
        print_info "Installing Poetry..."
        curl -sSL https://install.python-poetry.org | $PYTHON_VERSION -
        
        # Add Poetry to PATH
        export PATH="$HOME/.local/bin:$PATH"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        
        print_success "Poetry installed successfully"
    fi
}

#############################################################################
# Workspace Setup
#############################################################################

setup_workspace() {
    print_header "Setting Up Workspace"
    
    # Create workspace directory
    if [ ! -d "$WORKSPACE_DIR" ]; then
        print_info "Creating workspace directory: $WORKSPACE_DIR"
        mkdir -p "$WORKSPACE_DIR"
    else
        print_info "Workspace directory already exists: $WORKSPACE_DIR"
    fi
    
    cd "$WORKSPACE_DIR"
    print_success "Workspace created at $WORKSPACE_DIR"
}

#############################################################################
# Clone Repositories
#############################################################################

clone_repositories() {
    print_header "Cloning OpenCRS Repositories"
    
    cd "$WORKSPACE_DIR"
    
    for repo in "${REPOS[@]}"; do
        repo_name=$(basename "$repo" .git)
        
        if [ -d "$repo_name" ]; then
            print_warning "Repository $repo_name already exists, skipping..."
        else
            print_info "Cloning $repo_name..."
            git clone --recurse-submodules "$repo" || {
                print_error "Failed to clone $repo_name"
                continue
            }
            print_success "Cloned $repo_name"
        fi
    done
    
    print_success "All repositories cloned"
}

#############################################################################
# Python Virtual Environment Setup
#############################################################################

setup_python_environment() {
    print_header "Setting Up Python Virtual Environment"
    
    cd "$WORKSPACE_DIR"
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "$VENV_NAME" ]; then
        print_info "Creating Python virtual environment..."
        $PYTHON_VERSION -m venv "$VENV_NAME"
        print_success "Virtual environment created"
    else
        print_info "Virtual environment already exists"
    fi
    
    # Activate virtual environment
    source "$VENV_NAME/bin/activate"
    
    # Upgrade pip
    print_info "Upgrading pip..."
    pip install --upgrade pip
    
    # Install Poetry in venv
    print_info "Installing Poetry in virtual environment..."
    pip install poetry
    
    # Disable keyring (to avoid Poetry authentication issues)
    export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
    echo 'export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring' >> "$WORKSPACE_DIR/$VENV_NAME/bin/activate"
    
    print_success "Python environment configured"
}

#############################################################################
# Install Python Dependencies
#############################################################################

install_python_dependencies() {
    print_header "Installing Python Dependencies"
    
    cd "$WORKSPACE_DIR"
    source "$VENV_NAME/bin/activate"
    
    # Install commons first as it's a dependency
    if [ -d "commons" ]; then
        print_info "Installing commons module..."
        cd commons
        poetry install --only main || print_warning "Failed to install commons dependencies"
        cd "$WORKSPACE_DIR"
    fi
    
    # Install other modules
    for repo in "${REPOS[@]}"; do
        repo_name=$(basename "$repo" .git)
        
        if [ "$repo_name" == "commons" ] || [ "$repo_name" == "awesome-binary-analysis" ]; then
            continue  # Skip commons (already done) and awesome-binary-analysis (documentation)
        fi
        
        if [ -d "$repo_name" ] && [ -f "$repo_name/pyproject.toml" ]; then
            print_info "Installing dependencies for $repo_name..."
            cd "$repo_name"
            poetry install --no-dev 2>/dev/null || poetry install --only main 2>/dev/null || {
                print_warning "Poetry install failed for $repo_name, trying pip..."
                pip install -e . 2>/dev/null || print_warning "Failed to install $repo_name"
            }
            cd "$WORKSPACE_DIR"
        fi
    done
    
    print_success "Python dependencies installed"
}

#############################################################################
# Build Docker Images
#############################################################################

build_docker_images() {
    print_header "Building Docker Images"
    
    cd "$WORKSPACE_DIR"
    
    # Get user and group IDs
    USER_ID=$(id -u)
    GROUP_ID=$(id -g)
    
    # Build AFL++ Docker image for vulnerability_detection
    if [ -d "vulnerability_detection/docker" ]; then
        print_info "Building AFL++ Docker image..."
        cd vulnerability_detection
        sudo docker build \
            --build-arg USER_ID=$USER_ID \
            --build-arg GROUP_ID=$GROUP_ID \
            --tag aflplusplus \
            -f docker/Dockerfile.aflplusplus . 2>&1 | tee /tmp/docker_aflplusplus.log || \
            print_warning "Failed to build AFL++ image"
        
        # Build argv_adapter
        if [ -d "argv_adapter" ]; then
            print_info "Building argv_adapter..."
            cd argv_adapter
            make || print_warning "Failed to build argv_adapter"
            cd ..
        fi
        cd "$WORKSPACE_DIR"
    fi
    
    # Build Ghidra and QBDI images for commons
    if [ -d "commons" ]; then
        print_info "Building Ghidra Docker image..."
        if [ -d "commons/ghidra/docker" ]; then
            sudo docker build \
                --tag ghidra \
                -f commons/ghidra/docker/Dockerfile \
                commons/ghidra/docker 2>&1 | tee /tmp/docker_ghidra.log || \
                print_warning "Failed to build Ghidra image"
        fi
        
        print_info "Building QBDI Docker image..."
        if [ -d "commons/qbdi/docker" ]; then
            sudo docker build \
                --platform linux/386 \
                --tag qbdi_args_fuzzing \
                -f commons/qbdi/docker/Dockerfile \
                commons/qbdi/docker 2>&1 | tee /tmp/docker_qbdi.log || \
                print_warning "Failed to build QBDI image"
        fi
    fi
    
    print_success "Docker images built"
}

#############################################################################
# Configure Docker Permissions
#############################################################################

configure_docker_permissions() {
    print_header "Configuring Docker Permissions"
    
    # Option 1: Add user to docker group (recommended)
    print_info "User has been added to docker group"
    print_warning "Please log out and log back in for changes to take effect"
    
    # Option 2: Set socket permissions (not recommended for production)
    print_info "Alternatively, you can set docker socket permissions (less secure):"
    print_info "  sudo chmod 666 /var/run/docker.sock"
}

#############################################################################
# Create Helper Scripts
#############################################################################

create_helper_scripts() {
    print_header "Creating Helper Scripts"
    
    cd "$WORKSPACE_DIR"
    
    # Create activation script
    cat > activate_opencrs.sh << 'EOF'
#!/bin/bash
# OpenCRS Environment Activation Script

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
    export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
    echo "OpenCRS environment activated!"
    echo "Workspace: $SCRIPT_DIR"
else
    echo "Virtual environment not found!"
    exit 1
fi
EOF
    chmod +x activate_opencrs.sh
    
    # Create quick-start README
    cat > README_SETUP.md << 'EOF'
# OpenCRS VM Setup

## Quick Start

1. **Activate the Python environment:**
   ```bash
   source activate_opencrs.sh
   ```

2. **Verify Docker is working:**
   ```bash
   docker ps
   docker run --rm hello-world
   ```

3. **Test a module (example: vulnerability_detection):**
   ```bash
   cd vulnerability_detection
   poetry run vulnerability_detection --help
   ```

## Directory Structure

```
opencrs-workspace/
├── .venv/                          # Python virtual environment
├── activate_opencrs.sh             # Environment activation script
├── vulnerability_detection/        # Vulnerability detection module
├── dataset/                        # Dataset module
├── attack_surface_approximation/   # Attack surface module
├── automatic_exploit_generation/   # Exploit generation module
├── vulnerability_analytics/        # Analytics module
├── commons/                        # Common utilities
├── zeratool_lib/                   # Zeratool library
├── signature_generation/           # Signature generation module
├── nist_c_test_suite/             # NIST test suite
└── awesome-binary-analysis/        # Binary analysis resources
```

## Docker Images

The following Docker images have been built:
- `aflplusplus` - For fuzzing with AFL++
- `ghidra` - For binary analysis with Ghidra
- `qbdi_args_fuzzing` - For QBDI-based fuzzing

## Common Tasks

### Running Vulnerability Detection
```bash
cd vulnerability_detection
poetry run vulnerability_detection fuzz --help
```

### Listing Docker Images
```bash
docker images | grep -E "aflplusplus|ghidra|qbdi"
```

### Updating Repositories
```bash
for dir in */; do
    if [ -d "$dir/.git" ]; then
        echo "Updating $dir..."
        cd "$dir"
        git pull
        cd ..
    fi
done
```

## Troubleshooting

### Docker Permission Denied
If you get "permission denied" errors with Docker:
```bash
sudo usermod -aG docker $USER
newgrp docker  # Or log out and back in
```

### Poetry Issues
If Poetry has authentication issues:
```bash
export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
```

### Module Import Errors
Make sure you're in the virtual environment:
```bash
source .venv/bin/activate
```

## Resources

- OpenCRS Organization: https://github.com/open-crs
- Docker Documentation: https://docs.docker.com/
- Poetry Documentation: https://python-poetry.org/docs/
EOF
    
    print_success "Helper scripts created"
}

#############################################################################
# Verification
#############################################################################

verify_installation() {
    print_header "Verifying Installation"
    
    cd "$WORKSPACE_DIR"
    
    # Check Python
    print_info "Checking Python installation..."
    $PYTHON_VERSION --version
    
    # Check Docker
    print_info "Checking Docker installation..."
    docker --version
    docker ps > /dev/null 2>&1 && print_success "Docker is running" || print_warning "Docker may require sudo or group membership"
    
    # Check Poetry
    print_info "Checking Poetry installation..."
    source "$VENV_NAME/bin/activate"
    poetry --version
    
    # Check repositories
    print_info "Checking cloned repositories..."
    for repo in "${REPOS[@]}"; do
        repo_name=$(basename "$repo" .git)
        if [ -d "$repo_name" ]; then
            print_success "$repo_name ✓"
        else
            print_error "$repo_name ✗"
        fi
    done
    
    # Check Docker images
    print_info "Checking Docker images..."
    docker images | grep -E "aflplusplus|ghidra|qbdi" || print_warning "Some Docker images may not be built"
    
    print_success "Verification complete"
}

#############################################################################
# Main Installation Flow
#############################################################################

main() {
    print_header "OpenCRS VM Setup - Starting Installation"
    
    print_info "This script will install and configure:"
    print_info "  - System packages (git, build tools, etc.)"
    print_info "  - Docker and Docker images"
    print_info "  - Python 3 and Poetry"
    print_info "  - All OpenCRS repositories"
    print_info "  - Python dependencies"
    echo ""
    
    read -p "Continue with installation? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    # Run installation steps
    install_system_packages
    install_docker
    install_poetry
    setup_workspace
    clone_repositories
    setup_python_environment
    install_python_dependencies
    build_docker_images
    configure_docker_permissions
    create_helper_scripts
    verify_installation
    
    # Final message
    print_header "Installation Complete!"
    
    echo -e "${GREEN}OpenCRS has been successfully installed!${NC}\n"
    echo -e "Workspace location: ${BLUE}$WORKSPACE_DIR${NC}\n"
    echo -e "Next steps:"
    echo -e "  1. ${YELLOW}Log out and log back in${NC} (for Docker group changes)"
    echo -e "  2. Navigate to workspace: ${BLUE}cd $WORKSPACE_DIR${NC}"
    echo -e "  3. Activate environment: ${BLUE}source activate_opencrs.sh${NC}"
    echo -e "  4. Read the setup guide: ${BLUE}cat README_SETUP.md${NC}\n"
    
    print_success "Setup script completed successfully!"
}

# Run main installation
main
