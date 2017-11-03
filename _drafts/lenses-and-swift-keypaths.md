---
layout: post
title:  "Lenses and Swift KeyPaths"
date:   2017-08-28
categories: swift fp
author: Brandon Williams
---

An important aspect of functional programming languages is the use of immutable data. Applications written using immutable data tend to be easier to reason about, but some may argue that it comes at the cost of ease of use. For example, to change one field of an immutable value, one must construct a whole new copy of the value leaving all fields fixed except for the one changing. Compared to the simple getters and setters of mutable values, that does seem needlessly complicated.

Swift’s copy-on-write semantics for value types solve this pain point, for it is easy to copy a value and make changes to it without affecting the original. However, by pursuing a systematic study on other ways to solve this problem we can uncover a beautiful world of composability that is hidden from the getter/setter world.

We will explore the topic of “lenses” as a means to solve this problem. They solve this problem by

todo: playground

## The lens type

## Data transformations

## Key paths induce lenses

Swift, as of version 4, provides us an ample collection of lenses in the form of `WritableKeyPath`s. Essentially, every writable field in every struct automatically gets a `WritableKeyPath` created by the compiler, accessible via the syntax `\NameOfStruct.nameOfField`. Key paths even compose via `.` so that you can do things like `\Episode.host.location.name` to focus deeply into a value.

Using a key path is a little cumbersome, unfortunately. It requires one statement for creating a copy of a value, and another for setting the field using subscript syntax. For example:

```swift
var copy = episode
copy[keyPath: \.host.location.name] = "Brooklyn"
```

However, it is straightforward to have any key path induce a lens for free

## Not all lenses arise from key paths

## Lenses induce predicates and sorting functions

TODO: playground link

# Future-Forward Swift

What else does swift need to provide to support the full lens picture

# Exercises

1.) Implement the following way of combining two lenses into one:

```swift
func both<A, B, C>(_ lhs: Lens<A, B>, _ rhs: Lens<A, C>) -> Lens<A, (B, C)> {
  ???
}
```

This can be useful for focusing in on two parts of a piece of data at the same time. There is no way to represent this lens with key paths.

2.) Implement the lens that can peek inside a dictionary:

```swift
func key<K, V>(_ key: K) -> Lens<[K:V], [K:V], V?, V?> {
  ???
}
```

3.) Implement the lens that focuses on a particular index of an array:

```swift
func idx<A>(_ idx: Int) -> Lens<[A], [A], A, A> {
  ???
}
```

Unfortunately this lens can be dangerous to use since it may operate on an index out of bounds.

4.)
