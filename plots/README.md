# Plots

Generated figures for the report. **Do not edit these by hand** — they are
overwritten on each render.

Each figure is written twice, sharing a basename:

- `*.svg` — used by the Typst/PDF build (`pbc-report.pdf`)
- `*.png` — used by the HTML/web build (192 dpi)

They are produced by rendering [`../data/generate-plots.qmd`](../data/generate-plots.qmd):

```bash
quarto render data/generate-plots.qmd
```

That document sets `knitr: opts_chunk: fig.path: "../plots/"` so both formats
write here, and pins `fig-width`/`fig-height`/`fig-dpi` so the two versions match.

The report (`sections/*.qmd`) references figures with **extensionless** paths,
e.g. `![](plots/quarto-1)`. Quarto's per-format `default-image-extension` then
picks `.svg` for Typst and `.png` for HTML automatically.
