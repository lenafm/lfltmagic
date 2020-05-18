
#' @export
lfltmagic_prep <- function(data = NULL, opts = NULL, by_col = "name", ...) {

  map_name <- opts$extra$map_name
  topoInfo <- topo_info(map_name)

  lfmap <- geodataMeta(map_name)
  centroides <- data_centroid(lfmap$geoname, lfmap$basename)
  bbox <- topo_bbox(centroides$lon, centroides$lat)


  if (is.null(data)) {
    topoInfo@data <- topoInfo@data %>%
      mutate(labels = glue::glue('<strong>{name}</strong>') %>% lapply(htmltools::HTML))
  } else {
    f <- homodatum::fringe(data)
    nms <- homodatum::fringe_labels(f)
    d <- homodatum::fringe_data(f)
    dic <- homodatum::fringe_dic(f)
    dic$id <- names(nms)
    frtype_d <- f$frtype
    needs_num_agg <- frtype_d %in% c("Gcd", "Gnm", "Gnm-Cat", "Gcd-Cat", "Gln-Glt-Cat")
    if(needs_num_agg){
      d <- d %>%
        dplyr::group_by_all() %>%
        dplyr::summarise(Count = n())
      ind_nms <- length(nms)+1
      nms[ind_nms] <- 'Count'
      names(nms) <- c(names(nms)[-ind_nms], 'Count')
      dic_num <- data.frame(id = "Count", label = "Count", hdType= as_hdType(x = "Num"))
      dic <- dic %>% bind_rows(dic_num)
    } else {
      if (frtype_d %in% c("Gcd-Num", "Gnm-Num")) {
        d <- summarizeData(d, opts$summarize$agg, to_agg = b, a) %>% drop_na()}
      if (frtype_d %in% c("Gcd-Cat-Num", "Gnm-Cat-Num", "Gln-Glt-Cat")) {
        d <- summarizeData(d, opts$summarize$agg, to_agg = c, a, b) %>% drop_na(a, c)}
      if (frtype_d %in% c("Gln-Glt", "Glt-Gln")) {
        d <- d %>% mutate(c = opts$extra$map_radius) %>% drop_na()
      }
    }

    if (grepl("Gnm|Gcd|Cat", frtype_d)) {
      d <- d %>%
        mutate(name_alt = iconv(tolower(a), to = "ASCII//TRANSLIT"))
      topoInfo@data$name_alt <- iconv(tolower(topoInfo@data[[by_col]]), to = "ASCII//TRANSLIT")
      topoInfo@data  <- left_join(topoInfo@data, d, by = "name_alt")
      topoInfo@data$name <- makeup::makeup_chr(topoInfo@data[[by_col]], opts$style$format_cat_sample)
    } else {
      topoInfo@data <- d
      topoInfo@data$name <- opts$preprocess$na_label
    }
    topoInfo@data <- lflt_format(topoInfo@data, dic, nms, opts$style)
    topoInfo@data <- topoInfo@data %>%
      mutate(labels = ifelse(is.na(a), glue::glue("<strong>{name}</strong>") %>% lapply(htmltools::HTML),
                             glue::glue(lflt_tooltip(nms, tooltip = opts$chart$tooltip)) %>% lapply(htmltools::HTML))
      )
    # #if (is.null(by_col)) topoInfo@data <- d %>% drop_na
    # d

  }
  list(
    d = topoInfo,
    theme = opts$theme
  )
}
