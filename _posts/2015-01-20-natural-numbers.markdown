---
layout:     post
title:      "Creating the Natural Numbers from First Principles"
date:       2015-01-20
categories: swift math
summary:    "Learn how to construct the natural numbers from first principles in Swift."
author: Brandon Williams
---

> “God made the natural numbers; all else is the work of man.”
> – Leopold Kronecker

Let’s for a moment forget that Swift has any primitive types such as `Int`, `String`, arrays and even `Bool`. All we have are enums. Can we build the natural numbers (non-negative integers 0, 1, 2, …) from scratch?

The simplest way might be to just build a grab bag of values. We could try enumerating every natural explicitly:

```swift
enum NatLessThan4 {
  case Zero
  case One
  case Two
  case Three
}
```

Here we have explicitly enumerated all natural numbers less than 4. We could keep enlarging this type to cover more natural numbers, but clearly this isn’t going to scale. We need to think about natural numbers more abstractly.

Turns out, natural numbers can be constructed from two [basic objects](http://en.wikipedia.org/wiki/Peano_axioms). First, we start with the “smallest” member of the naturals, called `Zero`. Then we have a function `Succ` (the successor function) that takes a natural and returns the next natural. 

In this system the number `1` is represented by `Succ(Zero)`, i.e. the successor of `Zero`. `2` is `Succ(Succ(Zero))`, i.e. the successor of the succesor of `Zero`. And so on.

This gives an inductive definition of natural numbers. A natural number is either `Zero`, or the successor of natural number `Succ(n)`. This precisely translates to a recursive enum that we can write in Swift:

```swift
enum Nat {
  case Zero
  case Succ(Nat)
}
```

Unfortunately, this does not compile in Swift due to how the compiler handles the memory layout of a recursive enum. There’s an easy fix: we can mark the `Succ` case as `indirect` to let Swift figure this out:

```swift
enum Nat {
  case Zero
  indirect case Succ(Nat)
}
```

It’s unfortunate that we have to clutter our simple `Nat` type with a messy implementation detail.

We can now do the following to create a few values representing various natural numbers:

```swift
let zero: Nat = .Zero
let one: Nat = .Succ(.Zero)
let two: Nat = .Succ(one)
let three: Nat = .Succ(two)
let four: Nat = .Succ(.Succ(.Succ(.Succ(.Zero))))
```

For `one`, `two` and `three` we took the successor of previously defined values. For `four` we decided to chain many successors together to derive it directly from `Zero`. In fact, any natural number can (theoretically) be constructed in this manner, and therefore we have defined the natural numbers using only an enum. This is quite cumbersome to deal with of course, but nonetheless we have constructed the natural numbers. 

Now let’s see how easy or difficult it is to actually work with this type. One of the simplest functions we could try to implement is one that adds two natural numbers:

```swift
func add(_ a: Nat, _ b: Nat) -> Nat {
  ???
}
```

The recursive definition of `Nat` will lead us through implementing this funtion. Since `a` and `b` are enums, the only thing we can do with them is switch on their values:

```swift
func add(_ a: Nat, _ b: Nat) -> Nat {
  switch (a, b) {
  case (.Zero, .Zero):
    ???
  case (.Succ, .Zero):
    ???
  case (.Zero, .Succ):
    ???
  case (.Succ, .Succ):
    ???
  }
}
```

We have to figure out how to fill these cases. The first three are quite easy. `Zero` plus `Zero` is just `Zero`, and `Zero` plus something is just that something. We can use some wildcard pattern matching to simplify that even further:

```swift
func add(_ a: Nat, _ b: Nat) -> Nat {
  switch (a, b) {
  case (_, .Zero):
    return a
  case (.Zero, _):
    return b
  case (.Succ, .Succ):
    ???
  }
}
```

The last case that is left: how to add two natural numbers, each of which are decomposed as the successors of smaller natural numbers. Since we know how to add `Zero` to anything, we can try recursively breaking down these numbers to reach that base case. In fact, by taking the predecessor of `a` and the successor of `b` (and hence not changing the overall sum), we have made it one step closer to reaching the `Zero` base case. In code this looks like:

```swift
func add(_ a: Nat, _ b: Nat) -> Nat {
  switch (a, b) {
  case (_, .Zero):
    return a
  case (.Zero, _):
    return b
  case let (.Succ(pred_a), _):
    return add(pred_a, .Succ(b))
  }
}
```

Note that the last line is exactly what we verbalized: `a+b` is the sum of the predecessor of `a` and the successor of `b`, i.e. `a+b = (a-1)+(b+1)`. This recursive function will terminate since the predecessors of `a` will eventually reach `Zero`, which is a case that explicitly returns.

We can also overload `+` to make this more natural to use.

```swift
func + (a: Nat, b: Nat) -> Nat {
  return add(a, b)
}
```

And now we get to use this operator on our natural numbers:

```swift
let five = two + three
let ten = five + five
```

Ok. Well. That’s actually not telling us much. If you plug this into a playground these lines will only display as `(Enum Value)`. We probably want to come up with a way for testing equality of Nat values so that we can confirm that `five` is indeed equal to `.Succ(.Succ(.Succ(.Succ(.Succ(.Zero)))))` (*phew*).

So, let’s implement the `Equatable` protocol:

```swift
extension Nat : Equatable {}
func == (a: Nat, b: Nat) -> Bool {
  ???
}
```

Again we are forced to switch on `a` and `b` and analyze each case. This will play out like before where we unwrap successors in order to reduce `a` and `b` to the `Zero` base case.

```swift
extension Nat : Equatable {}
func == (a: Nat, b: Nat) -> Bool {
  switch (a, b) {
  case (.Zero, .Zero):
    return true
  case (.Zero, .Succ), (.Succ, .Zero):
    return false
  case let (.Succ(pred_a), .Succ(pred_b)):
    return pred_a == pred_b
  }
}
```

Our base cases are essentially the same. `Zero` is of course equal to `Zero`, and no successor could ever be equal to `Zero`. Then to consider two successors is a matter of checking their predecessors are equal, i.e. `a == b` if and only if `a-1 == b-1`.

Now we can verify that our add function does what is expected:

```swift
five == .Succ(.Succ(.Succ(.Succ(.Succ(.Zero)))))  // true
five == four                                      // false
one == one                                        // true
(one + three) == (two + two)                      // true
```

There are more arithmetic functions we can implement on `Nat` in order to flex our recursive muscles. For example multiplication. `Zero` times anything is `Zero`, so that’s our base case. Reducing to the base case involves observing that `a*b = (a-1) * b + b`. So we can reduce `a` until it reaches zero.

```swift
func * (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (_, .Zero), (.Zero, _):
    return .Zero
  case let (.Succ(pred_a), _):
    return pred_a() * b + b
  }
}
```

We can make sure this multiplication operates as we expect by testing some specific cases:

```swift
one * four == four                // true
two * two == four                 // true
four * three == two + two * five  // true
two * three == five               // false
```

Finally, we could try implementing exponentiation. I’ll leave that as an exercise for the reader (hint: `a^b = (a^(b-1)) * a`). If you want to play with this more you could try implementing `min`, `max`, modulus, `Comparable`, etc…

We have now constructed the natural numbers from scratch and implemented a bunch of arithmetic operations. Of course, `Nat` and the functions we defined are incredibly slow, but that wasn’t the point. It’s a fun exercise to take something as basic as the natural numbers and figure out how to build it from first principles, and even better that Swift’s type system is expressive enough to do this the right way. Some languages whose primary focus is mathematical correctness (such as [Agda](http://en.wikipedia.org/wiki/Agda_%28programming_language%29#Inductive_types)) use this inductive strategy to define natural numbers.

You can download this [playground](http://www.fewbutripe.com.s3.amazonaws.com/supporting/natural-numbers/natural-numbers.playground.zip) to poke around these ideas directly.

# Exercises

Below you will find some exercises to help you explore these ideas even deeper. You can try solving these exercises in the [playground](http://www.fewbutripe.com.s3.amazonaws.com/supporting/natural-numbers/natural-numbers.playground.zip) that accompanies this article.

1.) Implement exponentiation:

```swift
func exp(_ a: Nat, _ b: Nat) -> Nat {
  ???
}
```

2.) Make `Nat` implement the `Comparable` protocol.

3.) Implement `min` and `max`:

```swift
func min(_ a: Nat, _ b: Nat) -> Nat {
  ???
}

func max(_ a: Nat, _ b: Nat) -> Nat {
  ???
}
```

4.) Implement a distance function between natural numbers, i.e. the absolute value of their difference.

```swift
func distance(_ a: Nat, _ b: Nat) -> Nat {
  ???
}
```

5.) Implement modulus, i.e. the remainder after dividing `a` by `m`:

```swift
func modulus(_ a: Nat, _ m: Nat) -> Nat {
  ???
}
```

6.) Implement a predecessor function:

```swift
func pred(_ n: Nat) -> Nat? {
  ???
}
```

Since `Zero` doesn’t have a predecessor, this function must return an optional `Nat`.

7.) Make `Nat` implement the `IntegerLiteralConvertible` protocol.

8.) **Bonus:** The integers are a superset of the naturals and include all negative whole numbers. How might you model the integers as a new type in Swift?

