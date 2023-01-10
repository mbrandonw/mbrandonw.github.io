---
layout: page
title: Talks
permalink: /talks/
summary: "A list of my upcoming and past talks at conferences."
---

I’m available to speak at conferences and meet ups, so please feel free to drop me an email [mbrandonw@hey.com](mailto:mbrandonw@hey.com).

# Upcoming talks

None planned right now.

# Past talks

* [SwiftUI Navigation and URL Routing](#swiftui-navigation-and-url-routing)
* [Protocol Witnesses](#protocol-witnesses)
* [Seemingly Impossible Swift Programs](#seemingly-impossible-swift-programs)
* [Server-Side Swift from Scratch, for web devs](#server-side-swift-from-scratch-for-web-devs)
* [Server-Side Swift from Scratch](#server-side-swift-from-scratch)
* [Composable Reducers](#composable-reducers)
* [Playground-Driven Development](#playground-driven-development)
* [Anything you can do, I can do better](#anything-you-can-do-i-can-do-better)
* [Swift Talks](#swift-talks)
  * [View Models at Kickstarter](#view-models-at-kickstarter)
  * [Deep Linking at Kickstarter](#deep-linking-at-kickstarter)
  * [Playground-Driven Development at Kickstarter](#playground-driven-development-at-kickstarter)
* [Monoids, Predicates and Sorting Functions](#monoids-predicates-and-sorting-functions)
* [The Two Sides of Writing Testable Code](#the-two-sides-of-writing-testable-code)
* [Finding Happiness in Functional Programming](#finding-happiness-in-functional-programming)
* [Lenses in Swift](#lenses-in-swift)
* [Proof in Functions](#proof-in-functions)
* [Functional Programming in a Playground](#functional-programming-in-a-playground)

<br>

## [SwiftUI Navigation and URL Routing]()

## [Protocol Witnesses](https://vimeo.com/showcase/9831667/video/751580644)

**September 16, 2022: Logroño, Spain**: After a brief overview of how SwiftUI's new NavigationStack API works, we'll explore how to build a router that can transform nebulous URLs into state that drives deep-linking in your application. Then, almost magically, that same code will be used to power a server-side application for generating deep-linking URLs.

<div style="padding:56.25% 0 0 0;position:relative;"><iframe src="https://player.vimeo.com/video/751580644?h=6714fe76d6" style="position:absolute;top:0;left:0;width:100%;height:100%;" frameborder="0" allow="autoplay; fullscreen; picture-in-picture" allowfullscreen></iframe></div><script src="https://player.vimeo.com/api/player.js"></script>

<br>

## [Seemingly Impossible Swift Programs](https://www.youtube.com/watch?v=PXI53f2CnVw)

**December 2018: New York, NY**: In this talk I live code an implementation of a "seemingly impossible" Swift program. It's one that for all intents and purposes should be impossible, yet somehow isn't: we will perform an exhaustive search across an infinite space of values in finite time. Once this program is implemented I try to show some of the mathematics that explains how this could be true, and show that it has a surprising link to a field of mathematics known as topology.

I later turned this talk into a blog post “[Seemingly Impossible Swift Programs]({% post_url 2018-12-05-seemingly-impossible %})”. All of the material in this talk can be found in a series of papers and articles by Martín Escardó:

- [Infinite sets that admit fast exhaustive search](http://www.cs.bham.ac.uk/~mhe/papers/exhaustive.pdf) – Martín Escardó
- [Synthetic topology of data types and classical spaces](http://www.cs.bham.ac.uk/~mhe/papers/entcs87.pdf) – Martín Escardó
- [Seemingly Impossible Functional Programs](http://math.andrej.com/2007/09/28/seemingly-impossible-functional-programs/) – Martín Escardó
- [The topology of Seemingly impossible functional programs (Slides)](https://www.cs.bham.ac.uk/~mhe/.talks/popl2012/escardo-popl2012.pdf) – Martín Escardó
- [Swift playground with code from this talk](https://gist.github.com/mbrandonw/981f589f32800d3409f817ad4f7c6802)

<iframe width="560" height="315" src="https://www.youtube.com/embed/PXI53f2CnVw" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

<br>

## [Server-Side Swift from Scratch, for web devs](https://2018.conc.at)

**March 2018: Salzburg, Austria** I gave the same talk I gave at [Swift Summit](#server-side-swift-from-scratch), but this time to a room full of non-Swift and non-iOS engineers at a [web development conference](https://2018.conc.at).

<br>

## [Server-Side Swift from Scratch](https://www.skilled.io/u/swiftsummit/server-side-swift-from-scratch)

**October 2017: San Francisco, CA**: A rapid tour through what is required of a server-side web framework, and how Swift’s type system can help solve very complex problems in an expressive and safe way. I mostly focus on:

* Server middleware as just a function that takes a request and produces a response. We use a technique known as phantom types to actually model the entire request-to-responsive lifecycle directly in the type system.
* An applicative style router that is invertible. This means it can both route requests to a first class value, and print requests from a value. It is based on the ideas in [this](http://www.informatik.uni-marburg.de/~rendel/unparse/rendel10invertible.pdf) paper.
* Lifting HTML and CSS views into Swift types so that we can transform them in new and interesting ways.
* Using Xcode and the Swift toolchain to do painless snapshot testing, screenshot testing and using Swift playgounds to create entire webpages.

The talk covers a lot of the core ideas that went into building the [Point-Free](https://www.pointfree.co) website, which is fully [open source](http://github.com/pointfreeco/pointfreeco).

<a href="https://www.skilled.io/u/swiftsummit/server-side-swift-from-scratch">
  <img src="/assets/serve-side-swift-from-scratch.jpg" width="560" style="max-width: 100%;" alt="The two sides of writing testable code" />
</a>

<br>

## Composable Reducers

**September 2017: Berlin**: I gave this talk at the [Functional Swift Conference](http://2017-fall.funswiftconf.com) in Berlin, and it entirely focuses on the composability properties of reducers, which are functions of the form `(S, A) -> S`. Turns out, there are lots of nice ways to compose such functions, and when applied to ways to model application state (e.g. in Elm and Redux), we show that this allows one to write very simple, local reducers while still leaving yourself open to compose them in a global manner.

<iframe width="560" height="315" style="max-width: 100%;"  src="https://www.youtube.com/embed/QOIigosUNGU" frameborder="0" allowfullscreen></iframe>

<br>

## Playground-Driven Development

**September 2017: Paris**: I gave this talk at [FrenchKit](http://frenchkit.fr) in Paris, and it goes a little bit deeper into the topic I first [discussed](#playground-driven-development-at-kickstarter) on “Swift Talk” with Chris Eidhof. It shows how we can replace a large portion of our everyday work in simulators and storyboards with Swift playgrounds. Towards the end of the talk I give a small preview of how I’ve even been using playgrounds to do server-side Swift development.

<iframe width="560" height="315" style="max-width: 100%;"  src="https://www.youtube.com/embed/DrdxSNG-_DE" frameborder="0" allowfullscreen></iframe>

<br>

## Anything you can do, I can do better

**May 2017: Berlin**: My colleague [Lisa Luo](http://www.twitter.com/luoser) and I gave a talk at [UIKonf](http://www.uikonf.com) about how we unify our foundations across iOS and Android by building off of functional programming in Swift and Kotlin.

<iframe width="560" height="315" style="max-width: 100%;"  src="https://www.youtube.com/embed/_DuGaAkQSnM" frameborder="0" allowfullscreen></iframe>

<br>

## Swift Talks

**April 2017: Brooklyn, NY**: [Chris Eidhof](http://twitter.com/chriseidhof) and [Florian Kugler](http://www.twitter.com/floriankugler) of [objc.io](http://www.objc.io) invited me to record a few guest appearances on their “Swift Talks” series about Kickstarter’s [newly open-sourced](https://kickstarter.engineering/open-sourcing-our-android-and-ios-apps-6891be909fcd) code. It was a great opportunity to show how functional programming can be applied to a large codebase in real life.

#### [View Models at Kickstarter](https://talk.objc.io/episodes/S01E47-view-models-at-kickstarter)

> Brandon from Kickstarter joins us and shows how the company uses view models to write highly testable code. We integrate Apple Pay payments and look at Kickstarter's open-source codebase.

<video controls preload="none" playsinline="true" poster="https://i.vimeocdn.com/video/731751310_1280.jpg" tabindex="-1" src="https://d2sazdeahkz1yk.cloudfront.net/videos/480bc61f-3920-4282-b6ec-e0ab77b71cef/2/hls.m3u8" width="560" style="max-width: 100%;">
  <source src="https://d2sazdeahkz1yk.cloudfront.net/videos/480bc61f-3920-4282-b6ec-e0ab77b71cef/2/hls.m3u8" type="application/x-mpegURL">
</video>

<br>

#### [Deep Linking at Kickstarter](https://talk.objc.io/episodes/S01E49-deep-linking-at-kickstarter)

> Brandon from Kickstarter joins us to discuss deep linking into an iOS app. We show how to unify all potential entry points into the app using a common route enum, and then we take a look at this pattern in Kickstarter's open source codebase.


<video controls preload="none" playsinline="true" poster="https://i.vimeocdn.com/video/731751221_1280.jpg" tabindex="-1" src="https://d2sazdeahkz1yk.cloudfront.net/videos/be77e730-777a-4c1e-b2d4-b163ccd7e07a/1/hls.m3u8" width="560" style="max-width: 100%;">
  <source src="https://d2sazdeahkz1yk.cloudfront.net/videos/be77e730-777a-4c1e-b2d4-b163ccd7e07a/1/hls.m3u8" type="application/x-mpegURL">
</video>

<br>

#### [Playground-Driven Development at Kickstarter](https://talk.objc.io/episodes/S01E51-playground-driven-development-at-kickstarter)

> Brandon from Kickstarter is back to show us how the company uses playgrounds to prototype and style individual view controllers.

<video controls preload="none" playsinline="true" poster="https://d2sazdeahkz1yk.cloudfront.net/assets/media/W1siZiIsIjIwMTcvMDUvMTkvMTkvMTEvNTAvZGMxOWIwZTktMDljYS00ODk4LWIyMmQtNzc1ZThmN2JkNjNlLzUxIFBsYXlncm91bmQtRHJpdmVuIERldmVsb3BtZW50IGF0IEtpY2tzdGFydGVyLmpwZyJdLFsicCIsInRodW1iIiwiMTkyMHgxMDgwIyJdXQ?sha=6201e61a5cc75591" tabindex="-1" src="https://d2sazdeahkz1yk.cloudfront.net/videos/1e7e2723-36dc-4a11-b81f-02703b7bb305/1/hls.m3u8" width="560" style="max-width: 100%;">
  <source src="https://d2sazdeahkz1yk.cloudfront.net/videos/1e7e2723-36dc-4a11-b81f-02703b7bb305/1/hls.m3u8" type="application/x-mpegURL">
</video>

<br>

## Monoids, Predicates and Sorting Functions
**April 2017: Brooklyn, NY**: At the [2017 Functional Swift Conference](http://2017.funswiftconf.com) in Brooklyn I spoke about small atomic units of abstractions can piece together to build surprisingly complex, yet expressive, components. In particular, I used semigroups and monoids to build an expressive algebra for predicates and sorting functions. This talk is roughly based on the article I wrote “[The Algebra of Predicates and Sorting Functions]({% post_url 2017-04-18-algbera-of-predicates-and-sorting-functions %})”.

<iframe width="560" height="315" style="max-width: 100%;"  src="https://www.youtube.com/embed/VFPhPOnPiTY" frameborder="0" allowfullscreen></iframe>

<br>

## [The Two Sides of Writing Testable Code](https://news.realm.io/news/try-swift-brandon-williams-writing-testable-code/)

**March 2017: Tokyo**: There are precisely two things that make functions fully testable: the isolation of effects and the surfacing of ‘co-effects’. We will explore a bit of the formal theory behind these two sides, and show how they lead to code that can be easily tested. We will also show how we do this at Kickstarter by diving into our recently open sourced codebase.

<a href="https://news.realm.io/news/try-swift-brandon-williams-writing-testable-code/">
  <img src="/assets/two-sides-of-testing.jpg" width="560" style="max-width: 100%;" alt="The two sides of writing testable code" />
</a>

<br>

## Finding Happiness in Functional Programming
**Oct 2016: Budapest** At the [2016 Functional Swift Conference](http://2016.funswiftconf.com) in Budapest I spoke about how embracing simple, pure functions above all other abstractions has enabled my colleagues and me to build a well-tested, well-understood [codebase](https://kickstarter.engineering/open-sourcing-our-android-and-ios-apps-6891be909fcd). I first covered the basics of pure functions and the ideas of identifying effects and separating them from your functions. I then described how these ideas allowed us better our testing suites, enabled us to replace simulators and storyboards with Swift playgrounds, and ultimately a better working relationship with engineers, designers and product managers.

<iframe width="560" height="315" style="max-width: 100%;"  src="https://www.youtube.com/embed/A0VaIKK2ijM" frameborder="0" allowfullscreen></iframe>

<br>

## Lenses in Swift
**Dec 2015: Brooklyn, NY** At the [2015 Functional Swift Conference](http://2015.funswiftconf.com) in Brooklyn I described the basics of lenses and how to implement them in Swift.

<iframe width="560" height="315" style="max-width: 100%;"  src="https://www.youtube.com/embed/ofjehH9f-CU" frameborder="0" allowfullscreen></iframe>

<br>

## Proof in Functions
**Feb 2015: Brooklyn, NY** At the [Brooklyn Swift Meetup](https://www.meetup.com/Brooklyn-Swift-Developers/events/220352273/) I described how we can use the Swift type system to prove simple mathematical theorems. This talk covers most of everything I discussed in my post [“Proof in Functions”](http://www.fewbutripe.com/swift/math/2015/01/06/proof-in-functions.html).

<iframe src="https://player.vimeo.com/video/121953811" width="560" height="315" style="max-width: 100%;" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

<br>

## Functional Programming in a Playground
**Dec 2014: Brooklyn, NY** At the [2014 Functional Swift Conference](http://2014.funswiftconf.com) in Brooklyn I used Swift playgrounds as a highly interactive way for exploring functional programming ideas. In particular, I developed the ideas of transducers and show how they lead to highly composable data transformations.

<iframe width="560" height="315" style="max-width: 100%;"  src="https://www.youtube.com/embed/estNbh2TF3E" frameborder="0" allowfullscreen></iframe>
