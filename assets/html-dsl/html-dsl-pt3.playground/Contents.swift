
precedencegroup Semigroup { associativity: left }
infix operator <>: Semigroup
protocol Semigroup {
  static func <>(lhs: Self, rhs: Self) -> Self
}
protocol Monoid: Semigroup {
  static var e: Self { get }
}
extension Array: Monoid {
  static var e: Array<Element> { return  [] }
  static func <>(lhs: Array, rhs: Array) -> Array {
    return lhs + rhs
  }
}



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

func ul(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("ul", attribs, children)
}

func ul(_ children: [Node]) -> Node {
  return ul([], children)
}

func li(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("li", attribs, children)
}

func li(_ children: [Node]) -> Node {
  return li([], children)
}

func footer(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("footer", attribs, children)
}

func footer(_ children: [Node]) -> Node {
  return footer([], children)
}

func span(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("span", attribs, children)
}

func span(_ children: [Node]) -> Node {
  return span([], children)
}

func html(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("html", attribs, children)
}

func html(_ children: [Node]) -> Node {
  return html([], children)
}

func body(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("body", attribs, children)
}

func body(_ children: [Node]) -> Node {
  return body([], children)
}

func menu(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("menu", attribs, children)
}

func menu(_ children: [Node]) -> Node {
  return menu([], children)
}

func main(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("main", attribs, children)
}

func main(_ children: [Node]) -> Node {
  return main([], children)
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
    + ">"
  let children = (element.children ?? []).map(render(node:)).joined()
  let closeTag = element.children == nil ? "/>" : "</\(element.name)>"

  return openTagWithAttrs + children + closeTag
}

func render(attributes: [Attribute]) -> String {
  return attributes
    .map { attr in "\(attr.key)=\"\(attr.value)\"" }
    .joined(separator: " ")
}

struct View<D, N: Monoid> {
  let view: (D) -> N

  init(_ f: @escaping (D) -> N) {
    self.view = f
  }
}

let siteHeader = View<(), [Node]> { _ in
  [
    h1(["Few, but ripe..."]),
    menu([
      a([href => "#"], ["About"]),
      a([href => "#"], ["Hire Me"]),
      a([href => "#"], ["Talks"])
      ])
  ]
}

struct FooterData {
  let authorName: String
  let email: String
  let twitter: String
}
let siteFooter = View<FooterData, [Node]> {
  [
    ul([
      li([.text($0.authorName)]),
      li([.text($0.email)]),
      li([.text("@\($0.twitter)")]),
      ]),
    p(["Articles about math, functional programming and the Swift programming language."])
  ]
}

struct Article {
  let date: String
  let title: String
}

let articleListItem = View<Article, [Node]> { article in
  [
    li([
      span([.text(article.date)]),
      a([href => "#"], [.text(article.title)])
      ])
  ]
}

let articlesList = View<[Article], [Node]> { articles in
  [
    ul(
      articles.flatMap(articleListItem.view)
    )
  ]
}

struct HomepageData {
  let articles: [Article]
  let footerData: FooterData
}
let homepage = View<HomepageData, [Node]> {
  [
    html(
      [
        body(
          siteHeader.view(())
            + [ main(articlesList.view($0.articles)) ]
            + siteFooter.view($0.footerData)
        )
      ]
    )
  ]
}

func render<D>(view: View<D, [Node]>, with data: D) -> String {
  return view.view(data).map(render(node:)).reduce("", +)
}

let articles = [
  Article(date: "Jan 6, 2015", title: "Proof in Functions"),
  Article(date: "Feb 17, 2015", title: "Algebraic Structure and Protocols"),
  Article(date: "Jun 22, 2017", title: "Type-Safe HTML in Swift"),
]

let homepageData = HomepageData(
  articles: articles,
  footerData: .init(
    authorName: "Brandon Williams",
    email: "mbw234@gmail.com",
    twitter: "mbrandonw"
  )
)

print(
  render(view: homepage, with: homepageData)
)

extension View: Monoid {
  static var e: View {
    return View { _ in N.e }
  }

  static func <>(lhs: View, rhs: View) -> View {
    return View { lhs.view($0) <> rhs.view($0) }
  }
}

extension View {
  func map<S>(_ f: @escaping (N) -> S) -> View<D, S> {
    return .init { d in f(self.view(d)) }
  }

  func contramap<B>(_ f: @escaping (B) -> D) -> View<B, N> {
    return .init { b in self.view(f(b)) }
  }
}

func pure<A>(_ a: A) -> [A] {
  return [a]
}

precedencegroup Composition {
  associativity: left
}
infix operator >>>: Composition
func >>> <A, B, C>(_ f: @escaping (A) -> B, g: @escaping (B) -> C) -> (A) -> C {
  return { g(f($0)) }
}

let homepageView: View<HomepageData, [Node]> =
  siteHeader.map(header >>> pure).contramap { _ in () }
    <> articlesList.contramap { $0.articles }
    <> siteFooter.map(footer >>> pure).contramap { $0.footerData }

let homepage_v2 = homepageView
  .map(main >>> pure)
  .map { nodes in
    [
      html(
        [
          body(nodes)
        ]
      )
    ]
}

func layout(_ nodes: [Node]) -> [Node] {
  return [
    html(
      [
        body(nodes)
      ]
    )
  ]
}

let homepageV3 = homepageView
  .map(main >>> pure)
  .map(layout)

//func layout<D>(main: View<D, [Node]>) -> View<D, [Node]> {
//  return siteHeader.map(header >>> pure).contramap { _ in () }
//    <> main.map { $0.articles }
//  <> siteFooter.map(footer >>> pure).contramap { $0.footerData }
//}

//let homepage_v3 = main.map(body >>> pure >>> html >>> pure)
//
//render(view: main.map(main >>> pure), with: [])










1


