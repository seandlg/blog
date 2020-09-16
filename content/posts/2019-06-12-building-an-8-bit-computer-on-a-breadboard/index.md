---
layout: post
title: "Building an 8 bit computer on a breadboard"
date: 2019-06-12 14:07:54 +0200
categories: projects
tags: computer-architecture online-course self-learning microcode electronics logic-gates
author: Sean Eulenberg
---

Following the terrific online course [FromNand2Tetris](https://www.nand2tetris.org/ "Nand2Tetris Website") that I previously wrote an [article](https://sean.eulenberg.de/2019-05-14/what-nand-2-tetris-has-taught-me-about-computers-and-more-importantly-about-learning "Nand2Tetris Article") about, I decided to commit to [Ben Eater's Youtube Series](https://www.youtube.com/watch?v=HyznrdDSSGM&list=PLowKtXNTBypGqImE405J2565dvjafglHU "8-bit computer update"), in which he builds a fully functioning 8-bit computer from mere logic gates and 74LS series chips, on a breadboard. I first stumbled across this project with a couple of fellow students during my studies in China, but without the time or dedication required for such a project, we unfortunately never made it past the clock module.

Anyways! Ever since, I had this project stuck in the back of my head, and being naturally stubborn, I decided to tackle it some time in January this year.

I have quite the journey behind me.

{{< img src="images/HL_Overview.gif" title="My workspace." >}}

Without a doubt, this constitutes the single-most demanding project I have undertaken. Not necessarily in terms of time, but certainly in terms of perseverance and determination! At the same time as teaching me about electronics and computer architecture, I consolidated my credo about _intrinsic motivation_ — I might write a post about this personal discovery at some later stage.

## Computer modules

Alright, let's get to the computer. In essence, it consists of the following modules:

1. **The clock module:** This module creates short impulses that feed into the many electronic components that have to be kept in sync and is built using several [555-Timers](https://en.wikipedia.org/wiki/555_timer_IC "555-Timer IC") and some basic logic gates.
2. **The "A" and "B" registers:** These two 8-bit registers both feed into the ALU and can be addressed separately. Each register is built using two `74LS173s` and a `74LS245` for BUS communication.
3. **The Arithmetic Logic Unit (ALU):** In essence built out of two 4-bit adders (`74LS283`), two XOR-Gates (`74LS86`) and a `74LS245` for BUS communication.
4. **The Flags Register:** The Flags Register stores 2 values. The _Carry Flag_, which goes high when an arithmetic operation overflows, and the _Zero Flag_, which goes high whenever a calculation yields `0`. This register is also built using a `74LS173` Integrated Circuit (IC).
5. **The whopping 16 bytes of Random Access Memory (RAM):** The data itself is stored in two `74LS189` RAM chips (with a small inverter fix using `74LS004s`). Using some multiplexers (`74LS157`), one can switch between _Programming mode_ and _Running mode_. In programming mode, the user can write some program to RAM using some DIP switches.
6. **The Program Counter:** A simple counter (`74LS161`) that connects to the BUS and is used to address RAM to query a program. It can be set using (conditional) `jump`-instructions, which is what makes the computer Turing-complete.
7. **The Display Unit:** The display unit, as the name suggests, displays numbers up to 255 on a 7 segment display. An electrically erasable programmable read only memory chip (`28C16` EEPROM) is used to control the respective display segments of 4 individual displays. Displaying negative numbers as their Twos-complement is also possible.
8. **The Control Unit:** The Control Unit decodes every instruction after it has been fetched from memory. It is built using two `28C16` EEPROMs and runs through 5 microcode steps per instruction.

## Reflection

I cannot begin to describe how much I learned from building this computer. Previously, I knew little to nothing about electronics. Everything I knew about computer architecture built upon the great Online Course [FromNand2Tetris](https://www.nand2tetris.org/ "Nand2Tetris Website"). I didn't understand much about the inner workings of logic gates, registers, the clock module, microcode decoding, tri-state logic and so many other topics that interface with digital logic and computer architecture. Ben Eater pretty much taught me all of that and I'm incredibly excited that these resources are freely available on the Internet. You should really browse his [website](https://eater.net "Ben Eater's Website") to get an idea of how powerful his content is.

{{< img src="images/DTL_Overview.gif" title="The computer chewing over the multiplication problem 13x8. Here, I'm manually  adjusting the clock speed to speed up the calculation. The multiplication is realized using a program written in machine code, as the ALU only supports addition and subtraction." >}}
