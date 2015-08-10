import Foundation

protocol Semigroup {
  // Binary, associative semigroup operation (op)
  func op (g: Self) -> Self
}

extension Int : Semigroup {
  func op (n: Int) -> Int {
    return self + n
  }
}
extension UInt : Semigroup {
  func op (n: UInt) -> UInt {
    return self + n
  }
}

extension Bool : Semigroup {
  func op (b: Bool) -> Bool {
    return self || b
  }
}

extension String : Semigroup {
  func op (b: String) -> String {
    return self + b
  }
}

extension Array : Semigroup {
  func op (b: Array) -> Array {
    return self + b
  }
}

infix operator <> {associativity left precedence 150}
func <> <S: Semigroup> (a: S, b: S) -> S {
  return a.op(b)
}

protocol Monoid : Semigroup {
  static func e () -> Self
}

extension Int : Monoid {
  static func e() -> Int {
    return 0
  }
}
extension UInt : Monoid {
  static func e() -> UInt {
    return 0
  }
}
extension Bool : Monoid {
  static func e() -> Bool {
    return false
  }
}
extension String : Monoid {
  static func e() -> String {
    return ""
  }
}
extension Array : Monoid {
  static func e() -> Array {
    return []
  }
}

protocol CommutativeSemigroup : Semigroup {}

extension Int : CommutativeSemigroup {}
extension UInt : CommutativeSemigroup {}

struct K <M: Monoid where M: CommutativeSemigroup> {
  let p: M
  let n: M

  init() {
    self.p = M.e()
    self.n = M.e()
  }
  init(_ p: M) {
    self.p = p
    self.n = M.e()
  }
  init(n: M) {
    self.p = M.e()
    self.n = n
  }
  init(p: M, n: M) {
    self.p = p
    self.n = n
  }
}

extension K : Monoid, CommutativeSemigroup {
  func op (a: K) -> K {
    return K(p: self.p <> a.p, n: self.n <> a.n)
  }
  static func e () -> K {
    return K()
  }
}

func == <M: Monoid where M: CommutativeSemigroup, M: Equatable> (left: K<M>, right: K<M>) -> Bool {
  return (left.p <> right.n) == (left.n <> right.p)
}
func negate <M: Monoid where M: CommutativeSemigroup> (x: K<M>) -> K<M> {
  return K<M>(p: x.n, n: x.p)
}
func negate <M: Monoid where M: CommutativeSemigroup> (x: M) -> K<M> {
  return K<M>(n: x)
}

typealias Z = K<UInt>

let two = Z(2)
let ntwo = negate(Z(2))
let zero = Z()

two <> negate(two) == zero

enum M <S: Semigroup> {
  case Identity
  case Element(S)
}

extension M : Monoid {
  static func e () -> M {
    return .Identity
  }
  func op (b: M) -> M {
    switch (self, b) {
    case (.Identity, .Identity):
      return .Identity
    case (.Element, .Identity):
      return self
    case (.Identity, .Element):
      return b
    case let (.Element(a), .Element(b)):
      return .Element(a <> b)
    }
  }
}

