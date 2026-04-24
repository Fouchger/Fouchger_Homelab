## setup interfaces

Run
```
nano /etc/network/interfaces
```
Update interfaces to
```
auto lo
iface lo inet loopback

iface nic0 inet manual

auto vmbr0
iface vmbr0 inet manual
        bridge-ports nic0
        bridge-stp off
        bridge-fd 0
        bridge-vlan-aware yes

auto vmbr0.20
iface vmbr0.20 inet static
        address 192.168.20.10/24
        gateway 192.168.20.1

iface nic1 inet manual


source /etc/network/interfaces.d/*
```

## Commands to run to fix bridges

Run this on Proxmox:
```
bridge vlan add dev nic0 vid 20
bridge vlan add dev vmbr0 vid 20 self
```
Then verify:
```
bridge vlan show
```


