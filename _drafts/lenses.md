---
layout: post
title:  "Lenses"
date:   2017-04-28
categories: swift fp
author: Brandon Williams
---

An important aspect of functional programming languages is the use of immutable data. Applications written using immutable data tend to be easier to reason about, but some may argue that it comes at the cost of ease of use. For example, in order to change one field of an immutable value, one is forced to construct a whole new copy of the value leaving all fields fixed except for the one being changed. Compared to the simple getters and setters of mutable values, that does seem needlessly complicated. However, in the search to find a better way to handle these annoyances we can cook up an elegant construction to handle functional getters and setters. Further, it opens the doors to additional constructions that are hard to see from the mutable world.

## Immutable data

In Swift we model immutable with `struct`s, `enum`s and the `let` keyword:

```swift
struct Location {
  let id: Int
  let name: String
}
```

It is easy enough to create values of this type:

```swift
let brooklyn = Location(id: 1, name: "Brooklyn")
```

If we were using mutable data, it would also be easy to change a field in the value.

```swift
brooklyn.name = "Brooklyn, NY"
//            ^-- error: cannot assign to property: 'name' is a 'let' constant
```

This code doesn’t compile due to our use of `let` in the definition of `Location`. The only way to change a field in an immutable value is to generate a whole new value, and leave the original value untouched. In this case we construct a new location:

```swift
let newBrooklyn = Location(id: brooklyn.id, name: "Brooklyn, NY")
```

That doesn’t look terrible right now, but could become unweildy with more fields. Things get more complicated when you have nested values:

```swift
struct User {
  let id: Int
  let location: Location
  let name: String
}

let user = User(id: 1, location: brooklyn, name: "Blob")
```

Now if we want to change the user’s location’s name we to do a bit more work:

```swift
let newUser = User(
  id: user.id,
  location: Location(id: user.location.id, name: "Brooklyn, NY"),
  name: user.name
)
```

At this point we must ask: “is there is a better way?”

## Lenses

Stepping back for a moment, we can distill the essence of getters and setters into two functions. A getter on type `A` returns some subpart of type `B`, and hence can be thought of as a function `A -> B`. A setter produces a new value of type `A` by replacing some subpart of it with a value of `B`, hence a function `(B, A) -> A`.

We bundle these functions into a first class type:

```swift
struct Lens<Whole, Part> {
  let view: (Whole) -> Part
  let set: (Part, Whole) -> Whole
}
```

The name comes from the analogy that a getter/setter is like focusing in on a part of a whole.

These functions must satisfying some axioms in order to be considered a lens:

```swift
let lens: Lens<A, B>

lens.view(lens.set(b, a)) == b
lens.set(lens.view(a), a) == a
lens.set(b, lens.set(b, a)) == lens.set(b, a)
```

In words, the axioms describe the following common sense requirements:

* If you set the part of `a` to be `b`, and then view the part, you get back `b`.
* If you view the part `b` in `a`, and then set the part of `a` to `b`, you leave `a` unchanged.
* Setting the part twice is the same as setting it once.

We can construct and use lenses directly:

```swift
let locationNameLens = Lens<Location, String>(
  view: { $0.name },
  set: { Location(id: $1.id, name: $0) }
)

locationNameLens.view(brooklyn)
locationNameLens.set("Brooklyn, NY", brooklyn)
```

In order to reduce potential name conflicts, it can be helpful to namespace lenses in their respective types:

```swift
struct Location {
  let id: Int
  let name: String

  enum lens {
    static let id = Lens<Location, Int>(
      view: { $0.id },
      set: { Location(id: $0, name: $1.name) }
    )
    static let name = Lens<Location, String>(
      view: { $0.name },
      set: { Location(id: $1.id, name: $0) }
    )
  }
}

Location.lens.name.set("Brooklyn, NY", brooklyn)
```

## Composition of lenses

In its current form, lenses do not help with the messy situation of setting a value in a deeply nested value, e.g. `user.location.name`. We have two lenses at our disposal:

```swift
User.lens.location: Lens<User, Location>
Location.lens.name: Lens<Location, String>
```

Notice that there is some overlap in the types: `Lens<User, Location>` and `Lens<Location, String>`. The “part” of the first lens is the same as the “whole” of the second lens. Whenever types align so nicely like that it should tickle something in the back of your brain: a composition could be hiding somewhere! Turns out we can compose lenses quite easily, and we will express this via an operator:

