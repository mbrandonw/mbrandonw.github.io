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

2 <> 3
false <> true
"foo" <> "bar"
[2, 3, 5] <> [7, 11]

func sconcat <S: Semigroup> (xs: [S], initial: S) -> S {
  return reduce(xs, initial, <>)
}

sconcat([1, 2, 3, 4, 5], 0)
sconcat([false, true], false)
sconcat(["f", "oo", "ba", "r"], "")
sconcat([[2, 3], [5, 7], [11, 13]], [])

protocol Monoid : Semigroup {
  class func e () -> Self
}

extension Int : Monoid {
  static func e() -> Int {
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

3 <> Int.e()
false <> Bool.e()
"foo" <> String.e()
[2, 3, 5] <> Array.e()

func mconcat <M: Monoid> (xs: [M]) -> M {
  return reduce(xs, M.e(), <>)
}

mconcat([1, 2, 3, 4, 5])
mconcat([false, true])
mconcat(["f", "oo", "ba", "r"])
mconcat([[2, 3], [5, 7], [11, 13]])

protocol Group : Monoid {
  func inv () -> Self
}

extension Int {
  func inv () -> Int {
    return -self
  }
}

3 <> 3.inv()

protocol CommutativeSemigroup : Semigroup {
  // **AXIOM** The binary operation is commutative:
  //   a <> b == b <> a
  // for all values a and b
}

extension Int : CommutativeSemigroup {}
extension Bool : CommutativeSemigroup {}

func f <M: Monoid where M: CommutativeSemigroup> (a: M, b: M) -> M {
  return a <> b <> a <> b
}

protocol CommutativeMonoid : Monoid, CommutativeSemigroup {}
protocol AbelianGroup : Group, CommutativeMonoid {}

extension Int : AbelianGroup {}

struct Max <A: Comparable> {
  let a: A
  init (_ a: A) { self.a = a }
}
extension Max : Semigroup {
  func op (m: Max) -> Max {
    return Max(max(self.a, m.a))
  }
}

enum M <S: Semigroup> {
  case Identity
  case Element(S)
  init (_ s: S) { self = .Element(s) }
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

sconcat([Max(2), Max(5), Max(100), Max(2)], Max(3))
let a = mconcat([M(Max(2)), M(Max(5)), M(Max(100)), M(Max(2))])
switch a {
case let .Element(a):
  a;
case .Identity:
  "e"
}

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


func <> <S: Semigroup> (a: S?, b: S?) -> S? {
  switch (a, b) {
  case (.None, .None):
    return .None
  case (.None, .Some):
    return b
  case (.Some, .None):
    return a
  case let (.Some(a), .Some(b)):
    return a <> b
  }
}

