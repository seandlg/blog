---
layout: post
title: "Multi-threaded web scraping with Python"
date: 2020-05-26 17:33:26 +0200
categories: projects
tags: programming web
author: Sean Eulenberg
---

# The story

I get it. Some websites don't have the time, resources or (economic) interest to expose public APIs. Yet, sometimes you still need to extract structured data from them. That's the problem I was facing when I needed to convert roughly 100 WKNs (Wertpapierkennummer — it's a German standard for identifying financial securities) to their respective International Securities Identification Numbers (thank God for internationalization). [onvista](https://www.onvista.de/) is a great website for browsing through stock data and they are the only service I found to reliably convert WKNs to ISINs. However, they don't have any API to do that (that I know of). So that's where web scraping comes into play.

Essentially, I want to convert the following:

A1CX3T ➔ US88160R1014

It turns out there's really powerful web scraping software out there ([scrapy](https://scrapy.org/) anyone?), but sometimes this software is so powerful that all it does is leave me confused. So why not do things the old standard way, using a little bit of Python, [`beautifulsoup`](https://pypi.org/project/beautifulsoup4/) and Python's internal [`concurrent.futures`](https://docs.python.org/3/library/concurrent.futures.html).

In case you're not familiar, `beautifulsoup` sits on top of an HTML/XML parser and lets you search & modify XML-structured data using Pythonic idioms. `concurrent-futures` is a Python module that provides a high-level interface for asynchronously running threads, among other things.

In simple terms, web scraping reduces to no more than **programatically extracting data from websites**.

# Why multi-threading?

Python is quick. However, calls to websites not so much. So if you were to loop over 100 WKNs and _wait for each call to return synchronously_, this is a heavily I/O-bound task that could take forever.

For I/O-bound tasks, asynchronicity is key! How this is achieved is secondary — `javascript`, for instance, is famously single-threaded and uses an event-loop to handle asynchronous tasks. With Python, we're going to stick with `threads` (threads are light-weight units of execution scheduable by the OS). Generally speaking, it's very demanding to program with `threads`, due to race-conditions and all kinds of other mind-boggling concepts to wrap your head around. However, for the simple task at hand, and given Python's high-level interface, there's little to worry about.

# The code

All good Python scripts start with some imports.

```python
import urllib.request # for downloading data
from tqdm import tqdm # for displaying a smart progress meter in loops
from bs4 import BeautifulSoup # for XML parsing & searching
import concurrent.futures # for multi-threading
import pickle # to save Python objects to the disk as files
```

Next, we list the WKNs we want to convert to ISINs. I'm only showing three here, for brevity's sake.

```python
wkns = ["DBX0E8","A2N8AW","LYX0WA"]
```

Then, we define a function that takes a WKN and converts it to an ISIN, by scraping onvista. With `urllib`, we can `GET` a response from onvista's search page, which is a HTML-document. Using `beautifulsoup`, we can then _select_ from this document using [CSS-selectors](https://developer.mozilla.org/en-US/docs/Learn/CSS/Building_blocks/Selectors). This is great, because we can make use of the structure of the document, rather than brute-forcing through all data using something like regular expressions. We write the result to the dictionary `wkn_isin_db`.

```python
wkn_isin_db = {}

def wkn_to_isin(wkn):
    req = urllib.request.Request(url=f"https://www.onvista.de/suche/?onvHeaderSearchBoxAction=true&doSubmit=Suchen&searchValue={wkn}")
    with urllib.request.urlopen(req) as f:
        s = f.read().decode('utf-8')
        soup = BeautifulSoup(s, 'html.parser')
        isin = soup.select(".ui.very.compact.small.table tr:nth-child(2) td:nth-child(2)")[0].text.strip()
        wkn_isin_db[wkn] = isin
    print(f"Thread finished for WKN: {wkn}")
```

The magic happens as we use a `ThreadPoolExecutor` with `10` threads to concurrently execute our `wkn_to_isin`-function.

```python
no_threads = 10

with concurrent.futures.ThreadPoolExecutor(max_workers=no_threads) as executor:
    for wkn in tqdm(wkns):
        print(f"Thread starting for WKN: {wkn}")
        executor.submit(wkn_to_isin, wkn)

# Thread starting for WKN: DBX0E8
# Thread starting for WKN: A2N8AW
# Thread starting for WKN: LYX0WA
# Thread finished for WKN: DBX0E8
# Thread finished for WKN: LYX0WA
# Thread finished for WKN: A2N8AW
```

Notice, how the thread for WKN `A2N8AW` finished third, even though it was started as thread `#2`. This is, because all threads were running simultaneously and probably onvista's server took a little longer to return a response for `A2N8AW`.

Lastly, we print the result

```python
print(wkn_isin_db)

# {'DBX0E8': 'LU0484968812', 'LYX0WA': 'LU1563454310', 'A2N8AW': 'LU1899270539'}
```

Pretty great, no?

# Remarks

I do not endorse web scraping with **any** commercial interest in mind, without consulting a lawyer, nor do I suggest that building databases of publicly available data is legal or morally justifiable. I merely saved myself some hours of browsing a website to assemble **some** data for my private use.
