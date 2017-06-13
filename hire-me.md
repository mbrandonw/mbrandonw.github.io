---
layout: page
title: Hire Me
permalink: /hire-me/
published: true
---

<center style="margin: auto; width: 150px; height: 150px; overflow: hidden; border-radius: 50%;">
![It me]({{ site.url }}/assets/it-me.jpg)
</center>

> Howdy!

I’m Brandon Williams, and I’m [available](emailto:mbw234+hireme@gmail.com) for part-time consulting work in iOS. I’m mostly focused on teaching and applying functional programming to everyday work as a means of gaining more understanding, testability and sharing of code.


## My services

I am open to a variety of projects to work on:

#### **Building a 1.0**

Have an app that you’re just starting and want some help? I can build the 1.0 from scratch and help onboard any engineers you hire to take over development.

#### **Code review and consulting**

Have an existing code base that you’d like some help improving? I can help review code and architectural decisions, make suggestions, and consult on how to implement them.

#### **Workshops and Training**

Have a team that is interested in some of the [ideas](#my-work) discussed on this page? I can develop a syllabus of topics to help train a group of engineers to effectively use these ideas in their everyday work.

#### **Speaking**

I am available to speak at meet ups and conferences on a variety of topics.

- Kotlin for Swift Developers (and vice versa!)
- Functional Programming
- Playground Driven Development
- Writing Testable Code

# Contact me

If any of this sounds interesting to you and your team, please get in touch! My email is [mbw234@gmail.com](emailto:mbw234+hireme@gmail.com) and I have availability immediately.

<br>

---

<br>

<div id="my-work"></div>

## My work at Kickstarter

I worked at Kickstarter for five-and-a-half years, and in that time helped ship the [1.0 iPhone app](https://www.kickstarter.com/blog/introducing-the-kickstarter-app-for-iphone-and-ipo), the 2.0 universal iOS app, [advanced discovery](https://www.kickstarter.com/blog/introducing-advanced-search) features for web, the [Android 1.0](https://www.kickstarter.com/blog/announcing-kickstarter-for-android), and finally the iOS 3.0 app written in Swift, which was eventually [open sourced](https://kickstarter.engineering/open-sourcing-our-android-and-ios-apps-6891be909fcd).

I also managed a team of engineers with a focus on mentoring and career development. Management to me was a means to improve developer happiness by teaching others how to use concepts that improve expressivity and testability in their code. I worked with engineers from a variety of backgrounds and experience levels, and by the end of my time we were a unified team speaking the same language, regardless of platform or programming language. Some of the tools I advocated for include:

#### **Functional Programming**

The main driving force behind my work at Kickstarter has been centered on functional programming. By embracing pure functions as much as possible, and pushing side-effects to the boundary of your application, one is forced to write code in a way that carries with it many benefits. Writing code in this way is a departure from how most learn at first, so there was a lot of time spent teaching and pairing with engineers as we built up the skills.

#### **Testing**

The first benefit we got from embracing functional programming was testability. The most testable unit in any code base is a pure function: feed it some data and then make assertions on its output. Writing tests can often be seen as a chore, but when code is easy to test it becomes an isolated laboratory to experiment with your ideas. I gave a [talk](https://news.realm.io/news/try-swift-brandon-williams-writing-testable-code/) on what it means to write testable code, and using these ideas we completely transformed the way we think about writing code at Kickstarter.

#### **Playgrounds**

The next benefit was the ability to use playgrounds for development. If your code is written in a functional style, with all side-effects removed and all dependencies fully specified, an amazing thing happens where you can recreate any screen of your app in total isolation in a playground. You can then iterate on designs or plug in edge-case data to try to find subtle problems in your UI. I talked about our use of playgrounds in a [talk](https://youtu.be/A0VaIKK2ijM?t=26m43s) I gave in Budapest, and then later talked about the specifics of how to implement the ideas in a [Swift Talk episode](https://talk.objc.io/episodes/S01E51-playground-driven-development-at-kickstarter).

#### **Screenshot Testing**

After having spent a lot of time investing in playgrounds as means of speeding up development, we soon realized we could automate a lot of that work by using screenshot testing. Here the focus is on a static snapshot of a view as proof of what an interface is supposed to look like. We used these extensively, generating over [700 of them](https://github.com/kickstarter/ios-oss/tree/4aa72525007e184a4ce798756b4461e0c6cfb217/Screenshots/_64), covering nearly every screen, every language we supported (English, Spanish, French, German), every device we were interested in (usually iPhone 4.7" and iPad), and many times multiple device orientations. These screenshots allowed our junior engineers to touch areas of the code base they were not familiar with without fear, and allowed us to better communicate with our designer to show off all the subtle edge-cases she was worried about.

#### **Swift & Kotlin**

One of the more surprising benefits to pop-up from all of our work on functional programming was that it allowed us to share knowledge with colleagues, even across platforms and language. We became a team of engineers that could contribute to iOS just as effectively as Android, and we could all learn from each other, regardless of platform. I’ve talked extensively about these ideas, both in my [Finding Happiness in Functional Programming talk](https://www.youtube.com/watch?v=A0VaIKK2ijM), and a joint talk I gave with my former colleague [Lisa Luo](http://www.twitter.com/luoser) called [Anything You Can Do I Can Do Better](https://www.youtube.com/watch?v=_DuGaAkQSnM).


<br>

---

<br>




## Other contributions

# Functional Swift Conference

Since 2014 I have co-organized the [Functional Swift Conference](http://www.funswiftconf.com) with [Chris Eidhof](http://www.twitter.com/chriseidhof), and so far we have put on four free, full-day events ([2014](http://2014.funswiftconf.com), [2015](http://2015.funswiftconf.com), [2016](http://2016.funswiftconf.com), [2017](http://2017.funswiftconf.com)). This is the only conference of its kind, dedicated to functional programming and the Swift programming language, and the [videos](https://www.youtube.com/channel/UCNFUO_7gsLBk4YTmZoSTk5g) have collectively received more than 100,000 views.

# Talks

I’ve given [talks](/talks) on a variety of topics over the years, but all of them share a foundation of functional programming. Everything from using compilers to prove mathematical theorems to using functional programming as a base language for sharing knowledge between different platforms.

* [Anything you can do, I can do better](https://www.youtube.com/watch?v=_DuGaAkQSnM)
* [Monoids, Predicates and Sorting Functions](https://www.youtube.com/watch?v=VFPhPOnPiTY)
* [The Two Sides of Writing Testable Code](https://news.realm.io/news/try-swift-brandon-williams-writing-testable-code/)
* [Finding Happiness in Functional Programming](https://www.youtube.com/watch?v=A0VaIKK2ijM)
* [Lenses in Swift](https://www.youtube.com/watch?v=ofjehH9f-CU)
* [Proof in Functions](https://vimeo.com/121953811)
* [Functional Programming in a Playground](https://www.youtube.com/watch?v=estNbh2TF3E)

# Swift Talks

After we [open sourced](https://kickstarter.engineering/open-sourcing-our-android-and-ios-apps-6891be909fcd) the iOS and Android app code bases at Kickstarter,
[Chris Eidhof](http://www.twitter.com/chriseidhof) and [Florian Kugler](http://www.twitter.com/floriankugler) (of [objc.io](http://www.objc.io) fame) invited me to record a few guest appearances on their [Swift Talk](https://talk.objc.io) series. We ended up recording four episodes: three with me and one with my former colleague [Lisa Luo](http://www.twitter.com/luoser).

* [View Models at Kickstarter](https://talk.objc.io/episodes/S01E47-view-models-at-kickstarter)
* [Deep Linking at Kickstarter](https://talk.objc.io/episodes/S01E49-deep-linking-at-kickstarter)
* [Playground-Driven Development at Kickstarter](https://talk.objc.io/episodes/S01E51-playground-driven-development-at-kickstarter)

# Writings

I have written extensively on this [site](/) on topics of math and functional programming, and how they lead to very expressive constructs. I also wrote a few articles for the Kickstarter engineering blog:

* [Open sourcing our Android and iOS apps!](https://kickstarter.engineering/open-sourcing-our-android-and-ios-apps-6891be909fcd)
* [Why you should co-locate your Xcode tests](https://kickstarter.engineering/why-you-should-co-locate-your-xcode-tests-c69f79211411)
