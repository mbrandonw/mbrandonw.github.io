---
layout: post
title:  "Announcing Point-Free"
date:   2017-09-17
categories: swift functional programming
author: Brandon Williams
summary: "Announcing Point-Free, A weekly video series exploring Swift and functional programming."
image: /assets/point-free-card.png
---

> A soon-to-be launching [weekly video series](https://www.pointfree.co/) exploring Swift and functional programming!

For the past 3 years, since Swift’s early days, I have been a strong proponent of adopting the techniques of functional programming to improve the understandability and maintainability of Swift code. I co-organize the [Functional Swift Conference](http://www.funswiftconf.com/), I write extensively on my [site](http://www.fewbutripe.com/), give [talks](http://www.fewbutripe.com/talks/) whenever I can, and [open-sourced](https://kickstarter.engineering/open-sourcing-our-android-and-ios-apps-6891be909fcd) the iOS and Android code bases at Kickstarter to show how these techniques can be used in a real-life code base. However, functional programming often comes across as foreign and intimidating, and so there’s always more work that can be done to make it approachable!

So, with my former colleague from Kickstarter [Stephen Celis](http://www.stephencelis.com/), we are launching [Point-Free](https://www.pointfree.co/), a weekly video series exploring Swift and functional programming.

![](/assets/point-free-site.png)

We learned quite a bit while making this site! From the beginning we knew we wanted to make the site using server-side Swift, and we wanted to approach it in a functional way. We wanted the server to just be a pure function that takes a request and outputs a response. We wanted all the side-effects to be pushed to the boundaries of the application, and then be interpreted in an understandable and testable manner. And we wanted to embrace views as [composable, stateless functions](http://www.fewbutripe.com/swift/html/dsl/2017/06/29/composable-html-views-in-swift.html).

Turns out, if you accomplish all of the above, all types of fun stuff starts popping out. First, you get to easily write tests that traverse the full stack of the application and make assertions on every little thing that happened along the way. Then, because the server is just a pure function, you can easily load it up in a Swift Playground and pipe requests through, including `POST` requests!

![](/assets/point-free-playground.png)

And finally, we developed an all-purpose [snapshot testing library](https://www.github.com/pointfreeco/swift-snapshot-testing) so that we could take full snapshots of HTML text _and_ screenshots of pages at different browser sizes.

We are so excited with our findings that we decided to open-source the whole collection of libraries we made that aid in developing server-side Swift. We are also open-sourcing the full source code of the site itself! You can find all of the repositories on the [Point-Free GitHub organization](https://github.com/pointfreeco), but here are some of the interesting things you will find:

* [github/pointfreeco](https://github.com/pointfreeco/pointfreeco): The source to the full www.pointfree.co site! It includes all of the routing and server middleware, HTML views, CSS styling and business logic.
* [github/pointfreeco-server](https://github.com/pointfreeco/pointfreeco-server): A barebones Kitura application that delegates all of the request-to-response lifecycle responsibilities to pointfreeco.
* [github/swift-web](https://github.com/pointfreeco/swift-web): A collection of types and functions that aid in server-side developing, including HTML/CSS creation and rendering, request routing and server middleware.
* [github/swift-prelude](https://github.com/pointfreeco/swift-prelude): Offers a standard library for experimental functional programming in Swift.
* [github/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing): A full-featured snapshot testing library to capture a data structure as text, image or anything, and make assertions against reference data.

<br>

---
<br>

So, this is what I’ve been up to since [leaving Kickstarter](https://twitter.com/mbrandonw/status/874683027464622081) a few months ago! We hope to have our first episodes live by the end of this year. Please consider [signing up](https://www.pointfree.co/) to show us how much interest is out there for such a thing, and to be notified when we launch!

Also, if any of this interests you and you want to collaborate on some work together, I’m available [for hire](http://fewbutripe.com/hire-me/).
