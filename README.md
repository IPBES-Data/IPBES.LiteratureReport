# IPBES_Literature-Report

The repository contains the code to build the reports for the IPBES repositories.

To generate the reports, do the following:

1. Clone the repository
2. Render the document `index.qmd`. This will
    - install "devtools" and all dependencies needed for the code to run
    - dowlnoad the IPBES Zotero Libraries and store them as `.csv` files in ther folder `input`
    - generate the measures and graphs for the reports from all Zotero Libraries in the folde `_targets`
    - generate the reports in the folder `output`
    - create or update the file `index.html` which contains all the links to the reports

The following commands are "user commands":

- **`update_groups()`** Download new libraries from Zotero and update the local csv files.
- **`update_groups(overwrite = TRUE)`** Re-download all libraries from Zotero and update the local csv files.
- **`targets::tar_make()`**: Re-generate all out of date elements of the reports.

