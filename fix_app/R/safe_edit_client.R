#' Client for the Zotero Safe Edit plugin
#'
#' Functions to talk to the Zotero Safe Edit plugin on
#' `http://localhost:23119/safe-edit/`. The plugin checks every request,
#' shows the changes in Zotero for approval, and keeps the log; these
#' functions only send requests.
#'
#' The token is stored with `keyring::key_set_with_value("zotero_safe_edit_token", ...)`,
#' e.g. by [se_register()].

se_base_url <- "http://localhost:23119/safe-edit/"

#' Token of this application, or `NULL` if none is stored.
se_token <- function() {
  token <- NULL
  try(
    token <- keyring::key_get("zotero_safe_edit_token"),
    silent = TRUE
  )
  return(token)
}

#' Send a request to the plugin
#'
#' @param endpoint Endpoint name, e.g. `"status"`.
#' @param body List, sent as JSON.
#' @param timeout Seconds. `apply` and `undo` wait for the approval dialog.
#'
#' @return The parsed JSON response (list).
se_request <- function(
  endpoint,
  body = list(),
  timeout = 60,
  token = se_token()
) {
  req <- httr2::request(paste0(se_base_url, endpoint)) |>
    httr2::req_body_json(body, auto_unbox = TRUE, null = "null") |>
    httr2::req_timeout(timeout) |>
    httr2::req_error(is_error = function(resp) FALSE)
  if (!is.null(token)) {
    req <- httr2::req_headers(req, `X-Safe-Edit-Token` = token)
  }
  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      stop(
        "Zotero is not reachable. Is Zotero running, with the Safe Edit ",
        "plugin installed and 'Allow other applications on this computer to ",
        "communicate with Zotero' enabled? (", conditionMessage(e), ")",
        call. = FALSE
      )
    }
  )
  out <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  if (httr2::resp_status(resp) != 200) {
    stop("Safe Edit: ", out$error %||% httr2::resp_status(resp), call. = FALSE)
  }
  return(out)
}

#' Register this application in Zotero
#'
#' Zotero asks the user for permission. On approval, the token is stored in
#' the keyring.
#'
#' @return `TRUE` if registered.
se_register <- function(
  name = "IPBES Literature Report"
) {
  out <- se_request("register", list(name = name), timeout = 600, token = NULL)
  if (isTRUE(out$denied) || is.null(out$token)) {
    return(FALSE)
  }
  keyring::key_set_with_value("zotero_safe_edit_token", password = out$token)
  return(TRUE)
}

#' Plugin status, with backup age per group
se_status <- function(
  group_ids = numeric()
) {
  # unnamed, so that it is sent as a JSON array
  se_request("status", list(group_ids = as.list(unname(group_ids))))
}

#' Create a backup (snapshot) of a group
se_backup <- function(
  group_id
) {
  se_request("backup", list(group_id = group_id), timeout = 600)
}

#' Changes as a list for the plugin
#'
#' @param changes Data frame with `group_id`, `item_key`, `field`, `old`,
#'   `new` and `reason`.
se_changes <- function(
  changes
) {
  cols <- c("group_id", "item_key", "field", "old", "new", "reason")
  lapply(
    seq_len(nrow(changes)),
    function(i) as.list(as.data.frame(changes)[i, cols])
  )
}

#' Check changes and get the differences, nothing is written
se_preview <- function(
  changes
) {
  se_request("preview", list(changes = se_changes(changes)), timeout = 300)
}

#' Ask for approval in Zotero and write the approved changes
#'
#' Returns after the approval dialog in Zotero was closed.
se_apply <- function(
  changes,
  action = c("edit", "restore")
) {
  se_request(
    "apply",
    list(changes = se_changes(changes), action = match.arg(action)),
    timeout = 3600
  )
}

#' Change log of a group, with the current state of each change
se_log <- function(
  group_id
) {
  se_request("log", list(group_id = group_id))$entries
}

#' Undo applied changes (approval dialog in Zotero)
se_undo <- function(
  group_id,
  entry_ids
) {
  se_request(
    "undo",
    list(group_id = group_id, entry_ids = as.list(unname(entry_ids))),
    timeout = 3600
  )
}

#' Changes which restore a group from a snapshot (default: the latest)
se_restore <- function(
  group_id,
  snapshot = NULL
) {
  se_request("restore", list(group_id = group_id, snapshot = snapshot))
}
