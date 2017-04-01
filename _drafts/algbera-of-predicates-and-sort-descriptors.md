---
layout: post
title:  "The Algebra of Predicates and Sorting Functions"
date:   2017-04-01
categories: swift math algebra
---

In the article “[Algebraic Structure and Protocols]({% post_url 2015-02-17-algebraic-structure-and-protocols %})” we described how to use Swift protocols to describe some basic algebraic structures, such as semigroups and monoids, provided some simple examples, and then provided  constructions to build new instances from existing. Here we apply those ideas to the concrete ideas of predicates and sorting functions, and show how they build a wonderful little algebra that is quite expressive.

## Recall from last time…

…that we defined a semigroup and monoid as protocols satisfying some axioms:

```swift
protocol Semigroup {
  // **AXIOM** Associativity
  // For all a, b, c in Self:
  //    a.op(b.op(c)) == (a.op(b)).op(c)
  func op(_ s: Self) -> Self
}

protocol Monoid: Semigroup {
  // **AXIOM** Identity
  // For all a in Self:
  //    a.op(e) == e.op(a) == a
  static var e: Self { get }
}
```

Note that monoids are automatically semigroups by simply _forgetting_ that they has a distinguished identity element `e`.

Types that conform to these protocols have some of the simplest forms of computation around. They know how to take two values of the type, and combine them into a single value. We know of quite a few types that are monoids:

```swift
extension Bool: Monoid {
  func op(_ a: Bool) -> Bool {
    return self && a
  }
  static let e = true
}

extension Int: Monoid {
  func op(_ a: Int) -> Int {
    return self + a
  }
  static let e = 0
}

extension String: Monoid {
  func op(_ a: String) -> String {
    return self + a
  }
  static let e = ""
}

extension Array: Monoid {
  func op(_ a: Array) -> Array {
    return self + a
  }
  static var e: Array { return [] }
  //      ^-- Static properties are not allowed on generics in
  //          Swift 3.1, so we must store it as a computed variable.
}
```

Then we defined a special operator that can act on values of a semigroup:

```swift
precedencegroup SemigroupPrecedence { associativity: right }
infix operator <>: SemigroupPrecedence

func <> <S: Semigroup> (lhs: S, rhs: S) -> S {
  return lhs.op(rhs)
}
```

This allows us to abstract the idea of computation (two things combining into one) so that we can focus on structure instead of details:

```swift
1 <> 2 <> 3            // => 6
"foo" <> "bar"         // => "foobar"
[1, 3, 5] <> [2, 4, 6] // => [1, 3, 5, 2, 4, 6]
```

We were even able to write a form of `reduce` for monoids that didn’t need to take an initial value or accumulator because those concepts are already built into a monoid:

```swift
func mconcat <M: Monoid> (_ xs: [M]) -> M {
  return xs.reduce(M.e, <>)
}

mconcat([1, 2, 3])              // => 6
mconcat(["foo", "bar"])         // => "foobar"
mconcat([[1, 3, 5], [2, 4, 6]]) // => [1, 3, 5, 2, 4, 6]
```

## Constructing new monoids from old

In the <a href="{% post_url 2015-02-17-algebraic-structure-and-protocols %}#exercises">exercises</a> of the last article we encouraged the reader to play with some constructions that create new monoids from existing ones. For example, the set of all functions from a fixed type into a monoid can be expressed as:

```swift
struct FunctionM<A, M: Monoid> {
  let call: (A) -> M
}
```

This can be naturally made into a monoid:

```swift
extension FunctionM: Monoid {
  func op(_ s: FunctionM) -> FunctionM {
    return FunctionM { x in
      return self.call(x) <> s.call(x)
    }
  }

  static var e: FunctionM {
    return FunctionM { _ in M.e }
  }
}
```

In words, the computation `f <> g` of two functions `f, g: (A) -> M` produces a third function `(A) -> M` by mapping a value `a: A` into two values `f(a)`, `g(a)` in `M`, and then we combine them `f(a) <> f(b)`. We call this the _point-wise_ combining of `f` and `g`.

## Predicates

This construction pops up quite a bit in computer science. For example, functions of the form `(A) -> Bool` are called _predicates_, and they are precisely the types of functions you give `Array`’s `filter` method in order to obtain a subset of elements satisfying the predicate:

```swift
let isEven = { $0 % 2 == 0 }

Array(0...10).filter(isEven) // => [0, 2, 4, 6, 8, 10]
```

However, we saw that `Bool` is a monoid with `&&` as its operation and `true` as its identity. This means that `FunctionM<A, Bool>` is also a monoid. We can use Swift’s [generic typealiases](https://github.com/apple/swift-evolution/blob/master/proposals/0048-generic-typealias.md) to define quite simply:

```swift
typealias Predicate<A> = FunctionM<A, Bool>
```

Then constructing predicate instances can be done with:

```swift
let isLessThan10 = Predicate { $0 < 10 }
let isEven = Predicate { $0 % 2 == 0 }
```

Using the monoid operation to combine the predicates produces a new predicate which tests for integers less than 10 _and_ even:

```swift
let isLessThan10AndEven = isLessThan10 <> isEven
```

Recall that `FunctionM` has a `call` field for getting access to the underlying function the type represents and that `Predicate` is just a specialization of `FunctionM`, therefore `Predicate` similarly has a `call` field. That function is precisely what can be used with `Array`’s `filter` method:

```swift
Array(0...100).filter(isLessThan10AndEven.call) // => [0, 2, 4, 6, 8]
```

That doesn’t look as nice as it could if `Array` had first class support for `Predicate`. Fortunately, we can add it!

```swift
extension Array {
  func filtered(by predicate: Predicate<Element>) -> Array {
    return self.filter(predicate.call)
  }
}
```

Note that this `filtered(by:)` method could also be defined on the more general `Sequence` with minimal extra effort (see the exercises).

Now we can use `Predicate` more naturally with `Array`’s:

```swift
Array(0...100).filtered(by: isLessThan10AndEven) // => [0, 2, 4, 6, 8]
```

In fact, this first class support for `Predicate` means there’s no reason to define one off compositions of small predicates as we might as well use them inline:

```swift
Array(0...100).filtered(by: isLessThan10 <> isEven)
```

Further, we can create even smaller atomic units of predicates and have lots of flexibility in how we choose to compose them. We could have a function `isLessThan` that takes a `x: Comparable` value and produces a `Predicate` of all values less than `x`:

```swift
func isLessThan <C: Comparable> (_ x: C) -> Predicate<C> {
  return Predicate { $0 < x }
}

Array(0...100)
  .filtered(by: isLessThan(10) <> isEven) // => [0, 2, 4, 6, 8]

["foo", "bar", "baz", "qux"]
  .filtered(by: isLessThan("f")) // => ["bar", "baz"]
```

## Sorting functions

Functions that are used to sort collections also fit into this framework in a really beautiful way. To get there, we first need to define a very simple type:

```swift
enum Ordering {
  case lt
  case eq
  case gt
}
```

This type encapsulates the ideas of “less than”, “equal” and “greater than”.




## Exercises:

1. Define `filtered(by:)` on the more generic `Sequence` type.

1. Define the function `not<A>: Predicate<A> -> Predicate<A>` that reverses a predicate:

1. Define the functions `isGreaterThan`, `isLessThanOrEqualTo`, `isGreaterThanOrEqualTo` for generating predicates on a comparable, similarly to how we defined `isLessThan`.

1. Define the functions `isEqualTo` and `isNotEqualTo` for generating predicates on a equatable.








