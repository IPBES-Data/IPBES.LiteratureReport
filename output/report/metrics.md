# Metrics

## identifiers

### DOI coverage (`met_id_doi`)

Number and share of items with a valid DOI, and items whose DOI field is
filled but contains no valid DOI. DOIs are extracted with
`openalexPro::extract_doi()` and lower cased.

**Result:** A list with
- `doi_raw`: content of the DOI field, named by item key / OpenAlex id
- `doi`: valid DOIs, named by item key / OpenAlex id
- `invalid`: filled DOI fields without a valid DOI
- `count`: number of valid DOIs
- `count_invalid`: number of invalid DOI fields
- `pc`: percentage of items with a valid DOI

### ISBN coverage (`met_id_isbn`)

Number and share of items with an ISBN, overall and for the item types
which should have one (`book`, `bookSection`).

**Result:** A list with
- `isbn`: ISBNs, named by item key
- `count`: number of items with an ISBN
- `pc`: percentage of all items with an ISBN
- `pc_expected`: percentage of books and book sections with an ISBN

### ISSN coverage (`met_id_issn`)

Number and share of items with an ISSN, overall and for the item types
which should have one (`journalArticle`, `magazineArticle`).

**Result:** A list with
- `issn`: ISSNs, named by item key
- `count`: number of items with an ISSN
- `pc`: percentage of all items with an ISSN
- `pc_expected`: percentage of journal and magazine articles with an ISSN

### DOIs in the wrong field (`met_id_doi_misplaced`)

Items with an empty DOI field but a DOI in the `Url` or `Extra` field.
These DOIs are not used for the OpenAlex lookup and should be moved to the
DOI field.

**Result:** A list with
- `items`: tibble with `key`, `title`, `doi_in_url` and `doi_in_extra`
- `count`: number of items with a misplaced DOI
- `pc`: percentage of all items with a misplaced DOI

### DOIs in the wrong form (`met_id_doi_form`)

Items whose DOI field contains a valid DOI, but not as a bare DOI: as a link
(`https://doi.org/10.…`), with a prefix (`doi:`, `DOI `), URL-encoded
(`%5B` for `[`) or with spaces or other characters around it. Citation
styles add the link themselves, so a link in the DOI field appears twice in
a bibliography. The bare DOI is the one recognised by
`openalexPro::extract_doi()`, keeping its upper and lower case.

**Result:** A list with
- `items`: tibble with `key`, `title`, `doi_raw` (content of the DOI field)
  and `doi` (the bare DOI)
- `count`: number of items with a DOI in the wrong form
- `pc`: percentage of all items with a DOI in the wrong form

### Items without identifier (`met_id_none`)

Items with none of DOI, ISBN, ISSN or Url. These items can neither be
checked against OpenAlex nor easily be retrieved by readers.

**Result:** A list with
- `items`: tibble with `key`, `type` and `title`
- `count`: number of items without identifier
- `pc`: percentage of all items without identifier

### DOIs found in OpenAlex for items without a DOI (`met_id_candidates`)

For items without a DOI, OpenAlex was searched by title (see
[get_doi_candidates()]). The works found are compared with the item:
title (ignoring case and punctuation), year and the surname of the first
author. A work is a *likely* match if the titles are (nearly) the same
(similarity at least 0.95), the years differ by at most 1 and the first
authors have the same surname (year or author are not compared if the item
has none), and the title has at least 4 words (short titles like
"Zoonoses" are too general). It is a *possible* match if the titles are similar (at least
0.8). Only the best work with a DOI is kept per item. A likely match is
only proposed if no other likely match has a different DOI, and if the DOI
is not used by another item in the group (which would make it a
duplicate).

**Result:** A list with
- `items`: tibble with `key`, `title`, `year`, `author` (first author) of
  the item, and `doi`, `id`, `cand_title`, `cand_year`, `cand_author`,
  `cand_journal` of the work found, `similarity` (titles), `match`
  (`likely` or `possible`) and `note` (why a likely match is not
  proposed, else `NA`)
