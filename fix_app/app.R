# Local app to fix Zotero items found by the report, through the Zotero Safe
# Edit plugin. The app proposes changes and shows them; the plugin checks them,
# asks for approval in Zotero, writes them and keeps the log. The app stores
# nothing itself. Start with run_fix_app() from the project directory.

library(shiny)

project <- getOption("fix_app.project", normalizePath(".."))
source(file.path(project, "R", "report_helpers.R"))
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) {
  source(f)
}

cfg <- yaml::read_yaml(file.path(project, "input", "config.yaml"))
groups <- stats::setNames(
  vapply(cfg$assessments, function(a) as.numeric(a$id), numeric(1)),
  vapply(cfg$assessments, function(a) a$name, "")
)

# fix types: label -> function(m, group_id)
fixes <- list(
  "DOI in URL or Extra → DOI field" = fix_doi_misplaced,
  "DOI link or prefix → DOI" = fix_doi_form,
  "Language → language code" = fix_language,
  "Missing date → date from OpenAlex" = fix_date,
  "Empty journal, volume, issue, pages → from OpenAlex" = fix_fill
)

# check in the report (rep_checks()) each fix belongs to, for its status
fix_checks <- c(
  "DOI in URL or Extra → DOI field" = "misplaced-doi",
  "DOI link or prefix → DOI" = "doi-form",
  "Language → language code" = "language",
  "Missing date → date from OpenAlex" = "year",
  "Empty journal, volume, issue, pages → from OpenAlex" = "fill"
)

# whether Zotero has the new value of a change already; DOIs are not case
# sensitive, other fields are (`EN` -> `en` is a change)
is_made <- function(now, changes) {
  doi <- changes$field == "DOI"
  !is.na(now) & ifelse(doi, tolower(now) == tolower(changes$new), now == changes$new)
}

metrics_file <- function(group_id) {
  name <- names(groups)[groups == group_id]
  file.path(project, "output", "metrics", paste0("IPBES_", name, "_", group_id, ".rds"))
}

read_metrics <- function(group_id) {
  name <- names(groups)[groups == group_id]
  file <- metrics_file(group_id)
  if (!file.exists(file)) {
    stop("No metrics for group ", name, " — run the pipeline first.", call. = FALSE)
  }
  readRDS(file)
}

# before / after lines of a difference, as computed by the plugin. Built
# without any whitespace between the parts: values are shown with
# white-space: pre-wrap, so whitespace between tags would appear in the value.
diff_html <- function(diff) {
  span <- function(text, class = NULL) {
    paste0(
      "<span", if (!is.null(class)) paste0(' class="', class, '"'), ">",
      htmltools::htmlEscape(text),
      "</span>"
    )
  }
  line <- function(show, class) {
    parts <- unlist(lapply(diff$segments, function(s) {
      if (s$type == "same") {
        span(s$display)
      } else if (s$type == show) {
        span(s$display, s$type)
      }
    }))
    if (!length(parts)) {
      parts <- span("(empty)", "empty")
    }
    paste0('<div class="value ', class, '">', paste0(parts, collapse = ""), "</div>")
  }
  notes <- unlist(diff$notes)
  paste0(
    line("removed", "before"),
    line("added", "after"),
    if (length(notes)) {
      paste0('<div class="notes">', htmltools::htmlEscape(paste("Note:", paste(notes, collapse = "; "))), "</div>")
    }
  )
}

# links to open items in Zotero. Browsers often block zotero:// links, so the
# "app" link asks the server (running on this computer) to open it.
zotero_links <- function(keys, group_id) {
  url <- paste0("zotero://select/groups/", group_id, "/items/", keys)
  paste0(
    'Zotero: <a href="https://www.zotero.org/groups/', group_id, "/items/", keys,
    '" target="_blank">web</a> &middot; ',
    '<a href="#" onclick="Shiny.setInputValue(\'open_zotero\', \'', url,
    '\', {priority: \'event\'}); return false;">app</a>'
  )
}

# opens a zotero:// link with the system; only links to items are accepted
open_in_zotero <- function(url) {
  if (!is.character(url) || length(url) != 1 ||
    !grepl("^zotero://select/groups/[0-9]+/items/[A-Z0-9]+$", url)) {
    return(invisible(FALSE))
  }
  utils::browseURL(url)
  invisible(TRUE)
}

