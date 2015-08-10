import Foundation

protocol Semigroup {
  // Binary semigroup operation
  // **AXIOM** Should be associative:
  //   a.op(b.op(c)) == (a.op(b)).op(c)
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

func sconcat <S: Semigroup> (xs: [S], _ initial: S) -> S {
  return xs.reduce(initial, combine: <>)
}

sconcat([1, 2, 3, 4, 5], 0)
sconcat([false, true], false)
sconcat(["f", "oo", "ba", "r"], "")
sconcat([[2, 3], [5, 7], [11, 13]], [])

protocol Monoid : Semigroup {
  // Identity value of monoid
  // **AXIOM** Should satisfy:
  //   Self.e() <> a == a <> Self.e() == a
  // for all values a
  static func e () -> Self
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
  return xs.reduce(M.e(), combine: <>)
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


/**
 1.) Make Empty into a semigroup.
 */
enum Empty {}

/**
 2.) Make Unit into a monoid. What about a group?
 */
struct Unit {}

/**
 3.) How does our construction `M<S: Semigroup>` compare with Swift’s optional types `Optional<S: Semigroup>`.
 */

/**
 4.) Make Endomorphism into a monoid. What about a group?
 */
struct Endomorphism <A> {
  let f: A -> A
}

/**
 5.) Make Predicate into a monoid.
 */
struct Predicate <A> {
  let p: A -> Bool
}

/**
 6.) If M is a monoid, make FunctionM into a monoid:
 */
struct FunctionM <A, M: Monoid> {
  let f: A -> M
}

/**
 7.) If G is a group, make FunctionG into a group:
 */
struct FunctionG <A, G: Group> {
  let f: A -> G
}

/**
 8.) Make Max and Min into semigroups in the natural way:
 */
struct Max <A: Comparable> {
  let a: A
  init (_ a: A) { self.a = a }
}

struct Min <A: Comparable> {
  let a: A
  init (_ a: A) { self.a = a }
}

/**
 9.) What do the following computations represent?
 */
//sconcat([Max(2), Max(5), Max(100), Max(2)], Max(0))
//sconcat([Min(2), Min(5), Min(100), Min(2)], Min(200))

/**
 10.) What do the following computations represent?
 */
//mconcat([M(Max(2)), M(Max(5)), M(Max(100)), M(Max(2))])
//mconcat([M(Min(2)), M(Min(5)), M(Min(100)), M(Min(2))])

