---
layout:     post
title:      "[Solutions to Exercises] Algebraic Structure and Protocols"
date:       2016-04-09
categories: swift math algebra
summary:    ""
---

In the article “[Algebraic Structure and Protocols]({% post_url 2015-02-17-algebraic-structure-and-protocols %})” we explored the idea of abstracting algebraic properties of types through protocols. Exercises were provided at the end in order to delve deeper into the topic. Here we present some solutions

1.) In order to make `enum Empty {}` (the enum with no values) into a semigroup we must define the operation:

    ```swift
    extension Empty: Semigroup {
      func op(b: Empty) -> Empty {
        // ???
      }
    }
    ```

Now, `Empty` contains no values, hence `b: Empty` is impossible to construct, but a function `Empty -> Empty` can be constructed (c.f. the solution to #8 in “[Proof in Functions]({% post_url 2015-01-13-solutions-to-proof-in-functions %})”). There are two ways to implement `op`: we can return `self` or we can return `b`. They both satisfy the compiler and the semigroup axioms, and both options give equivalent definitions of the same semigroup:

    ```swift
    extension Empty: Semigroup {
      func op (b: Empty) -> Empty {
        return self // could also return `b`
      }
    }
    ```

The empty enum *cannot* be made into a monoid because a monoid requires an identity element `e: Empty`. No values can be constructed in `Empty, hence it cannot be a monoid.

The [empty semigroup](http://en.wikipedia.org/wiki/Empty_semigroup) may sound pathological, but allowing it can simplify some theories by giving us access to certain universal constructions.

2.) The empty struct `struct Unit {}` can be made into a monoid quite easily:

    ```swift
    extension Unit: Monoid {
      func op(b: Unit) -> Unit {
        return self // could also return `b`
      }
      static func e() -> Unit {
        return Unit()
      }
    }
    ```

This type can also be made into a group. Since the type contains only a single value we can simply make the inverse be the identity function:

    ```swift
    extension Unit: Group {
      func inv() -> Unit {
        return self
      }
    }
    ```

3.) The type `M<S: Semigroup>` essentially makes `S` into an optional type. It adjoins a new value `Identity` to `S` so that a value of `M<S: Semigroup>` is either of type `S` or that newly added value. The `Optional` type does the same, except the value it adjoins is called `None`.

4.) In order to make `Endomorphism<A>` into a semigroup we need to define the operation:

    ```swift
    extension Endomorphism : Semigroup {
      func op (endo: Endomorphism) -> Endomorphism {
        // ???
      }
    }
    ```

We need to figure out how to fill in this function. Taking inspiration from the article “[Proof in Functions]({% post_url 2015-01-06-proof-in-functions %})”, we look at the types we have at our disposal, and see how we can fit them together to get what we need. To start with, we definitely need to return something in `Endomorphism`, so we can fill in that part:

    ```swift
    extension Endomorphism: Semigroup {
      func op(endo: Endomorphism) -> Endomorphism {
        return Endomorphism { a in
          return ???
        }
      }
    }
    ```

Now we have `a: A` to work with, but we also have `self.f: A -> A` and `endo.f: A -> A`. Those functions compose, so we can finish this with:

    ```swift
    extension Endomorphism: Semigroup {
      func op(endo: Endomorphism) -> Endomorphism {
        return Endomorphism { a in
          return self.f(endo.f(a))
        }
      }
    }
    ```

To enhance this into a monoid we need to define the identity element. What’s a function such that when composed with any other function it leaves that function unchanged? None other than the identity function:

    ```swift
    extension Endomorphism: Monoid {
      static func e() -> Endomorphism {
        return Endomorphism { a in
          return a
        }
      }
    }
    ```

Now `Endomorphism` is a monoid. Can it be made into a group? If it could then any function `f: A -> A` would be invertible, i.e. we could find a `g: A -> A` such that their composition (in any order) is the identity function `A -> A`. Such a thing is clearly impossible, for example any constant function `A -> A` is not invertible. Therefore `Endomorphism` cannot be made into a group.

5.) We can make `Predicate` in a monoid with the following:

    ```swift
    extension Predicate: Monoid {
      func op(pred: Predicate) -> Predicate {
        return Predicate { a in
          return self.p(a) && pred.p(a)
        }
      }

      static func e() -> Predicate {
        return Predicate { _ in true }
      }
    }
    ```

6.) We can make `FunctionM` into a monoid with the following:

    ```swift
    extension FunctionM: Monoid {
      func op(function: FunctionM) -> FunctionM {
        return FunctionM { x in
          return self.f(x).op(function.f(x))
        }
      }

      static func e() -> FunctionM {
        return FunctionM { _ in M.e() }
      }
    }
    ```

7.) We can make `FunctionG` into a group with the following:

    ```swift
    extension FunctionG: Monoid {
      func op(function: FunctionG) -> FunctionG {
        return FunctionM { x in
          return self.f(x).op(function.f(x))
        }
      }

      static func e() -> FunctionG {
        return FunctionM { _ in G.e() }
      }

      func inv() -> FunctionG {
        return FunctionG { x in
          return self.f(x).inv()
        }
      }
    }
    ```

8.) We can make `Max` into a semigroup using the `max` function:

    ```swift
    extension Max: Semigroup {
      func op(s: Max) -> Max {
        return Max(max(self.a, s.a))
      }
    }
    ```

And similarly for `Min`:

    ```swift
    extension Min: Semigroup {
      func op(s: Min) -> Min {
        return Min(min(self.a, s.a))
      }
    }
    ```

We can't make `Max` and `Min` into monoids because they don’t have an identity, i.e. there isn't a single element that is less/greater than all comparable values.

9.) The following computations represent the max and min, respectively of the list of values:

    ```swift
    sconcat([Max(2), Max(5), Max(100), Max(2)], Max(0))    // #=> Max(100)
    sconcat([Min(2), Min(5), Min(100), Min(2)], Min(200))  // #=> Min(2)
    ```

10.) Performing the `M` construct on `Max` and `Min` will adjoin a new value to the types that is less/greater than any other value in `Max`/`Min`, respectively. Therefore the following computations correspond to finding the max and min values:

    ```swift
    mconcat([M(Max(2)), M(Max(5)), M(Max(100)), M(Max(2))])  // #=> Max(100)
    mconcat([M(Min(2)), M(Min(5)), M(Min(100)), M(Min(2))])  // #=> Min(2)
    ```