# times from the plugin (UTC, ISO 8601) in local time
local_time <- function(x) {
  format(
    as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC"),
    tz = "",
    "%Y-%m-%d %H:%M:%S"
  )
}

# traffic light in the colours of the report (rep_status_label)
light <- function(ok, text) {
  span(
    style = paste0("color:", if (ok) "#1a7f37" else "#c62828", "; font-weight: bold;"),
    HTML("&#9679; "),
    text
  )
}

# run f, show errors as notification
safely <- function(f) {
  tryCatch(f(), error = function(e) {
    showNotification(conditionMessage(e), type = "error", duration = NULL)
    NULL
  })
}

# readable reasons why the plugin did not apply (some) changes
explain <- function(r) {
  reasons <- c(
    unlist(r$reasons),
    vapply(r$refused %||% list(), function(x) x$reason, ""),
    vapply(
      Filter(function(x) !isTRUE(x$ok), r$rows %||% list()),
      function(x) paste0(x$title %||% x$item_key, ": ", x$problem),
      ""
    )
  )
  if (length(reasons)) paste0(" — ", paste(unique(reasons), collapse = "; ")) else ""
}

css <- "
.value { white-space: pre-wrap; overflow-wrap: anywhere; font-family: monospace;
         padding: 1px 4px; background: #f7f7f7; margin: 1px 0; }
.value.before::before { content: 'before: '; color: #888; }
.value.after::before { content: 'after: '; color: #888; }
.removed { background: #ffd7d5; text-decoration: line-through; }
.added { background: #ccf0d4; }
.empty { color: #999; font-style: italic; }
.notes { color: #555; font-size: 0.9em; }
.warn { color: #c62828; font-weight: bold; }
.intro { max-width: 60em; }
.made { opacity: 0.55; }
table.status { margin-bottom: 10px; }
table.status th { font-weight: normal; padding: 4px 16px 4px 0; }
table.status td { padding: 4px 16px 4px 0; }
table.status .count { text-align: right; }
"

# table of proposed changes, as shown in the Fixes and Restore tabs
changes_table <- function(changes, rows, doi, openalex, group_id, check = NULL) {
  tibble::tibble(
    # from Zotero; from the report if the item is not in this Zotero
    Title = dplyr::coalesce(
      dplyr::na_if(vapply(rows, function(r) r$title %||% "", ""), ""),
      changes$title
    ),
    Field = vapply(rows, function(r) r$field %||% "", ""),
    Change = vapply(rows, function(r) diff_html(r$diff), ""),
    Why = vapply(rows, function(r) r$reason_for_change %||% "", ""),
    Check = if (is.null(check)) {
      vapply(rows, function(r) if (isTRUE(r$ok)) "OK" else r$problem, "")
    } else {
      rep(check, length(rows))
    },
    Open = paste0(zotero_links(changes$item_key, group_id), doi_link(doi), openalex_link(openalex))
  )
}

# changes which are not proposed, to be fixed by hand. Items whose value in
# Zotero was changed since the report are marked as fixed locally (not
# marked if the plugin cannot be reached).
not_proposed_table <- function(x) {
  now <- rep(NA_character_, nrow(x))
  if (nrow(x)) {
    pv <- tryCatch(se_preview(x), error = function(e) NULL)
    if (!is.null(pv)) {
      now <- vapply(pv$rows, function(r) r$current %||% NA_character_, "")
    }
  }
  fixed <- !is.na(now) & now != x$old
  dplyr::transmute(
    x,
    Title = title,
    Field = field,
    Value = old,
    Note = ifelse(
      fixed,
      paste0("Fixed locally (now: ", ifelse(now == "", "empty", now), ")"),
      note
    ),
    Open = zotero_links(item_key, group_id)
  )
}

# ---- proposed changes: table, sending for approval, result ------------------
# Used by the Fixes and the Restore tab. `compute()` returns
# list(changes, not_proposed, action) or NULL; `reset` lists the inputs whose
# change makes the shown proposals obsolete.

changes_ui <- function(id) {
  ns <- NS(id)
  # sections appear only when they have content
  tagList(
    uiOutput(ns("result_ui")),
    uiOutput(ns("proposals_ui")),
    uiOutput(ns("not_proposed_ui"))
  )
}

changes_server <- function(id, group, status, load, reset, compute, done) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    pending <- reactiveVal(NULL) # list(changes, preview, action)
    not_proposed <- reactiveVal(NULL)
    result <- reactiveVal(NULL)
    n_done <- reactiveVal(0) # changes left out because they are made already

    clear <- function() {
      pending(NULL)
      not_proposed(NULL)
      result(NULL)
      n_done(0)
    }
    observeEvent(reset(), clear())

    observeEvent(load(), ignoreInit = TRUE, {
      clear()
      x <- compute()
      if (is.null(x)) return()
      not_proposed(x$not_proposed)
      if (!nrow(x$changes)) {
        showNotification("Nothing to change.")
        return()
      }
      pv <- safely(function() se_preview(x$changes))
      if (is.null(pv)) return()
      # OpenAlex work of the DOI an item gets (or keeps), if it exists
      doi <- ifelse(x$changes$new != "", x$changes$new, x$changes$old)
      doi[x$changes$field != "DOI"] <- NA
      # fixes taking values from the DOI's work give the DOI in a `doi` column
      if ("doi" %in% names(x$changes)) doi <- dplyr::coalesce(doi, x$changes$doi)
      oa <- unname(openalex_ids(doi)[tolower(doi)])
      # changes whose value is in Zotero already are made: they cannot be
      # applied again and are shown separately on request
      now <- vapply(pv$rows, function(r) r$current %||% NA_character_, "")
      made <- is_made(now, x$changes)
      n_done(sum(made))
      pv_open <- pv
      pv_open$rows <- pv$rows[!made]
      pending(list(
        changes = x$changes[!made, ],
        preview = pv_open,
        action = x$action,
        doi = doi[!made],
        openalex = oa[!made],
        done = list(
          changes = x$changes[made, ],
          rows = pv$rows[made],
          doi = doi[made],
          openalex = oa[made]
        )
      ))
    })

    output$proposals_ui <- renderUI({
      pc <- pending()
      req(pc)
      # the batch limit is handled by sending in several batches
      b <- unlist(pc$preview$blockers)
      b <- b[!grepl("^Too many changes", b)]
      tagList(
        hr(),
        h4("Proposed changes"),
        if (!nrow(pc$changes)) {
          p(sprintf("Nothing outstanding — all %d changes are made already.", n_done()))
        } else {
          tagList(
            if (length(b)) {
              div(class = "warn", "Zotero will refuse these changes: ", tags$ul(lapply(b, tags$li)))
            },
            reactable::reactableOutput(ns("proposals")),
            br(),
            actionButton(ns("send"), "Send selected changes to Zotero for approval", class = "btn-primary")
          )
        },
        if (n_done()) {
          tagList(
            br(),
            checkboxInput(
              ns("show_done"),
              sprintf("Show the %d change%s made already", n_done(), if (n_done() == 1) "" else "s")
            ),
            uiOutput(ns("done_ui"))
          )
        }
      )
    })

    # changes made already: greyed out, without tick boxes
    output$done_ui <- renderUI({
      req(isTRUE(input$show_done))
      d <- pending()$done
      div(
        class = "made",
        p(
          class = "notes",
          "These changes are in Zotero already and cannot be applied again. ",
          "Changes made through Safe Edit can be undone in the Undo tab."
        ),
        reactable::reactable(
          changes_table(d$changes, d$rows, d$doi, d$openalex, group(), check = "Made already"),
          columns = list(
            Change = reactable::colDef(html = TRUE, minWidth = 300),
            Open = reactable::colDef(html = TRUE, minWidth = 90)
          ),
          searchable = TRUE,
          defaultPageSize = 25,
          wrap = TRUE
        )
      )
    })

    output$not_proposed_ui <- renderUI({
      x <- not_proposed()
      req(!is.null(x), nrow(x) > 0)
      tagList(
        hr(),
        h4("Not proposed"),
        p("Fix these by hand in Zotero."),
        reactable::reactable(
          x,
          columns = list(Open = reactable::colDef(html = TRUE, minWidth = 90)),
          compact = TRUE,
          wrap = TRUE
        )
      )
    })

    output$result_ui <- renderUI({
      x <- result()
      req(!is.null(x))
      tagList(
        hr(),
        h4("Result"),
        if (nrow(x)) reactable::reactable(x, compact = TRUE, wrap = TRUE) else p("No change was written.")
      )
    })

    output$proposals <- reactable::renderReactable({
      p <- pending()
      req(p, nrow(p$changes))
      rows <- p$preview$rows
      # rows are selected with the tick boxes only, so that the links work
      reactable::reactable(
        changes_table(p$changes, rows, p$doi, p$openalex, group()),
        selection = "multiple",
        defaultSelected = which(vapply(rows, function(r) isTRUE(r$ok), TRUE)),
        columns = list(
          Change = reactable::colDef(html = TRUE, minWidth = 300),
          Open = reactable::colDef(html = TRUE, minWidth = 90)
        ),
        searchable = TRUE,
        defaultPageSize = 25,
        wrap = TRUE
      )
    })

    observeEvent(input$send, {
      p <- pending()
      req(p)
      sel <- reactable::getReactableState("proposals", "selected")
      if (!length(sel)) {
        showNotification("No changes selected.")
        return()
      }
      max_batch <- status()$max_batch_size %||% 25
      changes <- p$changes[sel, ]
      batches <- split(seq_len(nrow(changes)), ceiling(seq_len(nrow(changes)) / max_batch))
      results <- list()
      for (i in seq_along(batches)) {
        showNotification(sprintf("Batch %d of %d: approve the changes in Zotero …", i, length(batches)))
        r <- safely(function() se_apply(changes[batches[[i]], ], action = p$action))
        if (is.null(r)) break
        if (!identical(r$status, "done")) {
          showNotification(paste0("Batch ", i, ": ", r$status, explain(r)), type = "warning", duration = NULL)
          break # cancelled or refused: do not open further dialogs
        }
        results <- c(results, r$results)
      }
      titles <- stats::setNames(
        vapply(p$preview$rows, function(r) r$title %||% "", ""),
        vapply(p$preview$rows, function(r) r$item_key %||% "", "")
      )
      pending(NULL)
      not_proposed(NULL)
      result(dplyr::bind_rows(
        tibble::tibble(Title = character(), Field = character(), Status = character(), Reason = character()),
        lapply(results, function(x) tibble::tibble(
          Title = unname(titles[x$item_key]) %||% x$item_key,
          Field = x$field,
          Status = x$status,
          Reason = x$reason %||% ""
        ))
      ))
      done()
    })
  })
}

# ---- UI ------------------------------------------------------------------------

ui <- fluidPage(
  tags$head(tags$style(HTML(css))),
  titlePanel("Fix Zotero groups"),
  fluidRow(
    column(4, selectInput("group", "Group", choices = groups)),
    column(8, br(), actionButton("refresh", "Refresh"), textOutput("connection", inline = TRUE))
  ),
  tabsetPanel(
    id = "tabs",
    tabPanel(
      "Status",
      br(),
      uiOutput("status"),
      actionButton("backup", "Make a backup of this group"),
      actionButton("register", "Register this app in Zotero"),
      br(),
      br(),
      uiOutput("fixes_status")
    ),
    tabPanel(
      "Fixes",
      br(),
      p(
        class = "intro",
        "Changes proposed for problems found in the report. They are sent to ",
        "Zotero, where you approve them."
      ),
      selectInput("fix", "Fix", choices = names(fixes)),
      actionButton("load_fix", "Show proposed changes"),
      changes_ui("fixes")
    ),
    tabPanel(
      "Undo",
      br(),
      p(
        class = "intro",
        "All changes made through Safe Edit in this group, grouped by the batch ",
        "in which they were approved. Tick a batch to undo all its changes, or ",
        "open it (▸) to tick single changes. A change can only be undone if the ",
        "field still has the value Safe Edit set — changes made by hand since then ",
        "are never overwritten."
      ),
      uiOutput("log_ui")
    ),
    tabPanel(
      "Restore",
      br(),
      p(
        class = "intro",
        "Brings the group back to the state of a backup (made with \"Make a ",
        "backup of this group\" on the Status tab). Every difference in the fields ",
        "Safe Edit may change is proposed, including changes made by hand or ",
        "by others. The newest backup is usually the one made just before the ",
        "last changes — choose an older one to go back further."
      ),
      uiOutput("snapshot_ui"),
      actionButton("load_restore", "Show proposed changes"),
      changes_ui("restore")
    )
  )
)

# ---- server --------------------------------------------------------------------

server <- function(input, output, session) {
  tick <- reactiveVal(0)
  bump <- function() tick(tick() + 1)
  observeEvent(input$refresh, bump())

  group <- reactive(as.numeric(input$group))

  # "app" links in the tables
  observeEvent(input$open_zotero, open_in_zotero(input$open_zotero))

  status <- reactive({
    tick()
    safely(function() se_status(groups))
  })

  group_status <- reactive({
    g <- Filter(function(x) x$group_id == group(), status()$groups %||% list())
    if (length(g)) g[[1]] else NULL
  })

  output$connection <- renderText({
    s <- status()
    if (is.null(s)) {
      return("  Not connected")
    }
    sprintf(
      "  Connected as \"%s\" · Safe Edit %s · Zotero %s",
      s$client, s$plugin_version, s$zotero_version
    )
  })

  # ---- status ----------------------------------------------------------------

  output$status <- renderUI({
    s <- status()
    if (is.null(s)) {
      return(p(
        "Cannot connect. Is Zotero running with the Safe Edit plugin, and is ",
        "this app registered (button below)?"
      ))
    }
    g <- group_status()
    age <- g$backup_age_minutes
    fresh <- !is.null(age) && age <= s$max_backup_age_minutes

    rows <- list(
      list("Automatic sync", !isTRUE(s$auto_sync),
        if (isTRUE(s$auto_sync)) "on — switch it off in Zotero (Settings → Sync) before editing" else "off"),
      list("Backup of this group", fresh,
        if (is.null(age)) {
          "none — make one before editing"
        } else if (!fresh) {
          sprintf("%.0f minutes old (at most %s) — make a new one", age, s$max_backup_age_minutes)
        } else {
          sprintf("%.0f minutes old", age)
        }),
      list("Group in this Zotero", isTRUE(g$in_zotero), if (isTRUE(g$in_zotero)) "yes" else "no"),
      list("You can edit this group", isTRUE(g$editable), if (isTRUE(g$editable)) "yes" else "no")
    )
    tagList(
      tags$table(
        class = "status",
        lapply(rows, function(r) {
          tags$tr(tags$th(r[[1]]), tags$td(light(r[[2]], r[[3]])))
        })
      ),
      p(
        class = "notes",
        "Fields which may be edited: ", paste(unlist(s$allowed_fields), collapse = ", "),
        " · at most ", s$max_batch_size, " changes per approval (set in Zotero: Settings → Safe Edit)"
      )
    )
  })

  # supported fixes: items to fix (report data), items fixed since (current
  # values in Zotero, via the plugin) and status as in the report
  fix_counts <- reactive({
    tick()
    file <- metrics_file(group())
    if (!file.exists(file)) {
      return(NULL)
    }
    m <- readRDS(file)
    checks <- rep_checks(m)
    in_zotero <- isTRUE(group_status()$in_zotero)
    rows <- lapply(names(fixes), function(label) {
      x <- fixes[[label]](m, group())
      proposed <- x[x$proposed, ]
      fixed <- if (!nrow(proposed)) 0L else NA_integer_
      if (nrow(proposed) && in_zotero) {
        pv <- tryCatch(se_preview(proposed), error = function(e) NULL)
        if (!is.null(pv)) {
          now <- vapply(pv$rows, function(r) r$current %||% NA_character_, "")
          fixed <- sum(is_made(now, proposed))
        }
      }
      list(
        label = label,
        items = nrow(proposed),
        fixed = fixed,
        not_proposed = sum(!x$proposed),
        severity = checks$severity[checks$id == fix_checks[[label]]]
      )
    })
    list(rows = rows, time = file.mtime(file), in_zotero = in_zotero)
  })

  output$fixes_status <- renderUI({
    fc <- fix_counts()
    if (is.null(fc)) {
      return(p(class = "warn", "No report data for this group — run the pipeline first."))
    }
    rows <- lapply(fc$rows, function(r) {
      open <- r$items - if (is.na(r$fixed)) 0 else r$fixed
      status <- if (open == 0) {
        "OK"
      } else if (identical(r$severity, "fix")) {
        "Please fix"
      } else if (identical(r$severity, "check")) {
        "Please check"
      } else {
        "For information"
      }
      tags$tr(
        tags$th(tags$a(
          href = "#",
          onclick = sprintf(
            "Shiny.setInputValue('goto_fix', %s, {priority: 'event'}); return false;",
            jsonlite::toJSON(r$label, auto_unbox = TRUE)
          ),
          r$label
        )),
        tags$td(class = "count", r$items),
        tags$td(class = "count", if (is.na(r$fixed)) "–" else r$fixed),
        tags$td(HTML(rep_status_label(status))),
        tags$td(class = "notes", if (r$not_proposed) sprintf("%d not proposed", r$not_proposed))
      )
    })
    tagList(
      h4("Fixes"),
      tags$table(
        class = "status",
        tags$tr(
          tags$th("Fix"),
          tags$th(class = "count", "Items"),
          tags$th(class = "count", "Fixed"),
          tags$th("Status"),
          tags$th("")
        ),
        rows
      ),
      p(
        class = "notes",
        paste0(
          "Items: from the report data of ", format(fc$time, "%Y-%m-%d %H:%M"), ". ",
          "Fixed: of these, items which have the proposed value in Zotero now",
          if (!fc$in_zotero) " (–: the group is not in this Zotero)",
          ". Click a fix to show its outstanding proposed changes."
        )
      )
    )
  })

  # clicking a fix in the Status tab opens it in the Fixes tab
  fix_load <- reactiveVal(0)
  goto_pending <- reactiveVal(NULL)
  observeEvent(input$load_fix, fix_load(fix_load() + 1))
  observeEvent(input$goto_fix, {
    label <- input$goto_fix
    req(label %in% names(fixes))
    updateTabsetPanel(session, "tabs", selected = "Fixes")
    if (identical(input$fix, label)) {
      fix_load(fix_load() + 1)
    } else {
      goto_pending(label)
      updateSelectInput(session, "fix", selected = label)
    }
  })
  # after the proposals were cleared because the fix changed
  observeEvent(input$fix, priority = -10, {
    if (identical(goto_pending(), input$fix)) {
      goto_pending(NULL)
      fix_load(fix_load() + 1)
    }
  })

  observeEvent(input$register, {
    ok <- safely(function() se_register())
    if (isTRUE(ok)) showNotification("Registered. The token is stored in the keyring.")
    bump()
  })

  observeEvent(input$backup, {
    b <- safely(function() se_backup(group()))
    if (!is.null(b)) {
      showNotification(sprintf("Backup created: %s items (Zotero database backup: %s)", b$items, b$db_backup))
    }
    bump()
  })

  # ---- fixes -----------------------------------------------------------------

  changes_server(
    "fixes",
    group = group,
    status = status,
    load = fix_load,
    reset = reactive(list(input$group, input$fix)),
    compute = function() {
      m <- safely(function() read_metrics(group()))
      if (is.null(m)) return(NULL)
      all <- fixes[[input$fix]](m, group())
      list(
        changes = all[all$proposed, ],
        not_proposed = not_proposed_table(all[!all$proposed, ]),
        action = "edit"
      )
    },
    done = bump
  )

  # ---- restore ---------------------------------------------------------------

  output$snapshot_ui <- renderUI({
    backups <- group_status()$backups %||% list()
    if (!length(backups)) {
      return(p(class = "warn", "No backups of this group — make one on the Status tab."))
    }
    selectInput(
      "snapshot",
      "Backup to restore from",
      choices = stats::setNames(
        vapply(backups, function(b) b$name, ""),
        vapply(backups, function(b) local_time(b$created), "")
      )
    )
  })

  changes_server(
    "restore",
    group = group,
    status = status,
    load = reactive(input$load_restore),
    reset = reactive(list(input$group, input$snapshot)),
    compute = function() {
      req(input$snapshot)
      r <- safely(function() se_restore(group(), input$snapshot))
      if (is.null(r)) return(NULL)
      list(
        changes = dplyr::bind_rows(lapply(r$changes, tibble::as_tibble)),
        not_proposed = dplyr::bind_rows(lapply(r$not_restored, function(x) {
          tibble::tibble(
            Item = x$item_key,
            Note = paste0(x$field, ": not restored (field not allowed)"),
            Open = zotero_links(x$item_key, group())
          )
        })),
        action = "restore"
      )
    },
    done = bump
  )

  # ---- undo (log) ------------------------------------------------------------

  # groups which are not in this Zotero have no log
  log_entries <- reactive({
    tick()
    if (!isTRUE(group_status()$in_zotero)) {
      return(list())
    }
    safely(function() se_log(group())) %||% list()
  })

  output$log_ui <- renderUI({
    if (!isTRUE(group_status()$in_zotero)) {
      return(p(class = "warn", "This group is not in this Zotero."))
    }
    if (!length(log_entries())) {
      return(p("No changes have been made through Safe Edit in this group."))
    }
    tagList(
      reactable::reactableOutput("log"),
      br(),
      actionButton("undo", "Undo selected changes")
    )
  })

  # log as table, newest first, with one label per approval batch
  log_table <- reactive({
    e <- log_entries()
    req(length(e))
    tab <- dplyr::bind_rows(lapply(e, function(x) tibble::tibble(
      id = x$id,
      batch_id = x$batch_id,
      Time = local_time(x$time),
      By = x$client,
      Action = x$action,
      Title = x$title %||% "",
      Field = x$field,
      Old = x$old,
      New = x$new,
      Status = x$status,
      `Since then` = if (isTRUE(x$undone)) "undone" else x$state %||% "",
      Synced = if (is.null(x$synced)) "" else if (isTRUE(x$synced)) "yes" else "only local"
    )))
    # batches numbered in the order they were approved
    batches <- unique(tab$batch_id)
    labels <- vapply(seq_along(batches), function(i) {
      b <- tab[tab$batch_id == batches[i], ]
      # the number of changes is added by the table
      sprintf(
        "Batch %d · %s · %s",
        i, substr(b$Time[1], 1, 16), paste(unique(b$Action), collapse = "/")
      )
    }, "")
    tab$Batch <- labels[match(tab$batch_id, batches)]
    tab[rev(seq_len(nrow(tab))), c("Batch", setdiff(names(tab), "Batch"))]
  })

  output$log <- reactable::renderReactable({
    tab <- log_table()
    reactable::reactable(
      tab,
      groupBy = "Batch",
      selection = "multiple",
      columns = list(
        id = reactable::colDef(show = FALSE),
        batch_id = reactable::colDef(show = FALSE),
        Batch = reactable::colDef(minWidth = 260),
        Time = reactable::colDef(aggregate = "unique"),
        Action = reactable::colDef(aggregate = "unique"),
        Status = reactable::colDef(aggregate = "frequency"),
        `Since then` = reactable::colDef(aggregate = "frequency"),
        Synced = reactable::colDef(aggregate = "frequency")
      ),
      searchable = TRUE,
      defaultPageSize = 25,
      wrap = TRUE
    )
  })

  observeEvent(input$undo, {
    sel <- reactable::getReactableState("log", "selected")
    if (!length(sel)) {
      showNotification("No changes selected.")
      return()
    }
    ids <- log_table()$id[sel]
    max_batch <- status()$max_batch_size %||% 25
    for (b in split(ids, ceiling(seq_along(ids) / max_batch))) {
      r <- safely(function() se_undo(group(), b))
      if (is.null(r) || !identical(r$status, "done")) {
        if (!is.null(r)) {
          showNotification(paste0("Undo: ", r$status, explain(r)), type = "warning", duration = NULL)
        }
        break
      }
    }
    bump()
  })
}

shinyApp(ui, server)
