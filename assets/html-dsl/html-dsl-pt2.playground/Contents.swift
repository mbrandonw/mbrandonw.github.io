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

let verboseDoc: Node = .element(
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

let document = header([
  h1([id => "welcome"], ["Welcome!"]),
  p([
    "Welcome to you, who has come here. See ",
    a([href => "/more"], ["more"]),
    "."
    ])
  ]
)

func render(node: Node) -> String {
  switch node {
  case let .element(e):
    return render(element: e)
  case let .text(t):
    return t
  }
}

func render(element: Element) -> String {
  let openTag = "<\(element.name)"
  let openTagWithAttrs = openTag
    + (element.attribs.isEmpty ? "" : " ")
    + render(attributes: element.attribs)
    + (element.children == nil ? ">" : "")
  let children = (element.children ?? []).map(render(node:)).joined()
  let closeTag = element.children == nil ? "/>" : "</\(element.name)>"

  return openTagWithAttrs + children + closeTag
}

func render(attributes: [Attribute]) -> String {
  return attributes
    .map { attr in "\(attr.key)=\"\(attr.value)\"" }
    .joined(separator: " ")
}

render(attributes: [id => "welcome"])

render(element: Element("h1", [id => "Welcome"], ["Welcome!"]))

render(node: document)



