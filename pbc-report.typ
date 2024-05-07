// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
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

#show figure: it => {
  if type(it.kind) != "string" {
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
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

#show ref: it => locate(loc => {
  let suppl = it.at("supplement", default: none)
  if suppl == none or suppl == auto {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
    let target = query(it.target, loc).first()
    let parent_id = sup.captures.first()
    let parent_figure = query(label(parent_id), loc).first()
    let parent_location = parent_figure.location()

    let counters = numbering(
      parent_figure.at("numbering"), 
      ..parent_figure.at("counter").at(parent_location))
      
    let subcounter = numbering(
      target.at("numbering"),
      ..target.at("counter").at(target.location()))
    
    // NOTE there's a nonbreaking space in the block below
    link(target.location(), [#parent_figure.at("supplement") #counters#subcounter])
  } else {
    it
  }
})

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
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
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      block(
        inset: 1pt, 
        width: 100%, 
        block(fill: white, width: 100%, inset: 8pt, body)))
}

#let posit_colors = (
  blue: rgb("#447099"),
  grey: rgb("#404041"),
  orange: rgb("#EE6331"),
  dark_blue_2: rgb("#213D4F"),
  dark_blue_3: rgb("#17212B"),
  light_blue_1: rgb("#D1DBE5"),
  light_blue_2: rgb("#A2B8CB")
)

//  Pages with a blue background
#let page_blue(content)={
    set page(background: image("assets/images/hexes-8.5x11-#17212B.png", height: 100%, fit: "cover"))
    set text(fill: posit_colors.light_blue_1)
    show heading: set text(fill: posit_colors.light_blue_2)
    show heading.where(level: 1): it => {
      pagebreak()  
      it
    }
    content
  }

// Page with Impact Assessment header
#let page_impact(content)={
  set page(
    margin: (top: 2in),
    header: [
      #set text(fill: white)
      #block(width: 100%, height: 100%, outset: (x: 1.25in), inset: (y: 2em), fill: posit_colors.blue)[
        #place(right + horizon)[
          #image("assets/images/BLab_B_Impact_Assessment-white.png", height: 50%)
        ]
      ]
    ]
  )
  content
}

#let col-2(content)={
    columns(2, content)
} 

#let banner(content)={
    set text(fill: white)
    block(width: 100%, outset: (x: 1.25in), inset: (y: 2em), fill: posit_colors.blue, content)
}

#let conclusion(content)={
  set page(fill: posit_colors.blue,
    background: image("assets/images/Conf-2023-Crowd.jpg", height: 100%, fit: "cover"))
  set text(fill: white)
  place(horizon, dy: -1in)[
    #block(fill: posit_colors.blue, outset: 1.25in, content)
  ]
}

//   Custom title page
#let title_page(title, subtitle)={
    page(margin: 0in, fill: posit_colors.dark_blue_2, 
        background: image("assets/images/Hex-Stickers-high-res-uncropped.jpg", height: 100%, fit: "cover"))[
        #set text(fill: white)

        #place(center + horizon, dy: -2.5in)[
            #set align(center + horizon)
            #block(width: 100%, fill: posit_colors.dark_blue_3, outset: 4em)[
                #text(weight: "light", size: 36pt, title)

                #text(weight: "bold", size: 24pt, subtitle)
            ]
        ]
        #place(center + bottom, dy: -36pt)[
          #block(height: 36pt)[
            #box(height: 24pt, baseline: -6pt, image("assets/images/posit-logo-white-TM.svg"))
            #box(inset: (x: 12pt), line(length: 100%, angle: 90deg, stroke: 0.5pt + white))
            #box(image("assets/images/B-Corp-Logo-White-RGB.png"))
          ]
        ]
    ]
}

