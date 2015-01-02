---
layout: post
title:  "Creating the natural numbers from first principles "
date:   2015-01-01
categories: swift math
---

> “God made the natural numbers; all else is the work of man.”
> – Leopold Kronecker

Let’s for a moment forget that Swift has any primitive types such as `Int`, `String`, arrays and even `Bool`. All we have are enums. Can we build the natural numbers (0, 1, 2, …) from scratch?

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

However, this does not compile. Swift does not currently allow recursive enums. We can get around this by replacing the recursive `Nat` reference with an autoclosure:

```swift
enum Nat {
  case Zero
  case Succ(@autoclosure () -> Nat)
}
```

It’s unfortunate that we have to clutter our simple `Nat` type with a messy implementation detail. We have to remember that anytime we extract a value out of the `Succ` case we must invoke it with `()` in order to execute the closure.

We can now do the following to create a few values representing various natural numbers:

```swift
let zero = Nat.Zero
let one: Nat = .Succ(.Zero)
let two: Nat = .Succ(one)
let three: Nat = .Succ(two)
let four: Nat = .Succ(.Succ(.Succ(.Succ(.Zero))))
```

For `one`, `two` and `three` we took the successor of previously defined values. For `four` we decided to chain many successors together to derive it directly from `Zero`. In fact, any natural number can (theoretically) but constructed in this manner, and therefore we have defined the natural numbers using only an enum. This is quite cumbersome to deal with of course, but nonetheless we have constructed the natural numbers. 

Now let’s see how easy or difficult it is to actually work with this type. One of the simplest functions we could try to implement is one that adds two natural numbers:

```swift
func add (a: Nat, b: Nat) -> Nat {
  // ???
}
```

The recursive definition of `Nat` will lead us through implementing this funtion. Since `a` and `b` are enums, the only thing we can do with them is switch on their values:

```swift
func add (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (.Zero, .Zero):
    // ???
  case (.Succ, .Zero):
    // ???
  case (.Zero, .Succ):
    // ???
  case (.Succ, .Succ):
    // ???
  }
}
```

We have to figure out how to fill these cases. The first three are quite easy. `Zero` plus `Zero` is just `Zero`, and `Zero` plus something is just that something. We can use some wildcard pattern matching to simplify that even further:

```swift
func add (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (_, .Zero):
    return a
  case (.Zero, _):
    return b
  case (.Succ, .Succ):
    // ???
  }
}
```

The last case is left: how to add two natural numbers, each of which are decomposed as the successors of smaller natural numbers. Since we know how to add `Zero` to anything, we can try recursively breaking down these numbers to reach that base case. In fact, by taking the predecessor of `a` and the successor of `b` (and hence not changing the overall sum), we have made it one step closer to reaching the `Zero` base case. In code this looks like:

```swift
func add (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (_, .Zero):
    return a
  case (.Zero, _):
    return b
  case let (.Succ(pred), _):
    return pred() + .Succ(b)
  }
}
```

Notice in that last line we had to invoke `pred()` since technically the `Succ` case holds an autoclosure and not an actual `Nat`. Also note that the last line is exactly what we verbalized: `a+b` is the sum of the predecessor of `a` and the successor of `b`, i.e. `a+b = (a-1)+(b+1)`. This recursive function will terminate since the predecessors of `a` will eventually reach `Zero`, which is a case that explicitly returns.

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

Ok. Well. That’s actually not telling us much. If you plug this into a playground these lines will only display as `(Enum Value)`. We probably want to come up with a way for testing equality of Nat values so that we can confirm that `five` is indeed equal to `.Succ(.Succ(.Succ(.Succ(.Succ(.Zero)))))` (phew).

So, let’s implement the `Equatable` protocol:

```swift
extension Nat : Equatable {}
func == (a: Nat, b: Nat) -> Bool {
  // ???
}
```

Again we are forced to switch on `a` and `b` and analyze each case. This all will play out like before where we unwrap successors in order to reduce `a` and `b` to the `Zero` base case.

```swift
extension Nat : Equatable {}
func == (a: Nat, b: Nat) -> Bool {
  switch (a, b) {
  case (.Zero, .Zero):
    return true
  case (.Zero, .Succ), (.Succ, .Zero):
    return false
  case let (.Succ(preda), .Succ(predb)):
    return preda() == predb()
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

There are more arithmetic functions we can implement on `Nat` in order to flex our recursive muscles. For example multiplication. `Zero` times anything is `Zero`, so that’s our base case. Reducing to the base case involves observing that `a*b = a*(b-1) + b`. So we can reduce `b` until it reaches zero.

```swift
func * (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (_, .Zero), (.Zero, _):
    return .Zero
  case let (.Succ(pred), _):
    return b + pred() * b
  }
}
```

And finally, implementing exponentiation. I’ll leave that as an exercise for the reader (hint: `a^b = (a^(b-1)) * b`). If you want to play with this more you could try implementing `min`, `max`, modulus, `Comparable`, etc…

We have now constructed the natural numbers from scratch and implemented a bunch of arithmetic operations. Of course, `Nat` and the functions we defined are incredibly slow, but that wasn’t the point. It’s a fun exercise to take something as basic as the natural numbers and figure out how to build it from first principles, and even better that Swift’s type system is expressive enough to do this the right way. Some languages whose primary focus is mathematical correctness (such as [Agda](http://en.wikipedia.org/wiki/Agda_%28programming_language%29#Inductive_types)) use this inductive strategy to define natural numbers.

You can download this playground to poke around these ideas directly.

# Exercises

1.) Implement exponentiation: `a^b`.

2.) Implement `min` and `max`.

3.) Make Nat implement the `Comparable` protocol.

4.) Implement modulus: `a % m`
