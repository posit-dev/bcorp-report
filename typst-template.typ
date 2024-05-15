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

#let back_page(repo: none, content)={
  page_blue()[
      #set page(background: hex_background, numbering: none)
      #set text(fill: white)
      #show link: set text(fill: white)
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
  
  set table(
    align: left,
    inset: 7pt,
    stroke: (x: none, y: 0.5pt)
  )

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

