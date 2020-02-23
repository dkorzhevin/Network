# jan/02/1970 10:02:31 by RouterOS 6.46.3
# software id = 95ZB-06AQ
#
# model = RB941-2nD
# serial number = A1C30BABCFE0
/interface pwr-line
set [ find default-name=pwr-line1 ] mac-address=C4:AD:34:01:F1:F4
/interface sstp-server
add name=tun0 user=admin
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
set [ find default-name=wlan1 ] band=2ghz-b/g/n disabled=no frequency=2437 \
    name=wlan2 ssid=QTraining
/interface eoip
add local-address=192.168.12.1 mac-address=02:A0:72:3A:BE:5B name=\
    eoip-tunnel1 remote-address=192.168.13.1 tunnel-id=100
/interface gre
add local-address=22.1.1.12 name=gre-tunnel1 remote-address=22.1.1.13
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ppp profile
set *0 local-address=10.2.2.13 remote-address=10.2.2.14
/routing ospf area
add area-id=0.0.0.113 default-cost=1 inject-summary-lsas=no name=Area113 \
    type=stub
/routing ospf instance
add name=ospf1 redistribute-connected=as-type-1 router-id=192.168.12.1
/interface bridge port
add bridge=bridge-LAN interface=ether4
add bridge=bridge-WLAN interface=wlan2
/interface sstp-server server
set enabled=yes
/ip address
add address=192.168.113.129/26 interface=ether3 network=192.168.113.128
add address=192.168.12.1/24 interface=bridge-LAN network=192.168.12.0
add address=192.168.113.66/26 interface=ether2 network=192.168.113.64
add address=22.1.1.12/24 interface=bridge-WLAN network=22.1.1.0
add address=10.2.2.12/30 disabled=yes network=10.2.2.12
add address=10.1.1.13/30 interface=gre-tunnel1 network=10.1.1.12
add address=192.168.88.1/24 interface=eoip-tunnel1 network=192.168.88.0
/ppp secret
add name=admin password=admin
/routing ospf interface
add interface=bridge-WLAN network-type=broadcast
add cost=20 dead-interval=2s hello-interval=1s interface=ether2 network-type=\
    point-to-point
add dead-interval=2s hello-interval=1s interface=ether3 network-type=\
    point-to-point
add dead-interval=2s hello-interval=1s interface=gre-tunnel1 network-type=\
    point-to-point
add comment="SSTP tun binded" cost=20 dead-interval=2s hello-interval=1s \
    interface=tun0 network-type=point-to-point
/routing ospf network
add area=backbone disabled=yes network=192.168.113.0/26
add area=Area113 disabled=yes network=192.168.113.64/26
add area=Area113 disabled=yes network=192.168.113.128/26
add area=backbone disabled=yes network=22.1.1.0/24
add area=backbone network=10.2.2.12/30
add area=backbone network=10.1.1.12/30
add area=backbone network=192.168.12.0/24
/system identity
set name=Dima
/system logging
add topics=ospf,!debug
/system routerboard settings
set auto-upgrade=yes