#let back_page(content)={
  page_blue()[
      #set page(
        background: image("assets/images/hexes-8.5x11-#447099.png", height: 100%, fit: "cover"))
      #set text(fill: white)
      #show par: set block(spacing: 0.5em)
      #place(bottom + center)[
        #block(height: 48pt)[
                  #box(height: 36pt, baseline: -8pt, image("assets/images/posit-logo-white-TM.svg"))
                  #box(inset: (x: 24pt), line(length: 100%, angle: 90deg, stroke: 0.5pt + white))
                  #box(image("assets/images/B-Corp-Logo-White-RGB.png"))
                ]
        
        The open source data science company

        #text(size: 24pt, link("http://posit.co/")[posit.co])
        #v(2em)
        #set text(size: 10pt)
        
        #(content)

        Published with #box(height: 12pt, baseline: 20% , image("assets/images/quarto-logo-trademark-white.svg"))
        ]
      ]
}

#let posit(
  title: none,
  subtitle: none,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
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


  if title != none {
    title_page(title, subtitle)
  }

  show heading.where(level: 1): set text(weight: "light", size: 36pt)
  show heading.where(level: 1): set block(width: 100%, below: 1em)
  
  

  show heading.where(level: 2): it => {
    set block(below: 1.5em)
    upper(it)
  }

  doc
}

#show: doc => posit(
  title: [Posit Benefit Corporation],
  subtitle: [2024 Annual Report],
  font: ("Open Sans",),
  doc,
)


#page_blue()[
= A Message from our CEO
<a-message-from-our-ceo>
#col-2()[
Posit aims to create free and open-source software for data science, scientific research, and technical communication in a sustainable way, because it benefits everyone when the essential tools to produce and consume knowledge are available to all, regardless of economic means.

We believe corporations should fulfill a purposeful benefit to the public and be run for the benefit of all stakeholders including employees, customers, and the larger community.

As a Delaware Public Benefit Corporation (PBC) and a Certified B Corporation®, Posit’s open-source mission and commitment to a beneficial public purpose are codified in our charter, requiring our corporate decisions to balance the interests of the community, customers, employees, and shareholders.

B Corps#super[TM] meet the highest verified standards of social and environmental performance, transparency, and accountability. Posit measures its public benefit by utilizing the non-profit B Lab®’s "Impact Assessment", a rigorous assessment of a company’s impact on its workers, customers, community, and environment.

#colbreak()
In 2019, Posit (then RStudio) met the B Corporation certification requirements set by the B Lab. In 2023, our certification was renewed, and we are proud to share that our B Lab Impact Assessment score rose from 86.1 to 92.5 with this renewal. The B Lab certification process uses credible, comprehensive, transparent, and independent standards to measure social and environmental performance. Details of these assessments can be found on our #link("https://www.bcorporation.net/en-us/find-a-b-corp/company/rstudio/")[#underline[B Lab company page];];.

As a PBC, Posit publishes a report at least once every two years describing the public benefit we have created and how we seek to provide public benefits in the future. This is the fourth of these reports. The first report for 2019 #link("https://posit.co/wp-content/uploads/2022/11/RStudio-Benefit-Corporation-2019-Annual-Report.pdf")[#underline[may be found here];];. The second report for 2020 #link("https://posit.co/wp-content/uploads/2022/11/RStudio-Benefit-Corporation-2020-Annual-Report.pdf")[#underline[may be found here];];, and our 2021 report may be found here.

To fulfill its beneficial purposes, Posit intends to remain an independent company over the long term. With the support of our customers, employees, and the community, we remain excited to contribute useful solutions to the important problems of knowledge they face.

#place(right, dy: 3em)[
#emph[J.J. Allaire] \
CEO, Posit PBC

]
]
]
= Introduction
<introduction>
#col-2()[
Posit’s mission is to create free and open-source software for data science, scientific research, and technical communication. We do this to enhance the production and consumption of knowledge by everyone, regardless of economic means, and to facilitate collaboration and reproducible research, both of which are critical to the integrity and efficacy of work in science, education, government, and industry.

In addition to our open source products, Posit produces a modular platform of commercial software products that enable teams to adopt R, Python, and other open-source data science software at scale. Posit also offers online services that make it easier to learn and use data science tools over the web.

