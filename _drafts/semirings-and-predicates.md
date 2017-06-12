---
layout: post
title:  "Semirings and Predicates"
date:   2017-04-18
categories: swift math algebra semiring
author: Brandon Williams
---

In the article “[The Algebra of Predicates and Sorting Functions]({% post_url 2017-04-18-algbera-of-predicates-and-sorting-functions %})” we showed how predicates can be made into a monoid. In short, we considered `Bool` to be a monoid with its operation given by `&&` and identity `true`, and then defined `Predicate<A>` to be the type of functions `(A) -> Bool`. This allowed us to combine existing predicates in an expressive way, e.g. `isEven <> isLessThan(10)`.

One thing missing from that discussion is that `Bool` has another monoidal structure, `||` with `false`. 

## A tale of two monoids

The `Bool` type naturally has two monoidal structures: one defined by `(&&, true)` and the other by `(||, false)`. Neither of those is the _right_ one, or more important than the other, yet Swift’s protocols force us to choose only one for `Bool`. One way around this is to wrap `Bool` in another type so that we can conform it to the protocol without interferring with `Bool`:

```swift
struct ConjunctiveBool: Monoid {
  let value: Bool

  static let e = true

  static func <> (lhs: ConjunctiveBool, rhs: ConjunctiveBool) -> ConjunctiveBool {
  	return .init(value: lhs.value && rhs.value)
  }
}

struct DisjunctiveBool: Monoid {
  let value: Bool

  static let e = false

  static func <> (lhs: DisjunctiveBool, rhs: DisjunctiveBool) -> DisjunctiveBool {
  	return .init(value: lhs.value || rhs.value)
  }
}
```

We now have two different versions of booleans: one that is a monoid under conjunction and the other under disjunction. However, many times you dont want to separate the ideas of `&&` and `||` from `Bool`, but instead have one underlying structure that unifies them. This structure is called a _semiring_.

## Semirings

A semiring is much like a monoid, but it has an additional operation on it, and the operations must play nicely together. Formally, a semiring is a type with two operations, denoted by `|+|` and `|*|`, and two distinguished elements `zero` and `one` as identities, satisfying a bunch of axioms:

```swift
infix operator |+|: AdditionPrecedence
infix operator |*|: MultiplicationPrecedence

protocol Semiring {
	// **AXIOMS**
	//
	// Associativity:
	// 	 a |+| (b |+| c) == (a |+| b) |+| c
	// 	 a |*| (b |*| c) == (a |*| b) |*| c
	//
	// Identity:
	//   a |+| zero == zero |+| a == a
	//   a |*| one == one |*| a == a
	//
	// Commutativity of |+|:
	//   a |+| b == b |+| a
	//
	// Distributivity:
	//   a |*| (b |+| c) == a |*| b |+| a |*| c
	//   (a |+| b) |*| c == a |*| c |+| b |*| c
	//
	// Annihilation by zero:
	//   a |*| zero == zero |*| a == zero
	//
	static func |+| (lhs: Self, rhs: Self) -> Self
	static func |*| (lhs: Self, rhs: Self) -> Self
	static var zero: Self { get }
	static var one: Self { get }
}
```
 
We turn `Bool` into a semiring quite easily:

```swift
extension Bool: Semiring {
	static func |+| (lhs: Bool, rhs: Bool) -> Bool {
		return lhs || rhs
	}

	static func |*| (lhs: Bool, rhs: Bool) -> Bool {
		return lhs && rhs
	}

	static let zero = false
	static let one = true
}
```

## Constructing new semirings from existing

Many of the constructions we did for monoids also work for semigroups. For example, we can take the type of functions from a fixed type into a semiring:

```swift
struct FunctionS<A, S: Semiring> {
	let call: (A) -> Semiring
}
```

This type also naturally forms a semiring by performing the operations point-wise:

```swift
struct FunctionS: Semigroup {
	static func |+| (lhs: FunctionS, rhs: FunctionS) -> FunctionS {
		return FunctionS { lhs.call($0) |+| rhs.call($1) }
	}

	static func |*| (lhs: FunctionS, rhs: FunctionS) -> FunctionS {
		return FunctionS { lhs.call($0) |*| rhs.call($1) }
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

Now we can combine predicates using both conjunctive and disjunctive operations:

```swift
let isEven = Predicate { $0 % 2 == 0 }
let isLessThan10 = Predicate { $0 < 10 }
let isMagic = Predicate { $0 == 42 }

Array(0...100).filtered(by: isEven |*| isLessThan10 |+| isMagic)
```

This last expression describes getting only the integers from `0` to `100` that are even and less than 10, _or_ are the magic number. The operators are a bit of an eye-sore right now, so to remedy that we will leverage the boolean operators that are more familiar to us:

```swift
func || <A> (lhs: Predicate<A>, rhs: Predicate<A>) -> Predicate<A> {
	return lhs |+| rhs
}

func && <A> (lhs: Predicate<A>, rhs: Predicate<A>) -> Predicate<A> {
	return lhs |*| rhs
}
```

Now we can write:

```swift
Array(0...100).filtered(by: isEven && isLessThan10 || isMagic)
```


















