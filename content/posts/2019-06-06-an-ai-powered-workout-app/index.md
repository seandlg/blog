---
layout: post
title: "An AI-powered smart workout App"
date: 2019-06-06 14:52:53 +0200
categories: projects
tags: AI App Android Workout Sports Image-Recognition
author: Sean Eulenberg
---

In 2017/2018, I was studying in China for a year for a Masters degree in Industrial engineering. Towards the end of the degree, we were told that we could propose any topic for our final Mini thesis. Excited by the flexibility this provided, I decided to brainstorm ideas that would involve image recognition. My thinking was the following:

1. I had previously studied Machine learning, but lacked practical experience.
2. Image recognition had undergone a revolution in the past years. I was convinced that many ideas could be implemented by simply using the powerful tools available on the Internet.
3. A hands-on project would allow me to combine design, development and machine learning to build something that I could later showcase.

# The idea

From calorie estimators to bicycle traffic trackers — I had many ideas. In liaison with my [professor](http://www.ie.tsinghua.edu.cn/eng/Show/index/cid/29/id/16.html "Prof. Rau, Pei-Luen, Tsinghua University"), I finally decided to build an Android App that tracks a users body-weight workout. After some initial research, I refined the idea, defined objectives and named the project **xrcs** (short for exercise). In summary:

**Idea**: xrcs automatically keeps track of a users’ bodyweight workout by analyzing a video stream and detecting the user while he is performing the workout. It uses a deep learning neural network (DLNN) in the backend that proposes bounding boxes for the location of the user. The basic idea of xrcs is to track these proposed bounding boxes to thereby track the movement of the user. This should allow for identifying if the user has e.g. performed a pullup or a pushup.

**Supreme Objective**: Implementation of an algorithm that uses the output from a DLNN to correctly identify when a user performs repetitions of a certain exercise.

I expected that no actual training of any DLNN would be required! In particular, Google had open-sourced libraries that use [Tensorflow](https://www.tensorflow.org/ "Tensorflow") on Android smartphones. Notably, these came with a wide range of [examples](https://github.com/tensorflow/tensorflow/tree/master/tensorflow/examples/android "Tensorflow on Android") — one of which could already perform the detection of humans — at a whopping ~20 FPS on a smartphone! I was thrilled!

# The result

Though Tensorflow for Android was at a heavy development stage, I made quick progress. I created design sheets and brainstormed first algorithms that use bounding boxes to track bodyweight workout. Eventually, everything came together and a first version of the app was born.

{{< video src="media/demo.mp4" >}}

I recently decided to polish the App up a little to bring it to the [Google PlayStore](https://play.google.com/store/apps/details?id=com.xrcs.android "xrcs on the Play Store"). I even thought of founding a Startup in the field of image-recognition-based workout tracking, but mixed feedback from some gyms I talked to has kept me from seriously considering this idea at this stage. Further feedback will be helpful - though I'd definitely try to switch to pose estimation based algorithms.
