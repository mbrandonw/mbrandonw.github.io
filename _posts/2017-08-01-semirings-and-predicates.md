---
layout: post
title:  "Semirings and Predicates"
date:   2017-08-01
categories: swift math algebra semiring
author: Brandon Williams
summary: "We define semirings and construct predicates as semirings, leading to expressive sequence filtering."
image: /assets/semirings/cover.jpg
---

In the article “[The Algebra of Predicates and Sorting Functions]({% post_url 2017-04-18-algbera-of-predicates-and-sorting-functions %})” we showed how predicates can be made into a monoid. In short, we considered `Bool` to be a monoid with its operation given by `&&` and identity `true`, and then defined `Predicate<A>` to be the type of functions `(A) -> Bool`. This allowed us to combine predicates in an expressive way, e.g. `isEven <> isLessThan(10)` is the predicate that literally expresses “is even and is less than 10”.

One thing missing from that discussion is that `Bool` has another monoidal structure, `||` with `false`. We will discuss how to rectify that in detail by defining something called a _semiring_.

[Download](/assets/semirings/semiring.playground.zip) a playground of the code in this article to follow along at home!

## A tale of two monoids

First recall that a monoid is a type conforming to a protocol that specifies an associative binary operation and an identity element:

```swift
protocol Monoid {
  // **AXIOM** Associativity
  // For all a, b, c in Self:
  //    a <> (b <> c) == (a <> b) <> c
  static func <> (lhs: Self, rhs: Self) -> Self

  // **AXIOM** Identity
  // For all a in Self:
  //    a <> e == e <> a == a
  static var e: Self { get }
}
```

The `Bool` type naturally has two monoidal structures: one defined by `(&&, true)` and the other by `(||, false)`. Neither of those is the _right_ one, or more important than the other, yet Swift’s protocols force us to choose one for `Bool` (as do most programming languages out there!). One way around this is to wrap `Bool` in another type so that we can conform it to the protocol without interfering with `Bool`:

```swift
struct AndBool: Monoid {
  let value: Bool
  init(_ value: Bool) { self.value = value }

  static let e = AndBool(true)

  static func <> (lhs: AndBool, rhs: AndBool) -> AndBool {
    return .init(lhs.value && rhs.value)
  }
}

struct OrBool: Monoid {
  let value: Bool
  init(_ value: Bool) { self.value = value }

  static let e = OrBool(false)

  static func <> (lhs: OrBool, rhs: OrBool) -> OrBool {
    return .init(lhs.value || rhs.value)
  }
}
```

We now have two different versions of booleans: one that is a monoid under conjunction `&&` and the other under disjunction `||`. However, many times you don’t want to separate the ideas of `&&` and `||` from `Bool`, but instead have one underlying structure that unifies them. This structure is called a _semiring_.

## Semirings

A [semiring](https://en.wikipedia.org/wiki/Semiring) is much like a monoid, but it has an additional operation on it, and the operations must play “nicely” together. Formally, a semiring is a type with two operations, denoted by `+` and `*`, and two distinguished elements `zero` and `one` as identities, satisfying a bunch of axioms:

```swift
protocol Semiring {
  // **AXIOMS**
  //
  // Associativity:
  //    a + (b + c) == (a + b) + c
  //    a * (b * c) == (a * b) * c
  //
  // Identity:
  //   a + zero == zero + a == a
  //   a * one == one * a == a
  //
  // Commutativity of +:
  //   a + b == b + a
  //
  // Distributivity:
  //   a * (b + c) == a * b + a * c
  //   (a + b) * c == a * c + b * c
  //
  // Annihilation by zero:
  //   a * zero == zero * a == zero
  //
  static func + (lhs: Self, rhs: Self) -> Self
  static func * (lhs: Self, rhs: Self) -> Self
  static var zero: Self { get }
  static var one: Self { get }
}
```

A (perhaps) shorter way to say the same thing is that 1.) `S` is a commutative monoid with `(+, zero)`, 2.) a monoid with `(*, one)`, 3.) `*` distributes over `+`, and 4.) `zero` annihilates with `*`.

We can now turn `Bool` into a semiring:

```swift
extension Bool: Semiring {
  static func + (lhs: Bool, rhs: Bool) -> Bool {
    return lhs || rhs
  }

  static func * (lhs: Bool, rhs: Bool) -> Bool {
    return lhs && rhs
  }

  static let zero = false
  static let one = true
}
```

It may seem weird to define `+` and `*` on `Bool`, but `||` and `&&` really do behave like addition in multiplication since this distributivity property holds:

```swift
a && (b || c) == a && b || a && c
a *  (b +  c) == a *  b +  a *  c
```

## Constructing new semirings from existing

Many of the constructions we did for monoids also work for semirings. For example, we can take the type of functions from a fixed type into a semiring:

