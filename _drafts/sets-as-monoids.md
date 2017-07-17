---
layout: post
title:  "Sets as Monoids"
date:   2017-08-01
categories: swift fp set monoid
author: Brandon Williams
---

This is a quick article to describe some curious observations that can be made when trying to define monoid instances on `Set`. It turns out that, mathematically speaking, `Set` has two possible monoid definitions, yet one of them is _impossible_ to implement in Swift. However, by formulating sets in a new type we can define both monoid instances, but at the cost of losing other set features.

## Set as a monoid

In a [previous](%{ post_url 2017-08-01-semirings-and-predicates %}) article we described how types can carry multiple monoidal structures. Swift doesn’t allow a type to conform to a protocol in multiple ways, so one way around this is to wrap the type in a new type that can provide the conformance. Much like how `Bool` formed two different monoids with `||` and `&&`, the sets also have two different monoidal structures.

Let us speak abstractly for a moment before diving into code. A set is an un-ordered collection of values. Two natural operations on sets come in the form of union and intersection. The union of two sets $$a \cup b$$ is a new set containing all of the values from each set, and the intersection of two sets $$a \cap b$$ is a new set containing only the elements common to both sets. One can show that these operations are associative (i.e. $$(a \cup b) \cup c = a \cup (b \cup c))$$, etc.), and so at the very least we have two semigroups on our hands! Further, the set with no values $$\{\}$$ (the _empty set_) is an identity for union: $$a \cup \{\} = \{\} \cup a = a$$. Therefore sets with union and empty set form a monoid!

We can translate the above monoid on sets into an actual monoid instance on the `Set` type from Swift’s standard library:

```swift
extension Set: Monoid {
    static var empty: Set { return [] }

    static func <>(lhs: Set, rhs: Set) -> Set {
      return lhs.union(rhs)
    }
}
```

Now how about sets with intersection? They form a semigroup, but do they form monoid? In mathematics when dealing with sets you typically start out with a “universe” of all possible elements $$\mathscr U$$ that you can take from to form sets. In this world, the identity for intersection is $$\mathscr U$$ since the intersection of it with any set is the set itself: $$a \cap \mathscr U = \mathscr U \cap a = a$$. However, this universe is not constructible in `Set`, i.e. there is no value `universe: Set<A>` which contains every value of `A`. Therefore it is _impossible_ to define a monoid conformance on `Set<A>`! We can only do the semigroup:

```swift
extension Set: Semigroup {
    static func <>(lhs: Set, rhs: Set) -> Set {
      return lhs.intersection(rhs)
    }
}

extension Set: Monoid {
  static var empty: Set {
    // ??? – impossible to implement
  }
}
```

It’s quite interesting to think that although mathematically a set is a monoid with intersection, this fact is not expressible in the `Set` type form Swift’s standard library.

## An alternative definition of Set

Although the `Set` type cannot be conformed to `Monoid` with intersection as the operation, there is an alternate way of modeling sets in which the monoid conformance can be defined! In this new type, sets are defined as functions `f: (A) -> Bool`, and a value `a: A` is _in_ the set if `f(a)` is true.

```swift
struct _Set<A> {
  let contains: (A) -> Bool
}
```

We have called our set `_Set` to not conflict with Swift’s `Set`. Notice that we have no restrictions on `A`, whereas `Set` requires `A` to be `Hashable`. One can turn any `Set` into a `_Set` via:

```swift
extension _Set where A: Hashable {
  init(set: Set<A>) {
    self.contains = set.contains
  }
}
```

The opposite is not possible, i.e. constructing a `Set` from a `_Set`. We can also define an `intersection`:

```swift
extension _Set {
  func intersection(_ other: _Set) -> _Set {
    return .init { a in
      self.contains(a) && other.contains(a)
    }
  }
}
```

Amazingly, we can make `_Set` a monoid with `intersection`, which was impossible with `Set`!

```swift
extension _Set: Monoid {
  static var empty: _Set {
    return .init { _ in true }
  }

  static func <> (lhs: _Set, rhs: _Set) -> _Set {
    return lhs.intersection(rhs)
  }
}
```

The interesting part of this code is the `empty` definition. We’ve defined a `_Set` value via a function that returns `true` for any value you feed it, i.e. every value of `A` is contained in that set. It’s the universe!

Unfortunately, we cannot just throw away `Set` and work with this new `_Set`. There are some things that are very easy with `Set` that are impossible in `_Set`. For example, `Set`s can be iterated over to do something with every value in the set. Such a thing is not possible with `_Set`s because it is not possible to iterate over every value `a: A` for which `set.contains(a)` is true.

## Exercises

1.) The [symmetric difference](https://en.wikipedia.org/wiki/Symmetric_difference) is defined as the union of each of the differences of two sets: $$(A - B) \cup (B - A)$$. Swift supports this operation via the `symmetricDifference` method. Show that `Set<A>` forms a monoid with this operation.

2.) Define union, difference and symmetric difference on `_Set`.

3.) Make `_Set` into a semiring.

4.) Show how `Optional<Set<A>>` (i.e. `Set<A>?`) can be made into a monoid with intersection as the operation. What is the identity value? The exercises of a [previous article](%{ post_url 2015-02-17-algebraic-structure-and-protocols %}) might help.