Together, Posit\'s open-source software and commercial software form a virtuous cycle. In most companies, a \"customer\" is someone who pays you. For us, the definition of a customer must include the open source community, with whom we exchange the currencies of attention, respect, and love. When we deliver value to our open source users, they will likely bring our software into their professional environments, which opens up the possibility of commercial partnerships. To keep this cycle flowing, our open source developers must know and care about the integrations with proprietary solutions that matter to our enterprise customers. It also means that Posit\'s commercial teams consistently provide value to individuals who may never directly spend a dollar with us.

Posit’s approach is not typical. Traditionally, scientific and technical computing companies create exclusively proprietary software. While it can provide a robust foundation for investing in product development, proprietary software can also create excessive dependency that is not good for data science practitioners and the community. In contrast, Posit provides core productivity tools, packages, protocols, and file formats as open-source software so customers aren’t overly dependent on a single software vendor. Additionally, while our commercial products enhance the development and use of our open-source software, they are not fundamentally required for those without the need or the ability to pay for them.

In 2023, Posit spent #highlight()[\[33%?\]]
of its engineering resources on open-source software development, and led contributions to over #highlight()[\[xx\]]
open-source projects. Posit-led projects targeted a broad range of areas including the RStudio IDE; infrastructure libraries for R and Python; numerous packages and tools to streamline data manipulation, exploration and visualization, modeling, and machine learning; and integration with external data sources. Posit also sponsors or contributes to many open-source and community projects led by others, including NumFOCUS, the R Consortium, the Python Software Foundation, DuckDB, Pandoc, pyodide, and ProseMirror, as well as dozens of smaller projects via the Open Source Collective or directly on Github. Additional information about our products and company contributions for the past two years can be found in our #link("https://posit.co/blog/2023-posit-year-in-review/#:~:text=Posit%20Package%20Manager&text=This%20year%2C%20Package%20Manager%20enabled,R%20Application%20Network%20(MRAN).")[#underline[\"Year In Review\'\' blog posts];];.

#colbreak()
Today, millions of people download and use Posit open-source products in their daily lives. Additionally, more than #highlight()[\[how many paying customers?\]]
organizations that purchase our professional products help us sustain and grow our mission. It is inspiring to help so many people participate in global economies that increasingly reward data literacy, and know that our tools help produce insights essential to navigating our complex world.

]
#pagebreak()
= Posit\'s Charter and Statement of Public Benefit
<posits-charter-and-statement-of-public-benefit>
#col-2()[
== Posit\'s Charter
<posits-charter>
We want Posit to serve a meaningful public purpose, and we run the company for the benefit of our customers, employees, and the community at large. That’s why we’re organized as a Public Benefit Corporation (PBC).

What makes a PBC different from other types of corporations?

#quote(block: true)[
#emph["A 'public benefit corporation' is a for-profit corporation organized under and subject to the requirements of this chapter that is intended to produce a public benefit or public benefits and to operate in a responsible and sustainable manner."] — #link("https://delcode.delaware.gov/title8/c001/sc15/")[#underline[Delaware Public Benefit Corporations Law];]
]

As a PBC and Certified B Corporation, we must meet the highest verified standards of social and environmental performance, transparency, and accountability. Our directors and officers have a fiduciary responsibility to address social, economic, and environmental needs while still overseeing our business goals.

== Posit\'s Statement of Public Benefit
<posits-statement-of-public-benefit>
Creation of free and open source software for data science, scientific research, and technical communication:

#quote(block: true)[
1) To enhance the production and consumption of knowledge by everyone, regardless of economic means.

2) To facilitate collaboration and reproducible research, both of which are critical for ensuring the integrity and efficacy of scientific work.
]

]
== Our primary obligations as a PBC and Certified B Corporation
<our-primary-obligations-as-a-pbc-and-certified-b-corporation>
#figure(
  align(center)[#table(
    columns: (50%, 50%),
    align: (left,left,),
    table.header([Public Benefit Corporation:

      #emph[How we built our company charter]

      ], [Certified B Corp:

      #emph[How we hold ourselves accountable to our charter]

      ],),
    table.hline(),
    [- The board of directors shall manage or direct the business and affairs of the public benefit corporation in a manner that balances the pecuniary interests of the stockholders, the best interests of those materially affected by the corporation’s conduct, and the specific public benefit or public benefits identified in its certificate of incorporation.

    - A public benefit corporation shall no less than biennially provide its stockholders with a statement as to the corporation’s promotion of the public benefit or public benefits identified in the certificate of incorporation and of the best interests of those materially affected by the corporation’s conduct.

    ], [- Demonstrate high social and environmental performance by achieving a B Lab Impact Assessment score of 80 or above and passing the risk review.

    - Make a legal commitment by changing our corporate governance structure to be accountable to all stakeholders, not just shareholders, and achieve benefit corporation status if available in our jurisdiction.

    - Exhibit transparency by allowing information about our performance measured against B Lab’s standards to be publicly available on our B Corp profile on B Lab’s website.

    ],
  )]
  , kind: table
  )

