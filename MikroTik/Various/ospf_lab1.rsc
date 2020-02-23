# jan/02/1970 03:59:43 by RouterOS 6.46.3
# software id = 95ZB-06AQ
#
# model = RB941-2nD
# serial number = A1C30BABCFE0
/interface pwr-line
set [ find default-name=pwr-line1 ] mac-address=C4:AD:34:01:F1:F4
/interface bridge
add name=bridge-LAN
/interface ethernet
set [ find default-name=ether1 ] loop-protect=on mac-address=\
    C4:AD:34:01:F1:F0
set [ find default-name=ether2 ] loop-protect=on mac-address=\
    C4:AD:34:01:F1:F1
set [ find default-name=ether3 ] loop-protect=on mac-address=\
    C4:AD:34:01:F1:F2
set [ find default-name=ether4 ] loop-protect=on mac-address=\
    C4:AD:34:01:F1:F3
/interface wireless
set [ find default-name=wlan1 ] name=wlan2 ssid=MikroTik
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/interface bridge port
add bridge=bridge-LAN interface=ether4
/ip address
add address=192.168.113.129/26 interface=ether3 network=192.168.113.128
add address=192.168.12.1/24 interface=bridge-LAN network=192.168.12.0
add address=192.168.113.66/26 interface=ether2 network=192.168.113.64
/routing ospf network
add area=backbone network=192.168.12.0/24
add area=backbone network=192.168.113.0/26
add area=backbone network=192.168.113.64/26
add area=backbone network=192.168.113.128/26
/system identity
set name=Dima
/system routerboard settings
set auto-upgrade=yes
