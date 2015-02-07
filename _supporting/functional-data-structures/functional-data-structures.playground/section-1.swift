import Foundation

enum List <A> {
  case Nil
  case Cons(
    @autoclosure () -> A,
    @autoclosure () -> List<A>
  )
}

func map <A, B> (f: A -> B) -> List<A> -> List<B> {
  return { xs in
    switch xs {
    case .Nil:
      return .Nil
    case let .Cons(x, xs):
      return .Cons(
        f(x()),
        map(f)(xs())
      )
    }
  }
}

func cons <A> (x: A, xs: List<A>) -> List<A> {
  return .Cons(x, xs)
}

func head <A> (xs: List<A>) -> A {
  switch xs {
  case .Nil:
    fatalError("Can't take head of empty list")
  case let .Cons(x, _):
    return x()
  }
}

func tail <A> (xs: List<A>) -> List<A> {
  switch xs {
  case .Nil:
    return .Nil
  case let .Cons(_, xs):
    return xs()
  }
}

func append <A> (xs: List<A>, ys: List<A>) -> List<A> {
  switch xs {
  case .Nil:
    return ys
  case let .Cons(x, xs):
    return .Cons(x(), append(xs(), ys))
  }
}

func count <A> (xs: List<A>) -> Int {
  switch xs {
  case .Nil:
    return 0
  case let .Cons(_, xs):
    return 1 + count(xs())
  }
}

func concat <A> (xss: List<List<A>>) -> List<A> {
  switch xss {
  case .Nil:
    return .Nil
  case let .Cons(xs, xss):
    return append(xs(), concat(xss()))
  }
}

func concatMap <A, B> (f: A -> List<B>) -> List<A> -> List<B> {
  return { xs in
    return concat(map(f)(xs))
  }
}

//func ap <A, B> (fs: List<A -> B>) -> List<A> -> List<B> {
//  switch fs {
//  case .Nil:
//    return { _ in .Nil }
//  case let .Cons(f, fs):
//    return { xs in
//      switch xs {
//      case .Nil:
//        return .Nil
//      case let .Cons(x, xs):
//        return
//      }
//    }
//  }
//}

let xs: List<Int> = List.Cons(1, List.Cons(2, List.Cons(3, List.Cons(4, List.Cons(5, List.Nil)))))

count(xs)
count(append(xs, xs))

map { $0*$0 } (xs)


enum BinaryTree <A> {
  case Empty
  case Node(
    @autoclosure () -> BinaryTree<A>,
    @autoclosure () -> A,
    @autoclosure () -> BinaryTree<A>
  )
}

struct LeafyTree <A> {
  let node: A
  let leaves: List<LeafyTree<A>>
}

func map <A, B> (f: A -> B) -> LeafyTree<A> -> LeafyTree<B> {
  return { tree in
    return LeafyTree(
      node: f(tree.node),
      leaves: map(map(f))(tree.leaves)
    )
  }
}



typealias Nat = List<()>
func succ (n: Nat) -> Nat {
  return .Cons((), n)
}
let zero: Nat = .Nil
let one = succ(zero)
let two = succ(one)
let three = succ(succ(succ(zero)))
count(zero)
count(one)
count(two)
count(three)













