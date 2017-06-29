---
layout: post
title:  "Composable HTML Views in Swift"
date:   2017-06-29
categories: swift html dsl
author: Brandon Williams
summary: "We define a view as a function from data to HTML nodes, and show how this results in three different types of compositions of views."
image: /assets/html-dsl/pt2-preview-img.jpg
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

You can [download a playground](/assets/html-dsl/html-dsl-pt3.playground.zip) of the code snippets in this article so that you can follow along at home.

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
  static var e: Array { return  [] }
  static func <>(lhs: Array, rhs: Array) -> Array {
    return lhs + rhs
  }
}
```

Here we have defined two protocols that define what a semigroup and monoid are, and made `Array` conform because that is the monoid we are going to be most interested in for this article.

We are going to define a view, roughly, as a function from some data to an HTML node (which we defined [last time]({% post_url 2017-06-22-type-safe-html-in-swift %})). It turns out that it helps to actually map into an array of nodes, `[Node]`, since that aids composition by stacking views on top of each other. It also helps to generalize `[Node]` to be any monoid, not just `[Node]`. We will do this by making a struct that wraps a function:

```swift
struct View<D, N: Monoid> {
  let view: (D) -> N

  init(_ view: @escaping (D) -> N) {
    self.view = view
  }
}
```

All of our views will be mapping into `[Node]`, but that lil extra bit of generality will pay dividends later. With this simple type we can cook up a few views. Below I have roughly recreated some of the HTML on this very site:

```swift
let headerContent = View<(), [Node]> { _ in
  [
    h1(["Few, but ripe..."]),
    menu([
      a([href => "/about"], ["About"]),
      a([href => "/hire-me"], ["Hire Me"]),
      a([href => "/talks"], ["Talks"])
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
```

Notice that the header view has a `()` data parameter because it doesn’t need any data to construct its nodes. The footer however does need some data, which we packaged up into a struct. Let’s also make a view that renders a list of articles:

```swift
struct Article {
  let date: String
  let title: String
  // more fields, e.g. author, body, categories, ...
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

We can now bring this all together to create a homepage view that composes these views together. We will create a `HomepageData` struct to bundle up all of the data the page needs (for both the articles and footer).

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
          [ header(headerContent.view(())) ]
            + [ main(articlesList.view($0.articles)) ]
            + [ footer(footerContent.view($0.footerData)) ]
        )
      ]
    )
  ]
}
```

It isn’t the prettiest code, but we’ll make it better soon. And it’s not _that_ bad right now! Some things to note:

* It’s just a pure function mapping an array of articles to some HTML nodes, which can be rendered to a string and then tested in a unit test.

* We got to leverage Swift features to aid in composition. For example, here we used array concatenation with `+` to stack our three views on top of each other. It doesn’t look great right now because we had to wrap each of our subviews in semantic tags.

* We were able to use subviews to clean up this view and make it clear that we are just stacking a header on top of main content on top of a footer.


We can take the homepage for a spin by creating some homepage data and rendering. The `render(node:)` function we made [last time]({% post_url 2017-06-23-rendering-html-dsl-in-swift %}) only works on nodes, not views. We can write a `render` for views like so:

```swift
func render<D>(view: View<D, [Node]>, with data: D) -> String {
  return view.view(data)
    .map(render(node:))
    .reduce("", +)
}
```

And now creating some data and rendering looks like this:

```swift
let data = HomepageData(
  articles: [
    Article(date: "Jun 22, 2017", title: "Type-Safe HTML in Swift"),
    Article(date: "Feb 17, 2015", title: "Algebraic Structure and Protocols"),
    Article(date: "Jan 6, 2015", title: "Proof in Functions"),
    ],
  footerData: .init(
    authorName: "Brandon Williams",
    email: "mbw234@gmail.com",
    twitter: "mbrandonw"
  )
)

