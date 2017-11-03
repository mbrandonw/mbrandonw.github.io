---
layout: post
title:  "Composable Reducers"
date:   2017-07-28
categories: swift fp redux
author: Brandon Williams
---

[Elm](http://elm-lang.org) and [Redux](http://redux.js.org) have popularized a concise way of managing Applications state in an understandable and testable way. It consists of a few simple pieces: a model for state, a model for actions, a “reducer” to create new state from the current state and an action, and finally some runtime mechanism to accumulate state over time and update UI. In this article we will dissect the pattern in depth and show off some nice compositions lurking underneath the scenes.

TODO: playground link

## State, Action, Reducer

## Monoid composition

The first type of composition we will explore is putting a monoidal structure on `Reducer`. First, let’s explore what it would mean to compose two reducers in words. Say we have two reducers, `r1, r2: Reducer<S, A>`, how can we combine them to obtain a new reducer `r3: Reducer<S, A>`? Such a reducer must take an `action: A` and `state: S` and produce a new state. Well, we can use the first reducer to do that `state1 = r1.reduce(action, state)`. We have’t yet used the second reducer, so now we can feed `state1` into it to obtain another state `state2 = r2.reduce(action, state2)`. That is the final state that `r3` will return!

The composition we just defined in words is precisely the monoid operation we will define on `Reducer`. Recall that we defined a monoid as a protocol having a binary operation and an identity element:

```swift
precedencegroup Semigroup { associativity: left }
infix operator <>: Semigroup

protocol Monoid: Semigroup {
  static var empty: Self { get }
  static func <>(lhs: Self, rhs: Self) -> Self
}
```

We implement this interface for `Reducer` as follows:

```swift
struct Reducer: Monoid {
  static var empty: Reducer {
    return Reducer { _, state in state }
  }

  static func <> (lhs: Reducer, rhs: Reducer) -> Reducer {
      return Reducer { action, state in
        let state1 = lhs.reduce(action, state)
        let state2 = rhs.reduce(action, state1)
        return state2
      }
  }
}
```

The identity reducer is the one that discards the action and returns the state with no changes.

Using some of the ideas from a previous article, “[Algebraic Structure and Protocols]({% post_url 2015-02-17-algebraic-structure-and-protocols %})”, we state all of the above more simply. Functions of the form `(S, A) -> S` can be rewritten as `(A, S) -> S` (order of arguments doesn't matter), which can be curried to `(A) -> (S) -> S`, which can be rewritten as `(A) -> Endo<S>`, where `Endo<S>` is the type of functions `(S) -> S` (known as endomorphisms). We saw previously that `Endo<S>` is a monoid, and we say that the type of functions into a monoid forms a monoid, therefore `(A) -> Endo<S>` is naturally a monoid from previous results without even having to define anything in code.

Now, unfortunately, Swift’s type-system isn’t expressive enough to allow us to use all these facts without creating wrapper types, but still a fun digression!

## Store

## A sample reducer

## Simplifying with mutation

## Lifting of state

## Lifting of actions

## Exercises

1.) Functions of the form `(A, S) -> S` can be curried to be of the form `(A) -> (S) -> S`, which is the same as `(A) -> Endo<S>`, where `Endo<S>` is the type of functions `(S) -> S` (called “endomorphisms”). We discussed these previously [here]({% post_url 2015-02-17-algebraic-structure-and-protocols %}). We also previously saw that `Endo<S>` is a monoid, and that functions `(A) -> M` into a monoid `M` for a monoid. Is this monoid the same we one defined on `Reducer`?

## References

http://0.0.0.0:4000/swift/html/dsl/2017/06/29/composable-html-views-in-swift.html
http://0.0.0.0:4000/swift/math/algebra/2015/02/17/algebraic-structure-and-protocols.html
