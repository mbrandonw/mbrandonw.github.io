---
layout: post
title:  "Composable Reducers with an Effects System"
date:   2017-07-28
categories: swift fp redux effects
author: Brandon Williams
---

[Redux](http://redux.js.org) and [Elm](http://elm-lang.org) have popularized a concise way of modeling changing state in an understandable and testable way. It consists of a few simple pieces: a struct of state, an enum of actions, a “reducer” to create new state from the current state and an action, and finally some mechanism to notify interested parties of state changes. In this article we will dissect the pattern in depth and show off some nice compositions lurking underneath the scenes. We will also create a full blown effects system for modeling side-effects in a testable way.

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

## Lifting of state

## Lifting of actions

## Store

## Effects

Right now the system doesn’t provide a way to handle side-effects, it’s left up to the user. For example, on a button press action you may want to make an API call, and when the request finishes it dispatches an action back to the store. You could certainly put this logic directly in the reducer, but you wouldn’t be able to test it.

Rather than doing that effect right in the reducer, we will adapt the reducer to not only return the new state, but also a first-class value that _describes_ the effect to be done, without actually doing it. We will then build an interpreter into the `Store` that executes the effects. This allows us write tests to assert that effects

## Exercises

1.) Functions of the form `(A, S) -> S` can be curried to be of the form `(A) -> (S) -> S`, which is the same as `(A) -> Endo<S>`, where `Endo<S>` is the type of functions `(S) -> S` (called “endomorphisms”). We discussed these previously [here]({% post_url 2015-02-17-algebraic-structure-and-protocols %}). We also previously saw that `Endo<S>` is a monoid, and that functions `(A) -> M` into a monoid `M` for a monoid. Is this monoid the same we one defined on `Reducer`?

## References

http://0.0.0.0:4000/swift/html/dsl/2017/06/29/composable-html-views-in-swift.html
http://0.0.0.0:4000/swift/math/algebra/2015/02/17/algebraic-structure-and-protocols.html
