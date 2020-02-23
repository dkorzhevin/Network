# jan/02/1970 09:00:46 by RouterOS 6.46.3
# software id = 95ZB-06AQ
#
# model = RB941-2nD
# serial number = A1C30BABCFE0
/interface pwr-line
set [ find default-name=pwr-line1 ] mac-address=C4:AD:34:01:F1:F4
/interface bridge
add name=bridge-LAN
add name=bridge-WLAN
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
/routing ospf area
add area-id=0.0.0.113 default-cost=1 inject-summary-lsas=no name=Area113 \
    type=stub
/routing ospf instance
add name=ospf1 redistribute-connected=as-type-1 router-id=192.168.12.1
/interface bridge port
add bridge=bridge-LAN interface=ether4
add bridge=bridge-WLAN interface=wlan2
/ip address
add address=192.168.113.129/26 interface=ether3 network=192.168.113.128
add address=192.168.12.1/24 interface=bridge-LAN network=192.168.12.0
add address=192.168.113.66/26 interface=ether2 network=192.168.113.64
add address=10.10.12.1/24 interface=bridge-WLAN network=10.10.12.0
/routing ospf interface
add interface=bridge-WLAN network-type=broadcast
add cost=20 dead-interval=2s hello-interval=1s interface=ether2 network-type=\
    point-to-point
add dead-interval=2s hello-interval=1s interface=ether3 network-type=\
    point-to-point
/routing ospf network
add area=Area113 network=192.168.12.0/24
add area=backbone disabled=yes network=192.168.113.0/26
add area=Area113 network=192.168.113.64/26
add area=Area113 network=192.168.113.128/26
add area=backbone disabled=yes network=22.1.1.0/24
/system identity
set name=Dima
/system logging
add topics=ospf,!debug
/system routerboard settings
set auto-upgrade=yes
