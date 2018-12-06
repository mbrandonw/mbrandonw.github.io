---
layout: post
title:  "Seemingly Impossible Swift Programs"
date:   2018-12-05
author: Brandon Williams
summary: "We will construct Swift programs that should be impossible to implement, yet somehow are not!"
image: /assets/seemingly-impossible-cover.jpg
---


> It is well known that it is impossible to define equality between arbitrary functions. However, there is a large class of functions for which we can determine equality, and it's strange and surprising. We explore this idea using the Swift programming language.


I spend a lot of my time trying to find new and creative ways to bring seemingly complex functional programming ideas down to earth and make them approachable to a wider audience. I do this while creating episodes for [Point-Free](https://www.pointfree.co), and I do this when I [work with clients](https://www.fewbutripe.com/hire-me). There are a lot of wonderful ideas in functional programming that can be understood by everyone and can help make everyone's day-to-day code more extensible, transformable and testable.

However, I want to take a break from all of that and discuss something completely impractical. There's very little chance you will use this in your everyday work, but it does give us an opportunity to explore a strange and surprising result in computation and mathematics. It can help show that the connection between the two topics is perhaps deeper than we may first think.

To show this, we are going to be implementing seemingly impossible Swift programs. That is, we are going to implement some functions in Swift that for all intents and purposes should be absolutely impossible to implement. In fact, the mind kind of boggles when confronted with the implementation because it seems so outlandish and outside the realm of reality.

None of the results in this article are original material by me. I learned of these ideas in a series of papers and articles ([references](#references) at the end). The only thing original in this article is the presentation of the material in a (hopefully) approachable way, as the papers can be quite dense. All of the code in this article is available in a [gist](https://gist.github.com/mbrandonw/981f589f32800d3409f817ad4f7c6802) that can be copied and pasted into a Swift playground if you want to follow along at home.

## Completely possible programs

Let's start with something simple and very much possible in Swift. As of Swift 4.2, the standard library has a function [`allSatisfy`](https://developer.apple.com/documentation/swift/array/2994715-allsatisfy) that allows you to run a predicate on every value in an array and determine if the predicate is `true` for each element:

```swift
[1, 2, 3].allSatisfy { $0 >= 2 } // false
[1, 2, 3].allSatisfy { $0 >= 1 } // true
```

There is a _dual_ version of this operation that checks if _any_ value in a collection is satisfied by a predicate. The standard library calls this `contains` for historical reasons, but let's redefine it to give it a better name:

```swift
extension Array {
  func anySatisfy(_ p: (Element) -> Bool) -> Bool {
    for x in self {
      if p(x) { return true }
    }
    return false
  }
}
```

Although the implementation of this function is quite simple, it's still more complicated than it needs to be, because `anySatisfy` can be defined in terms of `allSatisfy`. This is given by the so-called [De Morgan’s Law](https://en.wikipedia.org/wiki/De_Morgan%27s_laws), which says that the negation of a disjunction is the conjunction of the negations, i.e.

```swift
!(a || b) == (!a && !b)
```

In particular, negating both sides of this equation we see that:

```swift
a || b == !(!a && !b)
```

This says that "any of `a` or `b` is true" is equivalent to the negation of "all of `a` and `b` are false." So, we can reimplement `anySatisfy` using this observation:

```swift
extension Array {
  func anySatisfy(_ p: (Element) -> Bool) -> Bool {
    return !self.allSatisfy { !p($0) }
  }
}
```

These programs are completely possible to implement today in Swift, and so nothing too surprising here.

## Approaching impossible programs

Now let's construct some functions similar to `allSatisfy` and `anySatisfy`, but that will naturally lead us down a road of impossibility. What if we wanted to check that a given predicate evaluates to `true` for _every_ value inside some type? That seems pretty hard, so let's start with some small types. For example, `Bool`:

```swift
extension Bool {
  static func allSatisfy(_ p: (Bool) -> Bool) -> Bool {
    return p(true) && p(false)
  }
}

Bool.allSatisfy { $0 == true }  // false
Bool.allSatisfy { $0 == false } // false
Bool.allSatisfy { $0 || !$0 }   // true
```

Since `Bool` only contains two values, we can simply evaluate the predicate on each of its values and confirm that it is `true` for both. Using this function we can clearly see that indeed not every boolean is equal to `true` or `false`, but every boolean *or* its negation is `true`.

More generally, Swift 4.2 has a protocol called `CaseIterable` which allows types to explicitly enumerate all of their values. All of those types could also carry this function:

```swift
extension CaseIterable {
  static func allSatisfy(_ p: (Self) -> Bool) -> Bool {
    return self.allCases.allSatisfy(p)
  }
}
```

To test this out we will define a `Direction` enum for the 4 cardinal directions, and then verify that certain properties are satisfied for all values in the type:

```swift
enum Direction: CaseIterable {
  case up, down, left, right

  var rotatedLeft: Direction {
    switch self {
    case .up:    return .left
    case .left:  return .down
    case .down:  return .right
    case .right: return .up
    }
  }

  var rotatedRight: Direction {
    switch self {
    case .up:    return .right
    case .left:  return .up
    case .down:  return .left
    case .right: return .down
    }
  }
}

Direction.allSatisfy { $0 == .up } // false
Direction.allSatisfy { $0.rotatedLeft.rotatedRight == $0 } // true
```

Here we see that indeed not every `Direction` value is equal to `.up`. But if you take any value and rotate left and then right, you get back to where you started. And we have verified that property holds for every value in the `Direction` type.

So, we've now seen that it's possible to sometimes ask an entire type to check if all of its values satisfy some predicate. In particular, we could do this for `Bool` and `CaseIterable`.

## Impossible programs

Now let's try to generalize the examples from the previous section to see how things bring us into the land of impossibility.

What if instead of asking `Bool` if all of its values satisfy a predicate, we asked `Int`?

```swift
extension Int {
  static func allSatisfy(_ p: (Int) -> Bool) -> Bool {
    // ???
  }
}

Int.allSatisfy { $0 % 2 == 0 }                // false?
Int.allSatisfy { $0 > 0 }                     // false?
Int.allSatisfy { $0 % 2 == 0 || $0 % 2 == 1 } // true?
```

If we were able to implement this function then we'd expect the first two invocations of it to return `false`, because certainly not all integers are even or greater than zero, but the last one should be `true` because indeed every integer is even or odd.

However, we cannot possibly implement this function. `Int` holds way too many values for us to possibly be able to check each one against a predicate in a reasonable amount of time (it's best to think of `Int` as modeling the infinite set of all integers). We could also try implementing this for large type, like `String`:

```swift
extension String {
  static func allSatisfy(_ p: (String) -> Bool) -> Bool {
    // ???
  }
}

String.allSatisfy { $0 == "cat" }   // false?
String.allSatisfy { $0.count > 0 }  // false?
String.allSatisfy { $0.count >= 0 } // true?
```

Again, if we were able to implement this function we'd expect the first two invocations to be `false` and the last to be `true`. But this function is impossible to implement. `String` contains infinitely many values, and so there is no way we could possibly check them all against the predicate.

We have finally come face-to-face with impossible functions. But actually impossible, not just seemingly impossible. These functions can never be implemented, and indeed their implementation is equivalent to the [halting problem](https://en.wikipedia.org/wiki/Halting_problem).

These functions may seem silly at first, but they are connected to a very real problem of determining if two functions are equal. For if we could implement the above functions, then we could implement equality between, say, functions `(Int) -> Int`:

```swift
func == (lhs: (Int) -> Int, rhs: (Int) -> Int) -> Bool {
  return Int.allSatisfy { lhs($0) == rhs($0) }
}
```

This is yet another impossible function to implement, and also equivalent to the [halting problem](https://en.wikipedia.org/wiki/Halting_problem).

## Seemingly impossible programs

Now that we have surveyed the possible and impossible for implementing a certain type of function, let's look at something that _should_ be impossible, yet somehow is not.

Consider the following types:

```swift
enum Bit {
  case one
  case zero
}

struct BitSequence {
  let atIndex: (UInt) -> Bit
}
```

`Bit` is a simple type that holds two values, and `BitSequence` is the type of functions from non-negative integers into `Bit`. The reason it is called `BitSequence` is because it is kind of like an infinite sequence of `Bit` values, in which you are able to ask what is the value at an index using the `atIndex` method. In this interpretation it is best to think of `UInt` as the infinite set of non-negative integers.

We can easily define values of `BitSequence` by just providing a closure to map `UInt`'s to `Bit`'s:

```swift
let xs = BitSequence { _ in .one }
let ys = BitSequence { $0 < 1_000 ? .zero : .one }
let zs = BitSequence { $0 % 2 == 0 ? .zero : .one }

xs.atIndex(0) // .one
xs.atIndex(1) // .one
xs.atIndex(2) // .one

ys.atIndex(0)     // .zero
ys.atIndex(1)     // .zero
ys.atIndex(1_001) // .one

zs.atIndex(0) // .zero
zs.atIndex(1) // .one
zs.atIndex(2) // .zero
```

And although we cannot concatenate two infinite sequences together, we can prepend a new head onto an existing sequence. I'm going to overload `+` for this purpose:

```swift
func + (lhs: Bit, rhs: BitSequence) -> BitSequence {
  return BitSequence { $0 == 0 ? lhs : rhs.atIndex($0 - 1) }
}

let ws = .zero + xs

ws.atIndex(0) // .zero
ws.atIndex(1) // .one
ws.atIndex(2) // .one
ws.atIndex(3) // .one
```

The `BitSequence` type holds infinitely many values. In fact, it holds an unconscionable number of values. It has more values than `String` does. It holds so many values that it cannot be [counted](https://en.wikipedia.org/wiki/Uncountable_set) with the natural numbers. It's an infinity that is even larger than the infinitude of natural numbers. It's so large that it can hold an infinite number of disjoint copies of the natural numbers inside it!

So, given how massive this type is, it might be surprising to learn that we can define `anySatisfy` and `allSatisfy` on it, and these functions will terminate in finite time. That means we can exhaustively search the very large infinite space of `BitSequence` in finite time. Even more, we can implement equality between functions on `BitSequence`:

```swift
func == <A: Equatable> (lhs: (BitSequence) -> A, rhs: (BitSequence) -> A) -> Bool {
  // How???
}
```

Surely this must be impossible. How on earth could we expect to determine the equality of two functions whose domains are not only infinite, but a size of infinity that is difficult to even grasp?

## Achieving the seemingly impossible

Let's take it one step at a time. Let's first see if we could define an `allSatisfy` function:

```swift
extension BitSequence {
  static func allSatisfy(_ p: (BitSequence) -> Bool) -> Bool {
    // ???
  }
}
```

This functions definitively answers the question of whether a given predicate evaluates to `true` for *every* value inside `BitSequence`. Well, this seems difficult, so let's kick the can down the road and appeal to a hypothetically defined `anySatisfy` by using De Morgan's law again:

```swift
extension BitSequence {
  static func allSatisfy(_ p: (BitSequence) -> Bool) -> Bool {
    return !BitSequence.anySatisfy { !p($0) }
  }
}
```

So, now we just have to define `anySatisfy`. Let's first get the signature set up:

```swift
extension BitSequence {
  static func anySatisfy(_ p: (BitSequence) -> Bool) -> Bool {
    // ???
  }
}
```

This seems just as difficult as `allSatisfy`, so what have we gained? Well, let's introduce a tiny twist. Suppose there existed a hypothetical `find` function such that when given a predicate on `BitSequence` it would find a `BitSequence` that satisfies the predicate, and if no such value exists it would just return any sequence, the contents of which don't really matter. Let's write the signature of such a function:

```swift
extension BitSequence {
  static func find(_ p: (BitSequence) -> Bool) -> BitSequence {
    // ???
  }
}
```

If such a function existed, we could then implement `anySatisfy` with:

```swift
extension BitSequence {
  static func anySatisfy(_ p: (BitSequence) -> Bool) -> Bool {
    return p(BitSequence.find(p))
  }
}
```

We first `find` a sequence satisfying `p`, if it exists, and then feed it into the predicate `p`. This means that if it does exist we'll get `true`, and if it does not exist we'll get `false`, just like we expect.

It probably feels like we're just kicking the responsibilities even further down the road without accomplishing anything, but we've now boiled down this seemingly impossible program to implementing the `find` function:

```swift
extension BitSequence {
  static func find(_ p: (BitSequence) -> Bool) -> BitSequence {
    // ???
  }
}
```

How can we find a sequence satisfying the predicate `p`? Turns out we can actually construct it recursively. For say there exists a sequence `s` such that the "larger" sequence `.zero + s` is satisfied by the predicate. Then we can peel a `.zero` off this hypothetical sequence, and continue our search on the tail. And if no such sequence exists we can try the same process but using `.one` instead. Let's give that a shot in code:

```swift
extension BitSequence {
  static func find(_ p: (BitSequence) -> Bool) -> BitSequence {

    if BitSequence.anySatisfy({ s in p(.zero + s) }) {
      // We found a sequence `s` such that `.zero + s` satisfies
      // the predicate. So, return `.zero +` that found sequence.
      return .zero + find({ s in p(.zero + s) })

    } else {
      // Otherwise try the same, but with prepending `.one` instead
      // of `.zero`.
      return .one + find({ s in p(.one + s) })
    }
  }
}
```

This now actually compiles in Swift! But it's really mysterious. Is there any reason to believe this function will ever terminate? Not only does it recursively call itself, but it also calls `anySatisfy` which also calls `find`.

In fact, Swift is giving us a warning to let us know this isn't quite right. As of Swift 4.2 the compiler can [prove](https://github.com/apple/swift/pull/11869) that all paths through a function will call itself, and hence never terminate:

```
⚠️ All paths through this function will call itself
```

We need to introduce some laziness into our functions so that we do not try to compute everything at once, but instead compute only as much as we need. The recursive calls to `find` happen in each of the `if`/`else` branches, and happen to the right of the concatenation operator `+`. In order for this function to ever terminate you would need that at some point the right side of `+` does not need to be executed anymore. So, we can lazily defer that by making the right side of `+` an `autoclosure`:

```swift
func + (lhs: Bit, rhs: @escaping @autoclosure () -> BitSequence) -> BitSequence {
  return BitSequence { $0 == 0 ? lhs : rhs().atIndex($0 - 1) }
}
```

Looks a little uglier, but now it's lazy, and the Swift warning went away! However, there's still a recursive call happening that will never terminate, and Swift cannot yet detect this one. In order for `find` to do its work, it needs to call out to `anySatisfy`, but then `anySatisfy` immediately calls `find` again. We have to make `anySatisfy` less eager by hiding some of its work inside a closure. Rather than calling out to `find` directly, let's construct a whole new `BitSequence` that calls `find` under the hood:

```swift
extension BitSequence {
  static func anySatisfy(_ p: @escaping (BitSequence) -> Bool) -> Bool {
    let found = BitSequence { n in find(p).atIndex(n) }
    return p(found)
  }
}
```

This is equivalent to what we had before, but now it is sufficiently lazy for Swift to be able to run this program! It's going to seem incredible, almost magical, but be assured you there are no tricks involved.

Let's take this for a spin. Let's try to find a `BitSequence` that satisfies the property that it evaluates to `.one` on the first 5 even indices:

```swift
let oneOnFirstFiveEvens = BitSequence.find { s in
  s.atIndex(0) == .one
    && s.atIndex(2) == .one
    && s.atIndex(4) == .one
    && s.atIndex(6) == .one
    && s.atIndex(8) == .one
}
```

This is incredible, but in finite time we have searched the *entire* infinite space of `BitSequence` values and constructed an instance that satisfies the predicate we provided. Don't believe it? Let's evaluate it to verify:


```swift
oneOnFirstFiveEvens.atIndex(0)  // .one
oneOnFirstFiveEvens.atIndex(1)  // .zero
oneOnFirstFiveEvens.atIndex(2)  // .one
oneOnFirstFiveEvens.atIndex(3)  // .zero
oneOnFirstFiveEvens.atIndex(4)  // .one
oneOnFirstFiveEvens.atIndex(5)  // .zero
oneOnFirstFiveEvens.atIndex(6)  // .one
oneOnFirstFiveEvens.atIndex(7)  // .zero
oneOnFirstFiveEvens.atIndex(8)  // .one
oneOnFirstFiveEvens.atIndex(9)  // .zero
oneOnFirstFiveEvens.atIndex(10) // .zero
oneOnFirstFiveEvens.atIndex(11) // .zero
oneOnFirstFiveEvens.atIndex(12) // .zero
```

Incredible! We are exhaustively searching an [uncountably](https://en.wikipedia.org/wiki/Uncountable_set) infinite space in finite time.

We can also ask to see if _every_ bit sequence satisfies some predicate, or if _any_ bit sequence satisfies it. For example:

```swift
BitSequence.allSatisfy { 
  s in s.atIndex(0) == .zero || s.atIndex(0) == .one  // true
} 
BitSequence.allSatisfy { s in s.atIndex(0) == .zero } // false
```

In the first expression we have determined that every `BitSequence` satisfies the property that its first value is either `.zero` or `.one.` In the second expression we have determined that not every `BitSequence` has its first value equal to `.zero`.

Another example:

```swift
BitSequence.anySatisfy { s in s.atIndex(4) == s.atIndex(10) } // true
```

Here we have successfully verified that there is at least one bit sequence whose 5th value is equal to its 11th (remember these sequences are 0-based).

We can keep going. Now that we have the `allSatisfy` function at our disposal, we can define equality between functions that have `BitSequence` as their domains:

```swift
func == <A: Equatable> (
  lhs: @escaping (BitSequence) -> A, 
  rhs: @escaping (BitSequence) -> A) -> Bool {

  return BitSequence.allSatisfy { s in lhs(s) == rhs(s) }
}
```

This is able to deterministically, and in finite time, determine when two functions on `BitSequence`'s are equal. This is completely impossible to do with `Int`'s and `String`'s, but here we have done it for `BitSequence`. Let's give it a spin:

```swift
let const1: (BitSequence) -> Int = { _ in 1 }
let const2: (BitSequence) -> Int = { _ in 2 }

const1 == const1 // true
const2 == const2 // true 
const1 == const2 // false
```

Here we have constructed two functions: one always returns `1` regardless of input, and the other returns `2`. Clearly these functions are equal to themselves and not equal to each other, but here we have actually computed it in real time.


To come up with some more complicated functions let's introduce a helper that converts a `Bit` value into an integer:

```swift
extension Bit {
  var toUInt: UInt {
    switch self {
    case .one:  return 1
    case .zero: return 0
    }
  }
}
```

With that helper defined, we can cook up some more complicated looking functions on `BitSequence`'s:

```swift
let f: (BitSequence) -> UInt = { s in
  s.atIndex(1).toUInt * s.atIndex(2).toUInt
}

let g: (BitSequence) -> UInt = { s in
  s.atIndex(1).toUInt + s.atIndex(2).toUInt
}
```

The first multiplies the 2nd and 3rd values of a sequence together, and the second one adds. It certainly seems like these functions are not equal, but let's check:

```swift
f == f // true
g == g // true 
f == g // false
```

Incredible! Again we have searched the infinite space of of `BitSequence` values and determined that these two functions are not equal to each other.

Let's introduce another function that looks a little different from `f` and `g`:

```swift
let h: (BitSequence) -> UInt = { s in
  switch (s.atIndex(1), s.atIndex(2)) {
  case (.zero, _), (_, .zero):
    return 0
  case (.one, let other), (let other, .one):
    return other.toUInt
  }
}
```

Do we think this function is equal to either `f` or `g`?

```swift
h == f // true 
h == g // false 
h == h // true
```

It seems that `h` is equal to `f`, and indeed if we look at its definition we see that we always return the non-zero value from `s.atIndex(1)` and `s.atIndex(2)`, and 0 otherwise, which is equivalent to multiplying bits together.

Let's try one last function, but something a lot more complicated:

```swift
let k: (BitSequence) -> UInt = { s in
  ((s.atIndex(1).toUInt + s.atIndex(2).toUInt + 908) % 6) / 4
}
```

Is this function equal to any of `f`, `g` or `h`? I have no idea! It's quite a bit more complicated than the others, so we'd have to do some actual math work to figure out if they are equal. Luckily we have we have a function that can do the work for us!

```swift
k == f // true
k == g // false
k == h // true
k == k // true
```

Fascinating! It seems that somehow `k` is equivalent to both `f` and `h`, even though it has a wildly different implementation.

## How is this possible?

The only thing better than implementing a seemingly impossible function is finding out that the explanation of its existence is deeply rooted in mathematics that have been known since the late 1800s. Although, we cannot give a full treatment of this topic, we explain some of the concepts and how they all fit together at a very high level. I try my hardest to draw a narrative line from the mathematics to what we just witnessed in this Swift code, but it's more of a story than a rigorous exposition.

### Topology

It begins with a field of mathematics known as [topology](https://en.wikipedia.org/wiki/Topology), which is the study of topological spaces and their properties. Intuitively a topological space is an object that comes equipped with a notion of when points in the space are "near" each other. The [rigorous definition](https://en.wikipedia.org/wiki/Topological_space) of topological spaces is far more abstract, and at first glance wouldn't seem connected at all to what we just described.

Just as in programming we see that functions between types tell us a lot about the types themselves, such is true of functions between topological spaces. However, we can't allow just any such function. We want those functions that "preserve" the structure of the space, and for topological spaces that means the function preserves the closeness of the points. Again, the [rigorous definition](https://en.wikipedia.org/wiki/Continuous_function#Continuous_functions_between_topological_spaces) looks nothing like what we have just described, but it is indeed the very general definition of continuity, and in fact subsumes the definition of continuity that you may have learned in calculus.

Now that we know the basic objects we are studying (topological spaces), and the functions that we allow between them (continuous functions), we want to understand their properties. Topological spaces in the large are [varied](https://en.wikipedia.org/wiki/Topologist's_sine_curve) and [wild](https://en.wikipedia.org/wiki/Wild_arc). There's a subset of spaces that have some nice properties called ["compact"](https://en.wikipedia.org/wiki/Compact_space) topological spaces. Intuitively these are spaces that have a kind of "finite" quality about them, and for many intents and purposes behave like finite sets even though they can have infinitely many points. Already we are seeing see shadows of our problem in the math, for we are very interested in infinite sets that have finite qualities about them.

We also want to know of some nice subsets of continuous functions, for even though continuous functions seem to be well-behaved in that they preserve closeness of points, there are still some truly [wild](https://en.wikipedia.org/wiki/Weierstrass_function) examples of them. There's a subset of continuous functions known as ["uniformly continuous"](https://en.wikipedia.org/wiki/Uniform_continuity), and they have a lot of nice properties. Intuitively these are functions that not only preserve the closeness of points, but the closeness of the points in the range of the function doesn't depend on the location of the points in the domain. That is, we get to control the closeness of points in a uniform manner across the domain of the function. It can be shown that every uniformly continuous function is continuous, but not vice versa, hence uniform continuity is a stronger property.

Once you know of the objects and functions you are playing with, and some nice subsets of those things that are well-behaved, you want to start proving some theorems. An important [theorem](https://en.wikipedia.org/wiki/Heine–Cantor_theorem) for our seemingly impossible functions is stated as such:

> If \\(X\\) is a compact space and \\(Y\\) is any space, then every continuous function \\(f: X \rightarrow Y\\) is uniformly continuous.

(NB: This is technically only true for a subset of topological spaces known as [metric spaces](https://en.wikipedia.org/wiki/Metric_space), but that detail is not important for this lay description.)

This is a very powerful theorem. It states that even though it is far from true that continuous functions are uniformly continuous, if the domain of the function is compact, then both types of functions coincide: continuous implies uniformly continuous.

### Computation

Now that we have some topological results at hand, the question remains how to apply this to programming and the Swift programs we constructed above. It turns out there is a very deep and far-reaching connection between math and computation known as the [Curry-Howard correspondence](https://en.wikipedia.org/wiki/Curry–Howard_correspondence). It's roots are in constructive mathematics, and it roughly says that any proposition in constructive mathematics can be translated into a type, and any proof can be translated into a value of that type.

Constructive mathematics is a weird subject. It's like classical mathematics, except it does not allow [the law of excluded middle](https://en.wikipedia.org/wiki/Law_of_excluded_middle) or [double negation elimination](https://en.wikipedia.org/wiki/Double_negation#Double_negative_elimination). This means that a lot of proofs in classical mechanics are not valid in constructive mathematics, and some theorems are just plain not true. In particular, in constructive mathematics it is true that every constructible function is continuous, which is definitely not true in classical mathematics.

### Tying the knot

And we are now able to tie our stories of topology and computation together. It can be shown that the `BitSequence` set is compact. In fact, it is equivalent to a well-known object called the [Cantor Set](https://en.wikipedia.org/wiki/Cantor_set), which is constructed by taking the unit interval of real numbers and recursively removing the middle third from it and all subsequent sub-intervals. After taking the limit of this process you are left with all the numbers between 0 and 1 whose ternary representation contains only 0's and 2's.

Now that we know `BitSequence` is compact, and that all functions on it are continuous, we can apply our theorem to know that all functions on `BitSequence` are even uniformly continuous. This means that although `BitSequence` is infinitely large, functions on it are determined by their behavior on a finite subset of `BitSequence`. The size of that finite set is known as the [modulus of continuity](https://en.wikipedia.org/wiki/Modulus_of_continuity) of the function. All of these results together explains why we are able to achieve the seemingly impossible by exhaustively searching an infinite space in finite time.

## Conclusion

We've now accomplished what we set out to: construct a seemingly impossible Swift program. We were able to exhaustively search and infinitely large space in finite time, and answer the question of whether two functions were equal at every point. In doing so we not only uncovered something that seems to defy reality, but also can be explained in a very concise way by mathematics that has been known for nearly 150 years.

And although these techniques and results aren't necessarily useful or practical for everyday Swift programming, I hope they can give you sense of awe at the effectiveness of mathematics in computing. To know that math has been able to produce such a counterintuitive result and give such a concise explanation of why it is the way it is, I begin to feel that I can trust mathematics as a guiding beacon for how programming can be done well. This is why I feel strongly that simple mathematical constructs, like pure functions, monoids, etc., form a strong foundation of abstraction as opposed to the overly complicated, and often ad-hoc, design patterns we see in software engineering.

## References

- [Infinite sets that admit fast exhaustive search](http://www.cs.bham.ac.uk/~mhe/papers/exhaustive.pdf) – Martín Escardó
- [Synthetic topology of data types and classical spaces](http://www.cs.bham.ac.uk/~mhe/papers/entcs87.pdf) – Martín Escardó
- [Seemingly Impossible Functional Programs](http://math.andrej.com/2007/09/28/seemingly-impossible-functional-programs/) – Martín Escardó
- [The topology of Seemingly impossible functional programs (Slides)](https://www.cs.bham.ac.uk/~mhe/.talks/popl2012/escardo-popl2012.pdf) – Martín Escardó
- [Swift playground with code from this article](https://gist.github.com/mbrandonw/981f589f32800d3409f817ad4f7c6802)
