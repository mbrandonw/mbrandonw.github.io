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
  case let (.Succ(pred), _):
    return add(pred(), .Succ(b))
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
  case let (.Succ(preda), .Succ(predb)):
    return preda() == predb()
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
  case let (.Succ(pred), _):
    return b + pred() * b
  }
}
