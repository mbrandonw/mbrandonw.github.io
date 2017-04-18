---
layout: post
title:  "The Algebra of Predicates and Sorting Functions"
date:   2017-04-18
categories: swift math algebra monoid
---

In the article “[Algebraic Structure and Protocols]({% post_url 2015-02-17-algebraic-structure-and-protocols %})” we described how to use Swift protocols to describe some basic algebraic structures, such as semigroups and monoids, provided some simple examples, and then provided  constructions to build new instances from existing. Here we apply those ideas to the concrete ideas of predicates and sorting functions, and show how they build a wonderful little algebra that is quite expressive.

## Recall from last time…

…that we [defined a semigroup and monoid]({% post_url 2015-02-17-algebraic-structure-and-protocols %}) as protocols satisfying some axioms:

```swift
infix operator <>: AdditionPrecedence

protocol Semigroup {
  // **AXIOM** Associativity
  // For all a, b, c in Self:
  //    a <> (b <> c) == (a <> b) <> c
  static func <> (lhs: Self, rhs: Self) -> Self
}

protocol Monoid: Semigroup {
  // **AXIOM** Identity
  // For all a in Self:
  //    a <> e == e <> a == a
  static var e: Self { get }
}
```

Types that conform to these protocols have some of the simplest forms of computation around. They know how to take two values of the type, and combine them into a single value. We know of quite a few types that are monoids:

```swift
extension Bool: Monoid {
  static func <>(lhs: Bool, rhs: Bool) -> Bool {
    return lhs && rhs
  }
  static let e = true
}

extension Int: Monoid {
  static func <>(lhs: Int, rhs: Int) -> Int {
    return lhs + rhs
  }
  static let e = 0
}

extension String: Monoid {
  static func <>(lhs: String, rhs: String) -> String {
    return lhs + rhs
  }
  static let e = ""
}

extension Array: Monoid {
  static func <>(lhs: Array, rhs: Array) -> Array {
    return lhs + rhs
  }
  static var e: Array { return [] }
  //      ^-- Static properties are not allowed on generics in
  //          Swift 3.1, so we must store it as a computed variable.
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
func concat <M: Monoid> (_ xs: [M]) -> M {
  return xs.reduce(M.e, <>)
}

concat([1, 2, 3])              // => 6
concat(["foo", "bar"])         // => "foobar"
concat([[1, 3, 5], [2, 4, 6]]) // => [1, 3, 5, 2, 4, 6]
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
  static func <>(lhs: FunctionM, rhs: FunctionM) -> FunctionM {
    return FunctionM { x in
      return lhs.call(x) <> rhs.call(x)
    }
  }

  static var e: FunctionM {
    return FunctionM { _ in M.e }
  }
}
```

In words, the computation `f <> g` of two functions `f, g: (A) -> M` produces a third function `(A) -> M` by mapping a value `a: A` into two values `f(a)`, `g(a)` in `M`, and then we combine them `f(a) <> f(b)`. We call this the _point-wise_ combining of `f` and `g`.

## Predicates

The `FunctionM` construction pops up quite a bit in computer science. For example, functions of the form `(A) -> Bool` are called _predicates_, and they are precisely the functions you give to `filter` in order to obtain a subset of elements satisfying the predicate:

```swift
let isEven = { $0 % 2 == 0 }

Array(0...10).filter(isEven) // => [0, 2, 4, 6, 8, 10]
```

