// Simple numbering for non-book documents
#let equation-numbering = "(1)"
#let callout-numbering = "1"
#let subfloat-numbering(n-super, subfloat-idx) = {
  numbering("1a", n-super, subfloat-idx)
}

// Theorem configuration for theorion
// Simple numbering for non-book documents (no heading inheritance)
#let theorem-inherited-levels = 0

// Theorem numbering format (can be overridden by extensions for appendix support)
// This function returns the numbering pattern to use
#let theorem-numbering(loc) = "1.1"

// Default theorem render function
#let theorem-render(prefix: none, title: "", full-title: auto, body) = {
  if full-title != "" and full-title != auto and full-title != none {
    strong[#full-title.]
    h(0.5em)
  }
  body
}
// Some definitions presupposed by pandoc's typst output.
#let content-to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms.item: it => block(breakable: false)[
  #text(weight: "bold")[#it.term]
  #block(inset: (left: 1.5em, top: -0.4em))[#it.description]
]

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let fields = old_block.fields()
  let _ = fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => {
          let subfloat-idx = quartosubfloatcounter.get().first() + 1
          subfloat-numbering(n-super, subfloat-idx)
        })
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => block({
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          })

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let children = old_title_block.body.body.children
  let old_title = if children.len() == 1 {
    children.at(0)  // no icon: title at index 0
  } else {
    children.at(1)  // with icon: title at index 1
  }

  // TODO use custom separator if available
  // Use the figure's counter display which handles chapter-based numbering
  // (when numbering is a function that includes the heading counter)
  let callout_num = it.counter.display(it.numbering)
  let new_title = if empty(old_title) {
    [#kind #callout_num]
  } else {
    [#kind #callout_num: #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block,
    block_with_new_content(
      old_title_block.body,
      if children.len() == 1 {
        new_title  // no icon: just the title
      } else {
        children.at(0) + new_title  // with icon: preserve icon block + new title
      }))

  align(left, block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1)))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color,
        width: 100%,
        inset: 8pt)[#if icon != none [#text(icon_color, weight: 900)[#icon] ]#title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



#let posit_colors = (
  blue: rgb("#447099"),
  grey: rgb("#404041"),
  dark_blue_3: rgb("#17212B"),
  light_blue_1: rgb("#D1DBE5"),
  light_blue_2: rgb("#A2B8CB")
)

#let hex_background={
  image("assets/images/hexes-8.5x11-#17212B.png", height: 100%, fit: "cover")
} 

//  Pages with a blue background
#let page_blue(content)={
    set page(background: hex_background)
    set text(fill: posit_colors.light_blue_1)
    show link: set text(fill: posit_colors.light_blue_2)
    show heading: set text(fill: posit_colors.light_blue_2)
    show heading.where(level: 1): it => {
      pagebreak()  
      it
    }
    content
  }

#let col-2(content)={
    columns(2, gutter: 3em, content)
} 

//   Custom title page
#let title_page(title, subtitle)={
    page(margin: 0in,
        background: image("assets/images/COVER-1-POSIT24 Seattle_Nick Klein Photography-927.jpg", height: 100%, fit: "cover"))[
        #set text(fill: white)

        #place(center + horizon, dy: -2.5in)[
            #set align(center + horizon)
            #block(width: 100%, fill: posit_colors.dark_blue_3, outset: 5em)[
                #text(weight: "light", size: 36pt, title)

                #text(weight: "bold", size: 24pt, subtitle)
            ]
        ]
        #place(center + bottom, dy: -40pt)[
          #block(height: 40pt)[
            #image("assets/images/Posit-PBC-lockup-white.svg")
          ]
        ]
    ]
}

#let back_page(repo: none, content)={
  page_blue()[
      #set page(background: hex_background, numbering: none)
      #set text(fill: white)
      #show link: set text(fill: white)
      #show par: set block(spacing: 0.5em)
      #place(bottom + center)[
        #block(height: 56pt)[
                  #image("assets/images/Posit-PBC-lockup-white.svg")
                ]
        
        The open source data science company

        #text(size: 24pt, link("http://posit.co/")[posit.co])
        #v(2em)
        #set text(size: 10pt)
        
        #(content)

        Published with #box(height: 12pt, baseline: 20% , image("assets/images/quarto-logo-trademark-white.svg"))
        
        #if repo != none {
          [Source code available at #link(repo)]
        }
        ]
      ]
}

