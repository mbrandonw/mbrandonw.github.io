import Foundation

func f <A> (x: A) -> A {
  return x
}

enum Empty {
}

func f <A, B> (x: A, y: B) -> A {
  return x
}

func f <A, B> (x: A, g: A -> B) -> B {
  return g(x)
}

func f <A, B, C> (g: A -> B, h: B -> C) -> (A -> C) {
  return { a in
    return h(g(a))
  }
}

enum Or <A, B> {
  case left(@autoclosure () -> A)
  case right(@autoclosure () -> B)
}

func f <A, B> (x: A) -> Or<A, B> {
  return Or.left(x)
}

func f <A, B, C> (x: Or<A, B>, g: A -> C, h: B -> C) -> C {
  switch x {
  case let .left(a):
    return g(a())
  case let .right(b):
    return h(b())
  }
}

// Can't implement this function!
//func f <A, B> (x: A) -> B {
  // ???
//}

// Can't implement this one either!
//func f <A, B, C> (g: A -> C, h: B -> C) -> C {
  // ???
//}





/* ===============
   De Morgan's Law
   =============== */

enum Nothing {
}

struct Not <A> {
  let not: A -> Nothing
}

struct And <A, B> {
  let left: A
  let right: B
  init (_ left: A, _ right: B) {
    self.left = left
    self.right = right
  }
}

// ¬(P ∨ Q) ⇒ ¬P ∧ ¬Q
func deMorgan1 <A, B> (f: Not<Or<A, B>>) -> And<Not<A>, Not<B>> {

  return And<Not<A>, Not<B>>(
    Not<A> {a in f.not(.left(a))},
    Not<B> {b in f.not(.right(b))}
  )
}

// ¬P ∧ ¬Q ⇒ ¬(P ∨ Q)
func deMorgan2 <A, B> (f: And<Not<A>, Not<B>>) -> Not<Or<A, B>> {

  return Not<Or<A, B>> {(x: Or<A, B>) in
    switch x {
    case let .left(a):
      return f.left.not(a())
    case let .right(b):
      return f.right.not(b())
    }
  }
}


/* ==============
     Exercises
   ============== */

/* 
 1.) Two of the following functions can be implemented
 and one cannot. Provide the implementations and explain 
 why the un- implementable one is different.
 */

//func f <A, B> (x: A) -> B -> A {
//}
//
//func f <A, B> (x: A, y: B) -> A {
//}
//
//func f <A, B> (f: A -> B) -> A {
//}


/*
 2.) Implement the following function:
 */

//func f <A, B, C> (f: A -> B) -> ((C, B) -> C) -> ((C, A) -> C) {
//}

/*
 3.) Implement the following function:
 */

//func f <A, B, C> (x: A, g: A -> B, h: A -> C) -> (B, C) {
//}

/*
 4.) Prove P ⇒ ¬(¬P) by implementing:
 */

//func f <A> (x: A) -> Not<Not<A>> {
//}

/* 
 5.) Try to implement the following function. Note that
 it is not actually possible to implement, but try
 anyway.
 */

//func f <A> (x: Not<Not<A>>) -> A {
//}

/*
 7.) Define a type that represents "true". Recall that "false"
 is represented by the empty type, which we called `Nothing`.
 */

/*
 8.) Using the type `T` defined in #7, construct a value
 in the type `Not<T>`.
 */


"compiled!"





