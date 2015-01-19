import Foundation


protocol Semigroup {
  // Binary, associative semigroup operation (sop)
  func sop (g: Self) -> Self
}

extension Int : Semigroup {
  func sop (n: Int) -> Int {
    return self + n
  }
}
extension UInt : Semigroup {
  func sop (n: UInt) -> UInt {
    return self + n
  }
}

extension Bool : Semigroup {
  func sop (b: Bool) -> Bool {
    return self || b
  }
}

extension String : Semigroup {
  func sop (b: String) -> String {
    return self + b
  }
}

extension Array : Semigroup {
  func sop (b: Array) -> Array {
    return self + b
  }
}

infix operator <> {associativity left precedence 150}
func <> <S: Semigroup> (a: S, b: S) -> S {
  return a.sop(b)
}

2 <> 3
false <> true
"foo" <> "bar"
[2, 3, 5] <> [7, 11]

protocol Monoid : Semigroup {
  class func id () -> Self
}

extension Int : Monoid {
  static func id() -> Int {
    return 0
  }
}
extension UInt : Monoid {
  static func id() -> UInt {
    return 0
  }
}

protocol CommutativeMonoid : Monoid {
}

extension Int : CommutativeMonoid {}
extension UInt : CommutativeMonoid {}

struct K <M: CommutativeMonoid> {
  let p: M
  let n: M

  init() {
    self.p = M.id()
    self.n = M.id()
  }
  init(p: M) {
    self.p = p
    self.n = M.id()
  }
  init(n: M) {
    self.p = M.id()
    self.n = n
  }
  init(p: M, n: M) {
    self.p = p
    self.n = n
  }
}

extension K : CommutativeMonoid {
  func sop (a: K) -> K {
    return K(p: self.p <> a.p, n: self.n <> a.n)
  }
  static func id () -> K {
    return K()
  }
}

func == <M: CommutativeMonoid where M: Equatable> (left: K<M>, right: K<M>) -> Bool {
  return (left.p <> right.n) == (left.n <> right.p)
}
func negate <M: CommutativeMonoid> (x: K<M>) -> K<M> {
  return K<M>(p: x.n, n: x.p)
}

typealias Z = K<UInt>

let two = Z(p: 2)
let ntwo = Z(n: 2)
let zero = Z()

two <> negate(two) == zero