// Page with image in header
#let page_banner(image_paths: none, image_height: 100%, image_location: right + horizon, fill: posit_colors.light_blue_1, content)={
  set page(
    margin: (top: 2in),
    header: [
      #set text(fill: white)
      #block(width: 100%, height: 100%, outset: (x: 1.25in), inset: (y: 2em), fill: fill)[
        #if (image_paths != none){
          set image(height: image_height)
          place(image_location, stack(dir: ltr, ..image_paths.map(image)))
        }
      ]
    ]
  )
  content
}

#let posit(
  title: none,
  subtitle: none,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 10pt,
  doc,
) = {
  
  set page(
    paper: paper,
    margin: margin,
    numbering: none,
  )

  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize,
           fill: posit_colors.grey)


  set par(
    leading: 0.8em
  )
  
  // Booktabs-style tables: bold header, horizontal rules only above and
  // below the header row and below the final row (no interior or vertical
  // lines). The stroke function draws the top rule and the header rule; the
  // show rule wraps the table to add the closing rule below the last row.
  set table(
    align: left,
    inset: 7pt,
    stroke: (x, y) => (
      top: if y == 0 { 1pt } else if y == 1 { 0.5pt } else { 0pt },
    ),
  )
  show table.cell.where(y: 0): strong
  show table: it => block(stroke: (bottom: 1pt), it)

  if title != none {
    title_page(title, subtitle)
  }

  show heading.where(level: 1): set text(weight: "light", size: 24pt)
  show heading.where(level: 1): set block(width: 100%, below: 1em)
  
  show heading.where(level: 2): it => {
    set block(below: 1.5em)
    upper(it)
  }

  show link: underline
  show link: set underline(stroke: 1pt, offset: 2pt)
  show link: set text(fill: posit_colors.blue)

  block(above: 0em, below: 2em)[
    #outline(
      indent: 1.5em
    );
  ]

  set page(numbering: "1")

  doc
}

#let brand-color = (:)
#let brand-color-background = (:)
#let brand-logo = (:)

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
  columns: 1,
)

#show: doc => posit(
  title: [Posit Benefit Corporation],
  subtitle: [DRAFT 2026 Annual Report],
  font: ("Open Sans",),
  doc,
)

#page_blue()[
#counter(page).update(1)
= A Message from our Founder & CEO
<a-message-from-our-founder-ceo>
#col-2()[
Posit aims to create free and open-source software for data science, scientific research, and technical communication in a sustainable way, because it benefits everyone when the essential tools to produce and consume knowledge are available to all, regardless of economic means.

We believe corporations should fulfill a purposeful benefit to the public and be run for the benefit of all stakeholders including employees, customers, and the larger community.

As a Delaware Public Benefit Corporation (PBC) and a Certified B Corporation®, Posit's open-source mission and commitment to a beneficial public purpose are codified in our charter, requiring our corporate decisions to balance the interests of the community, customers, employees, and shareholders.

B Corps#super[TM] meet the highest verified standards of social and environmental performance, transparency, and accountability. Posit measures its public benefit by utilizing the non-profit B Lab®'s "Impact Assessment", a rigorous assessment of a company's impact on its workers, customers, community, and environment.

#colbreak()
In 2019, Posit (then RStudio) met the B Corporation certification requirements set by the B Lab. In 2023, our certification was renewed, and we are proud to share that our B Lab Impact Assessment score rose from 86.1 to 92.5 with this renewal. The B Lab certification process uses credible, comprehensive, transparent, and independent standards to measure social and environmental performance. Details of these assessments can be found on our #link("https://www.bcorporation.net/en-us/find-a-b-corp/company/rstudio/")[B Lab company page].

To fulfill its beneficial purposes, Posit intends to remain an independent company over the long term. With the support of our customers, employees, and the community, we remain excited to contribute useful solutions to the important problems of knowledge they face.

#place(right, dy: 3em)[
#emph[J.J. Allaire] \
Founder & Executive Chair, Posit PBC

#emph[Tareef Kawaf] \
President & CEO, Posit PBC

]
]
]
= Introduction
<introduction>
#col-2()[
Posit's mission is to create free and open-source software for data science, scientific research, and technical communication. We do this to enhance the production and consumption of knowledge by everyone, regardless of economic means, and to facilitate collaboration and reproducible research, both of which are critical to the integrity and efficacy of work in science, education, government, and industry.

In addition to our open source products, Posit produces a modular platform of commercial software products that enable teams to adopt R, Python, and other open-source data science software at scale. Posit also offers online services that make it easier to learn and use data science tools over the web.

