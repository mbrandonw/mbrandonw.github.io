---
layout: post
title:  "Type-Safe HTML in Swift"
categories: swift html typesafety
author: Brandon Williams
---

As server-side Swift becomes more popular and widely adopted, it will be important to re-examine some of the past “best-practices” of web frameworks to see how Swift’s type system can improve them. One important job of a web server is to produce the HTML that will be served up to the browser. We claim that by using types and pure functions, we can enhance this portion of the web request lifecycle.

## Template Languages

A popular method for generating HTML is using so-called “templating languages”, for example [Mustache](http://mustache.github.io) and  [Handlebars](http://handlebarsjs.com). There is even one written in Swift for use with the [Vapor](https://github.com/vapor/) web framework called [Leaf](https://github.com/vapor/leaf). These libraries ingest plain text that you provide, and interpolate values into it using a token. For example, here is a Mustache (and Handlebar) template:

```html
{% raw %}
<h1>{{title}}</h1>
{% endraw %}
```

and here is a Leaf template:

```html
<h1>#(title)</h1>
```

You can then render these templates by providing a dictionary of key/value pairs to interpolate, e.g. `["title": "Hello World!"]`, and then it will generate HTML that can be sent to the browser:

```html
<h1>Hello World!</h1>
```

Templating languages will also provide simple constructs for injecting small amounts of logic into the templates. For example, an `if` statement can be used to conditionally show some elements:

```html
{% raw %}
{{#if show}}
  <span>I’m here!</span>
{{/if}}
{% endraw %}
```
```html
#if(show) {
  <span>I’m here!</span>
}
```

The advantages of approaching views like this is that you get support for all that HTML has to offer out of the gate, and instead focus on building a small language for interpolating values into the templates. Some claim also that these templates lead to “logic-less” views, though confusingly they all support plenty of constructs for logic such as “if” statements and loops. A more accurate description might be “less logic” views since you are necessarily constricted by what logic you can use by the language.

The downsides, however, far outweigh the ups. (more here)

We claim that rather than embracing “logic-less” templates, and instead embracing pure functions and types, we will get a far more expressive, safer and composable view layer.


## Embedded Domain Specific Language

An alternative approach to views is using [“embedded domain specific languages”](https://wiki.haskell.org/Embedded_domain_specific_language) (EDSL’s). In this approach we use an existing programming language (e.g. Swift), to build a system of types and functions that models the [structure](https://en.wikipedia.org/wiki/Abstract_syntax_tree) of the domain we are modeling (e.g. HTML). Let’s take a fragment of HTML that we will use as inspiration to build in an EDSL:

```html
<header>
  <h1 id="welcome">Welcome!</h1>
  <p>
    Welcome to you, who has come here. See <a href="/more">more</a>.
  </p>
</header>
```

We will define some terms:

* **Element**: tags that are opened with `<>` and closed with `</>`, e.g. `header`, `h1`, `p` and `a`. They are defined by their name (i.e. `header`), the attributes applied (see below for more, i.e. `id="welcome"`), and their children nodes (see below for more).
* **Attribute**: a key value pair that is associated to an element, e.g. `id="welcome"` and `href="/more"`.
* **Node**: the unit with which the HTML tree is built. All elements are nodes, but also free text fragments are nodes. You can think of all free text in the document as having imaginary `<text></text>` tags around it. For example, if we inserted these imaginary tags into our sample document, and added plenty of newlines, we could really expose the underlying tree structure of nodes:

```html
<header>
  <h1 id="welcome">
    <text>Welcome!</text>
  </h1>
  <p>
    <text>Welcome to you, who has come here. See </text>
    <a href="/more">
      <text>more</text>
    </a>
    <text>.</text>
  </p>
</header>
```

This dictionary of terms is already enough to build up types that will model this tree. The tree is naturally recursive, since nodes contain elements and elements can contain nodes, so it may seem a little tricky at first. However, by translating our definitions, almost verbatim, we can define some value types:

```swift
struct Attribute {
  let key: String
  let value: String

  init(_ key: String, _ value: String) {
    self.key = key
    self.value = value
  }
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
```

A few things to note about these types. I have provided convenience initializers for `Attribute` and `Element` to omit their named arguments, because fully specify those can become a pain. I also made the children nodes in `Element` optional, because some elements are not allowed to have any children, such as `img`, and this is an instance of Swift’s type system giving us a nice way to model that possibility.

This is already enough to model our simple HTML document:

```swift
let document: Node = .element(
  .init("header", [],  [
    .element(
      .init("h1", [.init("id", "welcome")], [
        .text("Welcome!")
        ])
    ),
    .element(
      .init("p", [],  [
        .text("Welcome to you, who has come here. See "),
        .element(
          .init("a", [.init("href", "/more")], [
            .text("more")
            ])
        ),
        .text(".")
        ])
    )]
  )
)
```

This definitely ain’t pretty, but there are some nice things about it!

* We can use Swift’s type inference in order to remove gratuitous uses of `Node` and `Element` everywhere, i.e. we could use `.element` everywhere instead of `Node.element`.
* The compiler holds our hand while we write this out, providing error messages any time the types didn't match up or a brace was forgotten. This provides safety at compile-time, whereas most templating languages discover errors only at runtime.
* The HTML is modeled as a simple value type, and so can be transformed in some interesting ways. For example, we could easily write a function that walks this node tree looking for any elements with an attribute `"remove-me": "true"`, and remove those from the tree!

```swift
// Removes all nodes that are an element with a `"remove-me": "true"`
// attribute.
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
```

In fact, everything Swift has to offer us can be freely used to build HTML. For example, here we can use `Array`’s `map` to build an HTML list:

```swift
let items: [String] = ["Foo", "Bar", "Baz"]

let list: Node = .element(
  .init("ul", [], items.map({ item in
    .element(.init("li", [], [
      .text(item)
    ]))
  }))
)
```

These kinds of transformations are completely hidden from you in the template world, and these are the kinds of things that unlock all types of surprising compositions.

## Making the EDSL easier to use

Currently our EDSL is not super friendly to work with. It’s quite a bit more verbose than the plain HTML, and it’s hard to see the underlying HTML from looking at the DLS. Fortunately, these problems are easily fixed with a couple of helper functions and some nice features of Swift!

To begin with, we can make `Node` conform to `ExpressibleByStringLiteral` by simply embedding a string into the `.text` case of the `Node` enum:

```swift
extension Node: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    self = .text(value)
  }
}
```

This allows us to omit `.text("string")` from all of our code and just use a string, for example our heading element could be created with:

```swift
Element("h1", [.init("id", "welcome")], ["Welcome!"])
```

Next, we often had code like `.element(.init(name:attribs:children:))` for creating element nodes, but that can be flattened down to one level of parentheses by using a little helper `node` function:

```swift
func node(_ name: String, _ attribs: [Attribute], _ children: [Node]?) -> Node {
  return .element(.init(name, attribs, children))
}
```

Now our heading tag can be created with:

```swift
node("h1", [.init("id", "welcome")], ["Welcome!"])
```

It is quite common to have node elements with no attributes (like our `p` tag in our example from before), and so we can provide an overload of `node` for that case:

```swift
func node(_ name: String, _ children: [Node]?) -> Node {
  return node(name, [], children)
}
```

And now a simple node element could be expressed as simply as:

```swift
node("p", ["Welcome to you, who has come here."])
```

For the elements which you do have attributes, using the shorthand `.init("id", "welcome")` doesn’t seem short enough, and so we could cook up an operator that makes this a bit nicer and mimics the raw HTML a little more closely:

```swift
infix operator =>
func => <V: Value> (lhs: String, rhs: String) -> Attribute {
  return .init(key, value)
}
```

And now our heading becomes:

```swift
node("h1", ["id" => "welcome"], ["Welcome!"])
```

Our final addition to make the DSL a little nicer to use will be to create additional `node` helpers that are specific to the type of element they create. For example, we can create an `h1` function:

```swift
func h1(_ attribs: [Attribute], _ children: [Node]) -> Node {
  return node("h1", attribs, children)
}

func h1(_ children: [Node]) -> Node {
  return h1([], children)
}
```

Now our heading can be just:

```swift
h1(["id" => "welcome"], ["Welcome!"])
```

Not bad! If we create helpers for the rest of the tags in our sample HTML document (i.e. `a`, `header` and `p`), the DSL for our document becomes:

```swift
let document: Node = header([
  h1(["id" => "Welcome"], ["Welcome!"]),
  p([
    "Welcome to you, who has come here. See ",
    a(["href" => "/more"], ["more"]),
    "."
  ])
])
```

Whoa! That's even shorter than the HTML document since we don’t have to worry about closing tags!

References:

https://wiki.haskell.org/Embedded_domain_specific_language
https://en.wikipedia.org/wiki/Domain-specific_language
http://wiki.c2.com/?EmbeddedDomainSpecificLanguage
https://en.wikipedia.org/wiki/Abstract_syntax_tree