render(view: homepage, with: data)
```

which will output the following HTML.

```html
<html>
  <body>
    <header>
      <h1>Few, but ripe...</h1>
      <menu>
        <a href="/about">About</a>
        <a href="/hire-me">Hire Me</a>
        <a href="/talks">Talks</a>
      </menu>
    </header>
    <main>
      <ul>
        <li><span>Jun 22, 2017</span><a href="#">Type-Safe HTML in Swift</a></li>
        <li><span>Feb 17, 2015</span><a href="#">Algebraic Structure and Protocols</a></li>
        <li><span>Jan 6, 2015</span><a href="#">Proof in Functions</a></li>
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

This is complicated enough view that was simple to compose from smaller pieces! We could stop here and we would have a nice model for creating views, but there is so much more we can do. We need to explore the ways that views can be composed to unlock the next benefits of views…

## View Composition

Since `View` is a function, we would expect that there are some nice ways to compose them. And indeed, there are at least 3 ways!

### View Composition #1 – `map`

The first type of composition we will discuss is called `map`. It is closely related to `Array`’s `map`, so let us recall that definition. `Array<A>` has a method called `map` that takes a function `f: (A) -> B` and returns an `Array<B>`. You can think of `f: (A) -> B` as transforming `Array<A>`s to `Array<B>`s by just applying `f` to each element of the array.

`View<D, N>` also has such a function, but it transforms the `N` part of the view. Let us first write the signature of how such a function would look:

```swift
extension View<D, N> {
  func map<S>(_ f: @escaping (N) -> S) -> View<D, S> {
    ???
  }
}
```

We know that this method returns a `View<D, S>`, which is really just a function `(D) -> S`, so we can fill in a bit of this function body:

```swift
extension View<D, N> {
  func map<S>(_ f: @escaping (N) -> S) -> View<D, S> {
    return View<D, S> { d in
      ???
    }
  }
}
```

Now we have at our disposal `d: D`, `f: (N) -> S`, and `self.view: (D) -> N`. Seems like we can just compose these two functions and feed `d` into em:

```swift
extension View<D, N> {
  func map<S>(_ f: @escaping (N) -> S) -> View<D, S> {
    return View<D, S> { d in
      f(self.view(d))
    }
  }
}
```

This function allows us to perform a transformation on a view’s nodes without knowing anything about the data that is involved. We already did something like this (3 times) when we wrapped our subviews in semantic tags, for example:

```swift
[ footer(footerContent.view($0.footerData)) ]
```

If we wanted to store this in another view, it would be a bit cumbersome in the naive way:

```swift
let siteFooter = View { [ footer(footerContent.view($0)) ] }
```

Our function `map` allows us to do this quite succinctly:

```swift
let siteFooter = footerContent.map { [footer($0)] }
```

