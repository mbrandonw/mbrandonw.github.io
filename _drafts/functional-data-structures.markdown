---
layout: post
title:  "Functional Data Structures in Swift"
date:   2015-03-01
categories: swift fp
author: Brandon Williams
---

In a previous [article]({% post_url 2015-01-20-natural-numbers %}) we explored the idea of constructing the natural numbers from first principles. We ended up with a data structure that looked like this:

```swift
enum Nat {
  case Zero
  case Succ(@autoclosure () -> Nat)
}
```
That is, a natural number is either `.Zero`, or the successor of a natural number `.Succ(Nat)`. Remember that the `@autoclosure` is due to a Swift limitation in which recursive enums are not allowed.

That article laid the groundwork for thinking about data structures in a more atomic, functional way.


```swift
typealias Nat = List<()>

let zero = Nat.Nil
let one = Nat.Succ()
```
