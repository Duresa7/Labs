# 06 - Wireless

Wireless is not a separate trust domain here. Each SSID drops its clients onto a specific VLAN, so a device on Wi-Fi lands in the same zone, and under the same firewall policies, as if it had plugged into a wall port for that segment.

| SSID | VLAN | Security | State |
|---|---|---|---|
| Home-WiFi | Trusted (10) | WPA2-PSK | enabled |
| IoT-WiFi | IoT (20) | WPA2-PSK | enabled |
| Endpoint-WiFi | AD-ENDUSER (66) | WPA2-PSK | enabled |
| Lab-IoT | Management | WPA2-PSK | disabled |

The split matters most for IoT. Everything that joins `IoT-WiFi` lands on VLAN 20, which is the one segment with client isolation on (see [chapter 01](01-segmentation.md)), so a smart plug or a camera can reach the internet through the gateway but cannot see my laptops or each other. `Endpoint-WiFi` puts domain-joined machines onto the AD-ENDUSER VLAN so they get the domain's DNS and policies over wireless the same way they would over a cable. `Home-WiFi` is the ordinary trusted network for personal devices.

A single radio (the U7 Pro XG) broadcasts all of these. Keeping the SSID-to-VLAN mapping strict is what lets one access point serve a trusted laptop, an isolated camera, and a managed endpoint at the same time without any of them sharing a broadcast domain.
