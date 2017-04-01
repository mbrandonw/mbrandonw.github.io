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

This type encapsulates the ideas of “less than”, “equal” and “greater than”. We can turn it into a monoid quite simply, but unfortunately it takes some malice aforethought to get it right, so hopefully it will become clear to the reader soon:


```swift
extension Ordering: Monoid {
  func op(_ s: Ordering) -> Ordering {
    switch (self, s) {
    case (.lt, _): return .lt
    case (.gt, _): return .gt
    case (.eq, _): return s
    }
  }

  static let e = Ordering.eq
}
```

Functions of the form `(A, A) -> Ordering` are precisely the types of functions that allow us to sort collections of values of `A`, for they map pairs `(lhs, rhs)` to `.lt`, `.gt` and `.eq` values to describe the order `lhs` and `rhs` are currently in. A sorting algorithm can use those values to figure out how to rearrange the values in a collection. Since `Ordering` is a monoid, the type of functions `(A, A) -> Ordering` is also a monoid, which is precisely `FunctionM<(A, A), Ordering>`. We give this the name `Comparator<A>` and define it with a typealias:

```swift
typealias Comparator<A> = FunctionM<(A, A), Ordering>
```

It is easy enough to cook up instances of comparators:

```swift
let intComparator = Comparator<Int> {
  $0 < $1 ? .lt : $0 > $1 ? .gt : .eq
}

let stringComparator = Comparator<String> {
  $0 < $1 ? .lt : $0 > $1 ? .gt : .eq
}
```

More generally, anything conforming to `Comparable` can be used to derive a comparator:

```swift
extension Comparable {
  static func comparator() -> Comparator<Self> {
    return Comparator.init { $0 < $1 ? .lt : $0 > $1 ? .gt : .eq }
  }
}

Int.comparator()
String.comparator()
```

We can make use of comparators by extending `Array` so that it understands how to use them:

```swift
extension Array {
  func sorted(by comparator: Comparator<Element>) -> Array {
    return self.sorted { comparator.call($0, $1) == .lt }
  }
}

[4, 6, 2, 8, 1, 2].sorted(by: Int.comparator())
```

This works, but it isn’t too impressive. We aren’t using the monoid structure on `Comparator` at all yet. To do that, let’s cook up a more interesting sorting challenge. Consider the following model:

```swift
struct User {
  let id: Int
  let firstName: String
  let lastName: String
}
```

We want to sort an array of users `[User]` first by their last name, then first name, and then finally in order to ensure a well-defined sorting of the array we will sort by `id` just case two users have the exact same name. To begin we define a few basic comparators to help us out:

```swift
let idComparator = Comparator<User> {
  Int.comparator().call($0.id, $1.id)
}

let firstNameComparator = Comparator<User> {
  String.comparator().call($0.firstName, $1.firstName)
}

let lastNameComparator = Comparator<User> {
  String.comparator().call($0.lastName, $1.lastName)
}
```

These can be combined together to build the comparator we previously described. To test it out, we build a large array of users and sort it:

```swift
let users = [
  User(id: 1,  firstName: "Denuy",    lastName: "Mosler"),
  User(id: 2,  firstName: "Daror",    lastName: "Achia"),
  User(id: 3,  firstName: "Achyk",    lastName: "Echsold"),
  User(id: 4,  firstName: "Ightrayu", lastName: "Rylye"),
  User(id: 5,  firstName: "Ageghao",  lastName: "Schohin"),
  User(id: 6,  firstName: "Umath",    lastName: "Achia"),
  User(id: 7,  firstName: "Risash",   lastName: "Radves"),
  User(id: 8,  firstName: "Gaon",     lastName: "Tanes"),
  User(id: 9,  firstName: "Rakgeng",  lastName: "Worirr"),
  User(id: 10, firstName: "Ightwbel", lastName: "Loler"),
  User(id: 11, firstName: "Ightrayu", lastName: "Rylye")
]

users.sorted(
  by: lastNameComparator <> firstNameComparator <> idComparator
)
// => [ {id 2,  firstName "Daror",    lastName "Achia"},
//      {id 6,  firstName "Umath",    lastName "Achia"},
//      {id 3,  firstName "Achyk",    lastName "Echsold"},
//      {id 10, firstName "Ightwbel", lastName "Loler"},
//      {id 1,  firstName "Denuy",    lastName "Mosler"},
//      {id 7,  firstName "Risash",   lastName "Radves"},
//      {id 4,  firstName "Ightrayu", lastName "Rylye"},
//      {id 11, firstName "Ightrayu", lastName "Rylye"},
//      {id 5,  firstName "Ageghao",  lastName "Schohin"},
//      {id 8,  firstName "Gaon",     lastName "Tanes"},
//      {id 9,  firstName "Rakgeng",  lastName "Worirr"} ]
```

If you look closely you’ll notice that the array is sorted first by last name, and then in the places there are equal last names it will be sorted by first name, and finally in the one instance there are equal names (“Ightrayu Rylye”) it is sorted by `id`.

## Conclusion



## Exercises:

1. Define `filtered(by:)` on the more generic `Sequence` type.

2. Define `sorted(by:)` on the more generic `Sequence` type.

3. Define the function `not<A>: Predicate<A> -> Predicate<A>` that reverses a predicate:

4. Define the functions `isGreaterThan`, `isLessThanOrEqualTo`, `isGreaterThanOrEqualTo` for generating predicates on a comparable, similarly to how we defined `isLessThan`.

5. Define the functions `isEqualTo` and `isNotEqualTo` for generating predicates on a equatable.

6. Define a method `reversed() -> Ordering` on `Ordering` that does the most sensible thing you can think of (hint: the name is telling).

7. Define a method `reversed() -> Comparator` on `Comparator` by using the `reversed()` method above. What does it represent? **Note**: Due to a [limitation](https://twitter.com/dgregor79/status/847975206538813440) of Swift 3.1 you cannot extend `Comparator` directly. Instead, define the method on:

```swift
extension FunctionM where M == Ordering {
  func reversed() -> FunctionM {
    // implementation
  }
}
```





