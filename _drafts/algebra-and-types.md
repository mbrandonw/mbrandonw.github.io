---
layout: post
title:  "The Algebra of Types"
date:   2017-09-05
categories: swift fp
author: Brandon Williams
---

There is a wonderful correspondence between Swift’s types and plain ole algebra. Turns out that forming enums and structs is analogous to taking sums and products of integers. Understanding this connection can help one to model data in a more precise way by simplify types via factoring and removing invalid states from the type. It’s much akin to how one might rewrite the algebraic expression `a * b + a * c` as `a * (b + c)`.

## Enums and Structs

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
TwoField<Bool, Bool>  // {one: true, two: true}, {one: false, two: true}, {one: true, two: false}, {one: false, two: false}
TwoField<Never, Void> // no values!
```

Again this last example is quite interesting. `Never` contains no values, and so `TwoField<Never, Void>` must necessarily have no values since we can’t inhabit the `one` field. It also makes sense from the perspective that `0` multiplied with anything is `0` again.

## Algebra with Types

At this point we have seen that there is a correspondence with forming enums and structs of finite types and taking the sum and product of the number of values those types hold. Let us take a leap of faith to speak more abstractly, and say that forming an enum or struct of types is the sum and product of types. So, where we previously would have used `TwoCase<Int, String>` we are now going to abstractly say `Int + String`, and similarly `TwoField<Bool, [Int]>` is `Bool * [Int]`. Right now these are just formal symbols we are using in hopes that later we will be able to extract some understanding or intuition from them.

Let also assign a special symbol to the types with zero and one elements respectively. Examples of each of those types are `Never` and `Void` respectively, and we will denote them by `0` and `1`.

Here are some examples of performing algebra with types:

```swift
TwoCase<Never, Never>                // 0 + 0 == 0
TwoField<Void, Int>                  // 1 * Int == Int
TwoField<Bool, TwoCase<Int, String>> // Bool * (Int + String)
Int?                                 // Int + 1
TwoField<Bool?, Int?>                // (Bool + 1) * (Int + 1)
```

These last two examples are interesting! Here we have interpreted `Int?` as `Int + 1`, but why? Recall the definition of optionals in Swift:

```swift
enum Optional<T> {
  case some(T)
  case none
}
```

This is similar to our `TwoCase` enum, except the `.none` case has no associated value. In Swift an enum case with no associated value is just a shortcut to saying that the associated value is in fact `Void`, i.e. `case none(Void)`. Since `Void` has a unique value, Swift can just substitute in `()` where necessary and you don’t have to worry about it.

It is now clear why `Int? = Int + 1`, for `Int?` is equivalent to `TwoCase<Int, Void>`. Then, in the example after that, we interpreted `TwoField<Bool?, Int?>` as `(Bool + 1) * (Int + 1)`. Remember that multiplication _distributes_ over addition (i.e. `a * (b + c) == a * b + a * c`), and so let’s apply that to this expression:

```swift
TwoField<Bool?, Int?>                
//    (Bool + 1) * (Int + 1)
// => (Bool + 1) * Int + (Bool + 1) * 1
// => Bool * Int + 1 * Int + Bool * 1 + 1 * 1
// => Bool * Int + Int + Bool + 1
```

In the first two steps of the algebraic manipulation we expanded via distribution of multiplication. In the last step, we got a little fancy. We applied the algebraic identity that `1` is a multiplicative identity, i.e. `1` times anything leaves that anything unchanged. Hence `Bool * 1` is just `Bool`. To see this directly, considering the struct:

```swift
struct BoolTimesOne {
  let a: Void
  let b: Bool
}
```

To create a value of this type you have no choice by to stick in `()` for the `a: Void` field, hence it isn’t really adding anything to this data type. This type is equivalent to if we dropped the `a` field entirely.

We have now built enough intuition to precisely say how we plan on doing algebra with types:

* The sum of two types `A` and `B` is the type `TwoCase<A, B>`.
* The product of two types `A` and `B` is the type `TwoField<A, B>`, which is equivalent to the tuple type `(A, B)`.
* If two types `A` and `B` are finite with the same number of elements, then they are equivalent, i.e. one can construct two functions `(A) -> B` and `(B) -> A` such that their compositions are the identity. This just means that one merely has to relabel the elements of `A` to obtain `B`.
* We will use integers `n` to denote the unique type with `n` elements. It should be clear from context whether `n` is being used as an integer or a type.


## Exponents

There’s another important operation in algebra that is not captured by addition or multiplication: exponentiation. It allows you to multiply an integer with itself a certain number of times, i.e. `m^n` means to multiply `m` with itself `n` times. How can we express this with types?

To answer this let’s focus on a special case and see if we can generalize. Consider `Int^2`, which is `Int * Int`, which we also called `TwoField<Int, Int>`. A value of this type is a choice of `Int` for the `one` and `two` fields of `TwoField`. Another way to express this is a function `(Bool) -> Int`, for a function of that type is a choice of `Int` for `true` and `false`, which we could use to represent the `one` and `two` fields.

Thinking of `Int^2` as functions `(2) -> Int` shows how to generalize integer exponentiation to types. We will say that the exponent `A^B` of two types `A` and `B` is simply the function type `(B) -> A`. Notice the ordering of `A` and `B`, i.e. the power of the exponent is `B` which is the source of the function `(B) -> A`.

## Recursive Types

The algebra of types also help guide us in understanding recursive types. A recursive type is one in which some subpart refers to the whole. The most canonical example is perhaps `List`s. A definition of `List` goes as so: a value of `List<A>` is either empty, or it’s a head value `head: A` and a tail value `tail: List<A>`. By using our intuition of “or” corresponding to enums and “and” corresponding to structs, we can write out code for this definition directly:

```swift
indirect enum List<A> {
  case empty
  case cons(A, List<A>)
}
```

Two things to note. We must use `indirect` since this enum is recursive, and it is traditional to denote the construction of the head with tail as `cons`.

Let’s write out `List` in its equivalent algebraic form:

```swift
List<A> = 1 + A * List<A>
```

Since `List` was defined using recursion, it’s not too surprising to see `List` appear on both sides of the equation. Now, there is absolutely no type-level justification for what we are about to do. We are going to manipulate these symbols in a purely formal fashion as if they were just algebraic objects even if it’s complete nonsense from a types perspective. The first thing we will do is subtract `A * List<A>` from both sides (I know, completely bonkers!) so get `List` on just one side:

```swift
List<A> = 1 + A * List<A>
=> List<A> - A * List<A> = 1
```

Then we are going to factor out the `List<A>` on the left-side of the equation (which is completely valid on the type level):

```swift
List<A> = 1 + A * List<A>
=> List<A> - A * List<A> = 1
=> List<A> * (1 - A) = 1
```

And finally we are going to _divide_ both sides by `1 - A` so to isolate `List` (I know, I know, it makes no sense!):

```swift
List<A> = 1 + A * List<A>
=> List<A> - A * List<A> = 1
=> List<A> * (1 - A) = 1
=> List<A> = 1 / (1 - A)
```

Ok, we are now left with an expression that makes little sense from a type theoretic viewpoint, but algebraically it’s totally fine. We are saying that `List` is a function that takes a variable `A`, and does the transformation `1 / (1 - A)`. Interestingly, this formula is well known in mathematics, and there is a very good chance you learned it long ago in school. It’s the closed form of a [geometric series](https://en.wikipedia.org/wiki/Geometric_series#Formula) and expanded forms an infinite sum of terms:

```swift
List<A> = 1 / (1 - A)
        = 1 + A + A^2 + A^3 + A^4 + ...
