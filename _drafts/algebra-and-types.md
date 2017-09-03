---
layout: post
title:  "The Algebra of Types"
date:   2017-09-05
categories: swift fp
author: Brandon Williams
---

There is a wonderful correspondence between Swift’s types and plain ole algebra. Turns out that forming enums and structs is analogous to taking sums and products of integers. Understanding this connection can help one to model data in a more precise way by simplify types via factoring and removing invalid states from the type. It’s much akin to how one might rewrite the algebraic expression `a * b + a * c` as `a * (b + c)`.

# Sums and Products

Recall that an enum type allows us to express a new type in which a value is precisely _one_ of the cases specified in the enum. For example:

```swift
enum TwoCase<A, B> {
  case one(A)
  case two(B)
}
```

A value of type `TwoCase<A, B>` is either of type `A` _or_ of type `B`. In a sense it contains all the values of `A` and values of `B` separately, each tagged by the `one` or `two` label. This is like a sum operation. In fact, if `A` were finite containing `m` values, and `B` were finite containing `n` values, then `TwoCase<A, B>` would be finite containing `m + n` elements. Here are some examples:

```swift
TwoCase<Void, Void>  // .one(()), .two(())
TwoCase<Bool, Void>  // .one(true), .one(false), .two(())
TwoCase<Bool, Bool>  // .one(true), .one(false), .two(true), .two(false)
TwoCase<Never, Void> // .two(())
```

The last example is particularly interesting. `Never` is the Swift type that is uninhabited, i.e. it contains no values. It’s definition is simply `enum Never {}`. This means that the `.one` case cannot hold a value, so only `.two` holds a value, the void value `()`. That means `TwoCase<Never, Void>` holds only one value, which checks out with `0 + 1 = 1`.

These findings so far lead us to have the intuition that an enum with associated types is kind of like “adding” the associated types together. For example, `TwoCase<Int, String>` is the type the represents the addition of `Int` and `String`. It contains all the values of `Int` as well as the values of `String`.

On the other hand, structs allow us to express a new type in which a value consists of one value from each of the fields specified in the struct. For example:

```swift
struct TwoField<A, B> {
  let one: A
  let two: B
}
```

A value of type `TwoField` consists of a value of type `A` _and_ of type `B`, together. This is like a multiplication operation. In fact, if `A` were finite containing `m` values, and `B` were finite containing `n` values, then `TwoField<A, B>` would be finite contain `m * n` values. Here are some examples:

```swift
TwoField<Void, Void>  // {one: (), two: ()}
TwoField<Bool, Void>  // {one: true, two: ()}, {one: false, two: ()}
TwoField<Bool, Bool>  // {one: true, two: true}, {one: false, two: true}, {one: true, two: false}, {one: false, two: false},
TwoField<Never, Void> // no values!
```

Again this last example is quite interesting. `Never` contains no values, and so `TwoField<Never, Void>` must necessarily have no values since we can’t inhabit the `one` field. It also makes sense from the perspective that `0` multiplied with anything is `0` again.



# Exponents

# Recursive Types

# Fixed points

# Categorification

# Exercises
