plot_types_data <- function(bibliography) {
  dplyr::bind_rows(
    bibliography$bibliography |>
      dplyr::select(
        type = Item.Type
      ) |>
      dplyr::group_by(
        type
      ) |>
      dplyr::summarize(
        count = n()
      ) |>
      dplyr::arrange(
        desc(count)
      ) |>
      dplyr::mutate(
        from = "Zotero"
      ),
    bibliography$works |>
      dplyr::group_by(
        type
      ) |>
      dplyr::summarize(
        count = n()
      ) |>
      dplyr::arrange(
        desc(count)
      ) |>
      dplyr::mutate(
        from = "OpenAlex"
      )
  )
}
