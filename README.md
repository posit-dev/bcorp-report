-   `import/` has an example of getting the content out of Google Docs and into `.md`
-   `pbc-report.qmd` has `.md` content plus some light editing to handle a few style changes (e.g. switching page themes)
-   Most styling happens in a Typst template: `typst-template.typ`

## Updating from Google Docs

1.  Clean Git status

2.  Run `import/initial-import.R`. Commit changes to `raw-report.md`.

3.  Generate patch:

    ``` bash
    git format-patch --relative HEAD^ --stdout > patch
    ```

4.  Apply patch:

    ``` bash
    git am --3way --directory pbc-report.qmd patch
    ```

5.  Resolve conflicts and merge.