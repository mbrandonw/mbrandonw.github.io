struct Lens<S, T, A, B> {
  let get: (S) -> A
  let set: (B, S) -> T
}


2

infix operator <<<

func <<< <S, T, A, B, C, D> (lhs: Lens<S, T, A, B>, rhs: Lens<A, B, C, D>) -> Lens<S, T, C, D> {

  return Lens<S, T, C, D>(
    get: { rhs.get(lhs.get($0)) },
    set: { d, s in
      let a = lhs.get(s)
      let b = rhs.set(d, a)
      return lhs.set(b, s)
  })
}

func lens<S, A>(_ keyPath: WritableKeyPath<S, A>) -> Lens<S, S, A, A> {
  return Lens<S, S, A, A>(
    get: { $0[keyPath: keyPath] },
    set: { a, s in
      var result = s
      result[keyPath: keyPath] = a
      return result
  })
}

func first<S, T, A>(_ f: @escaping (S) -> T) -> Lens<(S, A), (T, A), T, S> {
  return Lens<(S, A), (T, A), T, S>(
    get: { f($0.0) },
    set: { s, sa in (f(s), sa.1) }
  )
}

1