```

Yet again we’ve come to a perfectly fine algebraic equation that makes little sense in types. We can’t take an infinite sum of types in Swift, but let’s still try to make sense of this expression. The last equation represents a type where a value of that type is either `Void` (corresponding to `1`), or a value in `A`, or two values in `A`, or three values in `A`, or four values in `A`, etc. This is precisely what a list is! It’s either the empty list, a list of one element, a list of two elements, a list of three elements, etc! So, our bizarre algebraic manipulations of the types ultimately gave us something sensible!




## Fixed points

## Applications

* `{ data, response, error in }`
* cancelation state
* styling enum/struct
* non empty

### Modeling success and failure

A naive attempt at modeling the success and failure of an operation might be to use structs and optional values:

```swift
struct Result<A, E> {
  let value: A?
  let error: E?
}
```

A `Result` value can be considered successful if it has a non-`nil` `value` and can be considered an error if `error` is non-`nil`. This pattern is even prevalent in Apple API’s, such as `URLSession`’s completion callbacks:

```swift
func dataTask(
  with url: URL,
  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
)
->
URLSessionDataTask
```

The `completionHandler` is a function taking 3 optional values. You assume it went successfully if `Data` is non-`nil`, and assume not successful if `error` is non-`nil`.

Let us apply our principles of algebra to the `Result` type to see what it is problematic. Expanding out its definition in algebra gives us:

```swift
Result<A, E> = (A + 1) * (E + 1)
             = A * E + A + E + 1
