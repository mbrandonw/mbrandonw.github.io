---
layout: post
title:  "Lenses and Swift KeyPaths"
date:   2017-08-28
categories: swift fp
author: Brandon Williams
---

An important aspect of functional programming languages is the use of immutable data. Applications written using immutable data tend to be easier to reason about, but some may argue that it comes at the cost of ease of use. For example, to change one field of an immutable value, one must construct a whole new copy of the value leaving all fields fixed except for the one changing. Compared to the simple getters and setters of mutable values, that does seem needlessly complicated.

Swift’s copy-on-write semantics for value types solve this pain point, for it is easy to copy a value and make changes to it without affecting the original. However, by pursuing a systematic study on other ways to solve this problem we can uncover a beautiful world of composability that is hidden from the getter/setter world.

We will explore the topic of “lenses” as a means to solve this problem. They solve this problem by 

TODO: playground link
