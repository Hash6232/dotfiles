# Reverse Proxy with Wireguard, DDNS, Caddy and Pihole

This document describes the process of setting up a reverse proxy for free. Linux and networking basics are required.  

In a nuthsell, connecting to the Wireguard server from a deSEC address will grant you access to the services running on the system without opening a port for each one of them.
Wireguard will use Pihole as DNS Proxy in order to resolve subdomains to a local IP and ddclient will keep your deSEC address synced to your dynamic IP.
Finally, the deSEC address subdomains are reverse proxied by Caddy and certified by acme.sh through deSEC API every 60 days.

## Requirements

For simplicity I will describe the process based on this setup:

- Server linked via cable to the internet
- Laptop to configure the server via SSH
- New Debian installation
- Username named `hare`
- Server IP set to `192.168.1.10`
- Router IP set to `192.168.1.1`
- Router DHCP range not overlapping with the server IP
- deSEC address set to `himari.dedyn.io`
- deSEC secret token stored somewhere

## Initial setup

- [Download](https://www.debian.org/), [flash](https://rufus.ie/en/) and install Debian on your system
- On your first boot, login as `root` and run:
```bash
apt update && apt install sudo
# Adding hare to the sudo and docker groups
usermod -aG sudo hare
usermod -aG docker hare
```
- Enable the SSH server:
```bash
apt install openssh-server
systemctl enable ssh
systemctl start ssh
```
- Open `/etc/network/interfaces` to set a static IP
- Set `iface <interface-name> inet auto` to `static`:
```
# The primary network interface
allow-hotplug enp0s31f6
iface enp0s31f6 inet static
address 192.168.1.10
netmask 255.255.255.0
gateway 192.168.1.1
```
- Reboot running `restart now`

## First configuration

- Connect via SSH to the server with `ssh hare@192.168.1.10`
- Install Docker Engine following the official [documentation](https://docs.docker.com/engine/install/debian/#install-using-the-repository)
- Create a shared network for your services with `docker network create shared_net`
- Pick a location for your services and create the necessary folders structure:
```
/home/hare/
└── docker/
    ├── vpn/
    │   ├── wireguard/
    │   ├── ddclient/
    │   │   └── ddclient.conf
    │   ├── docker-compose.yml
    │   └── wireguard.env
    ├── reverse-proxy/
    │   ├── caddy/
    │   │   ├── certs/
    │   │   └── Caddyfile
    │   ├── docker-compose.yml
    │   └── pihole.env
    └── lsio.env
```
- Configure the `.env` files:
```bash
# lsio.env
PUID=1000
PGID=1000
TZ=Etc/UTC # Find your timezone @ https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List

# wireguard.env
SERVERURL=himari.dedyn.io
SERVERPORT=51820
PEERS=1
PEERDNS=auto
INTERNAL_SUBNET=10.13.13.0
ALLOWEDIPS=0.0.0.0/0
PERSISTENTKEEPALIVE_PEERS=all

# pihole.env
PIHOLE_UID=1000
PIHOLE_GID=1000
FTLCONF_webserver_api_password=your-web-ui-password-of-choice
TZ=Etc/UTC # Find your timezone @ https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
```
- Configure the `docker-compose.yml` files:
```yaml
# vpn/docker-compose.yml
services:
  wireguard:
    image: lscr.io/linuxserver/wireguard:latest
    container_name: wireguard
    env_file:
      - path: ../lsio.env
      - path: ./wireguard.env
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    volumes:
      - ./wireguard:/config
      - /lib/modules:/lib/modules
    ports:
      - 51820:51820/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped
  ddclient:
    image: lscr.io/linuxserver/ddclient:latest
    container_name: ddclient
    env_file: ../lsio.env
    volumes:
      - ./ddclient/ddclient.conf:/config/ddclient.conf
    restart: unless-stopped

networks:
  default:
    external: true
    name: shared_net
```
```yaml
# reverse-proxy/docker-compose.yml
services:
  caddy:
    image: caddy:latest
    container_name: caddy
    cap_add:
      - NET_ADMIN
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile
      - ./caddy/certs:/certs:ro
    restart: unless-stopped
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    env_file: ./pihole.env
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "8080:80/tcp"
    volumes:
      - pihole_data:/etc/pihole
    restart: unless-stopped

volumes:
  pihole_data:

networks:
  default:
    external: true
    name: shared_net
```

## Services configuration
- Navigate to `~/docker/vpn` and run `docker compose up -d && docker compose down`
- Add `DNS = 192.168.1.10` anywhere under `[Interface]` in `~/docker/vpn/wireguard/templates/server.conf`
- Configure `ddclient.conf` in `~/docker/vpn/ddclient/ddclient.conf`:
```conf
##
## deSEC (www.desec.io)
##
protocol=dyndns2
use=cmd, cmd='curl https://checkipv4.dedyn.io/'
server=update.dedyn.io
ssl=yes
login=himari.dedyn.io 
password='desec-secret-token'
himari.dedyn.io 
```
- Log into your router and [port forward](https://portforward.com/how-to-port-forward/#step-2-log-in-to-your-router) your wireguard port `51820` for server ip `192.168.1.10`
- Navigate to `~/docker/vpn` and run `docker compose up -d`
- Configure your `Caddyfile` in `~/docker/reverse-proxy/caddy`:
```
*.himari.dedyn.io {
	tls /certs/himari.dedyn.io/fullchain.cer /certs/himari.dedyn.io/himari.dedyn.io.key

	@pihole host pihole.himari.dedyn.io
	handle @pihole {
		redir / /admin
		reverse_proxy pihole:80
	}
}
```
- Issue a wildcard certificate for your subdomains:
```bash
# Issue certificate
export DEDYN_TOKEN="desec-secret-token"
acme.sh --issue --dns dns_desec -d himari.dedyn.io -d '*.himari.dedyn.io'

# Save API token in `.bashrc`
echo 'export DEDYN_TOKEN="desec-secret-token"' >> ~/.bashrc

# Install
acme.sh --install-cert -d himari.dedyn.io \  
  --key-file       $HOME/docker/reverse-proxy/caddy/certs/himari.dedyn.io/himari.dedyn.io.key \  
  --fullchain-file $HOME/docker/reverse-proxy/caddy/certs/himari.dedyn.io/fullchain.cer \  
  --reloadcmd      "docker restart caddy"
```
- Navigate to `~/docker/reverse-proxy` and run `docker compose up -d`
- Visit `192.168.1.10:8080/admin/` and go to `Settings > Local DNS Records`
- Add a new entry for `pihole.himari.dedyn.io` pointing to `192.168.1.10`
- Open a new terminal window on your laptop and run:
```bash
# Copies peer1.conf to your current directory on your local system
scp hare192.168.1.10:~/docker/vpn/wireguard/peer1/peer1.conf .
```
- Add the config file to your [Wireguard client](https://www.wireguard.com/install/) and connect to the server
- Open the browser and visit `https://pihole.himari.dedyn.io`
- Enjoy

## (Optional) Add a new service

TO DO