```swift
struct FunctionS<A, S: Semiring> {
  let call: (A) -> S
}
```

This type also naturally forms a semiring by performing the operations point-wise:

```swift
extension FunctionS: Semiring {
  static func + (lhs: FunctionS, rhs: FunctionS) -> FunctionS {
    return FunctionS { lhs.call($0) + rhs.call($0) }
  }

  static func * (lhs: FunctionS, rhs: FunctionS) -> FunctionS {
    return FunctionS { lhs.call($0) * rhs.call($0) }
  }

  static var zero: FunctionS {
    return FunctionS { _ in S.zero }
  }

  static var one: FunctionS {
    return FunctionS { _ in S.one }
  }
}
```

## A better definition of predicate

Rather than defining `Predicate` as the monoid of functions `(A) -> Bool`, we are going to defined as the semiring of functions `(A) -> Bool`:

```swift
typealias Predicate<A> = FunctionS<A, Bool>
```

And we can make Swift’s standard library understand these predicates by extending `Sequence`:

```swift
extension Sequence {
  func filtered(by p: Predicate<Element>) -> [Element] {
    return self.filter(p.call)
  }
}
```

Now we can combine predicates using both conjunctive and disjunctive operations and apply it to sequences:

```swift
let isEven = Predicate<Int> { $0 % 2 == 0 }
let isLessThan = { max in Predicate<Int> { $0 < max } }
let isMagic = Predicate<Int> { $0 == 13 }

Array(0...100).filtered(by: isEven * isLessThan(10) + isMagic)
```

This last expression describes getting only the integers from `0` to `100` that are even and less than 10, _or_ are the magic number. It reads quite nicely, but it would be even better if we could use `||` and `&&`, so let’s define them!

```swift
func || <A> (lhs: Predicate<A>, rhs: Predicate<A>) -> Predicate<A> {
  return lhs + rhs
}

func && <A> (lhs: Predicate<A>, rhs: Predicate<A>) -> Predicate<A> {
  return lhs * rhs
}
```

Now we can write:

```swift
Array(0...100).filtered(by: isEven && isLessThan(10) || isMagic)
```

And now that reads great! We can even take it a step further by defining a prefix function `!` for negating a predicate:

```swift
prefix func ! <A> (p: Predicate<A>) -> Predicate<A> {
  return .init { !p.call($0) }
}

Array(0...100).filtered(by: isEven && !isLessThan(10) || isMagic)
```

<!-- ## Semiring morphisms

Certain functions between semirings `f: (S) -> T` are more “well-behaved” than others in that they place nicely with the underlying semiring structures. In particular, `f` is said to be a “semiring morphism” if:

```swift
// for all a, b: S
f(a + b) = f(a) + f(b)
f(a * b) = f(a) * f(b)
f(S.zero) = T.zero
f(S.one) = T.one
``` -->

## Conclusion

We have now seen how sometimes when a type seems to have two different monoidal structures on it, secretly it may be a semiring where the two structures play nicely together! There can still be times where a type has two different monoidal structures on it such that they do not form a semiring, in which case you must resort to wrapping the type in a new type that provides the custom conformance.

## Exercises

1.) [Previously]({% post_url 2017-04-18-algbera-of-predicates-and-sorting-functions %}) we defined a `concat` function

```swift
func concat <M: Monoid> (_ xs: [M]) -> M {
  return xs.reduce(M.e, <>)
}
```

that concatenates an array of monoidal values into a single one by `<>`’ing them together. Semirings have two versions of this, so define em!

```swift
func add<S: Semiring>(_ xs: [S]) -> S {
  ???
}

func multiply<S: Semiring>(_ xs: [S]) -> S {
  ???
}
```

2.) A semiring `(S, +, *, zero, one)` naturally induces two different monoids, `(S, +, zero)` and `(S, *, one)`, where you “forget“ one of the operations. The former is even a commutative monoid. Make two new types `AdditiveMonoid<S: Semiring>` and `MultiplicativeMonoid<S: Semiring>` that converts a semiring to its monoid form.

3.) [Recall]({% post_url 2015-02-17-algebraic-structure-and-protocols %}) that a “commutative monoid” is a monoid `A` in which `a <> b = b <> a` for all `a, b: A`. Show that

```swift
struct EndoS<A: CommutativeMonoid> {
  let call: (A) -> A
}
```

is a semiring where `+` is given by pointwise `<>`-application of functions and `*` is given by function composition.

4.) A [ring](https://en.wikipedia.org/wiki/Ring_(mathematics)) is a semiring that has the additional axiom that addition is invertible, i.e. there is a function `inverse: (S) -> S` such that `a + inverse(a) = inverse(a) + a = S.zero` for all `a: S`. Can you think of anything that form a ring? Does `Bool` for a ring?
