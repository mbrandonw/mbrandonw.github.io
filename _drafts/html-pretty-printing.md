---
layout: post
title:  "Pretty Printing HTML"
date:   2017-06-29
categories: swift html dsl
author: Brandon Williams
summary: "TODO"
image: TODO
---

In a [previous article]({% post_url 2017-06-27-view-functions-vs-templates %}) we implemented a naive HTML renderer by recursively walking the node tree and rendering each atomic unit. The implementation was simple, and it produces a “minified” version of the HTML since there were no newlines or spaces to make the result more readable. Sometimes we want to produce a string representation that is easier to grok, for example in development mode of a server it can be helpful to have nicely formatted HTML, and it can be useful for doing [“snapshot testing”](https://facebook.github.io/jest/docs/snapshot-testing.html
) of documents.

“Pretty printing” is the act of taking a piece of data, and printing it to a string that in some sense is aesthetically pleasing. For example, HTML is a tree of nodes that make up a document, and can be printed to a string in a variety of ways:

```html
<html><body>Hello world</body></html>
```
```html
<html>    <body>Hello world</body>
</html>
```
```html
<html>
<body>
Hello world
</body>
</html>
```
```html
<html>
  <body>
    Hello world
  </body>
</html>
```

Each of those printings represent the same HTML document, yet the last one is easiest to comprehend. However, just adding newlines and tabs on nodes sometimes isn’t enough. A single line may be very long, and you might want to wrap lines after they flow past a certain page width. For example, the following document has been pretty printed to make sure that no line goes beyond 40 characters:

```html
<html>
  <body>
    Articles about math, functional
    programming and the Swift
    programming language.
  </body>
</html>
```

Notice that it kept track of its indentation so that the first character of each line matched up. It can even get more complicated! For example, the attributes of a tag can get quite long and when you wrap their values you want to make sure they are aligned together:

```html
<html>
  <body id="home" class="home-body"
        style="background: #fff;">
    Articles about math, functional
    programming and the Swift
    programming language.
  </body>
</html>
```

Notice how `style` is aligned with `id` above and not simply indented two spaces from `<body`. We can even add another layer of complication by requiring all the attributes to be on newlines if they can’t all fit on a single line:

```html
<html>
  <body id="home"
        class="home-body"
        style="background: #fff;">
    Articles about math, functional
    programming and the Swift
    programming language.
  </body>
</html>
```

And just to make things even more interesting, let’s also require that if `class` or `style` values go beyond the page width, then they will also break out onto newlines:

```html
<html>
  <body id="home"
        class="home-body
               active
               logged-in"
        style="background: #fff;
               color: #333;">
    Articles about math, functional
    programming and the Swift
    programming language.
  </body>
</html>
```

