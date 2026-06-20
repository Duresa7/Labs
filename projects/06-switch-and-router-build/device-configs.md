# Cisco device configs

These snippets are the switch-and-router lab configs: addressing, interface roles, SSH controls, and verification commands.

## Router Central

```ios
hostname Central
no ip domain-lookup
ip domain-name lab.example
service password-encryption
enable secret <secret>
username netadmin privilege 15 secret <secret>
banner motd #Unauthorized access is prohibited.#

interface GigabitEthernet0/0/0
 description link-to-S1-segment
 ip address 10.1.10.254 255.255.255.128
 no shutdown

interface GigabitEthernet0/0/1
 description link-to-PC-B
 ip address 172.16.30.97 255.255.255.224
 no shutdown

line con 0
 password <secret>
 login
 logging synchronous
 exec-timeout 5 0

line vty 0 4
 login local
 transport input ssh
 exec-timeout 5 0

crypto key generate rsa modulus 2048
ip ssh version 2
end
```

## Switch S1

```ios
hostname S1
no ip domain-lookup
ip domain-name lab.example
service password-encryption
enable secret <secret>
username netadmin privilege 15 secret <secret>
banner motd #Unauthorized access is prohibited.#

interface FastEthernet0/6
 description PC-A
 switchport mode access
 no shutdown

interface GigabitEthernet0/1
 description uplink-to-Central
 no shutdown

interface range FastEthernet0/1 - 5, FastEthernet0/7 - 24, GigabitEthernet0/2
 shutdown

line con 0
 password <secret>
 login
 logging synchronous
 exec-timeout 5 0

line vty 0 4
 login local
 transport input ssh
 exec-timeout 5 0

crypto key generate rsa modulus 2048
ip ssh version 2
end
```

## Verification commands

```ios
show ip interface brief
show running-config | section line vty
show ip ssh
show mac address-table
```

I used the MAC table after an end-to-end ping to confirm S1 learned the PC-A and router-facing entries dynamically on the expected ports.
