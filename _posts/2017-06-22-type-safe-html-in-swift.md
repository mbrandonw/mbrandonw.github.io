---
layout: post
title:  "Type-Safe HTML in Swift"
categories: swift html dsl
author: Brandon Williams
---

As server-side Swift becomes more popular and widely adopted, it will be important to re-examine some of the past “best-practices” of web frameworks to see how Swift’s type system can improve upon them. One important job of a web server is to produce the HTML that will be served up to the browser. We claim that by using types and pure functions, we can enhance this part of the web request lifecycle.

## Template Languages

A popular method for generating HTML is using so-called “templating languages”, for example [Mustache](http://mustache.github.io) and  [Handlebars](http://handlebarsjs.com). There is even one written in Swift for use with the [Vapor](https://github.com/vapor/) web framework called [Leaf](https://github.com/vapor/leaf). These libraries ingest plain text that you provide and interpolate values into it using tokens. For example, here is a Mustache (and Handlebar) template:

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

The advantages of approaching views like this is that you get support for all that HTML has to offer out of the gate, and focus on building a small language for interpolating values into the templates. Some claim also that these templates lead to “logic-less” views, though confusingly they all support plenty of constructs for logic such as “if” statements and loops. A more accurate description might be “less logic” views since you are necessarily constricted by what logic you can use by the language.

The downsides, however, far outweigh the ups. Most errors in templating languages appear at runtime since they are usually not compiled. One can adopt a linting tool to find some (but not all) errors, but that is also an extra dependency that you need to manage. Some templating languages are compiled (like [HAML](http://haml.info)), but even then the tooling basic and can return confusing error messages. In general, it is on you to make these languages safe for you to deploy with confidence.

Furthermore, a templating language is just that: a language! It needs to be robust enough to handle what most users what to do with a language. That means it should support expressions, logical flow, loops, IDE autocomplete, IDE syntax highlighting, and more. It also needs to solve all of the new problems that appear, like escaping characters that are ambiguous with respect to HTML and the template language.

We claim that rather than embracing “logic-less” templates, and instead embracing pure functions and types, we will get a far more expressive, safer and composable view layer that can be compiled directly in Swift with no extra tooling or dependencies.

## Embedded Domain Specific Language

An alternative approach to views is using [“embedded domain specific languages”](https://wiki.haskell.org/Embedded_domain_specific_language) (EDSLs). In this approach we use an existing programming language (e.g. Swift), to build a system of types and functions that models the [structure](https://en.wikipedia.org/wiki/Abstract_syntax_tree) of the domain we are modeling (e.g. HTML). Let’s take a fragment of HTML that we will use as inspiration to build in an EDSL:

```html
<header>
  <h1 id="welcome">Welcome!</h1>
  <p>
    Welcome to you, who has come here. See <a href="/more">more</a>.
  </p>
</header>
```

We define some terms:

* **Element**: tags that are opened with `<…>` and closed with `</…>`, e.g. `header`, `h1`, `p` and `a`. They are defined by their name (e.g. `header`), the attributes applied (see below for more, e.g. `id="welcome"`), and their children nodes (see below for more).
* **Attribute**: a key value pair that is associated to an element, e.g. `id="welcome"` and `href="/more"`.
* **Node**: the unit with which the HTML tree is built. All elements are nodes, but also free text fragments are nodes. You can think of all free text in the document as having imaginary `<text></text>` tags around it. For example, if we inserted these imaginary tags into our sample document, and added plenty of newlines, we could expose the underlying tree structure of nodes:

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

This dictionary of terms is already enough to build up types that will model this tree. The tree is naturally recursive, since nodes contain elements and elements can contain nodes, so it may seem a little tricky at first. By translating our definitions, almost verbatim, we can define some value types:

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

A few things to note about these types. I have provided convenience initializers for `Attribute` and `Element` to omit their named arguments, because fully specifying those can be a pain. I also made the children nodes in `Element` optional, because some elements are not allowed to have any children, such as `img`, and this is an instance of Swift’s type system giving us a nice way to model that possibility.

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

This ain’t pretty, but there are some nice things about it!

* We can use Swift’s type inference to remove gratuitous uses of `Node` and `Element` everywhere, i.e. we could use `.element` everywhere instead of `Node.element`.
* The compiler holds our hand while we write this out, providing error messages any time the types didn’t match up or a brace was forgotten. This provides safety at compile-time, whereas most templating languages discover errors only at runtime.
* This simple value type models the HTML, and so can be transformed in some interesting ways. For example, we could write a function that walks this node tree looking for any elements with an attribute `"remove-me": "true"`, and remove those from the tree!

```swift
// Removes all nodes that are an element with a `"remove-me": "true"`
// attribute.
func removeCertainElements(_ node: Node) -> Node? {
  switch node {
  case let .element(element):
    // If the element’s attribute’s contain the key we are looking
    // for, return `nil` to remove it!
    guard !element.attribs
      .contains(where: { $0.key == "remove-me" && $0.value == "true" }) else {
      return nil
    }

    // Recursive search the children for elements to remove.
    return .element(
      .init(element.name,
            element.attribs,
            element.children.map { $0.flatMap(removeCertainElements) })
    )
  case .text:
    return node
  }
}
```

In fact, everything Swift has to offer us can be freely used to build HTML. We can use `map` to build an HTML list from an array of strings:

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

Currently our EDSL is not super friendly to work with. It’s a bit more verbose than the plain HTML, and it’s hard to see the underlying HTML from looking at the code. Fortunately, these problems are fixed with a couple of helper functions and some nice features of Swift!

To begin with, we can make `Node` conform to `ExpressibleByStringLiteral` by embedding a string into the `.text` case of the `Node` enum:

```swift
extension Node: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    self = .text(value)
  }
}
```

This allows us to omit `.text("string")` from our code and use a string literal. Our heading element can now be written as:

```swift
Element("h1", [.init("id", "welcome")], ["Welcome!"])
```

Next, we often had code like `.element(.init(name:attribs:children:))` for creating element nodes, but that is now flattened down to one level of parentheses by using a little helper `node` function:

```swift
func node(_ name: String, _ attribs: [Attribute], _ children: [Node]?) -> Node {
  return .element(.init(name, attribs, children))
}
```

Now our heading tag simplifies to:

```swift
node("h1", [.init("id", "welcome")], ["Welcome!"])
```

The shorthand for creating attributes, `.init("id", "welcome")`, doesn’t seem short enough, and so we can cook up an operator that makes this a bit nicer and mimics the raw HTML a little more closely:

```swift
infix operator =>
func => (key: String, value: String) -> Attribute {
  return .init(key, value)
}
```

And now our heading becomes:

```swift
node("h1", ["id" => "welcome"], ["Welcome!"])
```

It is common to have node elements with no attributes (like our `p` tag in our example from before), and so we can provide an overload of `node` for that case:

```swift
func node(_ name: String, _ children: [Node]?) -> Node {
  return node(name, [], children)
}
```

And now a simple node element could be expressed as simply as:

```swift
node("p", ["Welcome to you, who has come here."])
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
let document = header([
  h1(["id" => "welcome"], ["Welcome!"]),
  p([
    "Welcome to you, who has come here. See ",
    a(["href" => "/more"], ["more"]),
    "."
  ])
])
```

Whoa! That’s about as short as the original HTML document!

## Safer Attributes

Right now our `Attribute` type is just a pair of strings representing the key and value. This allows for non-sensical pairs, such as `width="foo"`. We can encode the fact that attributes require specific types of values into the type system, and get additional safety on this aspect.

We start by creating a type specifically to model keys that can be used in attributes. This type has two parts: the name of the key as a string (e.g. `"id"`, `"href"`, etc...), and the _type_ of value this key is allowed to hold. There is a wonderful way to encode this latter requirement into the type system: you make the key’s type a generic parameter, but you don’t actually use it! Such a type is called a [_phantom type_](https://wiki.haskell.org/Phantom_type). We define our type as such:

```swift
struct AttributeKey<A> {
  let key: String
  init (_ key: String) { self.key = key }
}
```

Here `A` is our phantom type, and notice that it is never used. This allows you to create keys that also specify the types they expect:

```swift
let id = AttributeKey<String>("id")
let width = AttributeKey<Int>("width")
```

The first is the key `id` with it’s expected value type encoded as `String`, and the second is the key `width` with it’s expected value type as `Int`.

To enforce this contract we change `Attribute`s initializer to be private so that no one is allowed to create instances, and force the creation of attributes through the `=>` operator, which we redefine to take advantage of the phantom type:

```swift
func => <A> (key: AttributeKey<A>, value: A) -> Attribute {
  return .init(key.key, "\(value)")
}
```

This function is what enforces the type-safety of pairings between attribute keys and values. The only possible way to create an `Attribute` value is through this function, and the compiler ensures that the types match up correctly. We can make use of it easily enough:

```swift
h1([id => "welcome"], ["Welcome!"])

a([href => "/more"], ["See more"])

img([width => 100, height => 100, src => "img.png"])
```

If you misuse these types, you even get a pretty straight forward error message from the Swift compiler:

```swift
width => "foo"
// error: cannot convert value of type 'String' to expected argument
// type 'Int'
// width => "foo"
//          ^
```

## Rendering HTML

There are still even more improvements we can make to our EDSL, but before this article gets too long we should probably cut it off and address how to render the EDSL to a string of HTML that can actually be sent to the browser. Ideally one wants to implement the following function:

```swift
func render(node: Node) -> String {
}
```

This is a straightforward exercise, though subtle and can take a few tries to get right. The details, however, are not particularly important for the main point of this article, type-safe HTML. Therefore I’ve put the details in another article, which you can find [here]({% post_url 2017-06-23-rendering-html-dsl %}).

## Conclusion and next steps

Amazingly we have now created a very simple HTML DSL, all in about 80 lines of code. We of course don’t have the full set of HTML tags and attributes, but that is simple enough to add.

Further, because we have just embraced simple value types and pure functions, we can feel pretty confident that we haven’t backed ourselves into a corner with respect to future developments. In fact, this approach has opened many doors for us! Here is just a small sample of the next features we will implement in upcoming articles:

* We can use the type system to provide safety around how plain text is encoded for use with HTML. It allows us to prove that non-encoded strings never make it into our HTML.

* If you’re _really_ strict with yourself, then you can think of views as just pure functions from some piece of data to an array of nodes, i.e. `view: (Data) -> [Node]`. In a previous [article]({% post_url 2015-02-17-algebraic-structure-and-protocols %}) we saw that arrays form what is known as a monoid, and in another [article]({% post_url 2017-04-18-algbera-of-predicates-and-sorting-functions %}) we showed that the set of functions from any type into a monoid also forms a monoid. This gives a form of composition on views that can help form complicated views from simple building blocks.

* The set of functions between two types `(A) -> B` carries two structures. One is called a “functor” and the other is called a “co-functor”. These structures allow you to take transformations on `A` and `B` and lift them up to transformations on functions. Without knowing what these terms mean just yet, it pertains to views `(Data) -> [Node]` by lifting transformations of `Data` or `Node`s to transformations on views! This provides us with two additional forms of composition of views!

* These kinds of views are incredibly easy to test. Since they are just pure functions you can feed them some data and then make assertions on the output of HTML. You can even build up a little infrastructure so that output is saved to a plain text file in your test directory, and then future test runs will make assertions against the contents of that file. This is known as snapshot testing and is very popular in React.

* Once you go down the road to thinking of views as functions `(Data) -> [Node]`, you start to build up lots of lil helper views that can be reused in (hopefully) any which way. However, you soon find out that the data these subviews demand needs to be threaded all the way through the view hierarchy all the way back to the root view. This naturally leads one to something known as a [`Reader`](https://hackage.haskell.org/package/mtl-2.2.1/docs/Control-Monad-Reader.html) and solves this problem in a beautiful way.

All of these topics and more will be coming in future articles.

## Playground

All of the code developed in this article is available in a playground you can download <a href="/assets/html-dsl/html-dsl-pt1.playground.zip">here</a>.

## Exercises

1.) In HTML5, the `<strike>` tag for styling strikethrough text was removed from the standard. Instead one is supposed to use `<del>` or `<s>`. Write a function `updatedStrikes(node: Node) -> Node` that replaces all `<strike>`’s with `<s>`’s

2.) Enhance the EDSL by adding support for HTML comments.

## References:

* https://wiki.haskell.org/Embedded_domain_specific_language

* https://en.wikipedia.org/wiki/Domain-specific_language

* http://wiki.c2.com/?EmbeddedDomainSpecificLanguage

* https://en.wikipedia.org/wiki/Abstract_syntax_tree

* https://wiki.haskell.org/Phantom_type

* https://www.objc.io/blog/2014/12/29/functional-snippet-13-phantom-types/
