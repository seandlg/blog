---
layout: post
title: "Routing all traffic via a VPN using openconnect"
date: 2020-11-04T16:44:23+01:00
categories: networking
tags: vpn routing networking
author: Sean Eulenberg
---

I recently had to connect to my university's VPN to get access to statistics by [statista](https://www.statista.com/). I connected using `openconnect`, an Open Source Cisco-Anyconnect-Compliant VPN software. However, it turned out that my university's VPN config only routes university intranet traffic via the VPN, leaving all other traffic to be send via the default interface. Statista, obviously not belonging to my university's intranet, thus refused to serve me premium statistics.

A simple `ip route show` revealed that `openconnect` configured a whole bunch of `link local` routes, that it makes available through the `tun0` interface. Here, `scope link` means that hosts in the respective (sub-)net are directly addressable, without need for routing. `ARP` (Adress Resolution Protocol — IPv4) or NDP (Neighbor Discovery Protocol — IPv6) should therefore yield MAC-Address—IP-Address pairs for these hosts.

The following is an (anonymized) excerpt of the entries revealed by `ip route show`:

```bash
default via 192.168.178.1 dev wlan0
xyz.xyz.xyz.xy dev tun0 scope link
xyz.xyz.xyz.xy dev tun0 scope link
xyz.xyz.xyz.xy dev tun0 scope link
xyz.xyz.xyz.xy dev tun0 scope link
```

Notably, the `default` route remained at `default via 192.168.178.1 dev wlan0`.

So how do we route all traffic through `tun0`. Simple:

```bash
ip route del default via 192.168.178.1 dev wlan0
ip route add default via xyz.xyz.xyz.xyz dev tun0
```

And that's it. Simply changing the default route forces all traffic to go through the VPN-tunnel, thus unlocking Statista statistics. `xyz.xyz.xyz.xyz` here refers to the IP-address that we hold on the `tun0` interface.