#pagebreak()
= Posit’s Open Source Development Projects
<posits-open-source-development-projects>
#col-2()[
Before the company re-branded in 2022, Posit (then RStudio) was often thought of as an "R company" in the data community because of its dedication to developing and maintaining some of the most used R libraries in the world. However, Posit has always been better described as a #emph[scientific software] company. Supporting Python (via the #link("https://github.com/rstudio/reticulate")[#underline[reticulate];] package, RStudio language support), working with relational databases and data platforms such as Apache Spark (a cross-platform data frame compatibility via #link("https://github.com/apache/arrow")[#underline[feather/Apache Arrow];];), and much more mean that we’ve never been solely an "R company".

#colbreak()
Since the 2021 PBC report, Posit has released several new packages in the Python and R ecosystems and continues to maintain and grow the libraries previously developed. The following subsections highlight selected Posit software projects of interest to the broad data science community. Where metrics are published, please note these represent a #emph[lower bound] on the actual number, as it is difficult-to-impossible to account for every install and usage in the world.

]
#pagebreak()
== Quarto
<quarto>
#col-2()[
In July 2022, #link("https://posit.co/blog/announcing-quarto-a-new-scientific-and-technical-publishing-system/")[#underline[Posit announced];] the #link("https://quarto.org/")[#underline[Quarto];] project, an open-source scientific and technical publishing system as a successor to the #link("https://rmarkdown.rstudio.com/")[#underline[R Markdown];] library. While Quarto incorporates the lessons learned from over 10 years of developing R Markdown into an entirely new project, it’s likely still quite familiar to users of R Markdown as they share two core dependencies: Knitr and Pandoc. In fact, despite the fact that Quarto does some things differently, most existing R Markdown documents can be rendered unmodified using Quarto.

#colbreak()
Quarto allows users to choose from multiple computational engines (Knitr, Jupyter, and Observable), which makes it easy to use Quarto with R, Python, Julia, JavaScript and many other languages. It also allows users to author documents as plain text markdown or Jupyter Notebooks, and publish to numerous outputs such as HTML, PDF, MS Word, ePub and more. Finally, the community has already extended Quarto , as shown by the #link("https://machow.github.io/quartodoc/get-started/overview.html")[#underline[quartodoc];] project for developing API documentation.

]
#box(image("pbc-report_files/figure-typst/quarto-1.svg"))

#pagebreak()
== Shiny
<shiny>
#col-2()[
Shiny has been a mainstay in the R community since its launch in 2012, providing a web application framework that makes it easy to tell data stories in interactive point-and-click web applications. In April 2023, Posit released the Python version of Shiny, bringing the same great reactive programming model and modular design to the PyData ecosystem.

#colbreak()
Shiny applications can be shared with others via an open-source #link("https://posit.co/products/open-source/shinyserver/")[#underline[Shiny Server];];, the hosted #link("http://shinyapps.io")[#underline[shinyapps.io];] service, or with #link("https://posit.co/products/enterprise/connect/")[#underline[Posit Connect];];. Shiny and related packages include shiny (#link("https://shiny.posit.co/py/")[#underline[Python];];, #link("https://shiny.posit.co/r/getstarted")[#underline[R];];), #link("https://rstudio.github.io/bslib/")[#underline[bslib];];, #link("https://rstudio.github.io/shinytest/")[#underline[shinytest];];, #link("https://rstudio.github.io/shinyloadtest/")[#underline[shinyloadtest];];, #link("https://rstudio.github.io/shinydashboard/")[#underline[shinydashboard];];, #link("https://rstudio.github.io/leaflet/")[#underline[leaflet];];, and #link("https://rstudio.github.io/crosstalk/")[#underline[crosstalk];];.

