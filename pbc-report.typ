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
  let target = query(it.target, loc).first()
  let suppl = it.at("supplement", default: none)
  if suppl == none or suppl == auto {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
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

        Published with #box(height: 12pt, baseline: 20% , image("assets/images/quarto-logo-trademark.svg"))
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
Posit endeavors to create free and open-source software for data science, scientific research, and technical communication in a sustainable way, because it benefits everyone when the essential tools to produce and consume knowledge are available to all, regardless of economic means.

We believe corporations should fulfill a purpose beneficial to the public and be run for the benefit of all stakeholders including employees, customers, and the community at large.

As a Delaware Public Benefit Corporation \(PBC) and a Certified B Corporation®, Posit’s open-source mission and commitment to a beneficial public purpose are codified in our charter, requiring our corporate decisions to balance the interests of community, customers, employees, and shareholders.

B Corps#super[TM] meet the highest verified standards of social and environmental performance, transparency, and accountability. Posit measures its public benefit by utilizing the non-profit B Lab®’s "Impact Assessment", a rigorous assessment of a company’s impact on its workers, customers, community, and environment.

#colbreak()
In 2019, Posit \(then RStudio) met the B Corporation certification requirements set by the B Lab. In 2023, our certification was renewed, and we are proud to share that our B Lab Impact Assessment score rose from 86.1 to 92.5 with this renewal. The B Lab certification process uses credible, comprehensive, transparent, and independent standards of social and environmental performance. Details of these assessments can be found at \[web link\].

As a PBC, Posit publishes a report at least once every two years that describes the public benefit we have created, along with how we seek to provide public benefits in the future. This is the fourth of these reports. Previous published reports are available at \[here\].

To fulfill its beneficial purposes, Posit intends to remain an independent company over the long term. With the support of our customers, employees, and the community, we remain excited to contribute useful solutions to the important problems of knowledge they face.

#place(right, dy: 3em)[
  *J.J. Allaire* \
  CEO, Posit PBC
]
]
]
= Introduction
<introduction>
#col-2()[
Posit’s mission is to create free and open-source software for data science, scientific research, and technical communication. We do this to enhance the production and consumption of knowledge by everyone, regardless of economic means, and to facilitate collaboration and reproducible research, both of which are critical to the integrity and efficacy of work in science, education, government, and industry.

In addition to our open source products, Posit produces a modular platform of commercial software products that enable teams to adopt R, Python, and other open-source data science software at scale, along with online services to make it easier to learn and use them over the web.

Together, Posit\'s open-source software and commercial software form a virtuous cycle. In most companies, a \"customer\" is someone who pays you. For us, the definition of a customer must include the open source community, with whom we exchange the currencies of attention, respect, and love. When we deliver value to our open source users, they are likely to bring our software into their professional environments, which opens up the possibility of commercial partnerships. To keep this cycle flowing, our open source developers have to know and care about the integrations with proprietary solutions that matter to our enterprise customers. It also means that Posit\'s commercial teams need to consistently provide value to individuals who may never spend a dollar with us directly.

Posit’s approach is not typical. Traditionally, scientific and technical computing companies created exclusively proprietary software. While it can provide a robust foundation for investing in product development, proprietary software can also create excessive dependency that is not good for data science practitioners and the community. In contrast, Posit provides core productivity tools, packages, protocols, and file formats as open-source software so that customers aren’t overly dependent on a single software vendor. Additionally, while our commercial products enhance the development and use of our open-source software, they are not fundamentally required for those without the need or the ability to pay for them.

In 2023, Posit spent \[33%?\] of its engineering resources on open-source software development, and led contributions to over \[xx\] open-source projects. Posit-led projects targeted a broad range of areas including the RStudio IDE; infrastructure libraries for R and Python; numerous packages and tools to streamline data manipulation, exploration and visualization, modeling, and machine learning; and integration with external data sources. Posit also sponsors or contributes to many open-source and community projects led by others, including NumFOCUS, the R Consortium, the Python Software Foundation, DuckDB, Pandoc, pyodide, and prose mirror, as well as dozens of smaller projects via the Open Source Collective or directly on Github. Additional information about our products and company contributions for the past two years can be found in our \"Year In Review\'\' blog posts. \[available here\].

#colbreak()
Today, millions of people download and use Posit open-source products in their daily lives. Additionally, more than \[how many paying customers?\] organizations that purchase our professional products help us sustain and grow our mission. It is an inspiration to consider that we are helping many participate in global economies that increasingly reward data literacy, and that our tools help produce insights essential to navigating our complex world.

]
#pagebreak()
= Posit\'s Statement of Public Benefit and B Lab® Impact Assessment Results
<posits-statement-of-public-benefit-and-b-lab-impact-assessment-results>
#col-2()[
== Posit\'s Charter
<posits-charter>
We want Posit to serve a meaningful public purpose, and we run the company for the benefit of our customers, employees, and the community at large. That’s why we’re organized as a Public Benefit Corporation \(PBC).