```swift
infix operator ..
func .. <A, B, C> (_ lhs: Lens<A, B>, _ rhs: Lens<B, C>) -> Lens<A, C> {
  return Lens(
    view: { whole in rhs.view(lhs.view(whole)) },
    set: { subPart, whole in
      let part = self.view(whole)
      let newPart = rhs.set(subPart, part)
      return self.set(newPart, whole)
    }
  )
}
```

<!-- The `view` part is straightforward: we first use the `lhs` lens to view into the whole, and then use the `rhs` lens to further view into the part. This is precisely function composition of the `view`s. -->

<!-- The `set` part takes a bit more time to understand. Here we’ve broken it up into multiple steps. First we `view` into the part of the whole. Then we set -->

Now we can construct new lenses from existing ones:

```swift
(User.lens.location..Location.lens.name).set("Brooklyn, NY", user)
```

## Improving composition with protocol extensions

We can make the syntax of lens composition look nicer by using protocol extensions. In particular, we can extend the `Lens` type with constrained `Whole` and `Part` generics, and add computed variables to expose composed lenses:

```swift
extension Lens where Whole == User, Part == Location {
  var name: Lens<Whole, String> {
    return User.lens.location..Location.lens.name
  }
}
```

Note: this kind of extension with concrete constraints is only possible in Swift 3.1+.

Now we can use composed lenses much like regular dot syntax:

```swift
User.lens.location.name.set("Brooklyn, NY", user)
```

## Operators for better lensing

We can define operators to make working with lenses more pleasant. They not only reduce visual noise when using a lens, but also satisfy nice algebraic properties that can be used rewrite code in a more readable form, much like we can rewrite `a && b || a && c` as `a && (b || c)`. The first operator `.~` (I like to read this as “dot twiddle”) binds the `Part` of a lens with a value, giving a function to transform `Whole`s:

```swift
infix operator .~
func .~ <Whole, Part> (lhs: Lens<A, B>, part: B) -> (A) -> A {
  return { a in lens.set(b, a) }
}
```

Now we can cook up transformations of a model easily:

```swift
// Transform (User) -> User that changes a user’s name to “Blob”.
User.lens.name .~ "Blob"
```

If we introduce the “pipe-forward” operator `|>` for function application, then we can apply the transformation to a value, and do multiple transformations at once:

```swift
infix operator |>
func |> <A, B> (x: A, f: (A) -> B) -> B {
  return f(x)
}

user
  |> User.lens.name .~ "Blob"
  |> User.lens.location.name .~ "Brooklyn, NY"
```

The above transforms any `user` to one whose name is “Blob” and location’s name is “Brooklyn, NY”, all while leaving `user` unchanged.

We can introduce the monoid composition operator `<>` on functions of the form `(A) -> A` (see the exercises of my article on <a href="{% post_url 2015-02-17-algebraic-structure-and-protocols %}#exercises">monoids</a>) so that we can compose lens transformations without ever referring to a particular `user`!

```swift
infix operator <>
func <> <A, B, C> (f: @escaping (A) -> B, @escaping g: (B) -> C) -> (A) -> C {
  return { g(f($0)) }
}


let transform =
  User.lens.name .~ "Blob"
    <> User.lens.bio .~ "Turns coffeee into theorems."
    <> User.lens.location.name .~ "Brooklyn, NY"
```

Now `transform` is a function `(User) -> User` that can transform any user by the rules described above.


## Induced structure

By giving functional getters/setters a first class type `Lens`, we are now able to construct new abstractions that would have previously been difficult to see in the mutable world. We previously saw in “[The Algebra of Predicates and Sorting Functions]({% post_url 2017-04-18-algbera-of-predicates-and-sorting-functions %})” that we could define types `Predicate<A>` and `Comparator<A>` that encompass the ideas of filtering and sorting arrays, and that they carry a rich algebraic structure given by a monoid. We will now see how lenses allow us to construct these objects very easily, giving us an abundance of algebraic objects to compose in interesting ways.

For example, if `Part` is comparable, we can induce a predicate on the `Whole` by expressing the idea that whole values are less 

```swift
extension Lens where Part: Comparable {
  func isLessThan(_ x: Part) -> Predicate<Whole> {
    return Predicate { self.view($0) < x }
  }
}
```