```

This shows that an alternative way of interpreting this struct is to think of it as an enum for four different cases: one in which you have a value _and_ an error, one in which you have only a value, one in which you have only an error, and finally a case where you have neither. The first and last cases are completely invalid, for the user of this API should not have to understand what it means to get a value _and_ an error, or to get _neither_. What we really want is just the middle part, the `A + E` part. But, this is just a plain enum! And in fact, all along we should have defined our `Result` as just that!

```swift
enum Result<A, E> {
  case success(A)
  case failure(E)
}
```

Now we have forbidden the invalid states on the type level.

Going back to the `URLSession` example we see that the data being provided has the algebraic form:

```swift
(Data + 1) * (URLResponse + 1) * (Error + 1)
  = Data * URLResponse * Error
    + Data * URLResponse
    + URLResponse * Error
    + Data * Error
    + Data
    + URLResponse
    + Error
    + 1
```

This is an enum with 8 different cases! It’s a bit of a mess. A lot of it is completely invalid and should be forbidden by the types. (It should be noted that the signature of this method is forced due to interop with Objective-C. A modern API that can leverage the full feature set of Swift can more precisely narrow these types, but anything that needs to interface with Objective-C must resort to the struct of optionals method.)

### Cancelable operations

The previous example showed how to model a success and failure state of an operation into a `Result` type. What if we wanted to add the possibility that the operation was neither successful nor failed, but was simply canceled? One might extend `Result` to account for that case:

```swift
enum Result<A, E> {
  case success(A)
  case failed(E)
  case canceled
}
```

However, this isn’t so nice because `Result` stood quite well on its own as a success/failure description. Some operations have no concept of cancelation and we are now forcing them to expose that possibility to users of the API. A less intrusive possibility is to create another type to wrap the idea of cancelation:

```swift
enum Cancelable<A> {
  case value(A)
  case canceled
}
```

Now operations that can have a successful/failed/canceled state can be modeled by `Cancelable<Result<A, E>>`. This is a perfectly fine solution and we could stop right here. However, using our knowledge of algebra of types we could see if there is another interpretation that might flatten things a bit. Algebraically, `Cancelable` is simply:

```swift
Cancelable<A> = A + 1
Cancelable<Result<A, E>> = Result<A, E> + 1
```

This is equivalent to the optional type, where we interpret the `nil` case as the `.canceled` case. So, a cancelable result could equivalently be modeled as just an optional result `Result<A, E>?`. If you get `nil` back you can understand that to mean the operation was canceled, for example:

```swift
service.perform { result in
  switch result {
  case let .some(.success(value)):
    // success with `value`
  case let .some(.failed(error)):
    // failed with `error`
  case .none:
    // canceled
  }
}
```

### Non-empty lists

It is possible to express, at the type-level, a type which represents lists that cannot be empty. Recall that the algebraic expansion of `List<A>` looks like so:

```swift
List<A> = 1 + A + A^2 + A^3 + A^4 + ...
```

where each summand corresponds to a list of a specific lengths. The first term, `1`, in particular corresponds to the empty list, which is precisely what we want to exclude. So, rewriting this to represent our hypothetical `NonEmptyList<A>` we get:

```swift
NonEmptyList<A> = A + A^2 + A^3 + A^4 + ...
```

We have two ways of interpreting this. First, we could factor out an `A` in the right-hand side, obtaining:

```swift
NonEmptyList<A> = A * (1 + A + A^2 + A^3 + A^4 + ...)
```

This now translates directly to a struct using the `List<A>` type:

```swift
struct NonEmptyList<A> {
  let head: A
  let tail: List<A>
}
```

This makes perfect sense too. A non-empty list is nothing but a head value with a (possibly empty) tail list.

Alternatively, instead of factoring out `A` and using `List<A>`, we could have tried to work backwards to produce a recursive definition of `NonEmptyList`. For example, we could factor `A` and then convert the geometric series back to `1 / (1 - A)`:

```swift
NonEmptyList<A> = A + A^2 + A^3 + A^4 + ...
                = A * (1 + A + A^2 + A^3 + A^4 + ...)
                = A / (1 - A)
