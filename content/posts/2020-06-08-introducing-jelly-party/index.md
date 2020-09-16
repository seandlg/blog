---
layout: post
title: "Introducing Jelly-Party"
date: 2020-06-08 18:04:04 +0200
categories: projects
tags: web-extension chrome netflix social watching
author: Sean Eulenberg
---

When Covid-19 first struck Germany, I decided to get prepared for a longer quarantine by picking a project from my _things-the-world-might-need_ list. One idea straight up caught my attention: I have a [Jellyfin](https://jellyfin.org/) media server that I host some of my movies and series on, mostly to watch them with friends and family. Now, given Covid-19 I was already expecting this server to handle substantially more traffic — however, Watch-Parties remained a minor nightmare, given that some of my friends (if you're reading this, you know I'm addressing you!) run to the toilet on what feels like an hourly basis. Manually resynchronizing the movie playback after such a break meant going "3-2-1-GO!". Plus, we had to make sure that we're still in the same spot of the movie. Every time! This had fed me up so much, that the browser-sync-extension idea had made it to my _things-the-world-might-need_ list.

{{< img src="images/logo.png" title="Jelly-Party Logo" >}}

With Covid-19, the time had come. So I decided to build a Chrome extension that syncs playback on my Jellyfin server (Jellyfin is releasing such a feature natively in the near future, but it doesn't yet exist). And while I was prototyping the idea and playing around with the tech stack, I figured why not build this with support for virtually any website (think _Netflix_, _Disney+_) and release it free & open source and contribute to making this crisis a little less of a nightmare.

That's how [Jelly-Party](https://www.jelly-party.com/) came about. It caught quite a bit of attention and several thousand people downloaded it in the first weeks. As of today I've started working on v2 of the extension, which will fix many bugs and greatly improve the UI/UX.

# The tech stack

Jelly-Party is [free & open source](https://github.com/seandlg); it uses [`vuejs`](https://vuejs.org/) in the frontend (which is absolutely amazing) and makes use of many great libraries (notably [`notyf`](https://github.com/caroso1222/notyf), [`vue-beautiful-chat`](https://github.com/mattmezza/vue-beautiful-chat) and [`vuejs-avataars`](https://github.com/orgordin/vuejs-avataaars)).

The backend runs a [`nodejs`](https://nodejs.org/en/) powered websocket server for full-duplex communication. Parties are ephemeral. The entire backend is dockerized.

Logs are stored on the server and pushed to an [`elasticsearch`](https://www.elastic.co/) log instance using [`filebeat`](https://www.elastic.co/beats/filebeat), system metrics are pushed using [`metricbeat`](https://www.elastic.co/beats/metricbeat).

# Some stats

In the first two weeks since I started logging, Jelly-Party has had about 10,000 connections. People from all continents (except for Antarctica) and dozens of countries have downloaded and used Jelly-Party. Does usage correlate with Covid breakouts? It looks like it, though I haven't compiled any sound statistics. Currently, most users come from Italy, India, the US, Great Britan and Brazil.

{{< img src="images/map.png" title="Users during the first two weeks" >}}

# The future

I plan to release an updated version of Jelly-Party within the next couple of weeks. Many people have requested integrated voice and video chat, which is something that I'll certainly look at. Furthermore, I plan to support Firefox & mobile phones.