//func gcd (a: Int, b: Int) -> Int {
//  switch (a, b) {
//  case (_, 0): return abs(a)
//  case (0, _): return abs(b)
//  default: return gcd(b, a % b)
//  }
//}
//func xgcd (a: Int, b: Int) -> (Int, Int, Int) {
//  switch (a, b) {
//  case (_, 0): return (1, 0, a)
//  default:
//    let (x, y, g) = xgcd(b, a % b)
//    return (y, x - (Int)(a/b) * y, g)
//  }
//}
//func modinv (a: Int, m: Int) -> Int? {
//  let (x, y, g) = xgcd(a, m)
//  if g == 1 {
//    return x % m
//  }
//  return nil
//}
//
//infix operator <>  {associativity left precedence 150}
//
//protocol Semigroup {
//  func sop (g: Self) -> Self
//}
//func <> <S: Semigroup> (g: S, h: S) -> S {
//  return g.sop(h)
//}
//
//protocol Monoid : Semigroup {
//  func mid () -> Self
//}
//
//protocol Group : Monoid {
//  func inv () -> Self
//}
//
//protocol AbelianGroup : Group {
//}
//
//
//
//
//
//func <> <S: Semigroup> (g: S?, h: S?) -> S? {
//  switch (g, h) {
//  case (.None, .None):
//    return .None
//  case (.None, .Some):
//    return h
//  case (.Some, .None):
//    return g
//  case let (.Some(g), .Some(h)):
//    return g <> h
//  }
//}
//
//extension Int : Group {
//  func mid() -> Int {
//    return 0
//  }
//  func sop (g: Int) -> Int {
//    return self + g
//  }
//  func inv () -> Int {
//    return -1
//  }
//}
//
//struct MaxInt {
//  let a: Int
//  init (_ a: Int) { self.a = a }
//}
//extension MaxInt : Semigroup {
//  func sop(g: MaxInt) -> MaxInt {
//    return MaxInt(max(self.a, g.a))
//  }
//}
//
//struct MinInt {
//  let a: Int
//  init (_ a: Int) { self.a = a }
//}
//extension MinInt : Semigroup {
//  func sop(g: MinInt) -> MinInt {
//    return MinInt(min(self.a, g.a))
//  }
//}
//
//struct Predicate <A> {
//  let p: A -> Bool
//  init (_ p: A -> Bool) { self.p = p }
//}
//extension Predicate : Group {
//  func mid() -> Predicate {
//    return Predicate { _ in true }
//  }
//  func sop (pred: Predicate) -> Predicate {
//    return Predicate { a in
//      return self.p(a) && pred.p(a)
//    }
//  }
//  func inv () -> Predicate {
//    return Predicate { a in
//      return !self.p(a)
//    }
//  }
//}
//
//struct Function <A, B> {
//  let f: A -> B
//  init (_ f: A -> B) { self.f = f }
//}
//
//enum Ordering {
//  case LT
//  case EQ
//  case GT
//}
//extension Ordering : Monoid {
//  func mid() -> Ordering {
//    return EQ
//  }
//  func sop (g: Ordering) -> Ordering {
//    switch (self, g) {
//    case (.LT, _):
//      return .LT
//    case (.GT, _):
//      return .GT
//    case (.EQ, _):
//      return g
//    }
//  }
//}
//
//
//extension Bool : Monoid {
//  func mid() -> Bool {
//    return false
//  }
//  func sop (g: Bool) -> Bool {
//    return self && g
//  }
//}
//
//func <> <A, S: Semigroup> (f: A -> S, g: A -> S) -> (A -> S) {
//  return {a in
//    return f(a) <> g(a)
//  }
//}
//
//func isEven (n: Int) -> Bool {
//  return n % 2 == 0
//}
//func isPositive (n: Int) -> Bool {
//  return n > 0
//}
//
//
//func <> <S: Semigroup, T: Semigroup> (g: (S, T), h: (S, T)) -> (S, T) {
//  return (g.0 <> h.0, g.1 <> h.1)
//}
//
//(Predicate(isEven).inv() <> Predicate(isEven)).p(3)
//
//
//arc4random()
//
//
//
//
////protocol AdditiveSemigroup : Semigroup {
////  func sadd (a: Self) -> Self
////}
////protocol MultiplicativeSemigroup : Semigroup {
////  func smult (a: Self) -> Self
////}
////
////func <> <S: Semigroup> (a: S, b: S) -> S {
////  return a.sop(b)
////}
////func <+> <S: AdditiveSemigroup> (a: S, b: S) -> S {
////  return a.sadd(b)
////}
////func <*> <S: MultiplicativeSemigroup> (a: S, b: S) -> S {
////  return a.smult(b)
////}
////
////protocol Monoid : MultiplicativeSemigroup {
////  func mid () -> Self
////}
////protocol AdditiveMonoid : AdditiveSemigroup {
////  func mzero () -> Self
////}
////
////protocol Group : Monoid {
////  func inv () -> Self
////}
////protocol AdditiveGroup : AdditiveMonoid {
////  func negate () -> Self
////}
////
////
////
////
////extension Int : Semigroup {
////  func sop(a: Int) -> Int {
////    return self + a
////  }
////}
////extension Int : AdditiveSemigroup, AdditiveMonoid, AdditiveGroup {
////  func sadd(a: Int) -> Int {
////    return self + a
////  }
////  func mzero() -> Int {
////    return 0
////  }
////  func negate() -> Int {
////    return -self
////  }
////}
////extension Int : MultiplicativeSemigroup, Monoid {
////  func smult(a: Int) -> Int {
////    return self * a
////  }
////  func mid() -> Int {
////    return 1
////  }
////}
////
////func <> <S: Semigroup> (a: S?, b: S?) -> S? {
////  switch (a, b) {
////  case (.None, .None):
////    return .None
////  case (.None, .Some):
////    return b
////  case (.Some, .None):
////    return a
////  case let (.Some(a), .Some(b)):
////    return a <> b
////  }
////}
////
////struct CyclicGroup {
////  let order: Int = 1
////  let element: Int = 0
////}
////
////extension CyclicGroup : Equatable {
////}
////func == (lhs: CyclicGroup, rhs: CyclicGroup) -> Bool {
////  return lhs.order == rhs.order && ((lhs.element - rhs.element) % lhs.order == 0)
////}
////extension CyclicGroup : Semigroup, AdditiveSemigroup {
////  func sop(a: CyclicGroup) -> CyclicGroup {
////    assert(self.order == a.order, "orders must be equal")
////    return CyclicGroup(order: self.order, element: self.element + a.element)
////  }
////  func sadd(a: CyclicGroup) -> CyclicGroup {
////    return self.sop(a)
////  }
////}
////extension CyclicGroup : AdditiveMonoid {
////  func mzero () -> CyclicGroup {
////    return CyclicGroup(order: self.order, element: 0)
////  }
////}
////extension CyclicGroup : AdditiveGroup {
////  func negate() -> CyclicGroup {
////    return CyclicGroup(order: self.order, element: -self.element)
////  }
////}
////extension CyclicGroup : Group {
////  func mid() -> CyclicGroup {
////    return CyclicGroup(order: self.order, element: 1)
////  }
////  func smult (a: CyclicGroup) -> CyclicGroup {
////    return CyclicGroup(order: self.order, element: self.element * a.element)
////  }
////  func inv() -> CyclicGroup {
////    let inv = modinv(self.element, self.order)
////    if let inv = inv {
////      return CyclicGroup(order: self.order, element: inv)
////    }
////    assert(false, "cycle group order must be prime number")
////  }
////}
////
////struct DihedralGroup {
////  let order: Int = 1
////  let reflection: Bool = false
////  let rotation: Int = 0
////}
////
////extension DihedralGroup : Semigroup {
////  func sop(a: DihedralGroup) -> DihedralGroup {
////    assert(self.order == a.order, "orders must be equal")
////    return DihedralGroup(
////      order: self.order,
////      reflection: self.reflection ^ a.reflection,
////      rotation: self.rotation + a.rotation
////    )
////  }
////}
////extension DihedralGroup : MultiplicativeSemigroup {
////  func smult(a: DihedralGroup) -> DihedralGroup {
////    return self.sop(a)
////  }
////}
////extension DihedralGroup : Equatable {
////}
////func == (lhs: DihedralGroup, rhs: DihedralGroup) -> Bool {
////  return
////    lhs.order == rhs.order &&
////    lhs.reflection == rhs.reflection &&
////    ((lhs.rotation - rhs.rotation) % lhs.order == 0)
////}
////
////
////struct ProductSemigroup <G: Semigroup, H: Semigroup> {
////  let g: G
////  let h: H
////}
////extension ProductSemigroup : Semigroup {
////  func sop(a: ProductSemigroup) -> ProductSemigroup {
////    return ProductSemigroup(
////      g: self.g.sop(a.g),
////      h: self.h.sop(a.h)
////    )
////  }
////}
////func == <G: Semigroup, H: Semigroup where G: Equatable, H: Equatable> (lhs: ProductSemigroup<G, H>, rhs: ProductSemigroup<G, H>) -> Bool {
////  return (lhs.g == rhs.g) && (lhs.h == rhs.h)
////}
////
////struct QuotientGroup <G: Group, H: Group> {
////  let g: G
////  let phi: G -> H
////}
////extension QuotientGroup : Group {
////  func sop(a: QuotientGroup) -> QuotientGroup {
////    return QuotientGroup(g: self.g <*> a.g, phi: self.phi)
////  }
////  func smult(a: QuotientGroup) -> QuotientGroup {
////    return self.sop(a)
////  }
////  func inv() -> QuotientGroup {
////    return QuotientGroup(g: self.g.inv(), phi: self.phi)
////  }
////  func mid () -> QuotientGroup {
////    return QuotientGroup(g: g.mid(), phi: self.phi)
////  }
////}
////func == <G: Group, H: Group where G: Equatable, H: Equatable> (lhs: QuotientGroup<G, H>, rhs: QuotientGroup<G, H>) -> Bool {
////
////  return lhs.phi(lhs.g) == rhs.phi(rhs.g)
////}
////
////enum C4 {
////  case e
////  case a
////  case a2
////  case a3
////}
////extension C4 : Semigroup {
////  func sop(a: C4) -> C4 {
////    switch (self, a) {
////    case (.e, .a), (.e, .a2), (.e, .a3):
////      return a
////    case (_, .e):
////      return self
////    case (.a, .a):
////      return .a2
////    case (.a, .a2), (.a2, .a):
////      return .a3
////    case (.a, .a3), (.a3, .a):
////      return .e
////    case (.a2, .a2):
////      return .e
////    case (.a2, .a3), (.a3, .a2):
////      return .a
////    case (.a3, .a3):
////      return .a2
////    }
////  }
////}
////
////enum RubiksCubeRotation {
////  case Front(C4)
////  case Back(C4)
////  case Left(C4)
////  case Right(C4)
////  case Top(C4)
////  case Bottom(C4)
////}
////
////struct RubiksCubeSemigroup {
////  let transforms: [RubiksCubeRotation]
////}
////
////
////let a = CyclicGroup(order: 7, element: 2)
////(a <*> a).inv() <*> (a <*> a) == a.mid()
////
////
////struct Predicate <A> {
////  let p: A -> Bool
////}
////extension Predicate : Semigroup {
////  func sop(pred: Predicate) -> Predicate {
////    return Predicate { a in
////      return self.p(a) && pred.p(a)
////    }
////  }
////}
////
////struct Function <A, B> {
////  let f: A -> B
////}
////
////let isEvenPred = Predicate<Int> { $0 % 2 == 0 }
////let isPositive = Predicate<Int> { $0 > 0 }
////isEvenPred <> isPositive
////
////enum Ordering {
////  case LT
////  case EQ
////  case GT
////}
////
////func <> <A, S where S: Semigroup> (lhs: Function<A, S>, rhs: Function<A, S>) -> Function<A, S> {
////  return Function { a in
////    return lhs.f(a) <> rhs.f(a)
////  }
////}
//
//
//
//arc4random()
//
//