Even better, if we take a few nods from [Haskell](https://www.haskell.org), [PureScript](http://www.purescript.org) and other purely functional languages, we could rewrite this as:

```swift
precedencegroup ForwardComposition { associativity: left }
infix operator >>>: ForwardComposition

// Left-to-right function composition, i.e. (f >>> g) = g(f(x))
func >>> <A, B, C>(f: @escaping (A) -> B,
                   g: @escaping (B) -> C) -> (A) -> C {
  return { g(f($0)) }
}

// Wrap a single value in an array.
func pure<A>(_ a: A) -> [A] { return [a] }

let siteFooter = footerContent.map(footer >>> pure)
```

Here we have defined an operator `>>>` for composing functions, and a function `pure` for embedding any value into an array of one element. Then we defined `siteFooter` as mapping over `footerContent`’s nodes, wrapping those nodes in a `footer` tag, and then wrapping that in an array. We can use this for all 3 of our subviews:

```swift
let siteHeader = headerContent.map(header >>> pure)
let mainArticles = articlesList.map(main >>> pure)
let siteFooter = footerContent.map(footer >>> pure)
```

That is starting to look nice! We can now have our subviews concentrate _only_ on the content they provide, and not worry about what their enclosing tag should be. For example, `articleListItem` rendered an `li` tag with the article date and title in it. We could generalize view by omitting the `li` tag so that it could be reused in places that are not necessarily a list:

```swift
let articleCallout = View<Article, [Node]> { article in
  [
    span([.text(article.date)]),
    a([href => "#"], [.text(article.title)])
  ]
}
```

And then `articlesList` can be responsible for wrapping that subview in a `li` tag:

```swift
let articlesList = View<[Article], [Node]> { articles in
  [
    ul(
      articles.flatMap(articleCallout.view >>> li >>> pure)
    )
  ]
}
```

This allows us to maximize reusability of our subviews. We will also soon be able to use our other two forms of composition to even simplify that!

### View Composition #2 – Monoid

The next form of composition we will encounter is from our requirement that `N` be a monoid in the definition of `View<D, N>`. Recall from a [previous article](%{ post_url 2017-04-18-algbera-of-predicates-and-sorting-functions %}) we showed that the type of functions from a type into a monoid also forms a monoid. This means that `View` is a monoid, and so let’s implement its conformance:

```swift
extension View: Monoid {
  static var e: View {
    return View { _ in N.e }
  }

  static func <>(lhs: View, rhs: View) -> View {
    return View { lhs.view($0) <> rhs.view($0) }
  }
}
```

This function allows us to combine two views by stacking them, as long as the type of data they each take matches up. For example, say we were building a view for a particular article on this site. It consists of a header (title, date, author), body (paragraphs, code snippets), and footer (author contact info). All of those views can be rendered from an `Article` value:

```swift
let articleHeader = View<Article, [Node]> { ... }
let articleBody = View<Article, [Node]> { ... }
let articleFooter = View<Article, [Node]> { ... }
```

These views can be composed together with `<>` to obtain a new view that just stacks the views:

```swift
let fullArticle: View<Article, [Node]> =
  articleHeader
    <> articleBody
    <> articleFooter
```

And then later we could `map` on this view in order to wrap it in an `article` tag:

```swift
fullArticle.map(article >>> pure)
```

Views are now looking super composable! However, `<>` has one disadvantage in that all of the views you compose together need to take the same kind of data. So for example, we cannot `<>` our `siteHeader`, `mainContent` and `siteFooter` together since they each take different types of data:

```swift
siteHeader
  <> mainContent
  <> siteFooter
// error: binary operator '<>' cannot be applied to operands of
// type 'View<(), [Node]>' and 'View<[Article], [Node]>'
```

However, our last form of composition fixes this for us!

### View Composition #3 – `contramap`

The final form of composition we will discuss is kind of like the “dual” version of `map`. It’s called `contramap` and it has a very subtle difference from `map`. Whereas `map` performed a transformation on the nodes of the view `N` without touching the data `D`, `contramap` performs a transformation on the data of the view without touching the nodes.

To build intuition for `contramap` we will first try to naively define it like we did `map` and see what goes wrong. We might approach `contramap` as a method that takes a function `f: (D) -> B` and produces a new view `View<B, N>`:

```swift
extension View<D, N> {
  func contramap<B>(_ f: @escaping (D) -> B) -> View<B, N> {
    return View<B, N> { b in
      ???
    }
  }
}
```

What can we return in the `???` block? We have a `b: B`, `f: (D) -> B` and `self.view: (D) -> N`. None of these pieces fit together. We can’t plug `b` into anything, and we can’t compose `f` and `self.view`. This function is impossible to implement.

Let’s consider why. The method as it is defined now is saying that if we have a function `(D) -> B` we can transform views of the form `View<D, N>` to the form `View<B, N>`. If `D` were `Article`, and `f: (Article) -> String` were the function that plucked out the title, it would mean we could convert a view of an article to a view of a string, all without making any changes to the nodes. That can’t possibly be right, for the view of the article could have used any fields of `Article`, not just the title.

Turns out we are thinking of this in the reverse direction! `contramap` actually flips around the transformation of the views, so `f: (D) -> B` can transform views of the form `View<B, N>` to the form `View<D, N>`. If `f: (Article) -> String` plucks out the title of the article, then the induced transformation `View<String, N> -> View<Article, N>` allows us to lift a view of a simple string up to a view of a whole article by just plucking the title out of the article and rendering!

We can now write the correct definition of `contramap`:

```swift
extension View<D, N> {
  func contramap<B>(_ f: @escaping (B) -> D) -> View<B, N> {
    return .init { b in self.view(f(b)) }
  }
}
```

This function is useful for turning a view on a “smaller” piece of a data to a view on a “larger” piece of data. You just `contramap` on the view of the smaller data to pluck out the piece you need from the bigger data. For example, we can instantly make our site header, articles and footer all understand the same data by `contramap`ing on them to pluck the parts they need from `HomepageData`:

```swift
let combined: View<HomepageData, [Node]> =
  siteHeader.contramap { _ in () }
    <> mainArticles.contramap { $0.articles }
    <> siteFooter.contramap { $0.footerData }
```

This allows views to take only the data they need to do their job, while remaining open to being plugged into views that take more data.


<!--
like most things in math, one concept is easy to define and understand (`map`), and then we can define the dual version (`contramap`) easily, yet somehow it is hard to understand. and often it's the more useful of the two concepts!
-->

## Bringing it all together

We can now use all of our new tools of composition to refactor our view of articles into a short and sweet code snippet. Let’s first remind ourselves of all the atomic units of views we have at our disposal:

```swift
let headerContent = View<(), [Node]> { _ in
  [
    h1(["Few, but ripe..."]),
    menu([
      a([href => "/about"], ["About"]),
      a([href => "/hire-me"], ["Hire Me"]),
      a([href => "/talks"], ["Talks"])
      ])
  ]
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

let articleCallout = View<Article, [Node]> { article in
  [
    span([.text(article.date)]),
    a([href => "#"], [.text(article.title)])
  ]
}

let articlesList = View<[Article], [Node]> { articles in
  [
    ul(
      articles.flatMap(articleCallout.view >>> li >>> pure)
    )
  ]
}
```

From these pieces we want to create a `View<HomepageData, [Node]>` that assembles all the pieces and wraps it all in `html` and `body` tags. One approach would be to just take what we’ve done so far to combine the header/content/footer into a view, and then `map` on it for the enclosing tags. Remember that we also have to `map` on each of our subviews to properly enclose them in their semantic tags:

```swift
let homepage: View<HomepageData, [Node]> =
  (
    headerContent.map(header >>> pure).contramap { _ in () }
      <> articlesList.map(main >>> pure).contramap { $0.articles }
      <> footerContent.map(footer >>> pure).contramap { $0.footerData }
  )
  .map { nodes in
    [
      html(
        [
          body(nodes)
        ]
      )
    ]
  }
```

This looks quite nice! However, we probably want to render the header and footer on most pages, and be able to just plug in the middle content on a page-by-page basis. We may want to also render additional stuff into the pages, like stylesheets, javascripts and meta tags. Rails provides something called [“layouts”](http://guides.rubyonrails.org/layouts_and_rendering.html) to solve this, but we can just use a plain ole function!

```swift
// A struct to hold all the data that the layout needs, in addition
// to whatever the main content needs
struct SiteLayoutData<D> {
  let contentData: D
  let footerData: FooterData
}

func siteLayout<D>(content: View<D, [Node]>) -> View<SiteLayoutData<D>, [Node]> {
  return (
    headerContent.map(header >>> pure).contramap { _ in () }
      <> content.map(main >>> pure).contramap { $0.contentData }
      <> footerContent.map(footer >>> pure).contramap { $0.footerData }
    )
    .map(body >>> pure >>> html >>> pure)
}
```

We got a little fancy in that last line by adding the `body` and `html` tags all in one mapping, but it still reads quite well! And now this can be used to render our list of articles very easily!

```swift
let data = SiteLayoutData(
  contentData: [
    Article(date: "Jun 22, 2017", title: "Type-Safe HTML in Swift"),
    Article(date: "Feb 17, 2015", title: "Algebraic Structure and Protocols"),
    Article(date: "Jan 6, 2015", title: "Proof in Functions"),
  ],
  footerData: .init(
    authorName: "Brandon Williams",
    email: "mbw234@gmail.com",
    twitter: "mbrandonw"
  )
)

render(view: siteLayout(content: articlesList), with: data)
```

This generates the exact same HTML from the beginning of this article, but using very small atomic pieces that plug together in beautiful ways.

## Conlusion

We have now seen that by embracing views as simple, pure functions from data to nodes we are able to discover 3 different forms of composition: `map`, `contramap` and monoid append. These operations are either completely hidden or obfuscated from you in the templating language world. For example, the only way to do a `map` on a view is to create a whole new template file to enclose the existing view. And amazingly, these 3 simple compositions subsume all possible ways of combining views in templating languages, such as partials, layouts, `yield` blocks, collections, nested layouts, etc...!

Believe it or not, there is still at least one more type of composition that can be done on views. It’s called `flatMap` and it’s useful for when you need to combine two views in a more complicated way than stacking them. We’ll save that for a future article. Until then, checkout this [playground](/assets/html-dsl/html-dsl-pt3.playground.zip) of all the work we have done.

## Exercises

1.) Define `flatMap` on `View<D, N>`:

```swift
extension View<D, N> {
  func flatMap<S>(_ f: @escaping (N) -> FunctionM<A, S>) -> FunctionM<A, S> {
    ???
  }
}
```

2.) Explore the idea that [“layouts”](http://guides.rubyonrails.org/layouts_and_rendering.html), as defined by Rails, is just a function between `(View<S<D>, N>) -> View<D, N>`, where `S<D>` is some type generic of your data `D` that adds whatever data is required by the layout. How do these layout functions compose?

3.) Implement the following function:

