---
layout:     post
title:      "Algebraic Structure and Protocols"
date:       2015-02-17
categories: swift math algebra
summary:    ""
---

Protocols in Swift allow us to abstractly work with types that we know very little about. We distill the smallest piece of an interface that we want a type to conform to, and then we can write functions that are highly reusable. Apple provides a nice description in their “[The Swift Programming Language](https://itun.es/us/jEUH0.l)” book:

> “A protocol defines a blueprint of methods, properties, and other requirements that suit a particular task or piece of functionality. The protocol doesn’t actually provide an implementation for any of these requirements—it only describes what an implementation will look like.”

Mathematicians do something very similar to study objects abstractly, and it forms the field known as algebra. In this article we will link these two worlds together, and show that there is a fundamental piece missing when we only look at the protocol level.

## How mathematicians think about structure

In every day work, a mathematician will often have a set of elements that is equipped with some operation(s) and want to study the properties of that object. Perhaps she is studying the set of solutions to some equation, and it turns out that she has discovered a binary operation, denoted by \\(\cdot\\), that takes two solutions \\(a\\), \\(b\\) and produces a third solution \\(a \cdot b\\). There is now algebraic structure on something that was previously a naked set of elements.

Through much arduous work she then discovers that this operation satisfies some nice properties. For example, it’s [associative](http://en.wikipedia.org/wiki/Associative_property) so that when performing the operation on three elements it doesn’t matter the manner in which they are paranthesized: \\(a \cdot (b \cdot c) = (a \cdot b) \cdot c\\). Then she realizes that there’s an element \\(e\\) in this set such that whenever it’s combined with any other element it leaves that element unchanged: \\(e \cdot a = a \cdot e = a\\) for every element \\(a\\).

What this mathematician has discovered is that her set and operation form what is known in algebra as a *monoid*. Other mathematicians studied monoids abstractly and found many nice properties and proved many nice theorems, and now that entire body of knowledge is available to her. For example, through a process known as the *Grothendieck group construction* she can enhance this simple algebraic structure into something stronger known as an *abelian group*.

The process of studying algebraic structures abstractly and then specializing them to real world cases is relatively recent. A class of structures known as permutation groups had been studied in various guises throughout the 18th and 19th centuries, but it wasn’t until the late 1800’s that it was finally realized that all of that was just a special case of something far more general called a group. With that discovery came a major change in how mathematics was done. It became preferable to build a general theory around abstract objects and axiomatic systems and then apply them to concrete problems.

## Semigroup

Perhaps the simplest algebraic structure one can study is the [semigroup](http://en.wikipedia.org/wiki/Semigroup). In the language of mathematics, a semigroup is a set \\(X\\), a binary operation \\(\cdot\\) that takes two elements \\(a, b\\) in \\(X\\) and produces a third \\(a \cdot b\\), such that the operation is associative:

\\[
  a \cdot (b \cdot c) = (a \cdot b) \cdot c \ \ \ \text{for every $a,b,c$ in $X$}
\\]

Associativity is the simplest restriction we can put on a binary operation. It simply tells us that we do not have to worry about parenthesizing an expression and can write \\(a \cdot b \cdot c\\).

There are plenty of examples of semigroups out in the wild:

* Integers (denoted by \\(\mathbb Z\\)) equipped with addition: \\((\mathbb{Z}, +)\\)
* Boolean values \\( B = \\{ \top, \bot \\} \\) with disjunction: \\( (B, \lor) \\)
* Boolean values with conjunction: \\( (B, \land) \\)
* \\(2 \times 2\\) matrices equipped with multiplication: \\( (M_{2\times 2}, \times) \\)

How do we translate these ideas into Swift? The specification that we have a set \\(X\\) and a binary operation \\( \cdot : (X, X) \rightarrow X \\) fits very well into a protocol:

```swift
protocol Semigroup {
  // Binary semigroup operation
  // **AXIOM** Should be associative:
  //   a.op(b.op(c)) == (a.op(b)).op(c)
  func op (g: Self) -> Self
}
```

We have called this function `op`, short for “operation.” Any type that can implement this protocol is on its way to being thought of as a semigroup. For example, we can make `Int` implement this protocol via addition:

```swift
extension Int : Semigroup {
  func op (n: Int) -> Int {
    return self + n
  }
}
```

We can also make `Bool` implement this protocol via `||`:

```swift
extension Bool : Semigroup {
  func op (b: Bool) -> Bool {
    return self || b
  }
}
```

We’ve now made `Int` and `Bool` adopt the `Semigroup` protocol, but can we really say that these types behave as semigroups? Our mathematical definition of semigroup had another requirement that we are completely ignoring: associativity of the binary operation. This piece of the story is very important, and we must find a way to represent it in Swift. Using pseudo code, we essentially want:

```swift
// pseudo code to verify that Int.op is associative
for a in Int {
  for b in Int {
    for c in Int {
      assert(a.op(b.op(c)) == (a.op(b)).op(c))
    }
  }
}

// pseudo code to verify that Bool.op is associative
for a in Bool {
  for b in Bool {
    for c in Bool {
      assert(a.op(b.op(c)) == (a.op(b)).op(c))
    }
  }
}
```

Those `for` loops are theoretically looping over *every* value in `Int` and `Bool`. There is no way to make these assertions on the type level when Swift is compiled. So, anytime we make a type adopt the `Semigroup` protocol we should have a corresponding test to ensure that indeed the operation is associative. This leads us into a quick digression...

## QuickCheck digression

The pseudo code above, where we theoretically looped through every value of a type, can be made into something very tangible and practical. [QuickCheck](http://en.wikipedia.org/wiki/QuickCheck) is a library originally developed in Haskell that allows one to confirm that a function satifisfies certain univeral properties. It repeatedly invokes the function with random values looking for any combination that causes the proposed property not to hold.

For example, suppose we wanted to confirm that multiplication in `Int` is indeed commutative, i.e. `a * b == b * a` for any `a` and `b` in `Int`. A predicate that verifies this for a particular case looks like:

```swift
func multiplicationIsCommutative (a: Int, b: Int) -> Bool {
  return (a * b) == (b * a)
}
```

Now we want to test this predicate for hundreds, maybe thousands of different combinations of integers. We aren’t going to implement such a function, but its API might look something like this:

```swift
check("* is commutative", multiplicationIsCommutative)
```

The `check` function would be smart enough to infer the types of `multiplicationIsCommutative`’s arguments, generate many values, plug them in, and verify the predicate holds true. We will assume we have access to such a theoretical function for the remainder of this article.

For a quick introduction to QuickCheck in the context of Swift, check out Chris Eidhof's [blog post](http://chris.eidhof.nl/posts/quickcheck-in-swift.html), and for a more in-depth look there is a chapter dedicated to it in [Functional Programming in Swift](http://www.objc.io/books/). There are also at least two open source implementations, [Fox](https://github.com/jeffh/Fox) and [SwiftCheck](https://github.com/typelift/SwiftCheck).

## Back to semigroups

QuickCheck is precisely the machinery we need to verify that the semigroup laws hold for `Int` and `Bool`. Those tests might look something like:

```swift
check("Int.op is associative", { (a: Int, b: Int, c: Int) -> Bool in
  return a.op(b.op(c)) == (a.op(b)).op(c)
})

check("Bool.op is associative", { (a: Bool, b: Bool, c: Bool) -> Bool in
  return a.op(b.op(c)) == (a.op(b)).op(c)
})
```

This will run thousands of checks so that we can safely say that `Int.op` and `Bool.op` are indeed associative.

Now, `Int` with `+` and `Bool` with `||` are simple enough semigroups that we already knew they satisified the associativity law. But sometimes these laws can be subtle, and we may have convinced ourselves that they hold when in reality they do not. We should never feel comfortable saying a type is a semigroup unlesss these tests are written.

Two other types in the Swift standard library that immediately lend themselves to semigroup structures are `String` and `Array`, and their binary operations are nearly identical. Given two strings `a` and `b` there is a clear way to produce a third string: just concatenate the strings `a + b`. Similarly for `Array`, and so we have two more semigroups:

```swift
extension String : Semigroup {
  func op (b: String) -> String {
    return self + b
  }
}

extension Array : Semigroup {
  func op (b: Array) -> Array {
    return self + b
  }
}
```

There is a common infix operator used for `op` that we will define now:

```swift
infix operator <> {associativity left precedence 150}
func <> <S: Semigroup> (a: S, b: S) -> S {
  return a.op(b)
}
```

Now we can compute expressions such as:

```swift
2 <> 3                // 5
false <> true         // true
"foo" <> "bar"        // "foobar"
[2, 3, 5] <> [7, 11]  // [2, 3, 5, 7, 11]
```

These four lines of code are quite amazing. We have distilled a general principle of composition (two objects combining into one) into a protocol, and allowed types to publicize when they are capable of this fundamental unit of computation. For example, we can write a shorter version of `reduce` for arrays over semigroups since there is a distinguished accumulation function:

```swift
func sconcat <S: Semigroup> (xs: [S], initial: S) -> S {
  return reduce(xs, initial, <>)
}

sconcat([1, 2, 3, 4, 5], 0)             // 15
sconcat([false, true], false)           // true
sconcat(["f", "oo", "ba", "r"], "")     // "foobar"
sconcat([[2, 3], [5, 7], [11, 13]], []) // [2, 3, 5, 7, 11, 13]
```

I’ve called this function `sconcat` as is customary when dealing with semigroups in computer science. Notice that the last example is simply flattening a nested array of integers.

## Monoid

The next simplest algebraic structure is the [monoid](http://en.wikipedia.org/wiki/Monoid). A monoid is a set \\(X\\), a binary operation \\(\cdot\\) and a distinguished element \\(e\\) of \\(X\\) such that the following holds:

* \\(\cdot\\) is associative: \\( a \cdot (b \cdot c) = (a \cdot b) \cdot c \\) for all \\(a, b, c\\) in \\(X\\).
* \\(e\\) is an identity: \\(e \cdot a = a \cdot e = a\\) for all \\(a\\) in \\(X\\).

Said more succinctly, \\( (X, \cdot, e) \\) is a monoid if \\( (X, \cdot) \\) is first a semigroup and \\(e\\) is an identity element. Examples include:

* Integers with addition: \\( (\mathbb{Z}, +, 0) \\)
* Boolean values with disjunction: \\( (B, \lor, \top ) \\)
* Boolean values with conjunction: \\( (B, \land, \bot ) \\)
* \\(2 \times 2\\) matrices with multiplication and the identity matrix: \\( (M_{2\times 2}, \times, I_{2\times 2} ) \\)

A monoid in Swift is modeled by a protocol just like we did for semigroups. Since a monoid is a semigroup with some extra structure added, we can make the `Monoid` protocol inherit from the `Semigroup` protocol:

```swift
protocol Monoid : Semigroup {
  // Identity value of monoid
  // **AXIOM** Should satisfy:
  //   Self.e() <> a == a <> Self.e() == a
  // for all values a
  class func e () -> Self
}
```

Any type `A` that implements `Monoid` will have the binary operation `A.op` and the distinguished identity element `A.e()`.

All of the semigroups we have defined so far can be enhanced to monoids quite easily:

```swift
extension Int : Monoid {
  static func e () -> Int {
    return 0
  }
}

extension Bool : Monoid {
  static func e () -> Bool {
    return false
  }
}

extension String : Monoid {
  static func e () -> String {
    return ""
  }
}

extension Array : Monoid {
  static func e () -> Array {
    return []
  }
}

3 <> Int.e()            // 3
false <> Bool.e()       // false
"foo" <> String.e()     // "foo"
[2, 3, 5] <> Array.e()  // [2, 3, 5]
```

There should of course be corresponding QuickCheck tests to verifty that each of the proposed identity elements satisfy the necessary axioms.

The fact that monoids have a distinguished element means that we can provide an even simpler reduce:

```swift
func mconcat <M: Monoid> (xs: [M]) -> M {
  return reduce(xs, M.e(), <>)
}

mconcat([1, 2, 3, 4, 5])            // 15
mconcat([false, true])              // true
mconcat(["f", "oo", "ba", "r"])     // "foobar"
mconcat([[2, 3], [5, 7], [11, 13]]) // [2, 3, 5, 7, 11, 13]
```

Here we have used the monoid’s identity value as the initial value to feed into `reduce`. This is not possible to do in the more generic case of a semigroup because we have no way of constructing an element.

## Group

We can enhance our monoids with additional structure that is ubiquitous in mathematics, but turns out to be quite exotic in computer science. An element \\(a\\) in a monoid \\((X, \cdot, e)\\) is said to have an inverse, denoted by \\(a^{-1}\\), if \\(a\cdot a^{-1} = a^{-1}\cdot a = e\\). That is, if we multiply the element with it’s inverse in any order we get back to the identity element.

A group is a set \\(X\\), a binary operation \\(\cdot\\), and a distinguished element \\(e\\) of \\(X\\) such that the following holds:

* \\(\cdot\\) is associative: \\( a \cdot (b \cdot c) = (a \cdot b) \cdot c \\) for all \\(a, b, c\\) in \\(X\\).
* \\(e\\) is an identity: \\(e \cdot a = a \cdot e = a\\) for all \\(a\\) in \\(X\\).
* For every \\(a\\) in \\(X\\) there exists an element \\(a^{-1}\\) in \\(X\\) such that \\(a^{-1}\\), if \\(a\cdot a^{-1} = a^{-1}\cdot a = e\\)

Said more succintly, a group is a monoid with inverses. Examples include:

* The set of integers with addition.
* The set of *non-zero* real numbers with multiplication.
* The set of \\(2\times 2\\) matrices with addition.

Examples of monoids that are **not** groups:

* The natural numbers (0, 1, 2, 3, ...) with addition, for there is no natural number \\(n\\) such that \\(n + 1 = 0\\).
* The set of \\(2\times 2\\) matrices with multiplication, for not every matrix has an inverse.

The requirement for every element to have an inverse translates to a protocol quite easily:

```swift
protocol Group : Monoid {
  // Inverse value of group
  // **AXIOM** Should satisfy:
  //   a <> a.inv() == a.inv() <> a == Self.e()
  // for each value a.
  func inv () -> Self
}
```

The `Group` protocol has inherited from `Monoid` since that gives us the binary operation and identity element for free.

We can make `Int` into a group:

```swift
extension Int {
  func inv () -> Int {
    return -self
  }
}

3 <> 3.inv() // 0
```

All of the other monoids we have defined cannot be enhanced to adopt `Group`. For example, `String` cannot be made into a group with concatentation, for concatentation of strings increases the length, never decreases.

In mathematics there is the concept of the “[commutator](http://en.wikipedia.org/wiki/Commutator)” of two elements in a group. If \\(a\\) and \\(b\\) are elements of a group \\(X\\), then the commutator is denoted by \\([a, b]\\) and defined by

\\[ [a, b] = a \cdot b \cdot a^{-1} \cdot b^{-1} \\]

This gives us a nice example of something we can write in Swift to show how to deal with groups:

```swift
func commutator <G: Group> (a: G, b: G) -> G {
  return a <> b <> a.inv() <> b.inv()
}
```

In a sense, \\( [\cdot, \cdot] \\) measures how much elements fail to commute, for \\( [a, b] = e \\) if and only if \\( a\cdot b = b\cdot a \\).

We will not go any deeper into the theory behind `Group` given that computer science isn’t flush with good examples of groups. However, in upcoming articles we will explore `Group` more; in particular, the theory of [elliptic curves](XXX link) and the [Grothendieck construction](XXX link).


## Commutativity

Sometimes the additional structure we put on an object has nothing to do with defining additional operations or distinguished elements, but instead adds laws that the operations must satisfy. For example, some of the semigroups we defined have a commutative binary operation: `a <> b == b <> a` for every value `a` and `b`. This is true of `Int` and `Bool`. However, this is not true of `String` and `Array`, for example: `"foo" <> "bar" == "foobar"` does not equal `"bar" <> "foo" == "barfoo"`.

We can define a new protocol so that semigroups can advertise when their operation is commutative:

```swift
protocol CommutativeSemigroup : Semigroup {
  // **AXIOM** The binary operation is commutative:
  //   a <> b == b <> a
  // for all values a and b
}

extension Int : CommutativeSemigroup {}
extension Bool : CommutativeSemigroup {}
```

But, for us to truly say that `Int` and `Bool` are commutative semigroups we should write the corresponding QuickCheck test to verify that the operations are indeed commutative.

We can combine this protocol with `Monoid` and `Group` to get the commutative versions of those algebraic structures. In the case of commutative groups there is a historically significant name: *abelian group*, named after the Norwegian mathematician [Niels Henrik Abel](http://en.wikipedia.org/wiki/Niels_Henrik_Abel). Note that for some reason it has become accepted to not capitalize the “A” in abelian, even though it is named after a person.

An example of how these protocols combine:

```swift
func f <M: Monoid where M: CommutativeSemigroup> (a: M, b: M) -> M {
  return a <> b <> a <> b
}
```

Even better, we can define new protocols that compose these protocols for us:

```swift
protocol CommutativeMonoid : Monoid, CommutativeSemigroup {}
protocol AbelianGroup : Group, CommutativeMonoid {}

extension Int : AbelianGroup {}
```

## Enhancing Semigroups to Monoids

There is a universal construction that can naturally create a monoid out of any semigroup. Recall that the only thing a semigroup \\(S\\) lacks from being a monoid is a distinguished identity element \\(e\\) such that \\(a \cdot e = e \cdot a = a\\) for every element \\(a\\) in \\(S\\). Well, we could just create a new set \\(M\\) by simply adjoining a new element to \\(S\\), i.e. \\( M = S \cup e \\). The binary operation \\(\cdot\\) on \\(S\\) extends to all of \\(M\\) by declaring that \\(a \cdot e = e \cdot a = a\\).

The above may have sounded abstract, but it directly translates into code. Given a type `S` adopting the `Semigroup` protocol we want to construct a new type with all of the values from `S` plus one additional value, and then make this new type into a monoid. This sounds like an enum:

```swift
enum M <S: Semigroup> {
  case Identity
  case Element(S)
}

extension M : Monoid {
  static func e () -> M {
    return .Identity
  }

  func op (b: M) -> M {
    switch (self, b) {
    case (.Identity, .Identity):
      return .Identity
    case (.Element, .Identity):
      return self
    case (.Identity, .Element):
      return b
    case let (.Element(a), .Element(b)):
      return .Element(a <> b)
    }
  }
}
```

We now have a very general method of turning semigroups into monoids. Sadly, it’s not very common to encounter semigroups that aren’t also monoids. The reason for this is mostly due to the fact that it’s so easy to turn a semigroup into a monoid via the above construction. There is one particularly good example, but I’m saving that for the exercises.

In a future article we will explore a very general, universal construction for building an abelian group out of a commutative monoid. When one applies this construction to the natural numbers one recovers the integers.

## Exercises

Code samples from this article and exercises are in the following [playground](http://www.fewbutripe.com.s3.amazonaws.com/supporting/algebraic-structure-and-protocols/algebraic-structure.playground.zip).

1.) In the article “[Proof in Functions]({% post_url 2015-01-06-proof-in-functions %})” we considered the enum type with no values:

```swift
enum Empty {}
```

Make this type into a semigroup. Can this type be a monoid?

2.) In the exercises of “[Proof in Functions]({% post_url 2015-01-06-proof-in-functions %})” we considered the empty struct:

```swift
struct Unit {}
```

Make this type into a monoid. Can it be a group?

3.) How does our construction `M<S: Semigroup>` compare with Swift’s optional types `Optional<S: Semigroup>`.

4.) Functions that have the same domain and range, i.e. `A -> A`, are called *endomorphisms* in mathematics. Consider the type:

```swift
struct Endomorphism <A> {
  let f: A -> A
}
```

Make this type into a monoid. Can it be a group?


5.) Consider the type:

```swift
struct Predicate <A> {
  let p: A -> Bool
}
```

This is a type representation of a predicate, i.e. a function from a type to `Bool`. These are precisely the types of functions that can be fed into `filter`. Using the monoid structure on `Bool`, make `Predicate` into a monoid.

6.) Generalizing the previous exercise, consider type:

```swift
struct FunctionM <A, M: Monoid> {
  let f: A -> M
}
```

Make `FunctionM` into a monoid.

7.) Continuing with this theme of functions whose range has algebraic structure, consider:

```swift
struct FunctionG <A, G: Group> {
  let f: A -> G
}
```

Make `FunctionG` into a group.

8.) Any type that implements the `Comparable` protocol can be made into a semigroup in two different ways. Taking the hint from the suggestive names, make the following two types implement the `Semigroup` protocol:

```swift
struct Max <A: Comparable> {
  let a: A
  init (_ a: A) { self.a = a }
}

struct Min <A: Comparable> {
  let a: A
  init (_ a: A) { self.a = a }
}
```

9.) What do the following computations represent?

```swift
sconcat([Max(2), Max(5), Max(100), Max(2)], Max(0))
sconcat([Min(2), Min(5), Min(100), Min(2)], Min(200))
```

10.) Recall that the `M` construction can upgrade a semigroup to a monoid. Use this on the `Max` and `Min` semigroups defined above. What does the identity element correspond to in each case? What do the following computations represent?

```swift
mconcat([M(Max(2)), M(Max(5)), M(Max(100)), M(Max(2))])
mconcat([M(Min(2)), M(Min(5)), M(Min(100)), M(Min(2))])
```