There are #highlight()[7 full time equivalent (FTE)]
employees developing the open-source Shiny and Shiny Server products as of #highlight()[December 2021]
.

]
#box(image("pbc-report_files/figure-typst/shiny-1.svg"))

#block[
#box(image("pbc-report_files/figure-typst/shiny-2.svg"))

]
#pagebreak()
== gt / Great Tables
<gt-great-tables>
#col-2()[
When presenting an analysis, a table can often convey the results more concisely than the most beautiful and interactive of charts. However, the experience of creating and displaying tables in R and Python has been mixed, especially when you want to display something beyond a plain data frame representation.

#colbreak()
To that end, the #link("https://gt.rstudio.com/")[#underline[gt];] and #link("https://posit-dev.github.io/great-tables/articles/intro.html")[#underline[Great Tables];] packages have defined a "grammar of tables" to solve this problem (in R and Python, respectively), analogous to the "grammar of graphics" for specifying charts.

]
#box(image("pbc-report_files/figure-typst/gt-1.svg"))

#block[
#box(image("pbc-report_files/figure-typst/gt-2.svg"))

]
#pagebreak()
== Vetiver
<vetiver>
#col-2()[
#link("https://vetiver.posit.co/")[#underline[Vetiver];] solves the issues around versioning, sharing, deploying and monitoring predictive models served via APIs. Available for both R and Python, vetiver is extensible via generics that support many common types of models. #colbreak() Vetiver also provides the "model cards" functionality, which can help to generate documentation by extracting some information about the generated model.

]
#box(image("pbc-report_files/figure-typst/vetiver-1.svg"))

#block[
#box(image("pbc-report_files/figure-typst/vetiver-2.svg"))

]
#pagebreak()
== Posit Public Package Manager
<posit-public-package-manager>
#col-2()[
WIth the ubiquity of open source software in our daily lives, one area that most people don’t think about is 'How do you distribute that software quickly and securely to the end user?'. To that end, Posit created #link("https://posit.co/products/enterprise/package-manager/?_gl=1*1u2v1ey*_ga*MTA4ODg0NzAxNy4xNzA0OTE5NjEw*_ga_2C0WZ1JHG0*MTcxMzUzMzQ5Ni4xNDUuMS4xNzEzNTM0MjgzLjAuMC4w")[#underline[Posit Package Manager];];, which gives companies a means for providing curated repositories, repository snapshots for better reproducibility, the ability to air-gap the repository for enhanced security and much more.

#colbreak()
As part of our commitment to improving the quality and availability of open source software for all, Posit hosts a public instance of Posit Package Manager called #link("https://packagemanager.posit.co/client/#/")[#underline[Posit Public Package Manager];] that mirrors CRAN, PyPI and Bioconductor. This mirror served nearly 40 million downloads per month in Q1 2024.

]
== webR
<webr>
#col-2()[
#link("https://docs.r-wasm.org/webr/latest/")[#underline[WebR];] has the ambitious goal of bringing the R language to the browser, removing the need for a backend server for computation. It also allows for computation to be done on the client machine, supporting use cases that are infeasible or undesirable for using server-side processing (such as not wanting to send personal data over the internet). #colbreak() Also, by making the most of the user’s device capabilities, webR can improve performance and lower app hosting costs.

]
#pagebreak()
== Plotnine
<plotnine>
#col-2()[
#link("https://plotnine.org/")[#underline[Plotnine];] is an implementation of the grammar of graphics in Python, heavily influenced by ggplot2 in R. Built upon the ubiquitous #link("https://matplotlib.org/")[#underline[matplotlib];] plotting library, #colbreak() custom (and otherwise complex) plots are easy to reason about and build incrementally, while the simple plots remain simple to create.

]
#box(image("pbc-report_files/figure-typst/plotnine-1.svg"))