```

Then multiply both sides by `1 - A` and expand:

```swift
NonEmptyList<A> * (1 - A) = A
=> NonEmptyList<A> - A * NonEmptyList<A> = A
```

Finally move `A * NonEmptyList<A>` to the right side:

```swift
NonEmptyList<A> - A * NonEmptyList<A> = A
=> NonEmptyList<A> = A + A * NonEmptyList<A>
```

This now directly translates to a recursive enum:

```swift
indirect enum NonEmptyList<A> {
  case single(A)
  case cons(A, NonEmptyList<A>)
}
```

Both the struct and enum versions of this data type are equivalent, and which you choose to use is up to preference.

## Categorification

We have only scratched the surface of this topic, but I’d like to show a small glimpse of what else there is to explore. In mathematics there is a process known as “[categorification](https://en.wikipedia.org/wiki/Categorification)”. It takes objects of little or no structure and lifts them into a world with lots of structure. In this lifted world there are constructions that have no corresponding analogy down in the structureless world, so it necessarily gives you a richer playground to explore the domain you are interested in.

As an example from mathematics, there is an invariant of knots known as the [Alexander polynomial](https://en.wikipedia.org/wiki/Alexander_polynomial) discovered in the 1920’s. To each knot it associates a polynomial such that if two polynomials are equivalent then their polynomials are equal. For example, the Alexander polynomial of the simplest knot, the [trefoil](https://en.wikipedia.org/wiki/Trefoil_knot), is $$t - 1 + t^{-1}$$. Then, about 80 years later, it was discovered that living above the coeffecients of the polynomial (in this case $$1, -1, 1$$) is an entire world of groups (I briefly talked about groups [here]({% post_url 2015-02-17-algebraic-structure-and-protocols %})). You can recover the polynomial coeffecients from the groups by calculating the dimension of the group. But, the amazing part is where there was once only simple integers in a polynomial is an entire world of groups, along with everything that the [theory of groups](https://en.wikipedia.org/wiki/Group_theory) has to offer, which was previously hidden when only looking at the polynomial.

This is analogous to what we have just experienced with types. The categorification of the positive natural numbers


## Exercises

* do stuff for trees
* derivative of `List<A>`

## References

* https://en.wikipedia.org/wiki/Categorification