## Induced structure – old

 For example, if `Part` is `Equatable`, we can _induce_ a kind of equality on `Whole`s by lensing in:

```swift
extension Lens where Part: Equatable {
  func isEqual(to lhs: Whole) -> (Whole) -> Bool {
    return { rhs in self.view(lhs) == self.view(rhs) }
  }
}
```

For any `lens: Lens<Whole, Part>`, `lens.isEqual(to:)` is a curried function that allows you to bind one value to obtain a function `(Whole) -> Bool`. Such functions are called predicates, and are precisely the things you can feed into the `filter` method on arrays:

```swift
let users: [User] = [...]

users
  .filter(User.lens.location.name.isEqual(to: "Brooklyn, NY"))
```

Here we have filtered an array of users to just the subset that are located in Brooklyn, NY.

Another example of induced structure is when `Part` is `Comparable`, and how that can be used to induce a compare function on the `Whole`. We do this by lensing into the part and doing the comparison there:

```swift
extension Lens where Part: Comparable {
  func compare(_ lhs: Whole, _ rhs: Whole) -> Bool {
    return self.view(lhs) < self.view(rhs)
  }
}
```

If we have an array of users `[user]`, we can use any lens on `User` to sort it, e.g.:

```swift
let users: [User] = [...]

// Sort by user’s id
users.sorted(User.lens.id.compare)

// Sort by user’s location’s name
users.sorted(User.lens.location.name.compare)
```

We can also use lenses to cook up predicates on `Whole`s, for example:

```swift
extension Lens where Part: Comparable {
  func isLessThan(_ value: Part) -> (Whole) -> Bool {
    return { whole in self.view(whole) < value }
  }
}
```

This could be used to filter an array of users in various ways:

```swift
// All users whose location id is less than 100
users.filter(User.lens.location.id.isLessThan(100))
```

This type of construction is quite universal. In general, any structure that `Part` has, you can usually induce that structure onto `Whole` by lensing into wholes and exploiting the structure of the parts.

## Reducing boilerplate

Creating new lenses requires a bit of boilerplate. It can be particularly annoying when adding new fields to your types, or re-arranging fields, causing all of your lenses not to compile. There is a small compromise you can make to help with this. Instead of making all fields of your model be `let`s, you can mark them as `var private(set)`, which effectively makes your value immutable to the outside world, but inside you can create copies to mutate.

```swift
struct Location {
  var private(set) id: Int
  var private(set) name: String

  enum lens {
    static let id = Lens<Location, Int>(
      view: { $0.id },
      set: { var r = $1; r.id = $0; return r }
    )
    static let name = Lens<Location, String>(
      view: { $0.name },
      set: { var r = $1; r.name = $0; return r }
    )
  }
}
```

Now the compiler won’t complain if you add/arrange the fields in your type, and it’s mechanical exercise to implement new lenses.

## Real life use cases

At my [day job](https://www.kickstarter.com)


## Exercises

1.) Write lens instances for tuples of 2-elements:

```swift
func _1 <A, B> () -> Lens<(A, B), A> {
  // implement
}

func _2 <A, B> () -> Lens<(A, B), B> {
  // implement
}
```

2.) Implement the lens operator `%~` that allows you to replace a part of a whole by applying a transformation to the current value of the part:

```swift
infix operator %~
func %~ <Whole, Part> (lens: Lens<Whole, Part>, f: (Part) -> Part) -> (Whole) -> Whole {
  // implement
}
```

3.) Given an array `users: [User]`, express a new array that finds all users based in “Austin, TX” and transform the users’ names to uppercase.

4.) Define a `NonEmptyList` type via:

```swift
struct NonEmptyList<A> {
  let head: A
  let tail: [A]
}
```

Implement the following two lenses on `NonEmptyList`:

```swift
extension NonEmptyList {
  static let headLens: Lens<NonEmptyList<A>, A>
  static let tailLens: Lens<NonEmptyList<A>, [A]>
}
```

**Note:** Due to a limitation of Swift 3.1 we cannot nest the namespace `lens` inside the generic type `NonEmptyList<A>`, so we will just add the suffix `Lens` to the name of the lens.






### Sources

09 The Unreasonable Effectiveness of Lenses for Business Applications
https://www.youtube.com/watch?v=T88TDS7L5DY