Together, Posit's open-source software and commercial software form a virtuous cycle. In most companies, a "customer" is someone who pays you. For us, a "customer" must include the open source community, with whom we exchange the currencies of attention, respect, and love. When we deliver value to our open source users, they will likely bring our software into their professional environments, which opens up the possibility of commercial partnerships. To keep this cycle flowing, our open source developers must know and care about the integrations with proprietary solutions that matter to our enterprise customers. #colbreak() It also means that Posit's commercial teams consistently provide value to individuals who may never directly spend a dollar with us.

Posit's approach is not typical. Traditionally, scientific and technical computing companies create exclusively proprietary software. While it can provide a robust foundation for investing in product development, proprietary software can also create excessive dependency that is not good for data science practitioners and the community. In contrast, Posit provides core productivity tools, packages, protocols, and file formats as open-source software so customers aren't overly dependent on a single software vendor. Additionally, while our commercial products enhance the development and use of our open-source software, they are not fundamentally required for those without the need or the ability to pay for them.

As of December 2024, Posit is spending \~35% of its engineering resources on open-source software development, and is leading contributions to over 350 open-source projects. Posit-led projects targeted a broad range of areas including the RStudio IDE; infrastructure libraries for R and Python; numerous packages and tools to streamline data manipulation, exploration and visualization, modeling, and machine learning; and integration with external data sources. Posit also sponsors or contributes to many open-source and community projects led by others, including NumFOCUS, the R Consortium, the Python Software Foundation, DuckDB, Pandoc, pyodide, and ProseMirror, as well as dozens of smaller projects via the Open Source Collective or directly on Github. Additional information about our products and company contributions can be found in our #link("https://posit.co/blog/?search=year%2520in%2520review&post_tag=year-in-review")["Year In Review" blog posts].

#colbreak()
Today, millions of people download and use Posit open-source products in their daily lives. Additionally, more than 10,000 customers that purchase our professional products help us sustain and grow our mission. It is inspiring to help so many people participate in global economies that increasingly reward data literacy, and know that our tools help produce insights essential to navigating our complex world.

]
#place(bottom, dy: 1.25in,
  align(center, 
    image("assets/images/INTERNAL-2-POSIT24 Seattle_Nick Klein Photography-341.jpg", 
      width: 100% + 2.5in, fit: "cover")
  )
)
#pagebreak()
= Posit's Charter and Statement of Public Benefit
<posits-charter-and-statement-of-public-benefit>
#col-2()[
== Posit's Charter
<posits-charter>
We want Posit to serve a meaningful public purpose, and we run the company for the benefit of our customers, employees, and the community at large. That's why we're organized as a Public Benefit Corporation (PBC).

What makes a PBC different from other types of corporations?

#quote(block: true)[
#emph["A 'public benefit corporation' is a for-profit corporation organized under and subject to the requirements of this chapter that is intended to produce a public benefit or public benefits and to operate in a responsible and sustainable manner."] --- #link("https://delcode.delaware.gov/title8/c001/sc15/")[Delaware Public Benefit Corporations Law]
]

As a PBC and Certified B Corporation, we must meet the highest verified standards of social and environmental performance, transparency, and accountability. Our directors and officers have a fiduciary responsibility to address social, economic, and environmental needs while still overseeing our business goals.

#colbreak()
== Posit's Statement of Public Benefit
<posits-statement-of-public-benefit>
Creation of free and open source software for data science, scientific research, and technical communication:

#quote(block: true)[
1) To enhance the production and consumption of knowledge by everyone, regardless of economic means.

2) To facilitate collaboration and reproducible research, both of which are critical for ensuring the integrity and efficacy of scientific work.
]

]
#pagebreak()
== Our primary obligations as a PBC and Certified B Corporation
<our-primary-obligations-as-a-pbc-and-certified-b-corporation>
#col-2()[
=== Public Benefit Corporation
<public-benefit-corporation>
#emph[How we built our company charter]

- The board of directors shall manage or direct the business and affairs of the public benefit corporation in a manner that balances the pecuniary interests of the stockholders, the best interests of those materially affected by the corporation's conduct, and the specific public benefit or public benefits identified in its certificate of incorporation.

- A public benefit corporation shall no less than biennially provide its stockholders with a statement as to the corporation's promotion of the public benefit or public benefits identified in the certificate of incorporation and of the best interests of those materially affected by the corporation's conduct.

#colbreak()
=== Certified B Corp
<certified-b-corp>
#emph[How we hold ourselves accountable to our charter]

- Demonstrate high social and environmental performance by achieving a B Lab Impact Assessment score of 80 or above and passing the risk review.

- Make a legal commitment by changing our corporate governance structure to be accountable to all stakeholders, not just shareholders, and achieve benefit corporation status if available in our jurisdiction.

