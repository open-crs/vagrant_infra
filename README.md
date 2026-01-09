# Vagrant Infra

## Prereqs
Install VirtualBox and Vagrant for your platform
<br>
[VirtualBox](https://www.virtualbox.org/wiki/Downloads)
<br>
[Vagrant](https://developer.hashicorp.com/vagrant/install)

## For Linux
After installation, in terminal enter `vagrant_infra`and run `vagrant up`:
```
cd vagrant_infra
vagrant up
```

## For Windows
Do not use Wsl for vagrant. Install Vagrant for Windows and inside the cloned directory open powershell and run same command:
```
cd vagrant_infra
vagrant up
```

## Post-installation
In order to connect to VM use `vagrant ssh` command.
If the command seems to not work check VMs status using `vagrant status`