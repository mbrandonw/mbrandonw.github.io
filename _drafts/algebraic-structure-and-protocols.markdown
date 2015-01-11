---
layout:     post
title:      "Algebraic Structure and Protocols"
date:       2015-01-20
categories: swift math algebra
summary:    ""
---

Protocols in Swift allow us to abstractly work with types that we know very little about. We distill the smallest piece of an interface that we want a type to conform to, and then we can write functions that are highly reusable. Apple provides a nice description in their “[The Swift Programming Language](https://itun.es/us/jEUH0.l)” book:

> “A protocol defines a blueprint of methods, properties, and other requirements that suit a particular task or piece of functionality. The protocol doesn’t actually provide an implementation for any of these requirements—it only describes what an implementation will look like.”

Mathematicians do something very similar to study objects abstractly, and it forms the field known as algebra. In this article we will link these two worlds together, and show that there is a fundamental piece missing when we only look at the protocol level.

## How mathematicians think about structure

In every day work, a mathematician will often have a set of elements that is equipped with some operation(s) and want to study the properties of that object. Perhaps she is studying the set of solutions to some equation, and it turns out that she has found an operation that takes two solutions and produces a third solution. There is now algebraic structure on something that was previously a naked set of elements.

Through much arduous work she then discovers that this operation satisfies some nice properties. For example, it's [associative](http://en.wikipedia.org/wiki/Associative_property) so that when performing the operation on three elements it doesn't matter the order in which we combine them: \\(a \cdot (b \cdot c) = (a \cdot b) \cdot c\\). Then she realizes that there's a unique element in this set such that whenever it's combined with any other element it leaves that element unchanged: \\(e \cdot a = a \cdot e = a\\) for every element \\(a\\).

What this mathematician has discovered is that her set and operation form what is known in algebra as a monoid. Other mathematicians studied monoids abstractly and found many nice properties and proved many nice theorems, and now that entire body of knowledge is available to her. For example, through a process known as the *Grothendieck group construction* she can enhance this simple algebraic structure into something stronger known as an *abelian group*.

The process of studying algebraic structures abstractly and then specializing them to real world cases is relatively recent. A structure known as permutation groups had been studied in various guises throughout the 18th and 19th centuries, but it wasn't until the late 1800’s that it was finally realized that all of that was just a special case of something far more general called a group. With that discovery came a major change in how mathematics was done. It became preferred to build a general theory around abstract objects and axiomatic systems and then apply them to concrete problems.



## Semigroup

Perhaps the simplest algebraic structure one can study is the [semigroup](http://en.wikipedia.org/wiki/Semigroup). In the language of mathematics, a semigroup is a set \\(X\\), a binary operation \\(\cdot\\) that takes two elements \\(a, b\\) in \\(X\\) and produces a third \\(a \cdot b\\), and the operation is associative:

\\[
  a \cdot (b \cdot c) = (a \cdot b) \cdot c \ \ \ \text{for every $a,b,c$}
\\]

Associativity is the simplest restriction we can put on a binary operation. It simply tells us that we do not have to worry about parenthesizing an expression and can write \\(a \cdot b \cdot c\\).

There are plenty of examples of semigroups out in the wild:

* Integers equipped with addition: \\((\mathbb{N}, +)\\)
* Boolean values \\( B = \\{ \top, \bot \\} \\) with disjunction: \\( (B, \lor) \\)
* Boolean values with conjunction: \\( (B, \land) \\)
* \\(2 \times 2\\) matrices equipped with multiplication: \\( (M_{2\times 2}, \times) \\)
* Fix any set \\(A\\), then the set of functions \\(A \rightarrow \mathbb N\\) is a semigroup with the operation: for \\( f, g: A \rightarrow \mathbb N \\)

\\[ (f \cdot g)(a) = f(a) + g(a) \\]

How do we translate these ideas into Swift? The specification that we have a set \\(X\\) and a binary operation \\( \cdot : X \times X \rightarrow X \\) fits very well into a protocol:

```swift
protocol Semigroup {
  // Binary, associative semigroup operation (sop)
  func sop (g: Self) -> Self
}
```

We have called this function `sop`, short for “semigroup operation.” Any type that can implement this protocol is on its way to being thought of as a semigroup. For example, we can make `Int` implement this protocol via addition:

```swift
extension Int : Semigroup {
  func sop (n: Int) -> Int {
    return self + n
  }
}
```

We can also make `Bool` implement this protocol via `||`:

```swift
extension Bool : Semigroup {
  func sop (b: Bool) -> Bool {
    return self || b
  }
}
```

We've now made `Int` and `Bool` adopt the `Semigroup` protocol, but can we really say that these types behave as semigroups? Our mathematical definition of semigroup had another piece that we are completely ignoring: associativity of the binary operation. This piece of the story is very important, and we must find a way to represent it in Swift. In pseudo code we essentially want:

```swift
// pseudo code to verify that Int.sop is associative
for a in Int {
  for b in Int {
    for c in Int {
      assert(a.sop(b.sop(c)) == (a.sop(b)).sop(c))
    }
  }
}

// pseudo code to verify that Bool.sop is associative
for a in Bool {
  for b in Bool {
    for c in Bool {
      assert(a.sop(b.sop(c)) == (a.sop(b)).sop(c))
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

Now we want to test this predicate for hundreds, maybe thousands of different combinations of integers. We aren't going to implement such a function, but it might look something like this:

```swift
check("* is commutative", multiplicationIsCommutative)
```

The `check` function would be smart enough to be able to inspect the arguments of `multiplicationIsCommutative`, generate many inputs, plug them in, and verify the predicate holds true. We will assume we have access to such a function for the remainder of this article.

There is a very good discussion of QuickCheck in the context of Swift in the book [Functional Programming in Swift](http://www.objc.io/books/).

## Back to semigroups

QuickCheck is precisely the machinery we need to verify that the semigroup laws hold for `Int` and `Bool`. Those tests might look something like:

```swift
check("Int.sop is associative", { (a: Int, b: Int, c: Int) -> Bool in
  return a.sop(b.sop(c)) == (a.sop(b)).sop(c)
})

check("Bool.sop is associative", { (a: Bool, b: Bool, c: Bool) -> Bool in
  return a.sop(b.sop(c)) == (a.sop(b)).sop(c)
})
```

This will run thousands of checks so that we can safely say that `Int.sop` and `Bool.sop` are indeed associative.

Now, `Int` with `+` and `Bool` with `||` are simple enough semigroups that we already knew they satisified the associativity law. But sometimes these laws can be subtle, and we may have convinced ourselves that they hold when in reality they do not. We should never feel comfortable saying a type is a semigroup unlesss these tests are written.

Two other types in the Swift standard library that immediately lend themselves to semigroup structures are `String` and `Array`, and their binary operations are nearly identical. Given two strings `a` and `b` there is a clear way to produce a third string: just concatenate the strings `a + b`. Similarly for `Array`, and so we have two more semigroups:

```swift
extension String : Semigroup {
  func sop (b: String) -> String {
    return self + b
  }
}

extension Array : Semigroup {
  func sop (b: Array) -> Array {
    return self + b
  }
}
```

There is a common infix operator used for `sop` that we will define now:

```swift
infix operator <> {associativity left}
func <> <S: Semigroup> (a: S, b: S) -> S {
  return a.sop(b)
}
```

Now we can compute expressions such as:

```swift
2 <> 3                // 5
false <> true         // true
"foo" <> "bar"        // "foobar"
[2, 3, 5] <> [7, 11]  // [2, 3, 5, 7, 11]
```





## Monoid

The next simplest algebraic structure is the [monoid](http://en.wikipedia.org/wiki/Monoid). A monoid is a set \\(X\\), a binary operation \\(\cdot\\) and a distinguished element \\(e\\) of \\(X\\) such that the following holds:

* \\(\cdot\\) is associative: \\( a \cdot (b \cdot c) = (a \cdot b) \cdot c \\) for all \\(a, b, c\\) in \\(X\\).
* \\(e\\) is an identity: \\(e \cdot a = a \cdot e = a\\) for all \\(a\\) in \\(X\\).

Said more succinctly, \\( (X, \cdot, e) \\) is a monoid if \\( (X, \cdot) \\) is a semigroup and \\(e\\) is an identity element. Examples include:

* Natural numbers with addition: \\( (\mathbb N, +, 0) \\)
* Boolean values with disjunction: \\( (B, \lor, \top ) \\)
* \\(2 \times 2\\) matrices with multiplication and the identity matrix: \\( (M_{2\times 2}, \times, I_{2\times 2} ) \\)

A good *non-example* to consider is boolean values with conjunction \\((B, \land)\\). This is a semigroup, but cannot be made into a monoid because there is no identity element.

Implementing a monoid in Swift is


```swift
protocol Monoid : Semigroup {
  class func mid () -> Self
}
```

```swift
protocol Group : Monoid {
  func inv () -> Self
}
```






### footnotes

Sometimes it can even make sense to consider nonassociative operations, for example [octonions](http://en.wikipedia.org/wiki/Octonion), which are a kind of generalization of complex numbers.


## Exercises

* Show that `Bool` equipped with `&&` is not a monoid.

* In the article “[Proof in Functions]({% post_url 2015-01-06-proof-in-functions %})” we considered the enum type with no values:

```swift
enum Empty {
  // no cases
}
```

Make this type into a semigroup. Can this type be a monoid? Why or why not?

* In the exercises of “[Proof in Functions]({% post_url 2015-01-06-proof-in-functions %})” we considered the enum with a single value:

```swift
enum Unit {
  case A
}
```

Make this type into a monoid.




* Consider the struct:

```swift
struct Predicate <A> {
  let p: A -> Bool
}
```

This is a type representation of a predicate, i.e. a function from a type to `Bool`. These are precisely the types of functions that can be fed into `filter`. Using the monoid structure on `Bool`, make `Predicate` into a monoid.

make comparable a monoid

* Consider the following enum:

```swift
enum Comparable {
  case LT
  case EQ
  case GT
}
```


* Suppose that the type `S` is a semigroup.





http://www.scs.stanford.edu/14sp-cs240h/slides/phantoms.html


