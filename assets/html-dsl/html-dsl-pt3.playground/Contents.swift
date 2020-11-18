struct View<D, N: Monoid> {
  let view: (D) -> N

  init(_ f: @escaping (D) -> N) {
    self.view = f
  }
}

let headerContent = View<(), [Node]> { _ in
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

let footerContent = View<FooterData, [Node]> {
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
          [ header(headerContent.view(())) ]
            + [ main(articlesList.view($0.articles)) ]
            + [ footer(footerContent.view($0.footerData)) ]
        )
      ]
    )
  ]
}

func render<D>(view: View<D, [Node]>, with data: D) -> String {
  return view.view(data).map(render(node:)).reduce("", +)
}

let data = HomepageData(
  articles: [
    Article(date: "Jun 22, 2017", title: "Type-Safe HTML in Swift"),
    Article(date: "Feb 17, 2015", title: "Algebraic Structure and Protocols"),
    Article(date: "Jan 6, 2015", title: "Proof in Functions"),
    ],
  footerData: .init(
    authorName: "Brandon Williams",
    email: "mbrandonw@hey.com",
    twitter: "mbrandonw"
  )
)

print(
  render(view: homepage, with: data)
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

let siteHeader = headerContent.map(header >>> pure)
let mainArticles = articlesList.map(main >>> pure)
let siteFooter = footerContent.map(footer >>> pure)

let combined: View<HomepageData, [Node]> =
  siteHeader.contramap { _ in () }
    <> mainArticles.contramap { $0.articles }
    <> siteFooter.contramap { $0.footerData }

let homepage_v2 = combined
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

struct SiteLayoutData<D> {
  let contentData: D
  let footerData: FooterData
}

func siteLayout<D>(
  content: View<D, [Node]>
  )
  -> View<SiteLayoutData<D>, [Node]> {
  return (
    headerContent.map(header >>> pure).contramap { _ in () }
      <> content.map(main >>> pure).contramap { $0.contentData }
      <> footerContent.map(footer >>> pure).contramap { $0.footerData }
    )
    .map(body >>> pure >>> html >>> pure)
}

let siteData = SiteLayoutData(
  contentData: [
    Article(date: "Jun 22, 2017", title: "Type-Safe HTML in Swift"),
    Article(date: "Feb 17, 2015", title: "Algebraic Structure and Protocols"),
    Article(date: "Jan 6, 2015", title: "Proof in Functions"),
    ],
  footerData: .init(
    authorName: "Brandon Williams",
    email: "mbrandonw@hey.com",
    twitter: "mbrandonw"
  )
)

render(view: siteLayout(content: articlesList), with: siteData)



