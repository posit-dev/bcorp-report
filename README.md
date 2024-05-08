-   `import/` has an example of getting the content out of Google Docs and into `.md`
-   `pbc-report.qmd` has `.md` content plus some editing to handle a few style changes (e.g. switching page themes)
-   Most styling happens in a Typst template: `typst-template.typ`

## Updating from Google Docs

1.  Clean Git status

2.  Run `import/initial-import.R`. Commit changes to `raw-report.md`.

3.  Generate patch:

    ``` bash
    git format-patch HEAD^ --stdout > patch
    ```
    
    Edit header to point at `pbc-report.qmd`

4.  Apply patch:
    
    ``` bash
    git apply --3way -C1 --recount patch
    ```

5.  Resolve conflicts and merge.