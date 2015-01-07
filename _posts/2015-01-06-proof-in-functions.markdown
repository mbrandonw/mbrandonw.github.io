---
layout: post
title:  "Proof in functions"
date:   2015-01-06
categories: swift math
---

Swift’s generic functions allow us to explore a beautiful idea that straddles the line between mathematics and computer science. If you write down and implement a function using only generic data types, there is a corresponding mathematical theorem that you have proven true. There are a lot of pieces to that statement, but by the end of this short article you will understand what that means, and we will have constructed a computer proof of [De Morgan’s law](http://en.wikipedia.org/wiki/De_Morgan%27s_laws).

All of the code samples in this article are contained in a Swift playground available for download [here](http://www.fewbutripe.com.s3.amazonaws.com/supporting/proof-in-functions/proof-in-functions.playground.zip).

# Generic Functions

Let’s start with some exercises to prepare our brains for this kind of thinking. If someone handed you the following function declaration, which doesn’t currently compile, and asked you to fill it out so that it compiles, could you?

```swift
func f <A> (x: A) -> A {
  ???
}
```

It’s a function that takes an `x` in some type `A` (can be any type) and needs to return something in `A`. We have absolutely no knowledge of `A`. No way of constructing a value in that type. For example, we can’t even do something like `A()` to construct a value, for we have no way of knowing if `A` has an initializer of that form. Even worse, there’s a chance that A cannot be instantiated, i.e. `A` has no values! For example, an enum with no cases cannot be instantiated:

```swift
enum Empty {
  // no cases!
}
```

This type is valid and compiles just fine, but no instance of it can ever be created. Kind of bizarre, but it will be useful later. Some languages call this type Bottom (`⊥`). 

So, back to that function `f`. How can we implement it so that the compiler says everything is A-Ok? Well, we really have no choice but to just return `x`, i.e. it’s the identity function:

```swift
func f <A> (x: A) -> A {
  return x
}
```

Not only does this implementation appease the compiler, but it is the only implementation we could possibly provide. There is nothing else that could go in the body of the function. You might even ask yourself… then why isn’t the compiler smart enough to write it for me?! More on this later.

Let’s try to implement another generic function. Take this one:

```swift
func f <A, B> (x: A, y: B) -> A {
  ???
}
```

This involves two generic parameters. It’s a function taking values in `A` and `B` and returning something in `A`. After completing the previous function this probably seems obvious. Without knowing anything about `A` or `B` we really have no choice but to return `x` again:

```swift
func f <A, B> (x: A, y: B) -> A {
  return x
}
```

Let’s try something a little more difficult. How might we implement the following generic function?

```swift
func f <A, B> (x: A, g: A -> B) -> B {
  ???
}
```

It takes a value in `A` and a function from `A` to `B` and needs to produce something in `B`. We should notice that two types match up quite nicely: we have a value in `A` and a function that accepts things in `A`. When types align like that it’s probably a good idea to just compose them. In fact, the compiler likes that quite a bit:

```swift
func f <A, B> (x: A, g: A -> B) -> B {
  return g(x)
}
```

This all seems so simple, but take a moment to reflect on how strange it is that the compiler is essentially holding our hand in writing these functions. It is guiding us on what to write in order for the function to type check.

Now that we are getting the hang of this we’ll breeze through more of these.

```swift
func f <A, B, C> (g: A -> B, h: B -> C) -> A -> C {
  return { a in
    return h(g(a))
  }
}
```

This is a function which takes two functions, one from `A` to `B` and the other from `B` to `C`, and returns a new function from `A` to `C`. The only thing we can do is simply compose those two functions. That is, return a new function that first applies `g` and then applies `h`.

We’re going to continue exploring this world of implementing generic functions, but we need to introduce a new type. It’s a very simple enum with a suggestive name:

```swift
enum Or <A, B> {
  case left(A)
  case right(B)
}
```

The `Or<A, B>` type has two cases, a `left` and a `right`, each with associated values from `A` and `B`. A value of this type is really either holding a value of type `A` *or* of type `B`. Unfortunately, this does not work in Swift due to a bug in the compiler in which it cannot determine the memory layout of this enum. We can get around this bug by wrapping each case in an autoclosure:

```swift
enum Or <A, B> {
  case left(@autoclosure () -> A)
  case right(@autoclosure () -> B)
}
```

These `@autoclosure` pieces are just an implementation detail and not actually important to the theory we are exploring. It should be noted that this type is in some sense “dual” to the tuple type `(A, B)`. A value of type `(A, B)` is really holding a value of type `A` *and* of type `B`.

Let’s try implementing some generic functions with this new type. First, an easy one:

```swift
func f <A, B> (x: A) -> Or<A, B> {
  return Or.left(x)
}
```

This is saying that given something in `A` we want to produce something in `Or<A, B>`. Only way to do that is to instantiate a new value of the `left` case of `Or`.

A more difficult one that we will break down in more detail:

```swift
func f <A, B, C> (x: Or<A, B>, g: A -> C, h: B -> C) -> C {
  ???
}
```

We now have a value in `Or<A, B>`, a function from `A` to `C` and a function from `B` to `C`, and we want to produce a value in `C`. Well, the only way to really deal with enum values is to switch on them and deal with each case separately:

```swift
func f <A, B, C> (x: Or<A, B>, g: A -> C, h: B -> C) -> C {
  switch x {
  case .left:
    ???
  case .right:
    ???
  }
}
```

Now, how to fill in each case? In the left case we will have a value in `A`. Huh, but we also have a function that takes things in `A` so we might as well feed it into the function. Oh, and hey, that function outputs a value in `C` which is where we are trying to get anyway! The right case works the exact same way:

```swift
func f <A, B, C> (x: Or<A, B>, g: A -> C, h: B -> C) -> C {
  switch x {
  case let .left(a):
    return g(a())
  case let .right(b):
    return h(b())
  }
}
```

Remember that the `left` and `right` cases technically hold closure values, so that is why we have to invoke `a()` and `b()` in the case statements.

Time to throw a curve ball. Let’s implement the function:

```swift
func f <A, B> (x: A) -> B {
  ???
}
```

It needs to take a value in `A` and return a value in `B`. Hm. Well, we know absolutely nothing about `B`. It might even be that strange type, Bottom, that has no values. This is an example of a function which has no implementation. There is nothing we can write in this function to appease the compiler.

Here’s another:

```swift
func f <A, B, C> (g: A -> C, h: B -> C) -> C {
  ???
}
```

This seems similar to an example we already considered, but these functions don’t compose nicely. Their types don’t match up. They both output a value in `C` and so we can’t align them. Dang. This function also cannot be implemented.

# Propositional Logic

Time to step back and try to make sense of this. How can we interpret the fact that some of these functions have unique implementations and others have no implementation. It’s all connected to the world of formal logic.

In logic, the atomic object is the proposition which can be either true (\\(\top\\)) or false (\\(\bot\\)). We can connect two propositions \\(P\\) and \\(Q\\) with various operations to create new propositions. For example, disjunction \\(P \lor Q\\) is read as “P or Q”, and is false if both \\(P\\) and \\(Q\\) are false and true otherwise. On the other hand, conjunction \\(P \land Q\\) is read as “P and Q”, and is true if both \\(P\\) and \\(Q\\) are true and false otherwise. A few other operations:

| Symbol                    | Statement                                           | Truth value                                             |
|---------------------------|:----------------------------------------------------|:--------------------------------------------------------|
| \\(\lnot{P}\\)            | not \\(P\\)                                         | false if \\(P\\) true, true otherwise                   |
| \\(P \Rightarrow Q\\)     | \\(P\\) implies \\(Q\\)                             | false if \\(P\\) true and \\(Q\\) false, true otherwise |
| \\(P \Leftrightarrow Q\\) | \\(P\\) implies \\(Q\\) and \\(Q\\) implies \\(P\\) |                                                         |

Using these atoms and operations we can construct small statements. For example, \\(P \Rightarrow P\\), i.e. \\(P\\) implies \\(P\\). Well, of course that’s true, it’s called a *tautology*. Or even: \\(P \land Q \Rightarrow P\\), i.e if \\(P\\) and \\(Q\\) are true, then \\(P\\) is true.

Here’s a seemingly more complicated one:

\\[ \left( (P \Rightarrow Q) \land (Q \Rightarrow R) \right) \Rightarrow (P \Rightarrow R) \\]

That is: if \\(P\\) implies \\(Q\\) and \\(Q\\) implies \\(R\\), then \\(P\\) implies \\(R\\). Seems reasonable. For if “snowing outside” implies “you wear boots”, and “wearing boots” implies “you wear thick socks”, then “snowing outside” implies “you wear thick socks.”

At this point, you might be seeing a connection between these logical statements and the generic functions we wrote. In fact, the three simple statements we just constructed directly correspond to functions we wrote earlier:

```swift
// P ⇒ P
func f <A> (x: A) -> A {
  return x
}

// P ∧ Q ⇒ P
func f <A, B> (x: A, y: B) -> A {
  return x
}

// (P ⇒ Q ∧ Q ⇒ R) ⇒ (P ⇒ R)
func f <A, B, C> (g: A -> B, h: B -> C) -> (A -> C) {
  return { a in h(g(a)) }
}
```

See how the logical statement has the same “shape” as the function signature? This is the idea deep underneath everything we have been grasping at. For every function we could implement there is a corresponding mathematical theorem that is provably true. The converse is also true (but a little more nuanced): for every true logical theorem there is a corresponding generic function implementing the proof.

This view also gives us some perspective on why the function `A -> B` couldn’t be implemented. For if it could, then the corresponding theorem in logic would be true: \\(P \Rightarrow Q\\). That logical statement is saying that any proposition \\(P\\) implies any other proposition \\(Q\\), which is clearly false.

Another un-implementable function we considered was of the form `(A -> C, B-> C) -> C`. That is, it took functions `A -> C` and `B -> C` as input and wanted to output a value in `C`. In the world of logic this corresponds to the statement: \\((P \Rightarrow R \land Q \Rightarrow R) \Rightarrow R\\). Said verbally, if \\(P\\) implies \\(R\\) and \\(Q\\) implies \\(R\\) then \\(R\\) is true. It’s quite nice that we have two statements involving the truth of \\(R\\), but those statements alone do not prove the truth of \\(R\\). If you work better with concrete examples, here are some propositions we can substitute for \\(P\\), \\(Q\\) and \\(R\\) to show the absurdity of the statement:

<div>$$
  \begin{align*}
    P &= \text{$x$ and $y$ are even integers} \\
    Q &= \text{$x$ and $y$ are odd integers}  \\
    R &= \text{$x + y$ is even}
  \end{align*}
$$</div>

Clearly \\(P \Rightarrow R\\) and \\(Q \Rightarrow R\\), but \\(R\\) alone is not true, for that would mean the sum of any two integers is even.

# De Morgan’s Law


Swift’s type system is strong enough for us to prove De Morgan’s law, which relates the operations \\(\lnot\\), \\(\land\\) and \\(\lor\\). Programmers can apply this law in order to untangle and simplify gnarly conditional statements. The law states: for any propositions \\(P\\) and \\(Q\\), the following holds true:

\\[ \lnot(P \lor Q) \Leftrightarrow \lnot P \land \lnot Q \\]

You can think of this as \\(\lnot\\) distributing over \\(\lor\\) but at the cost of switching \\(\lor\\) to \\(\land\\).

In order to prove this in Swift we need a way to model all of the pieces. Generics take care of the propositions \\(P\\) and \\(Q\\). How can we model the negation of a statement: \\(\lnot P\\)? The concept of false is modeled in a type system by the type that holds no values. Previously we called this Bottom, but in order to be more explicit let’s call this Nothing:

```swift
enum Nothing {
  // no cases
}
```

Then the negation of the type `A` would be a function `A -> Nothing`. Such a function cannot possibly exist since `Nothing` has no values. To be more explicit we are going to make a new type to model this:

```swift
struct Not <A> {
  let not: A -> Nothing
}
```

This type corresponds to the negation of the proposition represented by `A`. 

Other parts of De Morgan’s law include \\(\lor\\) and \\(\land\\). We already have a type for the \\(\lor\\) disjunction: `Or<A, B>`. For the \\(\land\\) conjunction we have tuples `(A, B)`, but to be more explicit we will create a new type for this:

```swift
struct And <A, B> {
  let left: A
  let right: B
  init (_ left: A, _ right: B) {
    self.left = left
    self.right = right
  }
}
```

Now we can try to write the proof. There are two parts. First proving that \\(\lnot(P \lor Q)\\) implies \\(\lnot P \land \lnot Q\\). We do this by constructing a function:

```swift
func deMorgan <A, B> (f: Not<Or<A, B>>) -> And<Not<A>, Not<B>> {
  ???
}
```

We know we need to return something of type `And<Not<A>, Not<B>>`, so we can just fill that piece in:

```swift
func deMorgan <A, B> (f: Not<Or<A, B>>) -> And<Not<A>, Not<B>> {
  return And<Not<A>, Not<B>>(
    ???
  )
}
```

The constructor of `And<Not<A>, Not<B>>` takes two arguments, the left `Not<A>` and the right `Not<B>`, so now we can fill in those pieces:

```swift
func deMorgan <A, B> (f: Not<Or<A, B>>) -> And<Not<A>, Not<B>> {
  return And<Not<A>, Not<B>>(
    Not<A>(???),
    Not<B>(???)
  )
}
```

The constructor of `Not<A>` takes a single function `A -> Nothing`. This is about the time we take a look at what values we have available to us and see how we can piece them together to get what we need. We have a value `f: Not<Or<A, B>>`, which by definition means `f.not: Or<A, B> -> Nothing`. This is close to what we want. If we had some `a: A`, then we could plug `Or.left(a)` into `f.not`. So now we have:

```swift
func deMorgan <A, B> (f: Not<Or<A, B>>) -> And<Not<A>, Not<B>> {
  return And<Not<A>, Not<B>>(
    Not<A> {a in f.not(.left(a))},
    Not<B>(???)
  )
}
```

The `Not<B>` piece works exactly the same, giving us the fully implemented function, and hence half the proof of De Morgan’s law:

```swift
func deMorgan <A, B> (f: Not<Or<A, B>>) -> And<Not<A>, Not<B>> {
  return And<Not<A>, Not<B>>(
    Not<A> {a in f.not(.left(a))},
    Not<B> {b in f.not(.right(b))}
  )
}
```

Next we need to prove the converse: \\(\lnot P \land \lor Q\\) implies \\(\lnot(P \lor Q)\\). This is done by implementing the function:

```swift
func deMorgan <A, B> (f: And<Not<A>, Not<B>>) -> Not<Or<A, B>> {
  ???
}
```

We see that we need to return something of type `Not<Or<A, B>>`, which has a constructor taking a function `Or<A, B> -> Nothing`, so we can fill that in:

```swift
func deMorgan <A, B> (f: And<Not<A>, Not<B>>) -> Not<Or<A, B>> {
  return Not<Or<A, B>> { (x: Or<A, B>) in
    ???
  }
}
```

Now we have this value `x: Or<A, B>`, which is an enum, so we should switch on it and consider each case separately:

```swift
func deMorgan <A, B> (f: And<Not<A>, Not<B>>) -> Not<Or<A, B>> {
  return Not<Or<A, B>> { (x: Or<A, B>) in
    switch x {
    case let .left(a):
      ???
    case let .right(b):
      ???
    }
  }
}
```

Consider the `left` case. We have at our disposal `f: And<Not<A>, Not<B>>` and `a: A`. By definition `f.left: Not<A>`, and hence `f.left.not: A -> Nothing`. Therefore `f.left.not(a): Nothing`, which is exactly what we want. The `right` case works similarly, and we have implemented the function:

```swift
func deMorgan <A, B> (f: And<Not<A>, Not<B>>) -> Not<Or<A, B>> {
  return Not<Or<A, B>> {(x: Or<A, B>) in
    switch x {
    case let .left(a):
      return f.left.not(a())
    case let .right(b):
      return f.right.not(b())
    }
  }
}
```

We have now proven De Morgan’s law. The mere fact that we were able to implement these two functions and it type checks gives a computer proof of De Morgan’s law.

This is about the most advanced mathematical theorem we can prove in Swift, but the stronger a language’s type system is the more powerful of theorems that can be proven. For example, in [Idris](http://www.idris-lang.org) one can prove that the sum of two even integers is even. Astonishingly, the languages [Agda](http://en.wikipedia.org/wiki/Agda_%28programming_language%29) and [Coq](http://en.wikipedia.org/wiki/Coq) can prove a [theorem](http://www.math.uchicago.edu/~may/VIGRE/VIGRE2011/REUPapers/Dooley.pdf) from topology: the [fundamental group](http://en.wikipedia.org/wiki/Fundamental_group) of the circle is isomorphic to the [group](http://en.wikipedia.org/wiki/Group_%28mathematics%29) of integers.

# Curry-Howard correspondence


The rigorous statement of the relationship we have been grasping at is known as the [Curry-Howard correspondence](http://en.wikipedia.org/wiki/Curry–Howard_correspondence), first observed by the mathematician Haskell Curry in 1934 and later finished by logician William Howard in 1969. It sets up a kind of dictionary mapping terms in the computer science world to terms in the mathematics world.

| Computer Science     | Mathematics       |
-----------------------|:------------------|
| Type                 | Proposition       |
| Function             | Implication       |
| Tuple                | Conjunction (and) |
| Sum type             | Disjunction (or)  |
| Function application | [Modus ponens](http://en.wikipedia.org/wiki/Modus_ponens)   |
| Identity function    | [Tautology](http://en.wikipedia.org/wiki/Tautology_(logic)) |
| Function composition | [Syllogism](http://en.wikipedia.org/wiki/Syllogism)         |


That is only the beginning. There’s a lot more.

By the way, this isn’t the first time a dictionary has been made to map mathematical ideas to another, seemingly different field. In 1975 the mathematician Jim Simons worked with Nobel winning physicist C. N. Yang to create what later became known as the “Wu-Yang dictionary,” which mapped physics ideas to well-established (sometimes decades prior) mathematical concepts:

![Physics term on the left; mathematics term on the right.](https://s3.amazonaws.com/www.fewbutripe.com/assets/wu-yang-dictionary.png)

# Hole-Driven Development

Often when we tried to implement a function we used `???` as a placeholder for something we had not yet figured out. Sometimes we’d fill that placeholder with something more specific, but might have created more unknown chunks denoted by `???`. This is loosely known as “hole-driven development.” The hole is represented by the unknown `???` piece, and we look to the compiler for hints at how we should fill that hole. It’s almost like a [conversation](http://www.reddit.com/r/haskell/comments/19aj9t/holedriven_haskell/c8mazeg) with the compiler.

Some languages and compilers are sophisticated enough to do this work for you. See Agda as well as the `djinn` package for Haskell.

# Exercises

Below you will find some exercises to help you explore these ideas a little deeper. You can also download a [playground](http://www.fewbutripe.com.s3.amazonaws.com/supporting/proof-in-functions/proof-in-functions.playground.zip) with all of our code snippets and these exercises combined.

1.) Two of the following functions can be implemented and one cannot. Provide the implementations and explain why the un-implementable one is different.

```swift
func f <A, B> (x: A) -> B -> A {
}

func f <A, B> (x: A, y: B) -> A {
}

func f <A, B> (f: A -> B) -> A {
}
```

2.) Find an implementation of:

```swift
func f <A, B, C> (f: A -> B) -> ((C, B) -> C) -> ((C, A) -> C) {
  ???
}
```

3.) Find an implementation of:

```swift
func f <A, B, C> (x: A, g: A -> B, h: A -> C) -> (B, C) {
  ???
}
```

4.) Prove the theorem:

$$ P \Rightarrow \lnot(\lnot P) $$

by implementing the function:

```swift
func f <A> (x: A) -> Not<Not<A>> {
  ???
}
```

5.) Try to prove the converse:

$$ \lnot(\lnot P) \Rightarrow P $$

by implementing the function:

```swift
func f <A> (x: Not<Not<A>>) -> A {
  ???
}
```

If you are having trouble, don’t worry. It’s not possible to implement this function. However, it’s instructive to attempt it and see how it goes. The inability to implement this function has to do with the fact that we are modeled on “constructive logic”, and this theorem does not have a constructive proof, i.e. we can “construct” double negatives but we cannot remove them.

6.) The following is a function that will “curry” another function:

```swift
func curry <A, B, C> (f: (A, B) -> C) -> A -> B -> C {
  return { a in
    return {b in
      return f(a, b)
    }
  }
}
```

That is, it takes a function of two parameters and turns it into a function of one parameter that returns a function of one parameter. Describe what this function represents in the world of formal logic.

7.) If the type with no values represents false in a type system, what type would represent true? 

8.) The type `Not<A>` cannot be instantiated for nearly every type `A`. However, there is exactly one type for which you can create a value in `Not<A>`. What is that type and how does it relate to the type discovered in exercise #7.

9.) **Bonus:** Explore the idea that double-negation in the formal logic world corresponds to [“continuation-passing style”](http://en.wikipedia.org/wiki/Continuation-passing_style) (CPS) in the programming world.
