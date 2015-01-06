---
layout: post
title:  "Algebraic structure and protocols"
date:   2015-01-01
categories: swift math algebra
---


```swift
protocol Semigroup {
  func sop (g: Self) -> Self
}
```

```swift
protocol Monoid : Semigroup {
  class func mid () -> Self
}
```

```swift
protocol Group : Monoid {
  func inv () -> Self
}
```
