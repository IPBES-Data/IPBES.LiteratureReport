# IPBES_Literature-Report

The repository contains the code to build the reports for the IPBES repositories.

To generate the reports, do the following:

1. Start R
1. Install the package by running the following command:
    ```r
    remotes::install_github("IPBES/IPBES_Literature-Report")
    ```
3. Load the package by running the following command:
    ```r
    library(IPBES_Literature_Report)
    ```
4. Run the command 
    ```r
    make_all()
    ```
    and wait. This will render the document `index.qmd` and
        - dowlnoad the IPBES Zotero Libraries and store them as `.csv` files in ther folder `input`
        - generate the measures and graphs for the reports from all Zotero Libraries in the folde `_targets`
        - generate the reports in the folder `output`
        - create or update the file `index.html` which contains all the links to the reports

This is all you should have to know to use this package.

All functions are documented in the package. You can access the documentation by running `?function_name` in R.
