import Foundation

enum NatLessThan4 {
  case Zero
  case One
  case Two
  case Three
}

enum Nat {
  case Zero
  case Succ(@autoclosure () -> Nat)
}

let zero = Nat.Zero
let one: Nat = .Succ(.Zero)
let two: Nat = .Succ(one)
let three: Nat = .Succ(two)
let four: Nat = .Succ(.Succ(.Succ(.Succ(.Zero))))

func add (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (_, .Zero):
    return a
  case (.Zero, _):
    return b
  case let (.Succ(pred_a), _):
    return add(pred_a(), .Succ(b))
  }
}

func + (a: Nat, b: Nat) -> Nat {
  return add(a, b)
}

let five = two + three
let ten = five + five

extension Nat : Equatable {}
func == (a: Nat, b: Nat) -> Bool {
  switch (a, b) {
  case (.Zero, .Zero):
    return true
  case (.Zero, .Succ), (.Succ, .Zero):
    return false
  case let (.Succ(pred_a), .Succ(pred_b)):
    return pred_a() == pred_b()
  }
}

five == .Succ(.Succ(.Succ(.Succ(.Succ(.Zero)))))
five == four
one == one
(one + three) == (two + two)

func * (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (_, .Zero), (.Zero, _):
    return .Zero
  case let (.Succ(pred_a), _):
    return pred_a() * b + b
  }
}

one * four == four
two * two == four
four * three == two + two * five
two * three == five



/**
 Exercises
 */



/**
 1.) Implement the following `exp` function so that `exp(a, b)` is the mathematical exponentiatino of the numbers: a^b
 */

//func exp (a: Nat, b: Nat) -> Nat {
//  ???
//}



/**
2.) Make `Nat` implement `Comparable`:
*/

//extension Nat : Comparable {}
//func < (a: Nat, b: Nat) -> Bool {
//  ???
//}



/**
 3.) Implement the `min` and `max` functions:
*/

//func min (a: Nat, b: Nat) -> Nat {
//  ???
//}

//func max (a: Nat, b: Nat) -> Nat {
//  ???
//}



/**
4.) Implement a distance function between natural numbers, i.e. the absolute value of their difference.
*/

//func distance (a: Nat, b: Nat) -> Nat {
//  ???
//}



/**
 5.) Implement the `modulus` function, i.e. the remainder after dividing `a` by `b`:
 */

//func modulus (a: Nat, b: Nat) -> Nat {
//  ???
//}



/**
 6.) Implement a predecessor function. Since `Zero` doesn’t have a predecessor, you will need to use a non-returning function like `abort` in order to appease the compiler.
*/

//func pred (n: Nat) -> Nat? {
//  ???
//}




/**
 7.) Make `Nat` implement the `IntegerLiteralConvertible` protocol.
*/

//extension Nat : IntegerLiteralConvertible {
//  init (integerLiteral value: IntegerLiteralType) {
//    ???
//  }
//}




/**
 8.) **Bonus:** The integers are a superset of the naturals and include all negative whole numbers. How might you model the integers as a new type in Swift?
*/
