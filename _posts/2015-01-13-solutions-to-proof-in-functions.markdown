---
layout: post
title:  "[Solutions to Exercises] “Proof in Functions”"
date:   2015-01-13
categories: swift math
---

In the article “[Proof in Functions]({% post_url 2015-01-06-proof-in-functions %})” I provided some exercises at the end. I got a lot of tweets and emails about those exercises, so I decided to provide some solutions.

1.) The first two are the only implementable functions:

```swift
func f <A, B> (x: A) -> B -> A {
  return { _ in x }
}

func f <A, B> (x: A, y: B) -> A {
  return x
}
```

The third function cannot be implemented because it’s corresponding logical statement is “If \\(P\\) implies \\(Q\\), then \\(P\\) is true,” which is clearly false. Knowing that a proposition implies some other proposition does not make it true.

The main reason I stacked these three functions together is because they all have a similar shape: `ABA`. In fact, one can transform the second function into the first via currying. However, there is no way to transform the first into the third.

2.) Let’s use the idea of “hole-driven development” to fill this in. We need to return something of the form `((C, B) -> C) -> ((C, A) -> C)`, so it’s a closure that accepts `((C, B) -> C)` as an argument:

```swift
func f <A, B, C> (f: A -> B) -> ((C, B) -> C) -> ((C, A) -> C) {
  return { g in
    ???
  }
}
```

Now we need to return something of the form `((C, A) -> C)`, which is a closure accepting `(C, A)` as an argument:

```swift
func f <A, B, C> (f: A -> B) -> ((C, B) -> C) -> ((C, A) -> C) {
  return { g in
    return { c, a in
      ???
    }
  }
}
```

Now we need to return something in `C` where we have placed `???`. We have at our disposal `f: A -> B`, `g: (C, B) -> C`, `c: C` and `a: A`. Turns out there are two ways to finish the implementation of this function, something we didn’t encounter in the original article.

```swift
func f <A, B, C> (f: A -> B) -> ((C, B) -> C) -> ((C, A) -> C) {
  return { g in
    return { c, a in
      return c
    }
  }
}

func f <A, B, C> (f: A -> B) -> ((C, B) -> C) -> ((C, A) -> C) {
  return { g in
    return { c, a in
      return g(c, f(a))
    }
  }
}
```

So, why the two different imlementations? The logical representation of this function signature has a few redundancies:

\\[
  \text{Given } P \Rightarrow Q \text{, prove } (R \land Q \Rightarrow R) \Rightarrow (R \land P \Rightarrow R)
\\]

On the one hand, the consequence \\(R \land P \Rightarrow R\\) is tautologically true without even appealing to the antecedent \\(R \land Q \Rightarrow R\\), which corresponds to our first implementation. On the other hand, we can invoke the antecedents \\(P \Rightarrow Q\\) and \\(R \land Q \Rightarrow R\\) to conclude that \\(R \land P \Rightarrow R\\), which corresponds to the second implementation.

To summarize, redundancies in a logical statement lead to multiple proofs, and hence multiple function implementations.

3.) We are tasked with implementing the function:

```swift
func f <A, B, C> (x: A, g: A -> B, h: A -> C) -> (B, C) {
  ???
}
```

We can see that a few types align nicely: we are given `x: A` and we have two functions `g`, `h` whose sole arguement is of type `A`. By plugging `x` into those functions we now have values in types `B` and `C`, which is precisely what we want to return:

```swift
func f <A, B, C> (x: A, g: A -> B, h: A -> C) -> (B, C) {
  return (g(x), h(x))
}
```

4.) We are asked to prove the theorem:

$$ P \Rightarrow \lnot(\lnot P) $$

by implementing the function:

```swift
func f <A> (x: A) -> Not<Not<A>> {
  ???
}
```

Using “hole-driven development” we can fill in the first unknown piece:

```swift
func f <A> (x: A) -> Not<Not<A>> {
  return Not<Not<A>> { (n: Not<A>) -> Nothing in
    ???
  }
}
```

We we need to return something of type `Nothing`. We have at our disposal `x: A` and `n: Not<A>`, which by definition means `n.not: A -> Nothing`. These types align so we should try plugging `x` into `n.not`, and the compiler likes this quite a bit:

```swift
func f <A> (x: A) -> Not<Not<A>> {
  return Not<Not<A>> { (n: Not<A>) -> Nothing in
    return n.not(x)
  }
}
```

Implementing this function is kind of mind-bending. The line `return n.not(x)` is returning a value in `Nothing`, but `Nothing` has no values, so how could this be?!

5.) The converse of the previous proposition:

$$ \lnot(\lnot P) \Rightarrow P $$

was more of a thought exercise. The corresponding function:

```swift
func f <A> (x: Not<Not<A>>) -> A {
  ???
}
```

*cannot* be implemented in Swift. A very large detail we omitted from the original article is specifying the model of logic we were using. Anyone who has had a class in logic probably learned [classical logic](http://en.wikipedia.org/wiki/Classical_logic), but type theory and computation is modeled on [intuitionistic logic](http://en.wikipedia.org/wiki/Intuitionistic_logic) (also known as constructive logic). This is an example of a proposition that is provably true using classical logic, but not intuitionistic logic. One can create double negatives \\(P \Rightarrow \lnot(\lnot P)\\) in constructive logic, but one cannot remove them \\(\lnot(\lnot P) \Rightarrow P \\).

6.) Given that “\\(P\\) and \\(Q\\) implies \\(R\\)”, it is true that “if \\(P\\) is true then \\(Q\\) implies \\(R\\).”

8.) I’m going to cheat and answer #7 and #8 in reverse order. I messed up with my original exercises, I meant for them to be in this order.

So, the question is: what is the unique type `A` for which `Not<A>` contains a value? Remember that `Not<A>` is the type of functions `A -> Nothing`, so for what type `A` can we construct functions `A -> Nothing`? It may seem impossible since `Nothing` has no values, but consider:

```swift
function f (x: Nothing) -> Nothing {
  return x
}
```

This function will compile! Of course, there is no `x: Nothing`, but that does not matter. This function is analagous to what is known as the “[empty function](http://en.wikipedia.org/wiki/Empty_function)” in mathematics. So, we now have that `Not<Nothing>` has values, and in fact it has a unique value, the identity function on `Nothing`.

7.) Well, “true” is also “not false”. In the type world we represented “false” by `Nothing`, hence “not false” is `Not<Nothing>`. This answers the question, but we can explore a little more. By #8 we saw that this type holds precisely one value. The type with one value is essentially unique. We can find different descriptions of the type, but one description can be mapped onto another quite easily. In Swift, there are two other ways to construct a type with a unique value. First, the empty struct (the struct with no fields):

```swift
struct Unit {}
let x = Unit()
```

Using the default constructor `Unit()` we produce the only value that this type holds. Swift also has tuples, which are like simpler structs, and the empty tuple is the only value inhabiting the type of empty tuples:

```swift
let y: () = ()
```

Note that `()` stands for both the type *and* the only value in that type. Also note that `Void` is a typealias for `()`. This is why any function `A -> Void` does not need a return statement, because there is only one possible value to return!

9.) This bonus question will be the topic of a future article :)
