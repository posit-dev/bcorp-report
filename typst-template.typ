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
    set page(fill: posit_colors.dark_blue_3)
    set text(fill: posit_colors.light_blue_1)
    show heading: set text(fill: posit_colors.light_blue_2)
    content
  }

#let col-2(content)={
    columns(2, content)
} 

#let banner(content)={
    set text(fill: white)
    block(width: 100%, outset: (x: 1.25in), inset: (y: 2em), fill: posit_colors.blue, content)
}

//   Custom title page
#let title_page(title, subtitle)={
    page(margin: 0in, fill: posit_colors.blue)[
        #set text(fill: white)

        #place(center + horizon, dy: -2in)[
            #set align(center + horizon)
            #block(width: 100%, fill: posit_colors.blue, outset: 2em)[
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
  
  show heading.where(level: 1): it => {
    pagebreak()
    set block(width: 100%, below: 1em)
    it
  }

  show heading.where(level: 2): it => {
    set block(below: 1.5em)
    upper(it)
  }

  doc
}

