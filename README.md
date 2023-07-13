# This repo is a way to import a KVM onto a new baremetal machine.
## It **only** works for KVM's that are based on the default NAT network format.

Before you copy the KVM image you should remove the system-id field from the arango-database, and any uls identifiers.

Use virt-sparsify to copy the KVM image into the images directory, this can take a while,
this prevents the image from taking up unnecessary space despite being thin provisioned.

```
sudo virt-sparsify /var/lib/libvirt/images/<kvm_name.qcow2> ./images/<kvm_name.qcow2>
```
N.B. The name of the original KVM should match the copy made by virt-sparsify

Once there use 'virsh dumpxml' to place the xml of the KVM into this directory
```
virsh dumpxml <vmname> > <vmname>.xml
```

You must also use virsh net-dumpxml default > ./network/default.xml to dump the network xml to a file.

Then if your system has a northbound and a southbound network add two lines as demonstrated below
On a single NIC system just add one line
```
<host mac='<guest_NIC_mac>' name='<kvm_name>' ip='<guest_ip>'/>
```

Replace the variables in the above line with the information found in the kvm guest xml file.
This defines the KVM to have a static IP address.

The final thing before copying this directory is to update the variables in the hook
script. Hopefully it is self-explanatory.

Copy this directory to the new baremetal machine and run the .kvm_import.sh
(recommend copying using,
```
rsync -rhPS --append-verify ./<this directory> ./<destination directory>
```

This should install the KVM on the new machine and restart the machine.

Next check that the KVM starts on boot,
and also check that the Iptables forwarding is set.
```
virsh list --all, sudo iptables -L
```
