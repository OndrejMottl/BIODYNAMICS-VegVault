add_datasets <- function(
    data_source, con,
    data_type = NULL,
    data_source_type = NULL,
    dataset_source = NULL,
    sampling_method = NULL) {
  assertthat::assert_that(
    assertthat::has_name(
      data_source,
      c(
        "dataset_name",
        "coord_long",
        "coord_lat"
      )
    ),
    msg = "data_source must have columns 'dataset_name', 'coord_long' and 'coord_lat'"
  )

  dataset <- data_source

  if (
    isFALSE(is.null(dataset_source))
  ) {
    assertthat::assert_that(
      assertthat::has_name(dataset_source, "data_source_desc"),
      msg = "dataset_source must have column 'data_source_desc'"
    )
    assertthat::assert_that(
      assertthat::has_name(dataset, "data_source_desc"),
      msg = "dataset must have column 'data_source_desc'"
    )
    dataset <-
      dataset %>%
      dplyr::left_join(
        dataset_source,
        by = dplyr::join_by(data_source_desc)
      )
  }

  if (
    isFALSE(is.null(data_type))
  ) {
    assertthat::assert_that(
      assertthat::has_name(data_type, "dataset_type"),
      msg = "data_type must have column 'dataset_type'"
    )
    assertthat::assert_that(
      assertthat::has_name(dataset, "dataset_type"),
      msg = "dataset must have column 'dataset_type'"
    )

    dataset <-
      dataset %>%
      dplyr::left_join(
        data_type,
        by = dplyr::join_by(dataset_type)
      )
  }

  if (
    isFALSE(is.null(data_source_type))
  ) {
    assertthat::assert_that(
      assertthat::has_name(data_source_type, "dataset_source_type"),
      msg = "data_source_type must have column 'dataset_source_type'"
    )
    assertthat::assert_that(
      assertthat::has_name(dataset, "dataset_source_type"),
      msg = "dataset must have column 'dataset_source_type'"
    )

    dataset <-
      dataset %>%
      dplyr::left_join(
        data_source_type,
        by = dplyr::join_by(dataset_source_type)
      )
  }

  if (
    isFALSE(is.null(sampling_method))
  ) {
    assertthat::assert_that(
      assertthat::has_name(sampling_method, "sampling_method_details"),
      msg = "sampling_method must have column 'sampling_method_details'"
    )
    assertthat::assert_that(
      assertthat::has_name(dataset, "sampling_method_details"),
      msg = "dataset must have column 'sampling_method_details'"
    )

    dataset <-
      dataset %>%
      dplyr::left_join(
        sampling_method,
        by = dplyr::join_by(sampling_method_details)
      )
  }

  dataset_id_db <-
    dplyr::tbl(con, "Datasets") %>%
    dplyr::distinct(dataset_name) %>%
    dplyr::collect() %>%
    purrr::chuck("dataset_name")

  dataset_unique <-
    dataset %>%
    dplyr::select(
      dplyr::all_of(
        c(
          "dataset_name",
          "coord_long",
          "coord_lat"
        )
      ),
      dplyr::any_of(
        c(
          "dataset_type_id",
          "data_source_type_id",
          "data_source_id",
          "sampling_method_id"
        )
      )
    ) %>%
    dplyr::filter(
      !dataset_name %in% dataset_id_db
    )

  add_to_db(
    conn = con,
    data = dataset_unique,
    table_name = "Datasets"
  )

  dataset_id <-
    dplyr::tbl(con, "Datasets") %>%
    dplyr::select(dataset_id, dataset_name) %>%
    dplyr::collect() %>%
    dplyr::inner_join(
      data_source %>%
        dplyr::distinct(dataset_name),
      by = dplyr::join_by(dataset_name)
    )

  add_dataset_reference(
    data_source = data_source,
    dataset_id = dataset_id,
    con = con
  )

  return(dataset_id)
}