#pagebreak()
== Siuba
<siuba>
#col-2()[
#link("https://siuba.org/")[#underline[Siuba];] is a port of dplyr and other R libraries. It’s aim is to make data science faster through a consistent interface of verbs for working with real-world data: filter, arrange, select, mutate and summarize. #colbreak() Siuba supports several backends including pandas, #link("https://duckdb.org/")[#underline[DuckDB];] and SQL, providing a "write once, run many" freedom for your analytics code.

]
#box(image("pbc-report_files/figure-typst/siuba-1.svg"))

#pagebreak()
== RStudio Integrated Development Environment
<rstudio-integrated-development-environment>
#col-2()[
#link("https://posit.co/products/open-source/rstudio/")[#underline[RStudio];] is a multi-language IDE designed for Data Science with R and Python. It augments the standard code console with an editor that can display Notebooks, launch apps, highlight code syntax, spot code errors, and directly execute code. Built into the IDE are tools for debugging, plotting, browsing files, and managing project histories and workspaces. Together these tools make data scientists and developers much more efficient.

#colbreak()
There are #highlight()[5 full time equivalent (FTE) employees]
developing the RStudio IDE open-source desktop and server products as of #highlight()[December 2023]
.

]
#box(image("pbc-report_files/figure-typst/rstudio-1.svg"))

#pagebreak()
== Tidyverse
<tidyverse>
#col-2()[
The #link("https://www.tidyverse.org/")[#underline[tidyverse];] is an opinionated collection of R packages designed for data science. All packages share an underlying design philosophy, grammar and data structures.

The tidyverse consists of nine core packages (including ggplot2, tidyr and readr) and 31 packages overall.

#colbreak()
There are approximately #highlight()[6.5 full time equivalent]
Posit employees developing Tidyverse and related open-source products as of #highlight()[December 2023]
.

]
#box(image("pbc-report_files/figure-typst/tidyverse-1.svg"))

#pagebreak()
== Tidymodels
<tidymodels>
#col-2()[
#link("https://www.tidymodels.org/")[#underline[Tidymodels];] is a cohesive collection of packages that perform tasks relevant to statistical modeling and machine learning. Tidymodels packages share a common syntax and design philosophy, and are designed to work seamlessly with Tidyverse packages.

#colbreak()
There are currently 42 tidymodels packages on CRAN. Popular tidymodels packages include parsnip, rsample, recipes, tune and yardstick.

There are #highlight()[3.5 full time equivalent (FTE)]
Posit employees developing Tidymodels and related open-source products as of #highlight()[December 2023]

]
#box(image("pbc-report_files/figure-typst/tidymodels-1.svg"))

#pagebreak()
== Connectivity Packages
<connectivity-packages>
#col-2()[
Posit increases the efficiency of customers by making open-source packages that connect data scientists to spreadsheets, databases, distributed storage frameworks for big data, machine learning platforms, and the programming environments of other languages, like python.

#colbreak()
Connectivity packages include: #link("https://spark.posit.co/")[#underline[sparklyr];];, #link("https://tensorflow.rstudio.com/")[#underline[tensorflow for R];];, #link("https://keras.posit.co/")[#underline[keras];];, #link("https://solutions.posit.co/connections/db/r-packages/odbc/")[#underline[odbc];];, and #link("https://rstudio.github.io/reticulate/")[#underline[reticulate];];. \
There are #highlight()[4 full time equivalent Posit-funded developers]
creating connectivity-related open-source packages as of #highlight()[December 2021]
.

]
#box(image("pbc-report_files/figure-typst/connectivity-1.svg"))

#pagebreak()
== R Infrastructure Tools (r-lib)
<r-infrastructure-tools-r-lib>
#col-2()[
R-lib is a large collection of R packages that make it easier to build, find, and use effective tools for data analysis.

There are currently #highlight()[111]
R-lib packages. Popular packages include #link("https://devtools.r-lib.org/")[#underline[devtools];];, #link("https://testthat.r-lib.org/")[#underline[testthat];];, #link("https://roxygen2.r-lib.org/")[#underline[roxygen2];];, #link("https://pkgdown.r-lib.org/")[#underline[pkgdown];] and #link("https://usethis.r-lib.org/")[#underline[usethis];];.

