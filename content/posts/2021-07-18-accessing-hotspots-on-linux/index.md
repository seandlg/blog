---
layout: post
title: "Accessing Hotspots on Linux"
date: 2021-07-18T17:05:59+02:00
categories: linux hotspot networking
tags: blog
author: Sean Eulenberg
---

Accessing open wireless access points (aka _hotspots_) on Linux can sometimes be a pain. Depending on the network configuration of the system, [_captive portal_](https://www.wikiwand.com/en/Captive_portal) autodetection might not work, custom [DNS](https://www.wikiwand.com/en/Domain_Name_System) may mess up automatic redirects or [HSTS](https://www.wikiwand.com/en/HTTP_Strict_Transport_Security) presents you with obscure security warnings. Yet, if you understand what the computer is attempting to do, the riddle unravels quickly.

# Hotspot access
A hotspot usually presents itself as an __open__ (i.e. no passphrase required) wireless network, which any WiFi-capable device can connect to. However, the network access through this hotspot is __enabled dynamically__, after some mean of user input. This user input happens through a _captive portal_. What is a _captive portal_, you ask? 

> A captive portal is a web page accessed with a web browser that is displayed to newly connected users of a WiFi or wired network before they are granted broader access to network resources. Captive portals are commonly used to present a landing or log-in page which may require authentication, payment, acceptance of an end-user license agreement, acceptable use policy, survey completion, or other valid credentials that both the host and user agree to adhere by.

<cite>— Wikipedia</cite>

After successfully unlocking the network, the network host usually "remembers" a device by its unique [_media access code_](https://www.wikiwand.com/en/Medium_access_control). Anyways, the important point is: Almost all problems concerning _hotspot access_ revolve around __problems accessing the captive portal__. We can group these problems into three categories:

## 1. Autodetection problems
Many operating systems (think `MacOS`, `Windows`) automatically detect when they connect to an open network that requires _"solving a captive portal challenge"_, through multiple smart network tests. If your Linux distribution is not configured for this, a friendly Popup asking you to go through the __captive portal__ may not pop up upon connecting to the network.

## 2. DNS problems
In most cases, network devices that connect to a wireless access point obtain their address through means of [DHCP](https://www.wikiwand.com/en/Dynamic_Host_Configuration_Protocol). Besides centralized address configuration, DHCP usually assigns DNS-Servers. These are in charge of translating domain names (e.g. `https://duck.com`) to IP-Adresses (e.g. `40.89.244.232`).

So how does this relate to __captive portal access__? Simple: The network operator will resolve any domain to the IP-Address of its respective captive portal, until the users authenticates/pays/accepts the license agreement.

However, if the Linux system is configured to use __static__ DNS, e.g. [Quad9](https://www.quad9.net/), it disregards any DNS-Servers it was told about by its DHCP client and therefore attempts to redirect all DNS queries to `9.9.9.9`. This request fails, because the __captive portal challenge__ hasn't been passed.

## 3. HSTS problems
Consider the case that you are trying to access a website (say `duck.com`) and you successfully use the network assigned DNS server to obtain its IP-address. Therefore, the address is ("erroneously") resolved to e.g. `10.0.0.1`, which is where the _captive portal_ resides.

Still, problems may arise from a modern security mechanism called [HTTP Strict Transport Security](https://www.quad9.net/). In a nutshell, `HSTS` protects websites against [man-in-the-middle attacks](https://www.wikiwand.com/en/Man-in-the-middle_attack), by forcing a browser to only accept [`TLS`](https://www.wikiwand.com/en/Transport_Layer_Security)-encrypted traffic for that specific website. This renders DNS-rebinds to a _captive portal_ useless, because your browser will throw a security warning and try to warn you that somebody (the network operator) is trying to impersonate `duck.com`. 

# Some tips
If you're trying to pass through a _captive portal_, keep the above challenges in mind, and proceed as follows:

## 1. Directly query an IP-address
Preferably, attempt to access your `default gateway` via your browser. You can find it out using:

```bash
~ ➤ ip route
default via 172.18.0.1 dev wlan0 proto dhcp src 172.18.120.148 metric 1024
172.18.0.0/16 dev wlan0 proto kernel scope link src 172.18.120.148 metric 1024
172.18.0.1 dev wlan0 proto dhcp scope link src 172.18.120.148 metric 1024ip route
```

## 2. Access an HTTP-only website
Try accessing [`http://neverssl.com/`](http://neverssl.com/). You can exclude `HSTS` problems when using this website, since it is always served as pure `HTTP`.

## 3. Find out the _captive portal_ address
Some hotspots advertise their captive portal address. If you use a custom DNS-server, begin by identifying the address of the DNS server advertised through DHCP. Use your `DHCP`-client for this, or refer to `nmap`:

```bash
~ ➤ nmap --script broadcast-dhcp-discover
Starting Nmap 7.91 ( https://nmap.org ) at 2021-07-18 18:24 CEST
Pre-scan script results:
| broadcast-dhcp-discover:
|   Response 1 of 1:
|     Interface: wlan0
|     IP Offered: 172.18.198.70
|     DHCP Message Type: DHCPOFFER
|     Server Identifier: 172.18.0.1
|     IP Address Lease Time: 2m00s
|     Renewal Time Value: 1m00s
|     Rebinding Time Value: 1m45s
|     Subnet Mask: 255.255.0.0
|     Broadcast Address: 172.18.255.255
|     Router: 172.18.0.1
|     Domain Name Server: 172.18.0.1
|     NTP Servers: 172.18.0.1
|_    Interface MTU: 1440
WARNING: No targets were specified, so 0 hosts scanned.
Nmap done: 0 IP addresses (0 hosts up) scanned in 10.25 seconds
```

Next, use `drill` (or `dig`) to query the previously advertised DNS-server for the known _captive portal address_.

```bash
~ ➤ drill @172.18.0.1 wifionice.de
;; ->>HEADER<<- opcode: QUERY, rcode: NOERROR, id: 17224
;; flags: qr aa rd ra ; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
;; QUESTION SECTION:
;; wifionice.de.	IN	A

;; ANSWER SECTION:
wifionice.de.	0	IN	A	10.101.64.10

;; AUTHORITY SECTION:

;; ADDITIONAL SECTION:

;; Query time: 5 msec
;; SERVER: 172.18.0.1
;; WHEN: Sun Jul 18 18:45:09 2021
;; MSG SIZE  rcvd: 46
```

You should be able to connect to that IP-address and go through the _captive portal process_.

# Remarks
While an annoying issue to begin with, I remain convinced that the most sensible way to deal with these kind of network issues is to _drill_ (or _dig_) a little deeper and understand the underlying problems. It'll leave you with a better understanding of multiple pieces of technology. 
