---
layout: post
title:  "Continuation-passing style in Swift"
date:   2015-01-01
categories: swift
---

We will explore the idea of **continuation-passing style** (**CPS**) in Swift and show how this leads to a form of computing that can be paused and resumed at will.

## Tail recursion

To get our feet wet we‘ll see how recursive functions naturally lead us to the idea of computations that can be paused and resumed at any point. Consider the following naïve implementation of the factorial function:

```swift
func factorial (n: Int) -> Int {
  if n <= 1 {
    return 1
  }
  return n * factorial(n-1)
}
```

Let’s expand this out for the case `n = 5` so that we can see what the Swift compiler has to deal with:

```swift
factorial(5)
5 * factorial(4)
5 * (4 * factorial(3))
5 * (4 * (3 * factorial(2)))
5 * (4 * (3 * (2 * factorial(1))))
5 * (4 * (3 * (2 * 1)))
5 * (4 * (3 * 2))
5 * (4 * 6)
5 * 24
120
```

Note that only once we get to the line with `factorial(1)` can we actually start reducing expressions and computing multiplications. This rightward drift of expressions also represents the stack frames that are pushed onto the call stack for each recursive call. Each stack frame comes with a cost, and if you find yourself in a sutation where you are creatng tens of thousands of frames you run the chance of running into a stack overflow.

The reason for this growing stack trace is that the line in `factorial` which does the recursive call is of the form: `n * factorial(n-1)`, i.e. it involves the recursive call *and then* some additional work, multiplying by `n`. If the recursive `factorial` call was the only thing happening on that `return` line, then we could re-use the stack frame and make this whole thing much more efficient. Let’s see how to rewrite `factorial` so that it takes advantage of this optimization:

```swift
func factorial (n: Int) -> Int {
  return _factorial(n, 1)
}

func _factorial (n: Int, result: Int) -> Int {
  return n <= 1 {
    return result
  }
  return _factorial(n - 1, n * result)
}
```

We’ve decided to create a new private, helper function `_factorial`. It's first argument `n` corresponds to the same thing in `factorial`, but it's second argument tracks the amount of the factorial we have computed so far. Let's expand this for `n=5` so we can see what is happening:

```swift
factorial(5)
_factorial(5, 1)
_factorial(4, 5 * 1)
_factorial(3, 4 * 5)
_factorial(2, 3 * 20)
_factorial(1, 2 * 60)
120
```

We no longer have the rightward drift,