#colbreak()
There are #highlight()[2 full time equivalent (FTE)]
Posit employees developing r-lib and related open-source packages as of #highlight()[December 2023]
.

]
#box(image("pbc-report_files/figure-typst/rlibs-1.svg"))

#pagebreak()
= B Lab® Impact Assessment Results
<b-lab-impact-assessment-results>
#col-2()[
The BLab Impact Assessment is composed of questions in five Impact Areas: Governance, Workers, Community, Environment, and Customers. Posit\'s assessment results are available to the public #link("https://www.bcorporation.net/en-us/find-a-b-corp/company/rstudio/")[#highlight()[#underline[here];]
];. We completed our first Impact Assessment in 2019 and earned an overall score of #strong[86.1.] We are proud to report that our latest score from our recertification process in 2023, is #strong[92.5];. To put this in context, the threshold for B Lab certification is a score of 80 or higher, and the median score for ordinary businesses who take the assessment is 50.9. Posit seeks to continually improve our internal governance, increase our workforce diversity and employee development efforts, expand our stewardship of the environment, deepen our engagement in our communities, and better serve our customers so that our public benefit will continue to improve each year.

#colbreak()
In our initial assessment, we received high marks for incorporating as a benefit corporation, the health, wellness, safety, and financial security of our employees, and for educating and serving customers. We identified formal goal setting, career development, diversity, equity & inclusion, civic engagement & giving, and air & climate as areas for improvement.

]
#pagebreak()
== Summary of Score Improvements Since 2019
<summary-of-score-improvements-since-2019>
The B Lab’s Impact assessment standards have evolved since 2019 (we are now on version 6 of the assessment). New questions were added, and thresholds for performance were raised in other cases. Of the scored questions we responded to in our most recent assessment, 38 were unchanged from 2019, 71 were modified from 2019 wording, and 22 were brand new questions. On the unchanged or modified questions, we have gained points in the areas listed below.

#block[
#figure(
  align(center)[#table(
    columns: (22%, 35%, 39%),
    align: (left,left,left,),
    table.header(table.cell(align: left)[#strong[Impact Area];], table.cell(align: left)[#strong[Topic];], table.cell(align: left)[#strong[% Achievement Gain since 2019];],),
    table.hline(),
    table.cell(align: left, rowspan: 2)[Community], table.cell(align: left)[Civic Engagement & Giving], table.cell(align: left)[39%],
    table.cell(align: left)[Diversity, Equity, & Inclusion], table.cell(align: left)[60%],
    table.cell(align: left)[Customers], table.cell(align: left)[Customer Stewardship], table.cell(align: left)[28%],
    table.cell(align: left)[Environment], table.cell(align: left)[Air & Climate], table.cell(align: left)[75%],
    table.cell(align: left)[Governance], table.cell(align: left)[Ethics & Transparency], table.cell(align: left)[37%],
    table.cell(align: left, rowspan: 3)[Workers], table.cell(align: left)[Career Development], table.cell(align: left)[62%],
    table.cell(align: left)[Engagement & Satisfaction], table.cell(align: left)[50%],
    table.cell(align: left)[Financial Security], table.cell(align: left)[58%],
  )]
  , kind: table
  )

]
#col-2()[
=== Community
<community>
==== Civic Engagement and Giving
<civic-engagement-and-giving>
In addition to the open-source software we make freely available, and the open source data science package development produced by Posit engineers, Posit recognizes the importance of contributing financially to other valuable open-source and community initiatives. To date, Posit has given over \$1.9M to projects led by others. Current commitments include contributing to NumFOCUS, the R Consortium, the R Foundation, DuckDB, the Eclipse Foundation, and the authors and maintainers of several other open-source projects.

Posit’s financial support also extends beyond the world of open source data science. Since 2020, Posit and its employees have given over \$60k to over 135 nonprofits. Our donations reach a range of community-based causes, including organizations dedicated to racial equality, equal justice, LGBTQ+ support, and access to education. Alongside our donations to open source software development, this pool of charitable contributions contributes to the important work many are doing to increase the accessibility of data science for all. Our scoring in this area of the B Lab assessment has increased by 39.5% since 2019.

