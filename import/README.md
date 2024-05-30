## Updating from Google Docs

`initial-import.R` has an example of getting the content out of Google Docs and into `.md`, this forms the basis of `pbc-report.qmd`.

To update `pbc-report.qmd` with changes from the Google Doc:

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