- Exhibit transparency by allowing information about our performance measured against B Lab's standards to be publicly available on our B Corp profile on B Lab's website.

]
#pagebreak()
= Free and Open Source Software and Tools
<free-and-open-source-software-and-tools>
#col-2()[
In 2022 and earlier, when Posit was called RStudio, we were often thought of as an "R company" because of our dedication to developing and maintaining some of the most used R packages in the world. But Posit has always been better described as a #emph[scientific software] company: supporting Python (via the #link("https://github.com/rstudio/reticulate")[reticulate] package, RStudio language support), working with relational databases and data platforms such as Apache Spark (a cross-platform data frame compatibility via #link("https://github.com/apache/arrow")[feather/Apache Arrow]), and much more mean that we've never been solely an "R company".

#colbreak()
More recently, we have developed explicitly cross-language tools like Quarto and Positron, and developed Python packages like Great Tables, chatlas, and orbital.

The following subsections highlight selected Posit software projects of interest to the broader data science community. Where metrics are published, please note these represent a #emph[lower bound] on the actual number, as it is difficult-to-impossible to account for every install and usage in the world.

]
#place(bottom, dy: 1.25in,
  align(center, 
    box(
      image("assets/images/INTERNAL-1-POSIT24 Seattle_Nick Klein Photography-86.jpg", fit: "cover"), 
      width: 100% + 2.5in, clip: true, inset: (top: -1in)
    )
  )
)
#pagebreak()
#page_banner(
image_paths:("assets/images/quarto-logo-dark.svg",),
image_height:50%,
[
== Quarto
<quarto>
#col-2()[
In July 2022, #link("https://posit.co/blog/announcing-quarto-a-new-scientific-and-technical-publishing-system/")[Posit announced] the #link("https://quarto.org/")[Quarto] project, an open-source scientific and technical publishing system as a successor to the #link("https://rmarkdown.rstudio.com/")[R Markdown] library. While Quarto incorporates the lessons learned from over 10 years of developing R Markdown into an entirely new project, it's likely still quite familiar to users of R Markdown as they share two core dependencies: Knitr and Pandoc. In fact, despite the fact that Quarto does some things differently, most existing R Markdown documents can be rendered unmodified using Quarto.

#colbreak()
Quarto allows users to choose from multiple computational engines (Knitr, Jupyter, and Observable), which makes it easy to use Quarto with R, Python, Julia, JavaScript and many other languages. It also allows users to author documents as plain text markdown or Jupyter Notebooks, and publish to numerous outputs such as HTML, PDF, MS Word, ePub and more, and for the community to develop its own extensions.

There are 4 full time equivalent (FTE) employees developing open-source Quarto products as of May 2025.

]
#box(image("images/generate-plots_files/figure-typst/quarto-1.svg"))

])

#page_banner(
image_paths:("assets/images/shiny-logo.png",),
image_height:50%,
[
== Shiny
<shiny>
#col-2()[
Shiny has been a mainstay in the R community since its launch in 2012, providing a web application framework that makes it easy to tell data stories in interactive point-and-click web applications. In April 2023, Posit released the Python version of Shiny, bringing the same great reactive programming model and modular design to the PyData ecosystem. \
More recently, the #link("https://shiny.posit.co/py/docs/express-in-depth.html")[Shiny Express] syntax was introduced, offering streamlined syntax that makes it easier for Python developers to get started with Shiny.

#colbreak()
New packages (see #link(<ai-and-llm-enablement>)[AI and LLM Enablement]) also highlight Shiny as a strong platform for building chat-based and other LLM-powered apps.

Shiny applications can be shared with others via an open-source #link("https://posit.co/products/open-source/shinyserver/")[Shiny Server], the hosted #link("http://shinyapps.io")[shinyapps.io] service, with #link("https://connect.posit.cloud/")[Posit Connect Cloud] or #link("https://posit.co/products/enterprise/connect/")[Posit Connect]. Shiny and related packages include shiny (#link("https://shiny.posit.co/py/")[Python], #link("https://shiny.posit.co/r/getstarted")[R]), #link("https://rstudio.github.io/bslib/")[bslib], #link("https://rstudio.github.io/shinytest/")[shinytest], #link("https://rstudio.github.io/shinyloadtest/")[shinyloadtest], #link("https://rstudio.github.io/shinydashboard/")[shinydashboard], #link("https://rstudio.github.io/leaflet/")[leaflet], and #link("https://rstudio.github.io/crosstalk/")[crosstalk].

There are 5 FTE Posit employees developing the open-source Shiny and Shiny Server products as of May 2025.

]
#box(image("images/generate-plots_files/figure-typst/shiny-1.svg")) #box(image("images/generate-plots_files/figure-typst/shiny-2.svg"))

])

