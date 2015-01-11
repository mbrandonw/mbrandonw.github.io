---
layout: post
title:  "Solutions to Exercises from “Proof in Functions”"
date:   2015-01-06
categories: swift math
---

In the article [“Proof in Functions”]({% post_url 2015-01-06-proof-in-functions %}) I provided some exercises at the end. I got a lot of tweets and emails about those exercises, so I decided to provide some solutions.

1.) The first two are the only implementable functions:

```swift
func f <A, B> (x: A) -> B -> A {
  return { _ in x }
}

func f <A, B> (x: A, y: B) -> A {
  return x
}
```

The third function cannot be implemented because it’s corresponding logical statement is “If \\(P\\) implies \\(Q\\), then \\(P\\) is true,” which is clearly false. Knowing that a proposition implies some other proposition does not make it true.

The main reason I stacked these three functions together is because they all have a similar shape: `ABA`. In fact, one can transform the second function into the first via currying. However, there is no way to transform the first into the third.

2.) Let’s use the idea of “hole-driven development” to fill this in. We need to return something of the form `((C, B) -> C) -> ((C, A) -> C)`, so it's a close that accepts `((C, B) -> C)` as an argument:

```swift
func f <A, B, C> (f: A -> B) -> ((C, B) -> C) -> ((C, A) -> C) {
  return { g in
    ???
  }
}
```

Now we need to return something of the form `((C, A) -> C)`, which is a closure accepting `(C, A)` as an argument:

```swift
func f <A, B, C> (f: A -> B) -> ((C, B) -> C) -> ((C, A) -> C) {
  return { g in
    return { c, a in
      ???
    }
  }
}
```






