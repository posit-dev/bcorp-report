//   Custom title page
#let posit_blue = rgb("#447099")
#let posit_grey = rgb("#404041")
#let posit_orange = rgb("#EE6331")
#let posit_dark_blue_2 = rgb("#213D4F")

#let page_blue(content)={
    set page(fill: posit_blue)
    set line(stroke: 1pt + white)
    set text(fill: white)
    content
  }


#let title_page(title, subtitle)={
    page(margin: 0in)[
        #set text(fill: white)
        #place(center + horizon, dy: -2in)[
            #set align(center + horizon)
            #block(width: 100%, fill: posit_dark_blue_2, outset: 2em)[
                #heading(level: 1, title)
                #heading(level: 2, subtitle)
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
    numbering: "1",
  )

  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize,
           fill: posit_grey)

  show heading.where(level: 1): set text(weight: "light", size: 24pt)

  if title != none {
    title_page(title, subtitle)
  }

  set line(stroke: 1pt + posit_orange)

  show heading.where(level: 1): it => {
    pagebreak()
    set block(width: 100%, below: 1em)
    it
    block(line(length: 100%, stroke: 1pt), below: 2em)
  }

  show heading.where(level: 2): it => {
    set block(below: 1.5em)
    upper(it)
  }

  doc
}

