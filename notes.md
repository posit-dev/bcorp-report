## Google Doc -> Markdown

Export as .docx -> Pandoc

```{.r}
library(rmarkdown)

pandoc_convert(
    path, 
    to = "markdown",
    output = here(md_path)
  )
```

## Template

* Custom title page
* Similar Conclusion Page
* Custom Final Page


* General
    - Full width H1
    - Line
    - Two column text
    - All caps H2


* White page
    - Grey text
    - Orange line
    - Blue links
* Blue page
   - White text
   - Blue links (same blue)
