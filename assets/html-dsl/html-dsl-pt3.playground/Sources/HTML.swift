precedencegroup Semigroup { associativity: left }
infix operator <>: Semigroup
public protocol Semigroup {
  static func <>(lhs: Self, rhs: Self) -> Self
}
public protocol Monoid: Semigroup {
  static var e: Self { get }
}
extension Array: Monoid {
  public static var e: Array<Element> { return  [] }
  public static func <>(lhs: Array, rhs: Array) -> Array {
    return lhs + rhs
  }
}

public struct Attribute {
  public let key: String
  public let value: String

  public init(_ key: String, _ value: String) {
    self.key = key
    self.value = value
  }
}

public struct AttributeKey<A> {
  public let key: String
  init(_ key: String) { self.key = key }
}

public struct Element {
  public let name: String
  public let attribs: [Attribute]
  public let children: [Node]?

  public init(_ name: String, _ attribs: [Attribute], _ children: [Node]?) {
    self.name = name
    self.attribs = attribs
    self.children = children
  }
}

public enum Node {
  case element(Element)
  case text(String)
}

public func node(_ name: String, _ attribs: [Attribute], _ children: [Node]?) -> Node {
  return .element(.init(name, attribs, children))
}

public func node(_ name: String, _ children: [Node]?) -> Node {
  return node(name, [], children)
}

public func h1(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("h1", attribs, children)
}

public func h1(_ children: [Node]) -> Node {
  return h1([], children)
}

public func p(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("p", attribs, children)
}

public func p(_ children: [Node]) -> Node {
  return p([], children)
}


public func a(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("a", attribs, children)
}

public func a(_ children: [Node]) -> Node {
  return a([], children)
}

public func header(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("header", attribs, children)
}

public func header(_ children: [Node]) -> Node {
  return header([], children)
}

public func ul(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("ul", attribs, children)
}

public func ul(_ children: [Node]) -> Node {
  return ul([], children)
}

public func li(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("li", attribs, children)
}

public func li(_ children: [Node]) -> Node {
  return li([], children)
}

public func footer(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("footer", attribs, children)
}

public func footer(_ children: [Node]) -> Node {
  return footer([], children)
}

public func span(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("span", attribs, children)
}

public func span(_ children: [Node]) -> Node {
  return span([], children)
}

public func html(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("html", attribs, children)
}

public func html(_ children: [Node]) -> Node {
  return html([], children)
}

public func body(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("body", attribs, children)
}

public func body(_ children: [Node]) -> Node {
  return body([], children)
}

public func menu(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("menu", attribs, children)
}

public func menu(_ children: [Node]) -> Node {
  return menu([], children)
}

public func main(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("main", attribs, children)
}

public func main(_ children: [Node]) -> Node {
  return main([], children)
}

infix operator =>
public func => <A> (key: AttributeKey<A>, value: A) -> Attribute {
  return .init(key.key, "\(value)")
}

public let id = AttributeKey<String>("id")
public let href = AttributeKey<String>("href")

extension Node: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .text(value)
  }
}

public func render(node: Node) -> String {
  switch node {
  case let .element(e):
    return render(element: e)
  case let .text(t):
    return t
  }
}

public func render(element: Element) -> String {
  let openTag = "<\(element.name)"
  let openTagWithAttrs = openTag
    + (element.attribs.isEmpty ? "" : " ")
    + render(attributes: element.attribs)
    + (element.children == nil ? ">" : "")
  let children = (element.children ?? []).map(render(node:)).joined()
  let closeTag = element.children == nil ? "/>" : "</\(element.name)>"

  return openTagWithAttrs + children + closeTag
}

public func render(attributes: [Attribute]) -> String {
  return attributes
    .map { attr in "\(attr.key)=\"\(attr.value)\"" }
    .joined(separator: " ")
}

