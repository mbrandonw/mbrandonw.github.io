infix operator <>: AdditionPrecedence

protocol Monoid {
  // **AXIOM** Associativity
  // For all a, b, c in Self:
  //    a <> (b <> c) == (a <> b) <> c
  static func <> (lhs: Self, rhs: Self) -> Self

  // **AXIOM** Identity
  // For all a in Self:
  //    a <> e == e <> a == a
  static var e: Self { get }
}

struct AndBool: Monoid {
  let value: Bool
  init(_ value: Bool) { self.value = value }

  static let e = AndBool(true)

  static func <> (lhs: AndBool, rhs: AndBool) -> AndBool {
    return .init(lhs.value && rhs.value)
  }
}

struct OrBool: Monoid {
  let value: Bool
  init(_ value: Bool) { self.value = value }

  static let e = OrBool(false)

  static func <> (lhs: OrBool, rhs: OrBool) -> OrBool {
    return .init(lhs.value || rhs.value)
  }
}

protocol Semiring {
  // **AXIOMS**
  //
  // Associativity:
  //    a + (b + c) == (a + b) + c
  //    a * (b * c) == (a * b) * c
  //
  // Identity:
  //   a + zero == zero + a == a
  //   a * one == one * a == a
  //
  // Commutativity of +:
  //   a + b == b + a
  //
  // Distributivity:
  //   a * (b + c) == a * b + a * c
  //   (a + b) * c == a * c + b * c
  //
  // Annihilation by zero:
  //   a * zero == zero * a == zero
  //
  static func + (lhs: Self, rhs: Self) -> Self
  static func * (lhs: Self, rhs: Self) -> Self
  static var zero: Self { get }
  static var one: Self { get }
}

extension Bool: Semiring {
  static func + (lhs: Bool, rhs: Bool) -> Bool {
    return lhs || rhs
  }

  static func * (lhs: Bool, rhs: Bool) -> Bool {
    return lhs && rhs
  }

  static let zero = false
  static let one = true
}

struct FunctionS<A, S: Semiring> {
  let call: (A) -> S
}

extension FunctionS: Semiring {
  static func + (lhs: FunctionS, rhs: FunctionS) -> FunctionS {
    return FunctionS { lhs.call($0) + rhs.call($0) }
  }

  static func * (lhs: FunctionS, rhs: FunctionS) -> FunctionS {
    return FunctionS { lhs.call($0) * rhs.call($0) }
  }

  static var zero: FunctionS {
    return FunctionS { _ in S.zero }
  }

  static var one: FunctionS {
    return FunctionS { _ in S.one }
  }
}

typealias Predicate<A> = FunctionS<A, Bool>

let isEven = Predicate<Int> { $0 % 2 == 0 }
let isLessThan = { max in Predicate<Int> { $0 < max } }
let isMagic = Predicate<Int> { $0 == 13 }

extension Sequence {
  func filtered(by p: Predicate<Element>) -> [Element] {
    return self.filter(p.call)
  }
}

Array(0...100).filtered(by: isEven * isLessThan(10) + isMagic)

func || <A> (lhs: Predicate<A>, rhs: Predicate<A>) -> Predicate<A> {
  return lhs + rhs
}

func && <A> (lhs: Predicate<A>, rhs: Predicate<A>) -> Predicate<A> {
  return lhs * rhs
}

Array(0...100).filtered(by: isEven && isLessThan(10) || isMagic)

prefix func ! <A> (p: Predicate<A>) -> Predicate<A> {
  return .init { !p.call($0) }
}

Array(0...100).filtered(by: isEven && !isLessThan(10) || isMagic)

"done"
