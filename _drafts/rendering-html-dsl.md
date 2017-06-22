
## Rendering to HTML

There are still even more improvements we can make to our EDSL, but before doing that let’s create a function that will actually render a `Node` to a string. We do this by recursively walking the node tree, and rendering out the various parts in the most naive way possible. We begin by make a skeleton of such a function:

```swift
func render(_ node: Node) -> String {
  switch node {
  case let .element(e):
    // ???
  case let .text(t):
    // ???
  }
}
```

So far we have only switched on the node type, which is our clearest first step. Rendering a text node is actually the easiest, it’s just the text itself!

```swift
func render(node: Node) -> String {
  switch node {
  case let .element(e):
    // ???
  case let .text(t):
    return t
  }
}
```

Next we have to render the `.element` case. That will be more involved than the `.text` case, so let’s create a new function to handle it:

```swift
func render(element: Element) -> String {
  // ???
}
```

An element value has three components: the name of the element, the attributes, and the children nodes. The name is easy enough to render as it’s just the opened and closed tags, e.g. `<a...</a>`. The attributes get rendered out to pairs of `key="value"` strings. This is straightforward to do, and let’s do it in a new function:

```swift
func render(attributes: [Attribute]) -> String {
  return attributes
    .map { attr in "\(attr.key)=\"\(attr.value)\"" }
    .joined(separator: " ")
}

render(attributes: ["id" => "welcome"]) // => "id=\"welcome\""
```

Now going back to `render(element:)` we can fill in a little bit more:

```swift
func render(element: Element) -> String {
  let openTag = "<\(element.name)"
  let openTagWithAttrs = openTag
    + (element.attribs.isEmpty ? "" : " ")
    + render(attributes: element.attribs)
    + ">"
  let children = // ???
  let closeTag = element.children == nil ? "/>" : "</\(element.name)>"

  return openTagWithAttrs + children + closeTag
}
```

A couple of things to note about this. In the case that the element has no attributes we make sure to not accidentally render an additional space, i.e. we want `<a>`, not `<a >`. Also, if the element cannot have children, we close the tag with `/>` instead of a full tag, i.e. we want `<img />`, not `<img></img>`.

We are now only left with rendering the children, which we can do by calling the `render(node:)` function recursively on each node, and then joining the results. The `render(element:)` function now looks like this in its entirety:

```swift
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

render(element: Element("h1", ["id" => "welcome"], ["Welcome!"]))
  // => "<h1 id=\"welcome\">Welcome!</h1>"
```

And to round it all off, we just need to invoke `render(element:)` from `render(node:)`:

```swift
func render(node: Node) -> String {
  switch node {
  case let .element(e):
    return render(element: e)
  case let .text(t):
    return t
  }
}
```

And applying it to our document we’ve been building we recover the HTML we wanted to model:

```swift
render(node: document)
  // => "<header><h1 id=\"welcome\">Welcome!</h1><p>Welcome to you, who has come here. See <a href=\"/more\">more</a>.</p></header>"
```

This renders the entire document into a single line, because HTML doesn’t care about newlines and formatting. But, it’s a fun exercise (and in fact, check out the exercises down below!) to update our `render(node:)` function to also allow pretty rendering.

## Exercises


2.) Create an `AttributeValue` protocol to be the counterpart of our `AttributeKey` type. It’s job is to have a `render(withKey:)` method that knows how to render a single key/value pair. This will allow us to provide custom logic for rendering attributes. For example, boolean attributes either render their presence or not at all: one uses `<input>` and `<input disabled>` for enabled/disabled states, not `<input disabled="false">` and `<input disabled="true">`.

2.) Make a pretty renderer for `Node`. It should insert a newline after every opened tag, and indent its contents based on how deeply you are nested into the tags.

3.) Implement HTML escaping into our DSL and renderer. One approach is to model escaped strings as a new type, say `EncodedString`, and then require the DSL to only accept encoded strings. You will also need to provide a way to convert plain `String`s to `EncodedString`s. Once you fix all of the compiler errors, there’s a chance that everything will _just work_!