==== Diversity, Equity, and Inclusion
<diversity-equity-and-inclusion>
Since our initial B Lab assessment in 2019, Posit has continued to focus on increasing the strength of our team by utilizing talent practices that encourage diverse people to apply, join, and thrive at Posit. Specific changes made in recent years include the formation of a diversity, equity, inclusion, and accessibility council (DEIA Council), as well as the sponsoring of employee resource groups (ERG’s). We report our progress on our diversity metrics, as defined in the B Lab Assessment, in each quarter’s board meeting. We also pay close attention to issues of equity in compensation, hiring and interviewing, and employee experience. Our efforts to date have yielded increases in the percentages of women and those with minority racial or ethnic identities in both management and the employee population as a whole – and our recent assessment results reflect these gains.

=== Customers
<customers>
We have made meaningful improvements in our care for customers in the past few years – particularly in our standards for managing customer data and privacy. Since 2019, we have formalized our approach to data privacy and compliance – we now conduct thorough internal and external audits and train all employees on the essentials of guarding customer data. These changes have increased our assessment performance by 28% since 2019.

=== Environment
<environment>
We are happy to share that our assessment scores for Air and Climate impacts have improved by 75% since 2019. In November 2020, Posit achieved carbon neutrality by purchasing carbon offsets that counter the environmental impact of business travel (primarily for our annual conference and internal meetings). As a remote-first organization, we do not generate meaningful greenhouse gas emissions outside of air travel. By offsetting this impact through the funding of reforestation work in both South America and closer to home in Massachusetts, we hope to neutralize Posit’s potential damage to our planet.

=== Governance
<governance>
A company’s positive governance impact is measured by the extent to which the company is accountable to stakeholders, and the extent to which its decision-making is transparent to all constituents. In 2019, RStudio scored 16.1 points out of a possible 21.9+ points in the Governance Impact Area, including 10 points awarded for the specific legal structures we have established as a Benefit Corporation that preserve our mission and consider our stakeholders regardless of company ownership.

In our latest assessment, our governance score improved by 37% via improvements in ethics and transparency areas, including anti-corruption and code of ethics training for employees, and more rigorous financial controls and financial transparency with employees. Looking ahead, we plan to incorporate more social and community benefit metrics in our corporate reporting, including board meeting updates, so that all of our stakeholders are aware of our ongoing progress and can help support our success.

=== Workers
<workers>
We have made significant strides in our Worker assessment category since 2019, with scores increasing by 50% or more in areas such as career development, engagement and satisfaction, and financial security for our employees. Investments in employee career development include in-house management training programs, tooling and education to support constructive feedback, and documentation of job levels, pay ranges, and career paths within our major functions. In 2021, we initiated an annual organizational health survey, which allows us to collect and respond to employee feedback. We have also augmented our benefits to include a "lifestyle savings account" (LSA) funded by Posit that each individual can choose to apply to home office, professional development, wellness, or financial health expenses as they see fit. All together, we are working to continuously improve the value offered to our workers as our company grows.

]
#conclusion()[
= Conclusion
<conclusion>
Praesent ornare dolor turpis, sed tincidunt nisl pretium eget. Curabitur sed iaculis ex, vitae tristique sapien. Quisque nec ex dolor. Quisque ut nisl a libero egestas molestie. Nulla vel porta nulla. Phasellus id pretium arcu. Etiam sed mi pellentesque nibh scelerisque elementum sed at urna. Ut congue molestie nibh, sit amet pretium ligula consectetur eu. Integer consectetur augue justo, at placerat erat posuere at. Ut elementum urna lectus, vitae bibendum neque pulvinar quis. Suspendisse vulputate cursus eros id maximus. Duis pulvinar facilisis massa, et condimentum est viverra congue. Curabitur ornare convallis nisl. Morbi dictum scelerisque turpis quis pellentesque. Etiam lectus risus, luctus lobortis risus ut, rutrum vulputate justo. Nulla facilisi.

]
#back_page()[
  Trademark language here
]



