---
layout: post
title: "Forcing Docker Traffic Through Wireguard"
date: 2020-11-11T20:20:12+01:00
categories: snippets
tags: networking linux docker
author: Sean Eulenberg
---

# Some background

It is no understatement to say that networking inside Linux (and any other modern OS, for that matter) is little short of magic. Besides what feels like a trillion configuration options, there's powerful software for each and every use-case, enabling the interested person to dwell inside the terminal for hours and hours. After fathoming the [OSI model](https://www.wikiwand.com/en/OSI_model) and its abstraction layers, one might feel provoked to hop into the router to configure [DHCP](https://www.wikiwand.com/en/Dynamic_Host_Configuration_Protocol) or [IPv6](https://www.wikiwand.com/en/IPv6), set up a [PiHole](https://pi-hole.net/) or reliably expose local services to the world using [DynDNS](https://www.wikiwand.com/en/Dynamic_DNS).

At some stage, the interested learner may start containerizing applications. And something quite magical happens, once again. Suppose you run the following command:

```bash
docker run --name nginx1 --rm -p 8080:80 --cap-add NET_ADMIN nginx
```

Next, you open a new terminal and run:

```bash
docker run --name nginx2 --rm -p 8081:80 --cap-add NET_ADMIN nginx
```

If you now browse to `127.0.0.1:8080` and `127.0.0.1:8081` respectively, you'll be greeted by the `nginx` welcome page. Even though `nginx` is using port `80` in both container `nginx1` **and** container `nginx2`, this is okay, since `nginx1` is assigned IP-address `172.17.0.2` and `nginx2` is assigned IP-address `172.17.0.3`. A quick [Duckduckgo-search](https://stackoverflow.com/a/29578399/7383573) reveals that sockets are identified by the 5-tuple `(protocol, source address, source port, destination address, destination port)`. And on the public host, we use the two ports `(8080, 8081)`, respectively. So far so good. However, consider the following commands:

```bash
$ docker exec -it nginx1 bash
root@cb45a7f013c3:/# ip route
default via 172.17.0.1 dev eth0
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.2
root@cb45a7f013c3:/# ip route del default
```

Not only does the routing table look completely different from our `Host-OS`, but we can also modify it (this is why we added the `NET_ADMIN`-cap, otherwise we wouldn't be allowed to touch the routing table). Asthonishingly, this modification renders the network in container `nginx1` useless, while _it keeps working in container `nginx2`_! So the two containers must have different routing tables _yet again_..

```bash
# Container 1
root@49a50374ff67:/# ip r
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.2

# Container 2
root@6ca691166923:/# ip r
default via 172.17.0.1 dev eth0
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.3
```

What black magic is this? Enter [Linux namespaces](https://www.wikiwand.com/en/Linux_namespaces)! It turns out that processes (a running Docker container is nothing more!) access _namespaced_ resources, such as `mnt`-, `pid`-, `net`- or `ipc`-resources. This essentially means that every Docker container can be in its own `net`-namespace, with its own IP-addresses, routing table, socket listing, connection tracking, firewall etc. When creating a network interface in namespace `A` and moving it to namespace `B` (e.g. our container), the interface _remembers_ its heritage and keeps sending traffic through initially defined sockets.

# The setup

Now given the above information, I want a Docker container running [Deluge](https://www.deluge-torrent.org/) (specifically [this image](https://docs.linuxserver.io/images/docker-deluge)) to conform to the following requirements:

1. All default traffic leaves through a Wireguard network interface.
2. The service is available at the host's `localhost` interface to allow for a `nginx` reverse proxy to forward (& encrypt) the service.

Let's spin up the container from a `docker-compose.yml` file:

```yml
---
version: "2.1"
services:
  deluge:
    image: ghcr.io/linuxserver/deluge
    container_name: deluge
    network_mode: bridge
    ports:
      - "8112:8112"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - UMASK_SET=022 #optional
      - DELUGE_LOGLEVEL=error #optional
    volumes:
      - ./config:/config
      - ./downloads:/downloads
    restart: unless-stopped
```

Notably, we attach the container to our network using `bridging` and forward port `8112`. We spin up the container using `docker-compose up --build -d`.

## Making the networking namespace accessible to `ip`

It turns out that we can use `ip` to create network-namespaces **and to run commands within a network namespace**, using `ip netns exec namespace_name cmd` (or the simpler version that we'll stick to: `ip -n namespace_name cmd`). However, `ip netns list` reveals that even though our docker container lives in its own networking namespace, `ip` doesn't seem to know about it. We can fix this with the following few lines ([source](https://platform9.com/blog/container-namespaces-deep-dive-container-networking/)), which create a symlink to our container's network namespace in the `/var/run/netns`-directory, which is where `ip` looks for network namespaces.

```bash
#!/bin/bash
# Make the docker container network namespace available
pid=$(docker inspect -f '{{.State.Pid}}' "deluge")
mkdir -p /var/run/netns
ln -sf /proc/$pid/ns/net /var/run/netns/container
```

Using our "new" namespace named `container`, we can now create and configure a wireguard interface in our default namespace, and then move it into the `container`-namespace.

```bash
# Create a wireguard network interface
ip link add wg0 type wireguard
# Move the wireguard network interface to the above identified docker container
ip link set wg0 netns container
# Replace ww.xx.yy.zz/16 with an IP address assigned to you by your VPN provider
ip -n container addr add ww.xx.yy.zz/16 dev wg0
ip -n container wg setconf wg0 ./wg0.conf
ip -n container link set wg0 up
ip -n container route del default
ip -n container route add default dev wg0
```

This setup works, and all traffic is now forced through the `wg0` interface. Sweet! However, the service is not accessible to host `localhost` anymore. A quick inspection using [`tcpdump`]() reveals that traffic that was previously routed back via `172.17.0.1` is now routed via the VPN, where it vanishes into the depth of a data center. We can quickly fix this by adding a route for traffic that we want to route back via the bridge.

```bash
# Enable bridged packets to return
ip netns exec container ip route add 192.168.178.0/24 via 172.17.0.1
```

Lastly, make sure to double-check the contents of `/etc/resolv.conf`, to ensure that your DNS traffic goes to either your VPN's DNS, or a DNS-server that you have chosen specifically. In briding mode, `Docker` should copy your host's `/etc/resolv.conf` into the container. However, if you're using a local DNS resolver, e.g. to encrypt DNS traffic, things might break.
