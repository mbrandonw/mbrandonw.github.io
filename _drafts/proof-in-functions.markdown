---
layout: post
title:  "Proof in functions"
date:   2015-01-01
categories: swift logic math
---

Swift’s generic functions allow us to explore a beautiful idea that straddles the line between mathematics and computer science. If the signature of a function is sufficiently generic, then there is either a *unique* implementation of that function or *no* implementation of that function, and the existence of an implementation corresponds to a mathematical proof of some theorem in logic.

That was a bit of a mouthful, but by the end of this short article you will understand what that means, and we will have constructed a computer proof of [De Morgan’s law](http://en.wikipedia.org/wiki/De_Morgan%27s_laws).

# Generic Functions

Let’s start with some exercises to prepare our brains for this kind of thinking. If someone handed you the following function declaration, which doesn’t currently compile, and asked you to fill it out so that it compiles, could you?

{% highlight swift %}
func f <A> (x: A) -> A {
  // ???
}
{% endhighlight %}

It’s a function that takes an `x` in some type `A` (can be any type) and needs to return something in `A`. We have absolutely no knowledge of `A`. No way of constructing a value in that type. For example, we can’t even do something like `A()`, for we have no way of knowing if `A` has an initializer of that form. Even worse, there’s a chance that A cannot be instantiated, i.e. `A` has no values! For example, an enum with no cases cannot be instantiated:

{% highlight swift %}
enum Empty {
  // no cases!
}
{% endhighlight %}


This type is valid and compiles just fine, but no instance of it can ever be created. Kind of bizarre, but it will be useful later. Some languages call this type Bottom (`⊥`). 

So, back to that function `f`. How can we implement it so that the compiler says everything is A-Ok? Well, we really have no choice but to just return `x`, i.e. it’s the identity function:

{% highlight swift %}
func f <A> (x: A) -> A {
  // ???
}
{% endhighlight %}

Not only does this implementation appease the compiler, but it is the only implementation we could possibly provide. There is nothing else that could go in the body of the function. You might even ask yourself… then why isn’t the compiler smart enough to write it for me?! More on this later.

Let’s try to implement another generic function. Take this one:

{% highlight swift %}
func f <A, B> (x: A, y: B) -> A {
  // ???
}
{% endhighlight %}

This involves two generic parameters. It’s a function taking values in `A` and `B` and returning something in `A`. After completing the previous function this probably seems obvious. Without knowing anything about `A` or `B` we really have no choice but to return x again:

{% highlight swift %}
func f <A, B> (x: A, y: B) -> A {
  return x
}
{% endhighlight %}

Let’s try something a little more difficult. How might we implement the following generic function?

{% highlight swift %}
func f <A, B> (x: A, g: A -> B) -> B {
  // ???
}
{% endhighlight %}

It takes a value in `A` and a function from `A` to `B` and needs to produce something in `B`. We should notice that two types match up quite nicely: we have a value in `A` and a function that accepts things in `A`. When types align like that it’s probably a good idea to just compose them. In fact, the compiler likes that quite a bit:

{% highlight swift %}
func f <A, B> (x: A, g: A -> B) -> B {
  return g(x)
}
{% endhighlight %}

This all seems so simple, but take a moment to reflect on how strange it is that the compiler is essentially holding our hand in writing these functions. It is guiding us on what to write in order for the function to type check.

Now that we are getting the hang of this we’ll breeze through more of these.



This is a function which takes two functions, one from A to B and the other from B to C, and returns a new function from A to C. The only thing we can do is simply compose those two functions. That is, return a new function that first applies g and then applies h.

We’re going to continue exploring this world of implementing generic functions, but first we need to introduce a new type. It’s a very simple enum with a suggestive name:



The Or<A, B> type has two cases, a left and a right, each with associated values from A and B. A value of this type is really either holding a value of type A or of type B. Unfortunately, this does not work in Swift due to a compiler bug. We can get around this bug by wrapping each case in an autoclosure:



It should be noted that this type is in some sense “dual” to the tuple type (A, B). A value of type (A, B) is really holding a value of type A and of type B.

Let’s try implementing more generic functions with this new type. First, an easy one:



This is saying that given something in A we want to produce something in Or<A, B>, which of course means we just put it in the left case of the enum.

Let’s try a more difficult one that we will break down in more detail:



We now have a value in Or<A, B>, a function from A to C and a function from B to C, and we want to produce a value in C. Well, the only way to really deal with enum values is to switch on them and deal with each case separately:



Now, how to fill in each case? In the left case we will have a value in A. Huh, but we also have a function that takes things in A so we might as well feed it into the function. Oh, and hey, that function outputs a value in C which is where we are trying to get anyway! The right case works the exact same way:



Time to throw a curve ball. Let’s implement the function:



It needs to take a value in A and return a value in B. Hm. Well, we know absolutely nothing about B. It might even be that strange type, Bottom, that has no values. This is an example of a function which has no implementation. There is nothing we can write in this function to appease the compiler.

Here’s another:



This seems similar to an example we already considered, but these functions don’t compose nicely. Their types don’t match up. They both output a value in C and so we can’t align them. Dang. This function also cannot be implemented.

Propositional Logic


So, time to step back and try to make sense of this. How can we interpret the fact that some of these functions have unique implementations and others have no implementation. It’s all connected to the world of formal logic.

In logic, the atomic object is the proposition which can be either true (⊤) or false (⊥). We can connect two propositions P and Q with various operations to create new propositions. For example, disjunction P ∨ Q is read as “P or Q”, and is false if both P and Q are false and true otherwise. On the other hand, conjunction P ∧ Q is read as “P and Q”, and is true if both P and Q are true and false otherwise. A few other operations:

¬P : "not P" : false if P true, true if P

P ⇒ Q : "P implies Q" : false if P false and Q true, true otherwise

P ⇔ Q : "P implies Q and Q implies P"

Using these atoms and operations we can construct small statements. For example, P ⇒ P, i.e. P implies P. Well, of course that’s true. Or even: P ∧ Q ⇒ P, i.e if P and Q are true, then P is true.

Here’s a seemingly more complicated one:

(P ⇒ Q ∧ Q ⇒ R) ⇒ (P ⇒ R)

That is: if P implies Q and Q implies R, then P implies R. Seems reasonable. For if “snowing outside” implies “you wear boots”, and “wearing boots” implies “you wear thick socks”, then “snowing outside” implies “you wear thick socks.”

At this point, you might be seeing a connection between these logical statements and the generic functions we wrote. In fact, the three simple statements we just constructed directly correspond to functions we wrote earlier:



See how the logical statement has the same “shape” as the function signature? This is the idea deep underneath everything we have been grasping at. For every function we could implement there is a corresponding mathematical theorem that is provably true. The converse is also true (but a little more nuanced): for every true logical theorem there is a corresponding generic function implementing the proof.

This view also gives us some perspective on why the function f (A) -> B couldn’t be implemented. For if it could, then the corresponding theorem in logic would be true: P ⇒ Q. That logical statement is saying that any proposition P implies any other proposition Q, which is clearly false.

Another un-implementable function we considered was of the form f (A -> C, B-> C) -> C. That is, it took functions A -> C and B -> C as input and wanted to output a value in C. In the world of logic this corresponds to the statement: (P ⇒ R ∧ Q ⇒ R) ⇒ R. Said verbally, if P implies R and Q implies R then R is true. It’s quite nice that we have two statements involving the truth of R, but those statements alone do not prove the truth of R. If you work better with concrete examples, here are some propositions we can substitute for P, Q and R to show the absurdity of the statement:

P = x and y are even integers
Q = x and y are odd integers
R = x + y is even

Obviously P ⇒ R and Q ⇒ R, but R alone is not true, for that would mean the sum of any two integers is even.

De Morgan’s Law


Swift’s type system is strong enough for us to prove De Morgan’s law, which relates the operations ¬, ∧ and ∨. Programmers can apply this law in order to untangle and simplify gnarly conditional statements. The law states: for any propositions P and Q, the following holds true:

¬(P ∨ Q) ⇔ ¬P ∧ ¬Q

You can think of this as ¬ distributing over ∨ but at the cost of switching ∨ to ∧.

In order to prove this in Swift we need a way to model all of the pieces. Generics take care of the propositions P and Q. How can we model the negation of a statement: ¬P? The concept of false is modeled in a type system by the type that holds no values. Previously we called this Bottom, but in order to be more explicit let’s call this Nothing:



Then the negation of the type A would be a function A -> Nothing. Such a function cannot possibly exist since Nothing has no values. To be more explicit we are going to make a new type to model this:



This type corresponds the negation of the proposition represented by A. 

Other parts of De Morgan’s law include ∨ and ∧. We already have a type for the ∨ disjunction: Or<A, B>. For the ∧ conjunction we have tuples (A, B), but to be more explicit we will create a new type for this:



Now we can try to write the proof. There are two parts. First proving that ¬(P ∨ Q) implies  ¬P ∧ ¬Q. We do this by constructing a function:



There’s a lot to unwrap there, but the compiler says it’s ok so it must be ok. It’s a good idea to either write this function from scratch yourself or trace out every step of the above implementation and make sure all the types match up.

Next we need to prove the converse: ¬P ∧ ¬Q implies ¬(P ∨ Q). This is done by implementing the function:



We have now proven De Morgan’s law. The mere fact that we were able to implement these two functions gives a computer proof of De Morgan’s law.

This is about the most advanced mathematical theorem we can prove in Swift, but the stronger a language’s type system is the more powerful of theorems that can be proven. For example, in Idris one can prove that the sum of two even integers is even. Astonishingly, the languages Agda and Coq can prove a theorem from topology: the fundamental group of the circle is isomorphic to the group of integers.

Curry-Howard correspondence


The rigorous statement of the relationship we have been grasping at is known as the Curry-Howard correspondence, first observed by the mathematician Haskell Curry in 1934 and later finished by logician William Howard in 1969. It sets up a kind of dictionary mapping terms in the computer science world to terms in the mathematics world.

--------------------------------------------
| Computer Science     | Mathematics       |
--------------------------------------------
| Type                 | Proposition       |
| Function             | Implication       |
| Tuple                | Conjunction (and) |
| Sum type             | Disjunction (or)  |
| Function application | Modus ponens      |
| Identity function    | Tautology         |
| Function composition | Syllogism         |
--------------------------------------------

That is only the beginning. There’s a lot more.

By the way, this isn’t the first time a dictionary has been made to map mathematical ideas to another, seemingly different field. In 1975 the mathematician Jim Simons worked with Nobel winning physicist C. N. Yang to create what later became known as the “Wu-Yang dictionary,” which mapped physics ideas to well-established (sometimes decades prior) mathematical concepts:





Physics term on the left; mathematics term on the right.Hole-Driven Development


Often when we tried to implement a function we used “???” as a placeholder for something we had not yet figured out. Sometimes we’d fill that placeholder with something more specific, but might have created more unknown chunks denoted by ???. This is loosely known as “hole-driven development.” The hole is represented by the unknown ??? piece, and we look to the compiler for hints at how we should fill that hole. It’s almost like a conversation with with the compiler.

Some languages and compilers are sophisticated enough to do this work for you. See Agda as well as the djinn package for Haskell.

Exercises


Below you will find some exercises to help you explore these ideas a little deeper. You can also download a playground with all of our code snippets and these exercises combined.

1.) Two of the following functions can be implemented and one cannot. Provide the implementations and explain why the un-implementable one is different.



 2.) Find an implementation of:



3.) Find an implementation of:



4.) Prove the theorem:

P ⇒ ¬(¬P)

by implementing the function:



5.) Try to prove the converse:

¬(¬P) ⇒ P

by implementing the function:



If you are having trouble, don’t worry. It’s not possible to implement this function. However, it’s instructive to attempt it and see how it goes. The inability to implement this function has to do with the fact that we are modeled on “constructive logic”, and this theorem does not have a constructive proof, i.e. we can “construct” double negatives but we cannot remove them.

6.) The following is a function that will “curry” another function:



That is, it takes a function of two parameters and turns it into a function of one parameter that returns a function of one parameter. Describe what this function represents in the world of formal logic.

7.) If the type with no values represents false in a type system, what type would represent true? 

8.) The type Not<A> cannot be instantiated for nearly every type A. However, there is exactly one type for which you can create a value in Not<A>. What is that type and how does it relate to the type discovered in exercise #7.

9.) Bonus: Explore the idea that double-negation in the formal logic world corresponds to “continuation-passing style” (CPS) in the programming world.