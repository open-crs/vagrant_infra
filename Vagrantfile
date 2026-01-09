# OpenCRS Vagrant Configuration
# This creates a VM and installs everything inside it (nothing on your host machine)

Vagrant.configure("2") do |config|
  # Base box - Ubuntu 22.04 LTS
  config.vm.box = "ubuntu/jammy64"
  
  # VM Configuration
  config.vm.provider "virtualbox" do |vb|
    vb.name = "opencrs-dev-vm"
    vb.memory = "4096"  # 4GB RAM (adjust as needed: 8192 for 8GB)
    vb.cpus = 2         # 2 CPUs (adjust as needed: 4 for better performance)
    
    # Recommended: Increase disk space if working with large datasets
    # Requires: vagrant plugin install vagrant-disksize
    # config.disksize.size = '50GB'
  end
  
  # Copy the setup script to VM
  config.vm.provision "file", source: "./setup_opencrs_vm.sh", destination: "/home/vagrant/setup_opencrs_vm.sh"
  
  # Run the setup script inside the VM as vagrant user
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    set -e
    
    echo "========================================="
    echo "OpenCRS VM Provisioning Starting"
    echo "========================================="
    echo ""
    echo "This will install everything inside the VM:"
    echo "  - Docker and Docker images"
    echo "  - Python 3 and Poetry"
    echo "  - All OpenCRS repositories"
    echo "  - Build tools and dependencies"
    echo ""
    echo "Your host machine will NOT be affected."
    echo "========================================="
    echo ""
    
    # Make script executable
    chmod +x /home/vagrant/setup_opencrs_vm.sh
    
    # Run the setup script (everything happens inside the VM)
    # Use 'yes' to auto-confirm the installation prompt
    echo "y" | bash /home/vagrant/setup_opencrs_vm.sh
    
    echo ""
    echo "========================================="
    echo "OpenCRS VM Setup Complete!"
    echo "========================================="
    echo ""
    echo "IMPORTANT: Docker group changes require a new login session."
    echo "Please exit and reconnect:"
    echo "  1. exit (or Ctrl+D)"
    echo "  2. vagrant ssh"
    echo "  3. cd opencrs-workspace"
    echo "  4. source activate_opencrs.sh"
    echo ""
    echo "========================================="
  SHELL
  
  # Message to display after provisioning
  config.vm.post_up_message = <<-MSG
    =============================================
    OpenCRS Development VM is Ready!
    =============================================
    
    Everything has been installed INSIDE the VM.
    Your host machine remains untouched.
    
    To start using OpenCRS:
    
      1. Connect to the VM:
         $ vagrant ssh
      
      2. Activate the environment:
         $ cd opencrs-workspace
         $ source activate_opencrs.sh
      
      3. Test an installation:
         $ make test
    
    VM Management:
      vagrant ssh       # Connect to VM
      vagrant halt      # Stop VM
      vagrant up        # Start VM
      vagrant reload    # Restart VM
      vagrant destroy   # Delete VM completely
      vagrant status    # Check VM status
    
    Inside the VM, you can use:
      make help         # Show all available commands
      make test         # Test installation
      make update       # Update repositories
      make docker-list  # List Docker images
    
    =============================================
  MSG
end
