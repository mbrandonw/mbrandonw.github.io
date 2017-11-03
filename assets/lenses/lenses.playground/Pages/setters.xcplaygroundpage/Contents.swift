/*:
 # Composable Setters

 Stephen Celis (@stephencelis)
 */
let count = 0

func incr(_ x: Int) -> Int {
  return x + 1
}

let newCount = incr(count)

let score = (42, "blobbo")

let newScore = (incr(score.0), score.1)

func incrFirst(_ pair: (Int, String)) -> (Int, String) {
  return (incr(pair.0), pair.1)
}

incrFirst(score)

func first<A, B, C>(_ f: @escaping (A) -> C) -> ((A, B)) -> (C, B) {
  return { pair in
    return (f(pair.0), pair.1)
  }
}

first(incr)(score)

first(incr)(first(incr)(score))

precedencegroup Apply {
  associativity: left
}
infix operator |>: Apply

func |> <A, B>(x: (A), f: (A) -> B) -> B {
  return f(x)
}

score |> first(incr)

score
  |> first(incr)
  |> first(String.init)

func second<A, B, C>(_ f: @escaping (B) -> C) -> ((A, B)) -> (A, C) {
  return { pair in
    return (pair.0, f(pair.1))
  }
}

score
  |> first(incr)
  |> first(String.init)
  |> second { $0.uppercased() }

((1, 2), 3)
  |> first { $0 |> second { _ in 500 } }

precedencegroup Compose {
  associativity: right
  higherThan: Apply
}
infix operator <<<: Compose

func <<< <A, B, C>(g: @escaping (B) -> C, f: @escaping (A) -> B) -> (A) -> C {
  return { x in
    g(f(x))
  }
}

((1, 2), 3)
  |> (first <<< second) { _ in 500 }
  |> (first <<< first) { _ in "Dunno" }

((1, 2), 3)
  |> (first <<< second) { _ in 500 }

let tmp1: (@escaping ((Int, Int)) -> (Int, Int)) -> (((Int, Int), Int)) -> ((Int, Int), Int) = first
let tmp2: (@escaping (Int) -> Int) -> ((Int, Int)) -> (Int, Int) = second

let tmp3 = tmp1 <<< tmp2

struct Food {
  var name: String
}

struct User {
  var name: String
  private(set) var favoriteFood: Food
}

let user = User(name: "Stephen", favoriteFood: Food(name: "Burgers"))

//func userName(_ f: (String) -> String) -> (User) -> User

func prop<Root, Value>(_ keyPath: WritableKeyPath<Root, Value>)
  -> (@escaping (Value) -> Value)
  -> (Root)
  -> Root {
    return { update in
      { root in
        var copy = root
        copy[keyPath: keyPath] = update(copy[keyPath: keyPath])
        return copy
      }
    }
}

//dump(
(50, user)
  |> (second <<< prop(\.name)) { $0.uppercased() }
  |> (second <<< prop(\.favoriteFood.name)) { _ in "Salad" }
  |> first(incr)
//)

enum Result<A> {
  case value(A)
  case error(String)
}

func value<A, B>(_ f: @escaping (A) -> B) -> (Result<A>) -> Result<B> {
  return { result in
    switch result {
    case let .value(value):
      return .value(f(value))
    case let .error(error):
      return .error(error)
    }
  }
}

Result.value(score)
  |> (value <<< first)(incr)

func error<A>(_ f: @escaping (String) -> String) -> (Result<A>) -> Result<A> {
  return { result in
    switch result {
    case let .value(value):
      return .value(value)
    case let .error(error):
      return .error(f(error))
    }
  }
}

(1, Result<String>.error("Hello!"))
  |> first(incr)
  |> (second <<< error) { $0.uppercased() }

func map<A, B>(_ f: @escaping (A) -> B) -> ([A]) -> [B] {
  return { $0.map(f) }
}

[1, 2, 3, 4, 5]
  |> map(incr)

func map<A, B>(_ f: @escaping (A) -> B) -> (A?) -> B? {
  return { $0.map(f) }
}

[1, 2, nil, 3, 4, 5]
  |> (map <<< map)(incr)

dump(
  Result.value((42, [User?.some(user)]))
    |> (value <<< first)(incr)
    |> (value <<< second <<< map <<< map <<< prop(\.favoriteFood.name)) { $0.uppercased() }
)

// Thanks!
