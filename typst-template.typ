//   Custom title page
#let title_page(title, subtitle)={
    page(margin: 0in)[
        #set text(fill: white)
        #place(center + horizon, dy: -2in)[
            #set align(center + horizon)
            #block(width: 100%, fill: rgb("#444444"), outset: 2em)[
                #heading(level: 1, title)
                #heading(level: 2, subtitle)
            ]
        ] 
    ]
}

#let posit(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
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
           size: fontsize)

  set heading(numbering: sectionnumbering)

  if title != none {
    title_page(title, subtitle)
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[Abstract] #h(1em) #abstract
    ]
  }

  if toc {
    block(above: 0em, below: 2em)[
    #outline(
      title: auto,
      depth: none
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}
