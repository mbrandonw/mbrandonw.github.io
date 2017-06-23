struct Attribute {
  let key: String
  let value: String

  init(_ key: String, _ value: String) {
    self.key = key
    self.value = value
  }
}

struct AttributeKey<A> {
  let key: String
  init(_ key: String) { self.key = key }
}

struct Element {
  let name: String
  let attribs: [Attribute]
  let children: [Node]?

  init(_ name: String, _ attribs: [Attribute], _ children: [Node]?) {
    self.name = name
    self.attribs = attribs
    self.children = children
  }
}

enum Node {
  case element(Element)
  case text(String)
}

let verboseDocument: Node = .element(
  .init("header", [],  [
    .element(
      .init("h1", [.init("id", "welcome")],  [
        .text("Welcome!")
        ])
    ),
    .element(
      .init("p", [],  [
        .text("Welcome to you, who has come here. See "),
        .element(
          .init("a", [.init("href", "/more"), .init("remove-me", "true")], [
            .text("more")
            ])
        ),
        .text(".")
        ])
    )]
  )
)


// Removes all nodes that are an element with a `"remove-me": "true"` attribute
func removeCertainElements(_ node: Node) -> Node? {

  switch node {
  case let .element(element):
    guard !element.attribs
      .contains(where: { $0.key == "remove-me" && $0.value == "true" }) else {
        return nil
    }

    return .element(
      .init(
        element.name,
        element.attribs,
        element.children.map { $0.flatMap(removeCertainElements) }
      )
    )
  case .text:
    return node
  }

}

func node(_ name: String, _ attribs: [Attribute], _ children: [Node]?) -> Node {
  return .element(.init(name, attribs, children))
}

func node(_ name: String, _ children: [Node]?) -> Node {
  return node(name, [], children)
}

func h1(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("h1", attribs, children)
}

func h1(_ children: [Node]) -> Node {
  return h1([], children)
}

func p(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("p", attribs, children)
}

func p(_ children: [Node]) -> Node {
  return p([], children)
}


func a(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("a", attribs, children)
}

func a(_ children: [Node]) -> Node {
  return a([], children)
}

func header(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("header", attribs, children)
}

func header(_ children: [Node]) -> Node {
  return header([], children)
}

infix operator =>
func => <A> (key: AttributeKey<A>, value: A) -> Attribute {
  return .init(key.key, "\(value)")
}

let id = AttributeKey<String>("id")
let href = AttributeKey<String>("href")

extension Node: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    self = .text(value)
  }
}

let document: Node = header([
  h1([id => "welcome"], ["Welcome!"]),
  p([
    "Welcome to you, who has come here. See ",
    a([href => "/more"], ["more"]),
    "."
    ])
  ]
)
