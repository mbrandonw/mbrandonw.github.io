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


func exp (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (_, .Zero):
    return .Succ(.Zero)
  case (.Zero, .Succ):
    return .Zero
  case let (.Succ, .Succ(pred_b)):
    return exp(a, pred_b()) * a
  }
}

exp(two, three) == .Succ(.Succ(.Succ(five)))

extension Nat : Comparable {}
func < (a: Nat, b: Nat) -> Bool {
  switch (a, b) {
  case (.Zero, .Succ):
    return true
  case (_, .Zero):
    return false
  case let (.Succ(pred_a), .Succ(pred_b)):
    return pred_a() < pred_b()
  }
}

two < three

func distance (a: Nat, b: Nat) -> Nat {
  switch (a, b) {
  case (.Zero, .Zero):
    return .Zero
  case (.Zero, .Succ):
    return b
  case (.Succ, .Zero):
    return a
  case let (.Succ(pred_a), .Succ(pred_b)):
    return distance(pred_a(), pred_b())
  }
}

distance(two, four) == two

func modulus (a: Nat, m: Nat) -> Nat {
  if a < m {
    return a
  }
  return modulus(distance(a, m), m)
}

modulus(five, two) == one
modulus(.Succ(five), two) == .Zero

func pred (n: Nat) -> Nat? {
  switch n {
  case .Zero:
    return nil
  case let .Succ(pred):
    return pred()
  }
}

pred(two) == one
pred(.Zero) == nil

extension Nat : IntegerLiteralConvertible {
  init(integerLiteral value: IntegerLiteralType) {
    self = Nat.fromInt(value)
  }

  static func fromInt (n: Int, accum: Nat = .Zero) -> Nat {
    if n == 0 {
      return accum
    }
    return Nat.fromInt(n-1, accum: .Succ(accum))
  }
}

let six: Nat = 6
six == .Succ(five)
let seven = Nat.Succ(6)
seven == six + 1


enum Z {
  case Neg(Nat)
  case Pos(Nat)
}

func + (a: Z, b: Z) -> Z {
  switch (a, b) {
  case let (.Neg(a), .Neg(b)):
    return .Neg(a + b)
  case let (.Pos(a), .Pos(b)):
    return .Pos(a + b)
  case let (.Pos(a), .Neg(b)):
    return a > b ? .Pos(distance(a, b)) : .Neg(distance(a, b))
  case let (.Neg(a), .Pos(b)):
    return a < b ? .Pos(distance(a, b)) : .Neg(distance(a, b))
  }
}

func * (a: Z, b: Z) -> Z {
  switch (a, b) {
  case let (.Neg(a), .Neg(b)):
    return .Pos(a * b)
  case let (.Pos(a), .Pos(b)):
    return .Pos(a * b)
  case let (.Pos(a), .Neg(b)):
    return .Neg(a * b)
  case let (.Neg(a), .Pos(b)):
    return .Neg(a * b)
  }
}

extension Z : Equatable {}
func == (a: Z, b: Z) -> Bool {
  switch (a, b) {
  case let (.Neg(a), .Neg(b)):
    return a == b
  case let (.Pos(a), .Pos(b)):
    return a == b
  case let (.Pos(a), .Neg(b)):
    return false
  case let (.Neg(a), .Pos(b)):
    return false
  }
}

let pos_two = Z.Pos(two)
let neg_two = Z.Neg(two)
let pos_four = Z.Pos(four)
let neg_four = Z.Neg(four)

neg_two * neg_two == pos_two + pos_two
pos_two * neg_two == neg_four