What makes a PBC different from other types of corporations?

#quote(block: true)[
#emph[“A 'public benefit corporation' is a for-profit corporation organized under and subject to the requirements of this chapter that is intended to produce a public benefit or public benefits and to operate in a responsible and sustainable manner.\" \[link to source: #link("https://delcode.delaware.gov/title8/c001/sc15/")[#underline[https:\/\/delcode.delaware.gov/title8/c001/sc15/];];\].]
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
  columns: 2,
  align: (col, row) => (left,left,).at(col),
  inset: 6pt,
  [Public Benefit Corporation:

  #emph[How we built our company charter]

  ], [Certified B Corp:

  #emph[How we hold ourselves accountable to our charter]

  ],
  [- The board of directors shall manage or direct the business and affairs of the public benefit corporation in a manner that balances the pecuniary interests of the stockholders, the best interests of those materially affected by the corporation’s conduct, and the specific public benefit or public benefits identified in its certificate of incorporation.

  - A public benefit corporation shall no less than biennially provide its stockholders with a statement as to the corporation’s promotion of the public benefit or public benefits identified in the certificate of incorporation and of the best interests of those materially affected by the corporation’s conduct.

  ],
  [- Demonstrate high social and environmental performance by achieving a B Lab Impact Assessment score of 80 or above and passing the risk review.

  - Make a legal commitment by changing our corporate governance structure to be accountable to all stakeholders, not just shareholders, and achieve benefit corporation status if available in our jurisdiction.

  - Exhibit transparency by allowing information about our performance measured against B Lab’s standards to be publicly available on our B Corp profile on B Lab’s website.

  ],
)]
)

#pagebreak()
#col-2()[
== Posit\'s B Lab Impact Assessment Results
<posits-b-lab-impact-assessment-results>
The BLab Impact Assessment is composed of questions in five Impact Areas: Governance, Workers, Community, Environment, and Customers. Posit\'s assessment results are available to the public \[here\]. We completed our first Impact Assessment in 2019 with our initial B Lab certification, and earned an overall score of #strong[86.1.] We are proud to report that our latest score from our recertification process in 2023, is #strong[92.5];. To put this in context, the threshold for B Lab certification is a score of 80 or higher, and the median score for ordinary businesses who take the assessment is 50.9.

#colbreak()
Posit seeks to continually improve our internal governance, increase our workforce diversity and employee development efforts, expand our stewardship of the environment, deepen our engagement in our communities, and better serve our customers, so that our public benefit will continue to improve each year.

In our initial assessment, we received high marks for incorporating as a benefit corporation; the health, wellness, safety, and financial security of our employees; and for educating and serving customers. We identified formal goal setting, career development, diversity, equity & inclusion, civic engagement & giving, and air & climate as areas for improvement.

]
#pagebreak()
== Summary of Score Improvements Since 2019
<summary-of-score-improvements-since-2019>
The B Lab’s Impact assessment standards have evolved since 2019 \(we are now on version 6 of the assessment). New questions were added, and thresholds for performance were raised in other cases. Of the scored questions we responded to in our most recent assessment, 38 were unchanged from 2019, 71 were modified from 2019 wording, and 22 were brand new questions. On the questions that were unchanged or modified, we have gained points in the areas listed below.

#figure(
align(center)[#table(
  columns: 3,
  align: (col, row) => (left,left,left,).at(col),
  inset: 6pt,
  [#strong[Impact Area];], [#strong[Topic];], [#strong[% Achievement Gain since 2019];],
  [Community],
  [Civic Engagement & Giving],
  [39%],
  [],
  [Diversity, Equity, & Inclusion],
  [60%],
  [Customers],
  [Customer Stewardship],
  [28%],
  [Environment],
  [Air & Climate],
  [75%],
  [Governance],
  [Ethics & Transparency],
  [37%],
  [Workers],
  [Career Development],
  [62%],
  [],
  [Engagement & Satisfaction],
  [50%],
  [],
  [Financial Security],
  [58%],
)]
)

=== 
<section>
#col-2()[
=== COMMUNITY
<community>
==== Open Source Development
<open-source-development>
==== Civic Engagement and Giving
<civic-engagement-and-giving>
In addition to the open-source software we make freely available, and the open source data science package development produced by Posit engineers, Posit recognizes the importance of contributing financially to other valuable open-source and community initiatives. To date, Posit has givenover \$1.9M to projects led by others. Current commitments include contributing to NumFOCUS, the R Consortium, the R Foundation, DuckDB, the Eclipse Foundation, and the authors and maintainers of several other open-source projects.