However, we saw that `Bool` is a monoid with `&&` as its operation and `true` as its identity. This means that `FunctionM<A, Bool>` is also a monoid. We can use Swift’s [generic typealiases](https://github.com/apple/swift-evolution/blob/master/proposals/0048-generic-typealias.md) to give a name to this:

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

Note that we did not have to define `<>` for predicates. We got it for free by the fact that `Predicate` is automatically a `Monoid`.

Recall that `FunctionM` has a `call` field for getting access to the underlying function the type represents and that `Predicate` is just a specialization of `FunctionM`, therefore `Predicate` similarly has a `call` field. That function is what can be used with `Array`s `filter` method:

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

Now we can use `Predicate` more naturally with `Array`s:

```swift
Array(0...100).filtered(by: isLessThan10AndEven) // => [0, 2, 4, 6, 8]
```

In fact, this first class support for `Predicate` means there’s no reason to define one-off compositions of small predicates as we might as well use them inline:

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

["foo", "bar", "baz", "qux"].filtered(by: isLessThan("f")) // => ["bar", "baz"]
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
  static func <>(lhs: Ordering, rhs: Ordering) -> Ordering {
    switch (lhs, rhs) {
    case (.lt, _): return .lt
    case (.gt, _): return .gt
    case (.eq, _): return rhs
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
let intComparator = Comparator<Int> { lhs, rhs in
  lhs < rhs ? .lt : lhs > rhs ? .gt : .eq
}

let stringComparator = Comparator<String> { lhs, rhs in
  lhs < rhs ? .lt : lhs > rhs ? .gt : .eq
}
```

More generally, anything conforming to `Comparable` can be used to derive a comparator:

```swift
extension Comparable {
  static func comparator() -> Comparator<Self> {
    return Comparator.init { lhs, rhs in
      lhs < rhs ? .lt : lhs > rhs ? .gt : .eq
    }
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

We want to sort an array of users `[User]` first by their last name, then first name, and then finally to ensure a well-defined sorting of the array we will sort by `id` just in case two users have the exact same name. To begin we define a few basic comparators to help us out:

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
  User(id: 6,  firstName: "Umath",    lastName: "Achia"),
  User(id: 9,  firstName: "Rakgeng",  lastName: "Worirr"),
  User(id: 11, firstName: "Ightrayu", lastName: "Rylye")
]

users.sorted(by: lastNameComparator <> firstNameComparator <> idComparator)

// => [ {id 2,  firstName "Daror",    lastName "Achia"},
//      {id 6,  firstName "Umath",    lastName "Achia"},
//      {id 3,  firstName "Achyk",    lastName "Echsold"},
//      {id 1,  firstName "Denuy",    lastName "Mosler"},
//      {id 4,  firstName "Ightrayu", lastName "Rylye"},
//      {id 11, firstName "Ightrayu", lastName "Rylye"},
//      {id 9,  firstName "Rakgeng",  lastName "Worirr"} ]
```

If you look closely you’ll notice that the array is sorted first by last name, and then in the places there are equal last names it will be sorted by first name, and finally in the one instance there are equal names (“Ightrayu Rylye”) it is sorted by `id`.

You can also imagine that there is a interface that allows a user to specify any number of sorts, which you could accommodate by using an array of sorts. Then you can use the `concat` function to apply all of the sorts at once:

```swift
let sorts = [
  lastNameComparator,
  firstNameComparator,
  idComparator
]

users.sorted(by: concat(sorts))
```

## Conclusion

By starting with the simplest idea of computation, the monoid, we were able to derive an expressive algebra of predicates and sorting functions. This is largely possible due to the simplicity of monoids since it leaves a lot of wiggle room for opportunities of composition in places we might not expect. In the exercises you will dig a little deeper into this topic by constructing more operators on predicates and comparators, ending in a general construction for inducing monoid morphisms.

In a future article we will show how these ideas can be extended even further. One example is thinking of `Bool` as not only a monoid but a semiring: a structure that combines the conjuctive (`&&`) _and_ disjunctive (`||`) aspects of `Bool` into one object. Another example is using [lenses](https://www.youtube.com/watch?v=ofjehH9f-CU) to induce comparators for free by leveraging the getters you already have.


## Exercises:

1.) Define `filtered(by:)` on the more generic `Sequence` type.

2.) Define `sorted(by:)` on the more generic `Sequence` type.

3.) Define the function `not<A>: Predicate<A> -> Predicate<A>` that reverses a predicate:

4.) Define the functions `isGreaterThan`, `isLessThanOrEqualTo`, `isGreaterThanOrEqualTo` for generating predicates on a comparable, similarly to how we defined `isLessThan`.

5.) Define the function `isEqualTo` for generating predicates on an equatable.

6.) Define a method `reversed() -> Ordering` on `Ordering` that does the most sensible thing you can think of (hint: the name is telling).

7.) The method `reversed` in the previous exercise is not simply any old function. It is known as a “monoid morphism” because it preserves the monoidal structure of `Ordering`, i.e. `(a <> b).reversed() == a.reversed() <> b.reversed()` for all `a` and `b` in `Ordering`. Verify this in code by looping over all combinations of `a` and `b` and checking the equality.

8.) Define a method `reversed() -> Comparator` on `Comparator` by using the `reversed()` method above. What does it represent? **Note**: Due to a [limitation](https://twitter.com/dgregor79/status/847975206538813440) of Swift 3.1 you cannot extend `Comparator` directly. Instead, define the method on:

```swift
extension FunctionM where M == Ordering {
  func reversed() -> FunctionM {
    // implementation
  }
}
```

9.) Generalizing exercises #6-8 we can define the type of morphisms between monoids:

```swift
struct MorphismM<M: Monoid, N: Monoid> {
  // AXIOM: call(a <> b) == call(a) <> call(b)
  let call: (M) -> N
}
```

Any morphism of monoids can be used to induce a morphism on the corresponding monoid of functions. Show this by implementing the function:

```swift
extension FunctionM {
  func induced<N: Monoid>(_ morphism: MorphismM<M, N>) -> FunctionM<A, N> {
    // implementation
  }
}
```

Use this construction to show how `reversed` on `Comparator` could have been induced by `reversed` on `Ordering`. Further, the `not` transformation on `Predicate` could have been induced by negation on `Bool`.

----
<br>

##### _Thanks to [Stephen Celis](http://www.twitter.com/stephencelis) for reading a draft of this article._
