#!/bin/bash +x

# this script should copy the VM in the images dir to the appropriate system dir, and populate the hooks dir with the appropriate script
# the README file has more information should you need it

function import_vm(){

  # Get the source location.
  SOURCE_LOCATION=$(pwd)

  # Throws error if directory is not available and exit.
  [[ -d ${SOURCE_LOCATION} ]] || { echo "Please run script from inside it's directory"; exit 1 ; }

  # Copy all the files to default disk location.
  echo -e "[ Copying disk images ]\n" && sudo rsync -ahxPS --append-verify ${SOURCE_LOCATION}/images /var/lib/libvirt/

  if [[ $? -eq 0 ]]; then
    # Define VM
    echo -e "\n[ Defining VM ]\n"
    for XML_FILE in ${SOURCE_LOCATION}/*.xml; do
      sudo virsh define --file ${XML_FILE}
    done
    echo -e "\n[ Imported VM List ]\n" && sudo virsh list --all
  fi

}

# This should set the vm to autostart on host reboot. I have had issues with the autostart actually sticking, so it's worth a manual check after a host reboot
function autostart(){

    # Get the source location.
    SOURCE_LOCATION=$(pwd)

    # Throws error if directory is not available and exit.
    [[ -d ${SOURCE_LOCATION} ]] || { echo "Please run script from inside it's directory"; exit 1 ; }

    # Start default networking, the network file also houses the static ip rules
    sudo virsh net-define --file ./network/default.xml

    sudo virsh net-start default
    sudo virsh net-autostart default

    for vm in ${SOURCE_LOCATION}/*.xml; do
        vm=$(echo $vm | tr -d '.xml' | awk -F '/' '{print $NF}')

        sudo virsh autostart $vm
        sudo virsh start $vm

        sleep 10

        # I run autostart twice because I've had issues with it actually working, so this is my attempt to make sure it's mark as autostart
        sudo virsh autostart $vm
        sudo virsh shutdown $vm

        sleep 5

    done

}

wd=$(dirname "$0")

cd $wd

xargs -a ./requirements.txt -r sudo apt install -y

if kvm-ok > /dev/null ;then
    import_vm
    autostart
    sudo cp ./hooks/iptables_rules /etc/libvirt/hooks/qemu && sudo chmod 777 /etc/libvirt/hooks/qemu
    echo "System will reboot in 5 seconds"
    sleep 5
    sudo reboot
else
    printf "\nSystem is not configured to allow KVM hypervisor install, please check system config."
fi