# Posit's Benefit Corporation Annual Report

This repository holds the source for the PDF version of Posit's Benefit Corporation Annual Report found at <https://posit.co/about/pbc-report/>.

The report content lives in `pbc-report.qmd` and is produced using `format: typst` with the custom template partials in `typst-template.typ` and `typst-show.typ`.

## Local rendering

To preview the report:

```{.bash}
quarto preview pbc-report.qmd
```

## Updating download data and plots

To update the data and/or plots you'll need R.

When you first open the project (in RStudio or Positron), renv should bootstrap itself:

```
# Bootstrapping renv 1.0.5 ---------------------------------------------------
- Downloading renv ... 
OK
- Installing renv  ... OK

- Project '~/Desktop/bcorp-report' loaded. [renv 1.0.5]
- One or more packages recorded in the lockfile are not installed.
- Use `renv::status()` for more details.
```

Then to get the required packages, on the R Console, run:

```{.r}
renv::restore()
```
### Update data

Data extraction scripts live in `data/`, one per output CSV
(`get_python_package_downloads.R`, `get_r_package_downloads.R`,
`get_rstudio_os_downloads.R`, `get_quarto_downloads.R`). See `data/README.md`.

### Update plots

Plots are written to the top-level `plots/` directory, one `.svg` (used by the
Typst/PDF build) and one `.png` (used by the HTML/web build) per figure, sharing
the same basename (e.g. `plots/quarto-1.svg` and `plots/quarto-1.png`). The
report references them with extensionless paths (e.g. `![](plots/quarto-1)`), and
Quarto picks the right extension per format.

Re-render `data/generate-plots.qmd` to update the plots in the report:

```{.bash}
quarto render data/generate-plots.qmd
```