Posit’s financial support also extends beyond the world of open source data science. Since 2020, Posit and its employees have given over \$60k to over 135 nonprofits. Our donations reach a range of community-based causes, including organizations dedicated to racial equality, equal justice, LGBTQ+ support, and access to education. Alongside our donations to open source software development, this pool of charitable contributions contribute to the important work many are doing to increase the accessibility of data science for all. Our scoring in this area of the B Lab assessment has increased by 39.5% since 2019.

==== Diversity, Equity, and Inclusion
<diversity-equity-and-inclusion>
Since our initial B Lab assessment in 2019, Posit has continued to focus on increasing the strength of our team by utilizing talent practices that encourage diverse people to apply, join, and thrive at Posit. Specific changes made in recent years include the formation of a DEIA \(diversity, equity, inclusion, and accessibility) Council, as well as the sponsoring of employee resource groups \(ERG’s). We report our progress on our diversity metrics, as defined in the B Lab Assessment, in each quarter’s board meeting. We also pay close attention to issues of equity in compensation, hiring and interviewing, and employee experience. Our efforts to date have yielded increases in the percentages of women and those with minority racial or ethnic identities in both management and the employee population as a whole – and our recent assessment results reflect these gains.

=== CUSTOMERS
<customers>
We have made meaningful improvements in our care for customers in the past few years – particularly in our standards for managing customer data and privacy. Since 2019, we have formalized our approach to data privacy and compliance – we now conduct thorough internal and external audits, and train all employees on the essentials of guarding customer data. These changes have increased our assessment performance by 28% since 2019.

=== ENVIRONMENT
<environment>
We are happy to share that our assessment scores for Air and Climate impacts have improved by 75% since 2019. In November of 2020, Posit achieved carbon neutrality via the purchase of carbon offsets that counter the environmental impact of business travel \(primarily for our annual conference and internal meetings). As a remote-first organization, we do not generate meaningful greenhouse gas emissions outside of air travel. By offsetting this impact through the funding of reforestation work in both South America and closer to home in Massachusetts, we hope to neutralize Posit’s potential damage to our planet.

=== GOVERNANCE
<governance>
A company’s positive governance impact is measured by the extent to which the company is accountable to stakeholders, and the extent to which its decision-making is transparent to all constituents. In 2019, RStudio scored 16.1 points out of a possible 21.9+ points in the Governance Impact Area, including 10 points awarded for the specific legal structures we have put in place as a Benefit Corporation that preserve our mission and consider our stakeholders regardless of company ownership.

In our latest assessment, our governance score improved by 37% via improvements in ethics and transparency areas, including anti-corruption and code of ethics training for employees, and more rigorous financial controls and financial transparency with employees. Looking ahead, we plan to incorporate more social and community benefit metrics in our corporate reporting, including board meeting updates, so that all of our stakeholders are aware of our ongoing progress and can help support our success.

=== WORKERS
<workers>
We have made significant strides in our Worker assessment category since 2019, with scores increasing by 50% or more in areas such as career development, engagement and satisfaction, and financial security for our employees. Investments in employee career development include in-house management training programs, tooling and education to support constructive feedback, and documentation of job levels, pay ranges, and career paths within our major functions. In 2021, we initiated an annual organizational health survey, which allows us to collect and respond to employee feedback. We have also augmented our benefits to include a "lifestyle savings account" \(LSA) funded by Posit that each individual can choose to apply to home office, professional development, wellness, or financial health expenses as they see fit. All together, we are working to continuously improve the value offered to our workers as our company grows.

]
#conclusion()[
= Conclusion
<conclusion>
Etiam maximus accumsan gravida. Maecenas at nunc dignissim, euismod enim ac, bibendum ipsum. Maecenas vehicula velit in nisl aliquet ultricies. Nam eget massa interdum, maximus arcu vel, pretium erat. Maecenas sit amet tempor purus, vitae aliquet nunc. Vivamus cursus urna velit, eleifend dictum magna laoreet ut. Duis eu erat mollis, blandit magna id, tincidunt ipsum. Integer massa nibh, commodo eu ex vel, venenatis efficitur ligula. Integer convallis lacus elit, maximus eleifend lacus ornare ac. Vestibulum scelerisque viverra urna id lacinia. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Aenean eget enim at diam bibendum tincidunt eu non purus. Nullam id magna ultrices, sodales metus viverra, tempus turpis.

]
#back_page()[
  Trademark language here
]



