---
layout: post
title:  "Composable HTML Views in Swift"
date:   2017-06-27
categories: swift html dsl
author: Brandon Williams
summary: "We define a view as a function from data to HTML nodes, and show how this results in three different types of compositions of views."


image: TODO
---

[Last time]({% post_url 2017-06-22-type-safe-html-in-swift %}) we defined a DSL in Swift for creating HTML documents. We accomplished this by creating some simple value types to describe the domain (nodes and attributes) and some helper functions for generating values. In the end it looked like this:

```swift
header([
  h1(["id" => "welcome"], ["Welcome!"]),
  p([
    "Welcome to you, who has come here. See ",
    a(["href" => "/more"], ["more"]),
    "."
  ])
])
```

to generate this HTML:

```html
<header>
  <h1 id="welcome">Welcome!</h1>
  <p>
    Welcome to you, who has come here. See <a href="/more">more</a>.
  </p>
</header>
```

Now we are going to tackle a problem that goes up one layer in the web-server request lifecycle: creating views. These are the things responsible for taking some data, say a list of articles, and creating the HTML to represent that data. It may sound easy, but there are a lot of difficult problems to solve with views. We want our views to be composable so that we can create small sub-views focused on rendering one piece of data and be able to reuse it. We also want our views to be flexible enough for future developments that are hard to see right now.

## The View Function

Like most topics discussed on this site, we are going to define view as a plain ole function. Also, like most topics in computer science, a monoid is involved. Luckily we’ve talked about these topics a lot on this site ([here](%{ post_url 2015-02-17-algebraic-structure-and-protocols %}) and [here](%{ post_url 2017-04-18-algbera-of-predicates-and-sorting-functions %})), and so there’s a lot of material to pull from. We will assume you are familiar with most of this content, and quickly recap the code that defines these objects:

```swift
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
```

Here we have defined two protocols that define what a semigroup and monoid are, and made `Array` conform because that is the monoid we are going to be most interested in for this article.

We are going to define a view, roughly, as a function from some data to an HTML node (which we defined [last time]({% post_url 2017-06-22-type-safe-html-in-swift %})). It turns out that it helps to actually map into an array of nodes, `[Node]`, since that aids composition by stacking views on top of each other. It also helps to generalize `[Node]` to be any monoid, not just `[Node]`. We will do this by making a struct that wraps a function:

```
struct View<D, N: Monoid> {
  let view: (D) -> N

  init(_ view: @escaping (D) -> N) {
    self.view = view
  }
}
```

All of our views will be mapping into `[Node]`, but that lil extra bit of generality will pay dividends later. With this simple type we can cook up a few views. Below I have roughly recreated some of the HTML on this very site:

```swift

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
```

Notice that the header view has a `()` data parameter because it doesn’t need any data to construct its nodes. The footer however does need some data, which we packaged up into a struct. Let’s also make a view that renders a list of articles:

```swift
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
```

Note that we first created a helper view `articleListItem` for rendering a single item, and then we used it to render the full list of articles. We have to `flatMap` onto `articleListItem.view` since it returns an array of nodes.

We can now bring this all together to create a homepage view that composes these views together. Since the


```swift
struct HomepageData {
  let articles: [Article]
  let footerData: FooterData
}

let homepage = View<HomepageData, [Node]> {
  [
    html(
      [
        body(
          [ header(siteHeader.view(())) ]
            + [ main(articlesList.view($0.articles)) ]
            + [ footer(siteFooter.view($0.footerData)) ]
        )
      ]
    )
  ]
}
```

It isn’t the prettiest code right now, but we’ll make it better soon. And it’s not _that_ bad right now! Some things to note:

* It’s just a pure function mapping an array of articles to some HTML nodes, which can be rendered to a string and then tested in a unit test.

* We got to leverage Swift features to aid in composition. For example, here we used array concatenation with `+` to stack our three views on top of each other. It doesn’t look great right now because we had to wrap each of our subviews in additional semantic tags.


We can take the homepage for a spin by create some articles and rendering the homepage. The `render(node:)` function we made [last time](%{ post_url 2017-06-23-rendering-html-dsl-in-swift %}) only works on nodes, not views. We can write a `render` for views like so:

```swift
func render<D>(view: View<D, [Node]>, with data: D) -> String {
  return view.view(data).map(render(node:)).reduce("", +)
}
```

And now creating some articles and rendering the

```swift
let articles = [
  Article(date: "Jan 6, 2015", title: "Proof in Functions"),
  Article(date: "Feb 17, 2015", title: "Algebraic Structure and Protocols"),
  Article(date: "Jun 22, 2017", title: "Type-Safe HTML in Swift"),
]

render(view: homepage, with: articles)
```



```html
<html>
   <body>
      <header>
         <h1>Few, but ripe...</h1>
         <menu>
           <a href="#">About</a>
           <a href="#">Hire Me</a><a href="#">Talks</a>
         </menu>
      </header>
      <main>
        <ul>
           <li>
             <span>Jan 6, 2015</span><a href="#">Proof in Functions</a>
           </li>
           <li>
             <span>Feb 17, 2015</span><a href="#">Algebraic Structure and Protocols</a>
           </li>
           <li>
             <span>Jun 22, 2017</span><a href="#">Type-Safe HTML in Swift</a>
           </li>
        </ul>
      </main>
      <footer>
         <ul>
            <li>Brandon Williams</li>
            <li>mbw234@gmail.com</li>
            <li>@mbrandonw</li>
         </ul>
         <p>Articles about math, functional programming and the Swift programming language.</p>
      </footer>
   </body>
</html>
```

## Composition #1 – Functor

## Composition #2 – Monoid

## Composition #3 – Co-Functor


## Bonus

Using `get` helper we can use keypaths...



.

## References

* http://www.fewbutripe.com/swift/html/dsl/2017/06/22/type-safe-html-in-swift.html
* http://www.fewbutripe.com/swift/math/algebra/monoid/2017/04/18/algbera-of-predicates-and-sorting-functions.html
* http://www.fewbutripe.com/swift/math/algebra/2015/02/17/algebraic-structure-and-protocols.html