Now that’s pretty! This can be great for taking [snapshots](https://facebook.github.io/jest/docs/snapshot-testing.html) of your pages in tests, and then any changes to the document are easy to visualize as a diff because of the liberal use of new lines. In this case, a 40 column page is used to show pretty printing on small documents, but typically you would use something more standard like 80 or 110.

## DoctorPretty

To do this type of complex pretty printing we will use a wonderful little library called [DoctorPretty](https://github.com/bkase/DoctorPretty
) written by [Brandon Kase](https://twitter.com/bkase_). It is based on a fantastic article called [“A prettier printer”](https://homepages.inf.ed.ac.uk/wadler/papers/prettier/prettier.pdf
) by [Philip Wadler](http://homepages.inf.ed.ac.uk/wadler/), written 20 years ago in 1997!

The idea is to transform your data structure, in our case `Node`, into the `Doc` data structure using some combinators that describe how the lines of the document flow. The pretty printer is then in charge of turning that `Doc` into a nicely formatted string. We are not going to dive into the internals of DoctoryPretty, so you are encouraged to read its [documentation](https://github.com/bkase/DoctorPretty) and [tests](https://github.com/bkase/DoctorPretty/blob/master/Tests/DoctorPrettyTests/DoctorPrettyTests.swift).

## Pretty printing a node

We are tasked with implementing the following function:

```swift
func prettyPrint(node: Node) -> Doc {
  ???
}
```

Our `Node` type is an enum with an `element` and `text` case, so we can fill in that part:

```swift
func prettyPrint(node: Node) -> Doc {
  switch node {
  case let .element(element):
    ???
  case let .text(text):
    ???
  }
}
```

Let’s assume for a moment that we have two hypothetical functions `prettyPrint(element:)` and `prettyPrint(text:)` that no how to print those pieces, then we have:

```swift
func prettyPrint(node: Node) -> Doc {
  switch node {
  case let .element(element):
    return prettyPrint(element: element)
  case let .text(text):
    return prettyPrint(text: text)
  }
}
```

Now, the real work is to implement those functions!

## Pretty printing a text node

The `text` node is the easiest to deal with, so let’s start with that. A text node can fill the entire line up to the page width, and then wrap back to where the text node started but on a new line. We can’t just break a newline at any point in the text though, it should happen at a space in the text. So, we can build an array of `Doc.text` values by splitting on a space and mapping:

```swift
let textParts: [Doc] = text
  .split(separator: " ")
  .map { Doc.text(String($0)) }
```

We now have an array of `Doc` values. This is where we get to use a DoctorPretty combinator to decide how these text parts will be laid out in the document. There’s one function called `fillSep` that operates on sequences of `Doc` values whose documentation reads:

```swift
/// Concats all horizontally until end of page
/// then puts a line and repeats
public func fillSep() -> Doc
```

That’s precisely what we want! So we can fill in our function as:

```swift
func prettyPrint(text: String) -> Doc {
  return text
    .split(separator: " ")
    .map{ Doc.text(String($0)) }
    .fillSep()
}
```

We can give it a very simple test drive. The first step to getting a string out of DoctorPretty is to first invoke `renderPretty(ribbonFrac:pageWidth:)`, which returns an intermediate `SimpleDoc` value. The parameter `ribbonFrac` determines what percentage of a line is allowed to be made up of non-indentation characters, and `pageWidth` determines how wide a page is. Then you invoke `displayString` on the `SimpleDoc` to finally get a string:

```swift
prettyPrint(text: "Articles about math, functional programming and the Swift programming language.")
  .renderPretty(ribbonFrac: 1, pageWidth: 40)
  .displayString()
```
```
Articles about math, functional
programming and the Swift
programming language.
```

Not super impressive just yet, but still nice how little work we had to do to get there!

## Pretty printing an element node

The `element` node is where all the complexity is. We’ll break this one up into lots of little helper functions. We start with it’s definition:

```swift
func prettyPrint(element: Element) -> Doc {
  ???
}
```

The job of this function will be construct a `Doc` value for the open tag, all of the children with indentation, the closing tag, and then to stack them all. Let’s imagine we’ve already got the following helper functions:

```swift
func prettyPrintOpenTag(element: Element) -> Doc {
  ???
}

func prettyPrintChildren(nodes: [Node]?) -> Doc {
  ???
}

func prettyPrintCloseTag(element: Element) -> Doc {
  ???
}
```

Note that `children` of an `Element` is an optional array since some nodes cannot have children, such as `img`.

It turns out that `Doc` forms a [monoid]({% post_url 2015-02-17-algebraic-structure-and-protocols %}), and the `<>` operation flows the documents together with no spaces or breaks between them. Therefore we can write `prettyPrint(element:)` in terms of our helpers:

```swift
func prettyPrint(element: Element) -> Doc {
  return prettyPrintOpenTag(element: element)
    <> prettyPrintChildren(nodes: element.children)
    <> prettyPrintCloseTag(element: element)
}
```

Now we just gotta render those 3 pieces and we’ll be done!

### Pretty printing an open tag

Well, easier said than done! There’s still quite a bit of work to do. Rendering an open tag consists of the node’s name (e.g. `<body`), it’s attributes, and then possibly a `>` and newline depending on children nodes. Assume for a moment that we already have a `prettyPrint(attributes:)` function that can deal with an array of attributes, then our open tags function can be written as:

```swift
private func prettyPrintOpenTag(element: Element) -> Doc {

  return .text("<")
    <> .text(element.name)
    <> prettyPrint(attributes: element.attribs)
    <> (element.content == nil ? .text(" />") : .text(">") <> .hardline)
}
```

The most complicated part of this is how we checked if `children` is `nil` so that we can just close up immediately with ` />`, and otherwise we append `>` and a newline so that the children will be printed inside the tag.

### Pretty printing an array of attributes

### Pretty printing children nodes

### Pretty printing a close tag

When rendering the closing tag we need to make sure not to do anything for the tags that cannot have children nodes. There’s a special `Doc` value called `empty` that helps with that:

```swift
private func prettyPrintCloseTag(element: Element) -> Doc {
  return element.content == nil
    ? .empty
    : .hardline <> .text("</") <> .text(element.name) <> .text(">")
}
```

Here we make sure to do nothing in the case that `children` is `nil`, and otherwise we go to a newline and print the closing tag.

## Conclusion

## Exercises

* make this more robust by taking a `Config` value that describes pagewidth, indentation, hang style, etc...

## References

https://en.wikipedia.org/wiki/Prettyprint
https://homepages.inf.ed.ac.uk/wadler/papers/prettier/prettier.pdf
https://facebook.github.io/jest/docs/snapshot-testing.html
https://github.com/bkase/DoctorPretty
