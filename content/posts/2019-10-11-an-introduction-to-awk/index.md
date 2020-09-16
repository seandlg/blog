---
layout: post
title: "An introduction to awk"
date: 2019-10-11 14:12:00 +0000
categories: projects
tags: awk cli linux unix
author: Sean Eulenberg
---

Every Linux user has, at some stage, used some strange script from the internet that contained this `awk` command (and, contrary to what he or she knows to be right, he or she didn't really look at said script before executing it with root privileges..).

But what does `awk` actually do?

I've found a myriad of resources on the web, but felt like a simple, straightforward introduction was missing (it's probably there — but then again, I didn't find it). Anyways, here is one:

# What is `awk`?

> `awk` is a language for text processing.

Yes, it's that simple. `awk` is a domain-specific **language**, precisely one that is used to edit **text**. `awk` supports variables, functions and arrays. We'll get to some of that later.

# Why should I bother learning `awk`?

Honestly, I asked myself the same question. Why bother with `awk`? The simple answer: Because it's easy to get started with (given proper resources!) and very, very powerful. And if you already know your way around [regular expressions](https://en.wikipedia.org/wiki/Regular_expression "Regular Expressions on Wikipedia"), `awk` will be the perfect tool to complement this knowledge.

# So how does it work?

## Input & Output

`awk` works on a **file** (or any `stdin` supplied data), that it interprets as **records** and **fields**. `awk`s output consists of **records** and **fields** as well.

Consider the following file `fruit.txt`:

```text
melon  3
apples 5
lemon  2
```

This file has three records: `"melon 3"`, `"apples 5"` and `"lemon 2"`. Each record has two fields, respectively: `("lemon", "3")`, `("apples", "5")` and `("lemon", "2")`.

Essentially, what `awk` refers to as **records** and **fields** is by default **lines** and **columns**. It is easy to have `awk` behave differently by changing its record separator (RS) and field separator (FS). In a similar fashion - `awk` outputs data as **records** and **fields** as well — the output record separator (ORS) and output field separator can be modified. By default, `awk` uses these values (there are more [built-in variables](https://www.tutorialspoint.com/awk/awk_built_in_variables.htm "AWKs built-in variables")):

| Variable                                        | Default value                     | Regular expression |
| :---------------------------------------------- | :-------------------------------- | :----------------- |
| Record separator (RS)                           | Newline                           | \n                 |
| Field separator (FS)                            | Spaces and tabs&nbsp;&nbsp;&nbsp; | [\s\t]+            |
| Output record separator (ORS)&nbsp;&nbsp;&nbsp; | Newline                           | \n                 |
| Output field separator (OFS)                    | Space                             | \s                 |
|                                                 |                                   |                    |

It is important to remember: By default, `awk` will treat each **line** as a **record**, and **column entry** as a **field**. It delimits **fields** using **white-spaces**. This applies for **both input and output**.

## An AWK Program

From [Wikipedia](https://en.wikipedia.org/wiki/AWK "AWK on Wikipedia") we get:

> An AWK program is a series of condition action pairs.

```text
condition { action }
condition { action }
...
```

A simple `awk` program will therefore do roughly the following:

```python
# loop over every record in the file
for record in file:
    # loop over every (condition, action) pair in the program
    for (condition, action) in program:
        # check if the condition evaluates to True
        if test_condition_against_record(condition, record):
            # if it does, perform action
            do_action_on_record(action, record)
```

A program can have as many `condition { action }` pairs as you wish. You must specify either a `condition` and\|or an `{ action }`. If you specify only one of the two, either `condition` will default to `True` (so your program’s action is invoked for every record), or `{ action }` will default to print the record **as it appeared from the input** (if the condition evaluated to `True`).

Many times, the condition will be a regular expression **pattern**, within slashes, e.g. `/Hel+o+/`. For **patterns**, if the regular expression matches against the **record**, the condition evaluates to `True` and the action is executed. Else, the action is skipped.

Within `actions` and `conditions` you can access the current record as `$0` and the fields as `$1`, `$2`, …, `$n`, respectively. You can execute an `{ action }` before processing the first record (for instance to initialize variables), as well as after having processed the last record (for instance to print results) using the keywords `BEFORE { action }` and `AFTER { action }`. Multiple actions can be concatenated within a `{ }`-block, using `;`.

The most common `{ action }` is probably `{ print … }`, which takes a non-fixed comma-separated number of arguments. `{ print … }` will print each argument, and replace commas with the output field separator. Using `{ print … }`, we could do:

```sh
sean@pop-os:~$ echo -e "Hello World\n Hello Sean" | awk '{print $1 $2 }'
HelloWorld
HelloSean
sean@pop-os:~$ echo -e "Hello World\n Hello Sean" | awk '{print $1, $2 }'
Hello World
Hello Sean
sean@pop-os:~$ echo -e "Hello World\n Hello Sean" | awk '{print "Hello", $1, $2 }'
Hello Hello World
Hello Hello Sean
sean@pop-os:~$
```

For now, we are omitting the `condition`-part of our single `condition { action }`-program, which is why the `{ action }` is executed against every record in the input. Also notice how the `,` translates to spaces (in line 1, `$1 $2` gets String-concatenated and is therefore treated as a single argument). If we want, we could change what the comma translates to.

```sh
sean@pop-os:~$ echo -e "Hello World\n Hello Sean" | awk 'BEGIN { OFS="\t\t" } { print $1, $2 }'
Hello		World
Hello		Sean

```

What if we changed the input field separator to, say, `He[l]{2}o` (most `awk` implementations support regular expressions for RS, FS, ORS, OFS).

```sh
sean@pop-os:~$ echo -e "Hello World\n Hello Sean" | awk 'BEGIN { FS="He[l]{2}o"; OFS="" } { print $1, $2 }'
 World
  Sean
```

Notice that both `FS` and `OFS` were changed. As expected, we obtain one space in front of _World_ and two in front of _Sean_.

Next, let us use `condition` and `{ action }` together! We'll use our `fruit.txt` file from above for this.

```sh
sean@pop-os:~$ awk 'BEGIN {c=0} /[lm]e[ml]on/ {printf "The quantity of %s is %s\n", $1, $2; c+=$2} END {printf "The total amount of melon and lemon is: %s\n", c}' fruit.txt
The quantity of melon is 3
The quantity of lemon is 2
The total amount of melon and lemon is: 5
sean@pop-os:~$
```

Here, we use the **pattern** `[lm]e[ml]on` to select records that match both **lemon** and **melon** (as well as **memon** and **lelon**). We print a string to output the number of each type of fruit, and use the previously mentioned `END { action }` in combination with a variable `c` to print the total amount of melons and lemons. Also notice the use of the built-in action `printf` (that behaves pretty similar to its famous `C`-[counterpart](https://www.tutorialspoint.com/c_standard_library/c_function_printf.htm "printf in C")).

Let's look at another, more complex example. I recently wrote a one line `awk`-program to watch real-time CPU interrupts, which are accessible under proc/interrupts in a Linux-based OS. I use `watch` to run the command at a specified interval, in the present case every 0.1 seconds.

```sh
sean@pop-os:~$ watch -n.1 -x awk 'NR==1 {printf "\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4} /LOC/ {printf "%s\t%s\t%s\t%s\t%s\t\tLocal timer interrupts\n", $1, $2, $3, $4, $5}' /proc/interrupts

Every 0.1s: awk NR==1 {printf "\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4} /LOC/ {printf "%s\t%s\...  pop-os: Fri Oct 11 20:28:58 2019

        CPU0    CPU1    CPU2    CPU3
LOC:    2440342 2368815 2348514 3997973         Local timer interrupts
```

The program consists of two `condition { action }` pairs. The first pair matches the first line-here the condition uses the `NR`-variable (`NR` stands for "number record"). This condition only evaluates to `True` for line number `1`, hence the respective `printf` is only executed for line number `1`.

The second `condition { action }` pair looks for the string **"LOC"** using the straightforward pattern `LOC`—it matches against the line that contains local timer interrupt data. I grab and format this data, using `printf` once again. And voilà: I still don't understand Kernel Interrupts, but I am watching my computer screen for minutes, fascinated by the hundreds of interrupts (and `process|thread` context switches) flying past my screen.

So there you have it. `awk` — a language for text processing and terminal hacking, that you can use to process text data. The next time you curse over a broken `.csv` file, think of `awk` and see if you can write a small regular-expression-powered `awk`-program to fix things.
