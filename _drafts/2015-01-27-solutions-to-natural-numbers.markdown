---
layout:     post
title:      "[Solutions to Exercises] “Creating the Natural Numbers from First Principles”"
date:       2015-01-27
categories: swift math
summary:    ""
---

In the article “[Creating the Natural Numbers from First Principles]({% post_url 2015-01-20-natural-numbers %})” I provided some exercises at the end. If these exercises were easy for you, skip down to the solution of the bonus where I outline an interesting construct and provide more exercises for even deeper exploration.

1.) We need to implement exponentiation for `Nat`. Switching on `a` and `b` we have:

```swift
func exp (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (.Succ, .Zero):
    ???
  case (.Zero, .Succ):
    ???
  case (.Succ, .Succ):
    ???
  case (.Zero, .Zero):
    ???
  }
}
```

The first case is asking for the value of `a^0`. A positive integer raised to the zeroth power is just `1`. The next case is asking for `0^b`, which clearly is `0`. We can fill in those cases now:

```swift
func exp (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (.Succ, .Zero):
    return .Succ(.Zero)
  case (.Zero, .Succ):
    return .Zero
  case (.Succ, .Succ):
    ???
  case (.Zero, .Zero):
    ???
  }
}
```

Next we need `a^b` where we know `a` and `b` are positive natual numbers. We can reduce this to our base cases by observing that `a^b = a^(b-1) * a`:

```swift
func exp (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (.Succ, .Zero):
    return .Succ(.Zero)
  case (.Zero, .Succ):
    return .Zero
  case let (.Succ, .Succ(pred_b)):
    return exp(a, pred_b()) * a
  case (.Zero, .Zero):
    ???
  }
}
```

Now, this last case: `0^0`. In math this is left as an undefined value, so technically we should probably throw a `fatalError` or something. But, the standard library math function evaluates `pow(0.0, 0.0)` to be `1.0`, so we’ll adopt that. The final function is:


```swift
func exp (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (_, .Zero):
    return .Succ(.Zero)
  case (.Zero, .Succ):
    return .Zero
  case let (.Succ, .Succ(pred_b)):
    return exp(a, pred_b()) * a
  }
}
```

2.) Next we make `Nat` implement the `Comparable` protocol:

```swift
extension Nat : Comparable {}
func < (a: Nat, b: Nat) -> Bool {
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

The first three of these cases are obvious: `Zero` is less than every natural number except for itself.

```swift
extension Nat : Comparable {}
func < (a: Nat, b: Nat) -> Bool {
  switch (a, b) {
  case (.Zero, .Succ):
    return true
  case (_, .Zero):
    return false
  case (.Succ, .Succ):
    ???
  }
}
```

The last case is done recursively using the predecessors of `a` and `b` and the fact that `a < b` if and only if `a-1 < b-1`:

```swift
extension Nat : Comparable {}
func < (a: Nat, b: Nat) -> Bool {
  switch (a, b) {
  case (.Zero, .Succ):
    return true
  case (_, .Zero):
    return false
  case let (.Succ(pred_a), .Succ(pred_b)):
    return pred_a() < pred_b()
  }
}
```

3.) This question was to define `min` and `max` for `Nat`, but really we get that for free by adopting the `Comparable` protocol. I didn’t really think this one through :/

4.) Now we want to implement the distance function:

```swift
func distance (a: Nat, b: Nat) -> Nat {
  ???
}
```

This should return the absolute value of the difference between `a` and `b`. Our base cases are derived from the fact that `distance(n, .Zero) == distance(.Zero, n) == n`:

```swift
func distance (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (.Zero, _):
    return b
  case (_, .Zero):
    return a
  case (.Succ, .Succ)
    ???
  }
}
```

Now the last case can reduce `a` and `b` so that we get closer to the base case:


```swift
func distance (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (.Zero, .Zero):
    return .Zero
  case (.Zero, .Succ):
    return b
  case (.Succ, .Zero):
    return a
  case let (.Succ(pred_a), .Succ(pred_b)):
    return distance(pred_a(), pred_b())
  }
}
```

I explicity put every case instead of wildcards because the Swift compiler didn’t think I was being exhaustive in my case statements for some reason.

5.) Using the `distance` function from above we can write this quite easily:

```swift
func modulus (a: Nat, m: Nat) -> Nat {
  if a < m {
    return a
  }
  return modulus(distance(a, m), m)
}

modulus(five, two) == one
modulus(.Succ(five), two) == .Zero
```

Notice that `distance` is simulating subtraction in `Nat`.

6.) This function is quite simple to implement:

```swift
func pred (n: Nat) -> Nat? {
  switch n {
  case .Zero:
    return nil
  case let .Succ(pred):
    return pred()
  }
}

