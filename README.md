## connect wifi
```sh
rfkill unblock wifi
ip link set wlan0 up
connmanctl
    scan wifi
    services
    agent on
    connect <wifi_>
    quit
pacman -Syy
```
## connect ethernet
```sh
sudo ip link set eth0 up
sudo ip addr add 192.168.0.249/24 dev eth0
sudo ip route add default via 192.168.0.1
```