- `count_searched`: number of items searched
- `count_likely`: items with a likely match which is proposed
- `count_possible`: items with a possible match, or a likely one which is
  not proposed

## metadata

### Filled fields per item type (`met_meta_fields`)

Percentage of items with a filled field, per item type, for the main
fields: Title, Author, Publication Year, Publication Title, Publisher, DOI,
ISBN, ISSN, Url, Abstract Note and Language. Not every field is expected
for every item type, e.g. reports have no Publication Title.

**Result:** A list with
- `pc_filled`: tibble with one row per item type: `type`, `count` and the
  percentage of items with a filled field, one column per field

### Problematic publication years (`met_meta_year`)

Items whose date is missing (`missing`), from whose date Zotero could not
derive a year (`unparseable`), or whose year lies in the future
(`future`).

**Result:** A list with
- `items`: tibble with `key`, `title`, `date`, `year` and `problem`
- `count`: number of items per problem (`missing`, `unparseable`,
  `future`)
- `pc`: percentage of all items per problem

### Duplicate items (`met_meta_duplicates`)

Items which are in the group more than once, identified by the same DOI,
or by the same normalised title (lower case, letters and digits only),
publication year and first word of the first author.

**Result:** A list with
- `by_doi`: tibble with `doi`, `keys` of the duplicates, `title` and
  `count`
- `by_title`: tibble with `year`, `first_author`, `keys` of the
  duplicates, `title` and `count`
- `count_doi`, `count_title`: number of surplus copies, i.e. items which
  could be removed

### Language not given as a standard code (`met_meta_language`)

Items whose language is not given as a standard language code, i.e. a
two-letter ISO 639-1 code, optionally with a region (`en`, `en-US`), but
e.g. as a name (`English`), a three-letter code (`eng`) or in a different
spelling (`EN`, `en_us`). Citation styles and other tools only recognise the
codes. Where the value is recognised, the standard code is proposed, based
on the ISO 639-2 list (R package ISOcodes): codes, three-letter codes and
the English names of the languages. Other values, e.g. names in the language
itself, several languages or other text, are listed without a proposal.

**Result:** A list with
- `items`: tibble with `key`, `title`, `language` (as entered) and `code`
  (proposed standard code, `NA` if not recognised)
- `count`: number of items whose language is not a standard code
- `count_recognised`: of these, items for which a code is proposed
- `pc`: percentage of all items whose language is not a standard code

## openalex_check

### Zotero DOIs found in OpenAlex (`met_check_found`)

Valid Zotero DOIs which were / were not found in OpenAlex. A DOI which is
not found is either not indexed by OpenAlex or wrong.

**Result:** A list with
- `zotero_in_oa`: DOIs found, named by item key
- `zotero_not_in_oa`: DOIs not found, named by item key
- `count_not_in_oa`: number of DOIs not found
- `pc_in_oa`: percentage of valid Zotero DOIs found

### Retracted works (`met_check_retracted`)

Works flagged as retracted by OpenAlex, with the key of the Zotero item(s)
with the same DOI.

**Result:** A list with
- `items`: tibble with the OpenAlex `id`, `doi`, `title` and the Zotero
  item `key`
- `count`: number of retracted works

### Wrong DOIs (`met_check_mismatch`)

Items whose DOI points in OpenAlex to a work with a different title or
year, which usually means that the wrong DOI is attached to the item. An
item is flagged when the title similarity (normalised Levenshtein
distance) is below 0.8 or the years differ by more than one.

**Result:** A list with
- `items`: tibble with `key`, `doi`, `title_zotero`, `title_openalex`,
  `title_similarity`, `year_zotero` and `year_openalex`
- `count`: number of flagged items
- `pc`: percentage of the items found in OpenAlex which are flagged

### Item type agreement (`met_check_type`)