```swift
func divide<A, B, C, N: Monoid>(_ f: @escaping (A) -> (B, C))
  -> (View<B, N>)
  -> (View<C, N>)
  -> View<A, N> {

    ???
}
```

This allows you to take a function that splits a piece of data into two smaller pieces (`(A) -> (B, C)`), then take two views on the smaller pieces of data, and glues them together. This can also be achieved with `contramap` and `<>`, but this is a slightly shorter way of doing it. Also, this function can be seen as the contravariant analogue to [applicative functors](https://hackage.haskell.org/package/base-4.9.1.0/docs/Control-Applicative.html).

4.) Implement the following function:

```swift
enum Either<A, B> {
  case left(A)
  case right(B)
}

func choose<A, B, C, N>(_ f: @escaping (A) -> Either<B, C>)
  -> (View<B, N>)
  -> (View<C, N>)
  -> View<A, N> {

    ???
}
```

This allows you to choose between what views to use based on a function `(A) -> Either<B, C>`.This function can be seen as the contravariant analogue to [alternative functors](https://hackage.haskell.org/package/base-4.9.1.0/docs/Control-Applicative.html#g:2).

## References

* [Type Safe HTML in Swift](http://www.fewbutripe.com/swift/html/dsl/2017/06/22/type-safe-html-in-swift.html)
* [The Algebra of Predicates and Sorting Functions](http://www.fewbutripe.com/swift/math/algebra/monoid/2017/04/18/algbera-of-predicates-and-sorting-functions.html)
* [Algebraic Structures and Protocols](http://www.fewbutripe.com/swift/math/algebra/2015/02/17/algebraic-structure-and-protocols.html)

## A little bit of math…

I would be remiss if I didn’t take a brief moment to mention a bit of mathematical jargon so that you can research some of these topics more deeply. The fact that `View<D, N>` has a `map` on it means that `View` is a [_functor_](https://en.wikipedia.org/wiki/Functor) in the type parameter `N`. You are already familiar with some functors in Swift, like `Array<A>` and `Optional<A>`.

The fact that `View<D, N>` has a `contramap` on it means that `View` is a [_contravariant functor_](https://en.wikipedia.org/wiki/Functor#Covariance_and_contravariance) in the type parameter `D`. If you read our previous article on [predicates and sorting functions]({% post_url 2017-04-18-algbera-of-predicates-and-sorting-functions %}) you would have seen us define `Predicate<A>` and `Comparator<A>`. Both of those types are contravariant functors.

And finally, the fact that `View<D, N>` is a functor in `N` _and_ a contravariant functor in `D` at the same time, makes `View` a [_profunctor_](https://en.wikipedia.org/wiki/Profunctor).