#pagebreak()
#page_banner(
image_paths:("assets/images/hexes/ellmer.svg", "assets/images/hexes/chatlas.png", "assets/images/hexes/ragnar.png", "assets/images/hexes/gander-lores.png", "assets/images/hexes/mall.png"),
[
== AI and LLM Enablement
<ai-and-llm-enablement>
#col-2()[
Large language models (LLMs) are changing how data scientists work. Posit's Open Source teams are building tools to help data scientists responsibly use LLMs in their analysis, leverage them during development, and incorporate LLM capabilities in the solutions they provide others.

#heading(level: 3, outlined: false)[Packages to enable LLMs in data science]
<packages-to-enable-llms-in-data-science>
- #link("https://ellmer.tidyverse.org/")[ellmer] makes it easy to use large language models (LLM) from R. It supports a variety of LLM providers and implements a rich set of features including streaming outputs, tool/function calling and structured data extraction.
- #link("https://posit.co/blog/announcing-chatlas/")[chatlas] is a flexible Python interface to many LLM providers (playing a similar role to ellmer). It supports tool use, function calling, and streaming responses.
- #link("https://ragnar.tidyverse.org")[ragnar] brings Retrieval-Augmented Generation (RAG) to R. Helps users index their own data and get LLM responses with grounded answers.
- #link("https://github.com/posit-dev/querychat")[querychat] adds an SQL-powered LLM to Shiny apps. It lets users explore data with natural language. Querychat works in both R and Python.

#colbreak()
#heading(level: 3, outlined: false)[Selection of packages that assist during development]
<selection-of-packages-that-assist-during-development>
- #link("https://shiny.posit.co/blog/posts/shiny-assistant/")[Shiny Assistant] helps prototype Shiny apps using a simple chat interface leveraging LLMs to generate entire applications.
- #link("https://posit.co/blog/introducing-gander/")[gander] is a coding assistant that understands R environments and shares context like column names and types to improve help quality.
- #link("https://posit.co/blog/introducing-chores/")[chores] connects Ellmer to your source editor in RStudio and Positron. It automates repetitive programming tasks.
- #link("https://posit.co/blog/mall-ai-powered-text-analysis/")[mall] enables LLM powered sentiment analysis, text summarization, text classification, information extraction and text translation. Mall is available for both R and Python.

LLMs are also integrated as coding assistants into RStudio and Positron. Positron is Posit's new IDE described in the #link(<positron>)[Positron] section below.

As of May 2025, 4 FTE Posit employees are working \
on open-source tools related to LLMs.

]
])

#page_banner(
image_paths:("assets/images/hexes/gt.svg",),
[
== gt / Great Tables
<gt-great-tables>
#col-2()[
When presenting an analysis, a table can often convey the results more concisely than the most beautiful and interactive of charts. However, the experience of creating and displaying tables in R and Python has been mixed, especially when you want to display something beyond a plain data frame representation.

#colbreak()
To that end, the #link("https://gt.rstudio.com/")[gt] and #link("https://posit-dev.github.io/great-tables/articles/intro.html")[Great Tables] packages have defined a "grammar of tables" to solve this problem (in R and Python, respectively), analogous to the "grammar of graphics" for specifying charts.

As of May 2025, there is 1 FTE Posit employee developing gt / Great Tables open-source packages.

]
#box(image("images/generate-plots_files/figure-typst/gt-1.svg")) #box(image("images/generate-plots_files/figure-typst/gt-2.svg"))

])

#page_banner(
image_paths:("assets/images/hexes/plotnine.png",),
[
== Plotnine
<plotnine>
#col-2()[
#link("https://plotnine.org/")[Plotnine] is an implementation of the grammar of graphics in Python, heavily influenced by ggplot2 in R. Built upon the ubiquitous #link("https://matplotlib.org/")[matplotlib] plotting library, #colbreak() custom (and otherwise complex) plots are easy to reason about and build incrementally, while the simple plots remain simple to create.

]
#box(image("images/generate-plots_files/figure-typst/plotnine-1.svg"))

])