pred(two) == one
pred(.Zero) == nil
```

7.) Implementing the `IntegerLiteralConvertible` involves filling in this function:

```swift
extension Nat : IntegerLiteralConvertible {
  init(integerLiteral value: IntegerLiteralType) {
    self = ???
  }
}
```

Now, every function we wrote involving `Nat` was recursive, and that’s due to the inductive nature of `Nat`. Unfortunately we cannot inmplement `init` using recursion. So, we will need to define a helper function:

```swift
extension Nat : IntegerLiteralConvertible {
  init(integerLiteral value: IntegerLiteralType) {
    self = Nat.fromInt(value)
  }

  static func fromInt (n: Int, accum: Nat = .Zero) -> Nat {
    if n == 0 {
      return accum
    }
    return Nat.fromInt(n-1, accum: .Succ(accum))
  }
}

let six: Nat = 6        // true
six == .Succ(five)      // true
let seven = Nat.Succ(6) // true
seven == six + 1        // true
```

8.) This will be a topic of a future post where we will discuss a very general construction for turning any commutative monoid into an abelian group. In a very precise sense, this is the most universal and “correct” way of constructing the integers from the natural numbers.

However, only using what we know from the previous [article]({% post_url 2015-01-20-natural-numbers %}) we can construct the integers in a less general manner. An integer is either a natural number, or the negative of a natural number. This perfectly translates into an enum in Swift:

```swift
enum Z {
  case Neg(Nat)
  case Pos(Nat)
}
```

I’m using `Z` for this type because that is what is used in mathematics (for the German word *Zahlen*, and the symbol used is \\(\mathbb Z\\)).

To make this type resemble the integers we should define addition, multiplication, equality, et cetera. Some of that would look like this:

```swift
func + (a: Z, b: Z) -> Z {
  switch (a, b) {
  case let (.Neg(a), .Neg(b)):
    return .Neg(a + b)
  case let (.Pos(a), .Pos(b)):
    return .Pos(a + b)
  case let (.Pos(a), .Neg(b)):
    return a > b ? .Pos(distance(a, b)) : .Neg(distance(a, b))
  case let (.Neg(a), .Pos(b)):
    return a < b ? .Pos(distance(a, b)) : .Neg(distance(a, b))
  }
}

func * (a: Z, b: Z) -> Z {
  switch (a, b) {
  case let (.Neg(a), .Neg(b)):
    return .Pos(a * b)
  case let (.Pos(a), .Pos(b)):
    return .Pos(a * b)
  case let (.Pos(a), .Neg(b)):
    return .Neg(a * b)
  case let (.Neg(a), .Pos(b)):
    return .Neg(a * b)
  }
}

extension Z : Equatable {}
func == (a: Z, b: Z) -> Bool {
  switch (a, b) {
  case let (.Neg(a), .Neg(b)):
    return a == b
  case let (.Pos(a), .Pos(b)):
    return a == b
  case let (.Pos(a), .Neg(b)):
    return a == .Zero && b == .Zero
  case let (.Neg(a), .Pos(b)):
    return a == .Zero && b == .Zero
  }
}
```

We can now construct some integers and perform some arithmetic on them:

```swift
let pos_two = Z.Pos(two)
let neg_two = Z.Neg(two)
let pos_four = Z.Pos(four)
let neg_four = Z.Neg(four)

neg_two * neg_two == pos_two + pos_two
pos_two * neg_two == neg_four
```

Now, we have indeed constructed the integers from the natural numbers `Nat`, but there is something not quite right about this solution. In the definition of `+` we had to use the fact that `Nat` is comparable. Otherwise, the definition of `Z` depended on only the abstract properties of `Nat`.

Turns out, there is a very general construction that can be used to make `Z` out of `Nat`, but it also works in many other situations. Even better, in a very precise since, it is the most universal way of constructing `Z` out of `Nat`. This will be the topic of a future post after the necessary concepts have been developed. This object is known as the “[Grothendieck group](http://en.wikipedia.org/wiki/Grothendieck_group)”, and it constructs an abelian group from a commutative monoid.


I leave it as an exercise to develop the rest of the integer theory, in particular:

* Make `Z` implement `Comparable`.
* Define the predecessor function `pred (Z) -> Z` (no longer need the optional return type).
* Define the absolute value function: `abs (Z) -> Nat`.
* Define subtraction `- (Z, Z) -> Z`.
* Define exponentiation `exp (Z, Nat) -> Z`. Note that the power is `Nat` because if one uses negative exponents one needs fractions.
* **Bonus**: Can you construct the rational numbers (fractions `a/b`) from `Z`?