Zotero item type compared with the OpenAlex work type for items with the
same DOI.

**Result:** A list with
- `comparison`: tibble with `type_zotero`, `type_openalex` and `count`

### Missing dates found in OpenAlex (`met_check_date`)

Items without a date whose DOI was found in OpenAlex: the publication date
in OpenAlex is proposed. OpenAlex gives 1 January when only the year is
known, so such dates are proposed as the year only. Items whose DOI points
to a different publication are left out.

**Result:** A list with
- `items`: tibble with `key`, `title`, `doi` and `date` (the publication
  date in OpenAlex, `YYYY-MM-DD`, or `YYYY` if only the year is known)
- `count`: number of items without a date for which OpenAlex has one

### Empty fields found in OpenAlex (`met_check_fill`)

Journal articles with an empty journal, volume, issue or pages field whose
DOI was found in OpenAlex with these details: the values in OpenAlex are
proposed. The journal is only taken if the publication is in a journal in
OpenAlex (not e.g. a repository). Items whose DOI points to a different
publication are left out.

**Result:** A list with
- `items`: tibble with `key`, `title`, `doi`, `field` (Zotero field:
  `publicationTitle`, `volume`, `issue` or `pages`) and `value` (in
  OpenAlex), one row per empty field, sorted by publication
- `count`: number of items with at least one field to fill
- `count_fields`: number of fields to fill

## profile

### Publication years (`met_prof_year`)

Number of items per publication year, with cumulative counts. Items
without a year are counted as `NA`.

**Result:** A list with
- `by_year`: tibble with `year`, `count`, proportion `p`, `count_cumsum`
  and `p_cumsum`

### Open access status (`met_prof_oa`)

OpenAlex open access status (gold, diamond, green, hybrid, bronze, closed)
of the works, overall and per publication year.

**Result:** A list with
- `total`: tibble with `oa_status`, `count` and `pc`
- `by_year`: tibble with `year`, `oa_status` and `count`

### Top journals (`met_prof_journals`)

The 50 most frequent journals, from the Publication Title in Zotero and the
source of the primary location in OpenAlex. Ties at rank 50 are included.

**Result:** A list with
- `top`: tibble with `journal` and `count`

### Author countries (`met_prof_countries`)

Number of works with at least one author affiliated with an institution in
a country, per country (ISO 3166-1 alpha-2 codes from OpenAlex).

**Result:** A list with
- `by_country`: tibble with `country` and `count`
- `count_no_country`: number of works without any country

### Item types and grey literature (`met_prof_types`)

Number of items per item type (Zotero) or work type (OpenAlex), and the
share of grey literature, i.e. reports, theses, dissertations, web pages,
documents, presentations, manuscripts, blog posts and preprints.

**Result:** A list with
- `by_type`: tibble with `type`, `count`, `grey` (logical) and `pc`
- `pc_grey`: percentage of grey literature

### Languages (`met_prof_language`)

Languages as entered, and normalised to two letter codes (lower case,
region removed, English spellings mapped to `en`). Inconsistent codes in
the language as entered are a quality issue in themselves.

**Result:** A list with
- `raw`: tibble with `language` as entered and `count`
- `by_language`: tibble with normalised `language` and `count`
- `pc_missing`: percentage of items without language
- `pc_english`: percentage of items in English

## maintenance

### Group activity (`met_maint_activity`)

Items added per month, and items added / modified in the 30 days before
the metrics were calculated.

**Result:** A list with
- `added_by_month`: tibble with `month`, `count` and `count_cumsum`
- `added_last_30d`: number of items added in the last 30 days
- `modified_last_30d`: number of items modified in the last 30 days

### Items without tags (`met_maint_tags`)

Items without manual tags. Automatic tags, e.g. keywords imported from the
publisher, are ignored.

**Result:** A list with
- `items`: tibble with `key`, `type` and `title`
- `count`: number of items without manual tags
- `pc`: percentage of all items without manual tags