#page_banner(
image_paths:("assets/images/hexes/pins.svg",),
[
== Pins
<pins>
#col-2()[
Pins (for #link("https://pins.rstudio.com/")[R] and #link("https://rstudio.github.io/pins-python/")[python]) publish data, models, and other objects, making them easy to share across projects and with other. Users can pin objects to a variety of pin boards, including folders (to share on a networked drive or with services like DropBox), Posit Connect, Amazon S3, and Google Cloud Storage.

#colbreak()
Pins can be automatically versioned, making it straightforward to track changes, re-run analyses on historical data, and undo mistakes.

]
#box(image("images/generate-plots_files/figure-typst/pins-1.svg")) #box(image("images/generate-plots_files/figure-typst/pins-2.svg"))

])

#page_banner(
image_paths:("assets/images/hexes/vetiver.svg",),
[
== Vetiver
<vetiver>
#col-2()[
#link("https://vetiver.posit.co/")[Vetiver] solves the issues around versioning, sharing, deploying and monitoring predictive models served via APIs. Available for both R and Python, vetiver is extensible via generics that support many common types of models. #colbreak() Vetiver also provides the "model cards" functionality, which can help to generate documentation by extracting information about the generated model.

]
#box(image("images/generate-plots_files/figure-typst/vetiver-1.svg")) #box(image("images/generate-plots_files/figure-typst/vetiver-2.svg"))

])

#page_banner(
image_paths:("assets/images/hexes/orbital.png","assets/images/hexes/webr.svg"),
[
#col-2()[
== Orbital
<orbital>
#link("https://github.com/posit-dev/orbital")[Orbital] lets you run machine learning models inside your database. Originally an #link("https://orbital.tidymodels.org/articles/orbital.html")[R package], it now also supports Python. In Python, orbital converts scikit-learn models into SQL, so they can run directly in a database like Snowflake---no Python environment needed. \
The performance gains this approach has provided is quite significant.

#colbreak()
== webR
<webr>
#link("https://docs.r-wasm.org/webr/latest/")[WebR] has the ambitious goal of bringing the R language to the browser, removing the need for a backend server for computation. It also allows for computation to be done on the client machine, supporting use cases that are infeasible or undesirable for using server-side processing (such as not wanting to send personal data over the internet). Also, by making the most of the user's device capabilities, webR can improve performance and lower app hosting costs.

There is 1 FTE Posit employee developing enterprise focused open-source products like orbital as of May 2025.

]
])

#page_banner(
image_paths:("assets/images/hexes/tidyverse.svg", ),
[
== Tidyverse
<tidyverse>
#col-2()[
The #link("https://www.tidyverse.org/")[tidyverse] is an opinionated collection of R packages designed for data science. All packages share an underlying design philosophy, grammar and data structures.

The tidyverse consists of nine core packages (including ggplot2, tidyr and readr) and 31 packages overall.

#colbreak()
There are 9 FTE Posit employees developing Tidyverse and related open-source products as of May 2025.

]
#box(image("images/generate-plots_files/figure-typst/tidyverse-1.svg"))

])

#page_banner(
image_paths:("assets/images/hexes/tidymodels.svg", ),
[
== Tidymodels
<tidymodels>
#col-2()[
#link("https://www.tidymodels.org/")[tidymodels] is a cohesive collection of packages that perform tasks relevant to statistical modeling and machine learning. Tidymodels packages share a common syntax and design philosophy, and are designed to work seamlessly with Tidyverse packages.

#colbreak()
There are currently 42 tidymodels packages on CRAN. Popular tidymodels packages include parsnip, rsample, recipes, tune and yardstick.

There are 3 FTE Posit employees developing Tidymodels and related open-source products as of May 2025.

]
#box(image("images/generate-plots_files/figure-typst/tidymodels-1.svg"))

])

#page_banner(
image_paths:("assets/images/hexes/sparklyr.svg", "assets/images/hexes/reticulate.svg", "assets/images/hexes/tensorflow.svg"),
[
== Connectivity Packages
<connectivity-packages>
#col-2()[
Posit increases the efficiency of customers by making open-source packages that connect data scientists to spreadsheets, databases, distributed storage frameworks for big data, machine learning platforms, and the programming environments of other languages, like python.

#colbreak()
Connectivity packages include: #link("https://spark.posit.co/")[sparklyr], #link("https://tensorflow.rstudio.com/")[tensorflow for R], #link("https://keras.posit.co/")[keras], #link("https://solutions.posit.co/connections/db/r-packages/odbc/")[odbc], and #link("https://rstudio.github.io/reticulate/")[reticulate].

There are 3 FTE Posit employees creating connectivity-related open-source packages as of May 2025.

]
#box(image("images/generate-plots_files/figure-typst/connectivity-1.svg"))

])

