---
layout: post
title:  "Lenses and Swift KeyPaths"
date:   2017-04-28
categories: swift fp
author: Brandon Williams
---

An important aspect of functional programming languages is the use of immutable data. Applications written using immutable data tend to be easier to reason about, but some may argue that it comes at the cost of ease of use. For example, to change one field of an immutable value, one must construct a whole new copy of the value leaving all fields fixed except for the one being changed. Compared to the simple getters and setters of mutable values, that does seem needlessly complicated.

Swift’s copy-on-write value types solve this pain point, for it is easy to copy a value and make changes to it without affecting the original. However, by pursuing a systematic study on other ways to solve this problem, we can uncover a beautiful world of composability that is hidden from the getter/setter world.

We will explore the topic of “lenses” as a means to solve this problem. They are a first-class type to represent a getter and setter for a field of a type, where the setter must return a new value and not mutate.


TODO: playground link

One way the functional programming community has approached this topic is via “lenses.” Even “lenses” breakdown into a multitude of approaches (see [here](https://hackage.haskell.org/package/lens), [here](https://github.com/purescript-contrib/purescript-profunctor-lenses), [here](https://hackage.haskell.org/package/fclabels)).


<!-- However, in the search to find a better way to handle these annoyances we can cook up an elegant construction to handle functional getters and setters. Further, it opens the doors to additional constructions that are hard to see from the mutable world. -->