#page_banner(
image_paths:("assets/images/hexes/devtools.svg","assets/images/hexes/usethis.svg", "assets/images/hexes/roxygen2.svg", "assets/images/hexes/testthat.svg", "assets/images/hexes/pkgdown.svg"),
[
== R Infrastructure Tools (r-lib)
<r-infrastructure-tools-r-lib>
#col-2()[
R-lib is a large collection of R packages that make it easier to build, find, and use effective tools for data analysis.

#colbreak()
There are currently 114 R-lib packages. Popular packages include #link("https://devtools.r-lib.org/")[devtools], #link("https://testthat.r-lib.org/")[testthat], #link("https://roxygen2.r-lib.org/")[roxygen2], #link("https://pkgdown.r-lib.org/")[pkgdown] and #link("https://usethis.r-lib.org/")[usethis].

]
#box(image("images/generate-plots_files/figure-typst/rlibs-1.svg"))

])

#page_banner(
image_paths:("assets/images/hexes/RStudio.svg",),
[
== RStudio Integrated Development Environment
<rstudio-integrated-development-environment>
#col-2()[
#link("https://posit.co/products/open-source/rstudio/")[RStudio] is a multi-language IDE designed for Data Science with R and Python. It augments the standard code console with an editor that can display Notebooks, launch apps, highlight code syntax, spot code errors, and directly execute code. Built into the IDE are tools for debugging, plotting, browsing files, and managing project histories and workspaces. Together these tools make data scientists and developers much more efficient.

#colbreak()
There are 5 FTE Posit employees developing the RStudio IDE open-source desktop and server products as of May 2025.

]
#box(image("images/generate-plots_files/figure-typst/rstudio-1.svg"))

])

#pagebreak()
#page_banner(
image_paths:("assets/images/hexes/positron.png",),
image_height:50%,
[
== Positron
<positron>
#col-2()[
#link("https://positron.posit.co//")[Positron] is a new multi-language IDE designed for Data Science. Positron has first-class, built-in support for R and Python via an integrated console, with extensibility options for other languages. This native support includes specialized views and panes throughout Positron such as a #link("https://positron.posit.co/data-explorer.html")[Data Explorer], #link("https://positron.posit.co/connections-pane.html")[Connections Pane], Variables Pane, access to AI/LLM driven data assistants and more.

Positron separates the language interpreter from the IDE itself, which makes it more robust during development---if R or Python encounters an error, the IDE remains unaffected. This architecture also allows a user to switch between different versions of their preferred language without needing to reload the entire IDE.

Positron is built on #link("https://github.com/microsoft/vscode")[Code OSS] and supports VS Code compatible extensions (.vsix files), providing extensibility of capabilities beyond the core IDE itself. By building on Code OSS, Positron gets rich text editor capabilities and access to 1,000s of community extensions out of the box.

#colbreak()
Additional languages typically used in package development are supported via existing third party extensions. These don't make use of the full Positron data science experience including an interactive console, plots, and similar. Some examples include Rust, Javascript/Typescript, C/C++, or Lua.

Positron™ is licensed under the #link("https://github.com/posit-dev/positron?tab=License-1-ov-file#readme")[Elastic License 2.0], a source-available license. #link("https://positron.posit.co/licensing.html")[Read more] about what this license means and our decision to use it.

Positron is deeply focused on native data science workflows; it provides a batteries-included and cohesive experience beyond that of a general-purpose IDE or text editor such as VS Code.

A beta version is currently available for Windows and macOS, with a full release planned for August 2025.

There are 14 FTE Posit employees developing Positron as of May 2025.

]
])

#page_banner(
image_paths:("assets/images/hexes/package-manager.svg",),
[
== Posit Public Package Manager
<posit-public-package-manager>
#col-2()[
With the ubiquity of open source software in our daily lives, one area that most people don't think about is 'How do you distribute that software quickly and securely to the end user?'. To that end, Posit created #link("https://posit.co/products/enterprise/package-manager/")[Posit Package Manager], which gives companies a means for providing curated repositories, repository snapshots for better reproducibility, the ability to air-gap the repository for enhanced security and much more.

#colbreak()
As part of our commitment to improving the quality and availability of open source software for all, Posit hosts a public instance of Posit Package Manager called #link("https://packagemanager.posit.co/client/#/")[Posit Public Package Manager] that mirrors CRAN, PyPI and Bioconductor. This mirror serves over 46 million downloads per month (as of Q1 2025).

]
])

#page_banner(
fill:posit_colors.blue,
image_paths:("assets/images/BLab_B_Impact_Assessment-white.png",),
image_height:75%,
[
= B Lab® Impact Assessment Results
<b-lab-impact-assessment-results>
#col-2()[
The B Lab's Version 1.6 Impact Assessment is composed of questions in five Impact Areas: Governance, Workers, Community, Environment, and Customers. Posit's assessment results are available to the public #link("https://www.bcorporation.net/en-us/find-a-b-corp/company/rstudio/")[here]. We completed our first Impact Assessment in 2019 and earned an overall score of #strong[86.1.] We completed our first recertification in 2023 and earned a score of #strong[92.5]. To put this in context, the threshold for B Lab certification is a score of 80 or higher, and the median score for ordinary businesses who take the assessment is 50.9. Posit seeks to continually improve our internal governance, increase our workforce diversity and employee development efforts, offset our carbon emissions, deepen our engagement in our communities, and better serve our customers so that our public benefit will continue to improve each year.

#colbreak()
In our initial assessments, we received high marks for incorporating as a benefit corporation, the health, wellness, safety, and financial security of our employees, and for educating and serving customers.

== Summary of 2023 Score
<summary-of-2023-score>
#table(
  columns: 2,
  align: (left,right,),
  table.header([Impact Area], [Score],),
  table.hline(),
  [Governance], [17.7],
  [Workers], [32.5],
  [Community], [15.4],
  [Environment], [4.4],
  [Customers], [22.4],
)
]
])

#col-2()[
== Community
<community>
=== Civic Engagement and Giving
<civic-engagement-and-giving>
In addition to the open-source software we make freely available, and the open source data science package development produced by Posit engineers, Posit recognizes the importance of contributing financially to other valuable open-source and community initiatives. To date, Posit has given over \$3.3M to projects led by others. Current commitments include contributing to NumFOCUS, the R Consortium, the R Foundation, DuckDB, the Eclipse Foundation, and the authors and maintainers of several other open-source projects.

Posit's financial support also extends beyond the world of open source data science. Since 2020, Posit and its employees have given over \$107k to over 220 nonprofits. Our donations reach a range of community-based causes, including organizations dedicated to racial equality, equal justice, LGBTQ+ support, and access to education. Alongside our donations to open source software development, this pool of charitable contributions contributes to the important work many are doing to increase the accessibility of data science for all. Our scoring in this area of the B Lab assessment has increased by 39.5% since 2019.

=== Diversity, Equity, and Inclusion
<diversity-equity-and-inclusion>
Posit continues to focus on increasing the strength of our team by utilizing talent practices that encourage diverse people to apply, join, and thrive at Posit. Specific changes made in recent years include the formation of a diversity, equity, inclusion, and accessibility council (DEIA Council), as well as the sponsoring of employee resource groups (ERGs). We also pay close attention to issues of equity in compensation, hiring and interviewing, and employee experience.

== Customers
<customers>
We have made meaningful improvements in our care for customers in the past few years -- particularly in our standards for managing customer data and privacy. Since 2019, we have formalized our approach to data privacy and compliance -- we now conduct thorough internal and external audits and train all employees on the essentials of guarding customer data.

== Governance
<governance>
A company's positive governance impact is measured by the extent to which the company is accountable to stakeholders, and the extent to which its decision-making is transparent to all constituents.

We've made improvements in ethics and transparency areas, including anti-corruption and code of ethics training for employees, and more rigorous financial controls and financial transparency with employees. Looking ahead, we plan to incorporate more social and community benefit metrics in our corporate reporting, including board meeting updates, so that all of our stakeholders are aware of our ongoing progress and can help support our success.

== Workers
<workers>
Investments in employee career development include in-house management training programs, tooling and education to support constructive feedback, and documentation of job levels, pay ranges, and career paths within our major functions. In 2021, we initiated an annual organizational health survey, which allows us to collect and respond to employee feedback. We have also augmented our benefits to include a "lifestyle savings account" (LSA) funded by Posit that each individual can choose to apply to home office, professional development, wellness, or financial health expenses as they see fit. All together, we are working to continuously improve the value offered to our workers as our company grows.

#colbreak()
== Environment
<environment>
As a remote-first organization, we do not generate meaningful greenhouse gas emissions. However, for the emissions we do generate from cloud computing, business travel, and our Boston headquarters we purchase carbon offsets to achieve carbon neutrality. We first achieved carbon neutrality in 2020 and have since maintained our neutrality by purchasing carbon offsets for years 2021 - 2025. Below is a breakdown of our scope 2 and scope 3 greenhouse gas emissions from the past three years. We track our emissions so that we can purchase an equal amount of carbon offsets.

]
#box(image("images/generate-plots_files/figure-typst/emissions-1.svg"))

#back_page(repo: "https://github.com/posit-dev/bcorp-report/")[
  
]



