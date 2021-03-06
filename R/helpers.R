#' Legend by palette type
lflt_palette <- function(opts) {
  if (opts$color_scale %in% c("Category", "Custom")) {
    color_mapping <- "colorFactor"
    # l <- list(levels = opts$levels,
    #           ordered = opts$ordered)
    l <- list()
  } else if (opts$color_scale == "Quantile") {
    color_mapping <- "colorQuantile"
    l <- list(n = opts$n_quantile)
  } else if (opts$color_scale == 'Bins') {
    color_mapping <- "colorBin"
    l <- list(bins = opts$n_bins,
              pretty = opts$pretty)
  } else {
    color_mapping <- "colorNumeric"
    l <- list()
  }

  l$palette <- opts$palette
  l$domain <- opts$domain
  l$na.color <- opts$na_color
  do.call(color_mapping, l)
}

#' labels
lflt_tooltip <- function(nms, tooltip) {
  if (is.null(nms)) stop("Enter names")
  nms_names <- names(nms)
  if (is.null(tooltip) | tooltip == "") {
    l <- map(seq_along(nms), function(i){
      paste0("<span style='font-size:15px;'><strong>", nms[[i]], ":</strong> {", nms_names[i], "_label}</span>")
    }) %>% unlist()
    tooltip <- paste0(l, collapse = "<br/>")
  } else {
    points <- gsub("\\{|\\}", "",
                   stringr::str_extract_all(tooltip, "\\{.*?\\}")[[1]])
    if (identical(points, character())) {
      tooltip <- tooltip
    } else {
      l <- purrr::map(1:length(points), function(i){
        true_points <-  paste0("{",names(nms[match(points[i], nms)]),"_label}")
        tooltip <<- gsub(paste0("\\{",points[i], "\\}"), true_points, tooltip)
      })[[length(points)]]}
  }
  tooltip
}

#' Format
lflt_format <- function(d, dic, nms, opts) {

  var_nums <- dic$id[dic$hdType %in% c("Num", "Gln", "Glt")]
  l_num <- map(var_nums, function(v) {
    d[[paste0(v, "_label")]] <<- ifelse(is.na(d[[v]]), NA,
                                        paste0(opts$prefix,
                                               makeup::makeup_num(v = d[[v]],
                                                                  opts$format_num_sample#,
                                                                  #locale = opts$locale
                                               ),
                                               opts$suffix))
  })
  var_cats <- dic$id[dic$hdType %in% c("Cat", "Gnm", "Gcd")]
  l_cat <- map(var_cats, function(v) {
    d[[paste0(v, "_label")]] <<- ifelse(is.na(d[[v]]), NA,
                                        makeup::makeup_chr(v = d[[v]],
                                                           opts$format_cat_sample))
  })
  d
}


lflt_legend_bubbles <- function(map, colors, labels, sizes,
                                title, na.label, position, opacity){
  colorAdditions <- paste0(colors, ";
                           border-radius: 50%;  width:", sizes, "px; height:", sizes, "px;")
  labelAdditions <- paste0("<div style='display: inline-block; height: ",
                           max(sizes), "px; margin-bottom: 5px; line-height: ", max(sizes), "px; font-size: 15px; '>",
                           makeup::makeup_num(labels), "</div>")

  return(addLegend(map, colors = colorAdditions, labels = labelAdditions,
                   opacity = opacity, title = title, na.label = na.label,
                   position = position))
}


#'
lflt_legend_format <- function (prefix = "",
                                suffix = "",
                                between = " &ndash; ",
                                sample = "1,324.2",
                                locale = NULL,
                                transform = identity)
{
  formatNum <- function(x) {
    makeup::makeup_num(transform(x), sample)#, locale = locale)
  }
  function(type, ...) {
    switch(type, numeric = (function(cuts) {
      paste0(prefix, formatNum(cuts), suffix)
    })(...), bin = (function(cuts) {
      n <- length(cuts)
      paste0(prefix, formatNum(cuts[-n]), between, formatNum(cuts[-1]),
             suffix)
    })(...), quantile = (function(cuts, p) {
      n <- length(cuts)
      p <- paste0(round(p * 100), "%")
      cuts <- paste0(formatNum(cuts[-n]), between, formatNum(cuts[-1]))
      paste0("<span title=\"", cuts, "\">", prefix, p[-n],
             between, p[-1], suffix, "</span>")
    })(...), factor = (function(cuts) {
      paste0(prefix, as.character(transform(cuts)), suffix)
    })(...))
  }
}

#' Basic layer choroplets
lflt_basic_choropleth <- function(l) {

  color_map <- l$theme$na_color

  lf <- leaflet(l$d,
                option = leafletOptions(zoomControl= l$theme$map_zoom, minZoom = l$min_zoom, maxZoom = 18)) %>%
    addPolygons( weight = l$theme$border_weight,
                 fillOpacity = l$theme$topo_fill_opacity,
                 opacity = 1,
                 label = ~labels,
                 color = l$border_color,
                 fillColor = color_map,
                 highlight = highlightOptions(
                   color= 'white',
                   opacity = 0.8,
                   weight= 3,
                   bringToFront = TRUE))

  if (!is.null(l$data)) {
    if(sum(is.na(l$d@data$b)) == nrow(l$d@data)) {
      lf <- lf
    } else {
      domain <- l$d@data[["b"]]
      if(l$color_scale == "Custom"){
        intervals <- calculate_custom_intervals(cutoff_points = l$cutoff_points, domain = domain)
        domain <- intervals
      }


      opts_pal <- list(color_scale = l$color_scale,
                       palette = l$palette_colors,
                       # sequential = l$palette_colors_sequential,
                       # divergent = l$palette_colors_divergent,
                       na_color = l$theme$na_color,
                       domain = domain,
                       n_bins = l$n_bins,
                       n_quantile = l$n_quantile,
                       pretty = l$bins_pretty)

      pal <- lflt_palette(opts_pal)

      color_map <- pal(domain)

      fill_opacity <- l$theme$topo_fill_opacity
      if (is(l$d$c, "numeric")){
        fill_opacity <- scales::rescale(l$d$c, to = c(0.5, 1))
      }


      lf <- leaflet(l$d,
                    option = leafletOptions(zoomControl= l$theme$map_zoom, minZoom = l$min_zoom, maxZoom = 18)) %>%
        addPolygons( weight = l$theme$border_weight,
                     fillOpacity = fill_opacity,
                     opacity = 1,
                     color = l$border_color,
                     fillColor = color_map,
                     layerId = ~a,
                     label = ~labels,
                     highlight = highlightOptions(
                       color= 'white',
                       opacity = 0.8,
                       weight= 3,
                       bringToFront = TRUE)
        )
      if (!is.null(l$data) & l$theme$legend_show) {

        lf <- lf %>% addLegend(pal = pal, values = domain, opacity = 1,
                               position = l$theme$legend_position,
                               na.label = l$na_label,
                               title = l$legend_title,
                               labFormat = lflt_legend_format(
                                 sample =l$format_num, locale = l$locale,
                                 prefix = l$prefix, suffix = l$suffix,
                                 between = paste0(l$suffix, " - ", l$prefix),
                               ))
      }
    }}
  lf
}


#' Basic layer points
lflt_basic_points <- function(l) {

  color_map <- l$theme$na_color
  lf <- leaflet(l$d,
                option = leafletOptions(zoomControl= l$theme$map_zoom, minZoom = l$min_zoom, maxZoom = 18)) %>%
    addPolygons( weight = l$theme$border_weight,
                 fillOpacity = l$theme$topo_fill_opacity,
                 opacity = 1,
                 label = ~labels,
                 color = l$border_color,
                 fillColor = color_map)

  if (!is.null(l$data)) {

    radius <- 0
    color <- l$palette_colors[1]
    legend_color <- color

    if (is(l$d$d, "numeric")){
      radius <- scales::rescale(l$d$d, to = c(l$min_size, l$max_size))
      opts_pal <- list(color_scale = l$color_scale,
                       palette = l$palette_colors,
                       na_color = l$theme$na_color,
                       domain = l$d@data[["c"]],
                       n_bins = l$n_bins,
                       n_quantile = l$n_quantile)
      pal <- lflt_palette(opts_pal)
      color <- pal(l$d@data[["c"]])
      legend_color <- "#505050"
      cuts <- create_legend_cuts(l$d$d)
    } else if (is(l$d$c, "numeric")){
      radius <- scales::rescale(l$d$c, to = c(l$min_size, l$max_size))
      cuts <- create_legend_cuts(l$d$c)
    } else if (is(l$d$c, "character")){
      radius <- ifelse(!is.na(l$d$c), 5, 0)
      opts_pal <- list(color_scale = l$color_scale,
                       palette = l$palette_colors,
                       na_color = l$theme$na_color,
                       domain = l$d@data[["c"]],
                       n_bins = l$n_bins,
                       n_quantile = l$n_quantile)
      pal <- lflt_palette(opts_pal)
      color <- pal(l$d@data[["c"]])
    }

    lf <- leaflet(l$d,
                  option = leafletOptions(zoomControl= l$theme$map_zoom, minZoom = l$min_zoom, maxZoom = 18)) %>%
      addPolygons( weight = l$theme$border_weight,
                   fillOpacity = l$theme$topo_fill_opacity,
                   opacity = 1,
                   color = l$border_color,
                   fillColor = color_map) %>%
      addCircleMarkers(
        lng = ~a,
        lat = ~b,
        radius = radius,
        color = color,
        stroke = l$map_stroke,
        fillOpacity = l$bubble_opacity,
        label = ~labels,
        layerId = ~a
      )


    if (l$theme$legend_show){

      if (is(l$d$c, "numeric") | is(l$d$d, "numeric")){
        lf <- lf %>% lflt_legend_bubbles(sizes = 2*scales::rescale(cuts, to = c(l$min_size, l$max_size)),
                                         labels = cuts,
                                         color = legend_color,
                                         opacity = 1,
                                         position = l$theme$legend_position,
                                         na.label = l$na_label,
                                         title = l$legend_title)
      }

      if (is(l$d$c, "character")) {
        lf <- lf %>% addLegend(pal = pal, values = ~c, opacity = 1,
                               position = l$theme$legend_position,
                               na.label = l$na_label,
                               title = l$legend_title,
                               labFormat = lflt_legend_format(
                                 sample =l$format_num, locale = l$locale,
                                 prefix = l$prefix, suffix = l$suffix,
                                 between = paste0(l$suffix, " - ", l$prefix),
                               ))
      }
    }


  }

  lf
}



#' Basic layer bubbles
lflt_basic_bubbles <- function(l) {

  color_map <- l$theme$na_color

  lf <- leaflet(l$d,
                option = leafletOptions(zoomControl= l$theme$map_zoom, minZoom = l$min_zoom, maxZoom = 18)) %>%
    addPolygons( weight = l$theme$border_weight,
                 fillOpacity = l$theme$topo_fill_opacity,
                 opacity = 1,
                 label = ~name,
                 color = l$border_color,
                 fillColor = color_map)
  if (!is.null(l$data)) {

    radius <- 0
    color <- l$palette_colors[1]
    legend_color <- color

    if (is(l$d$c, "numeric")){
      radius <- scales::rescale(l$d$c, to = c(l$min_size, l$max_size))
      opts_pal <- list(color_scale = l$color_scale,
                       palette = l$palette_colors,
                       na_color = l$theme$na_color,
                       domain = l$d@data[["b"]],
                       n_bins = l$n_bins,
                       n_quantile = l$n_quantile)
      pal <- lflt_palette(opts_pal)
      color <- pal(l$d@data[["b"]])
      legend_color <- "#505050"
      cuts <- create_legend_cuts(l$d$c)
    } else if (is(l$d$b, "numeric")){
      radius <- scales::rescale(l$d$b, to = c(l$min_size, l$max_size))
      cuts <- create_legend_cuts(l$d$b)
    } else if (is(l$d$b, "character")){
      radius <- ifelse(!is.na(l$d$b), 5, 0)
      opts_pal <- list(color_scale = l$color_scale,
                       palette = l$palette_colors,
                       na_color = l$theme$na_color,
                       domain = l$d@data[["b"]],
                       n_bins = l$n_bins,
                       n_quantile = l$n_quantile)
      pal <- lflt_palette(opts_pal)
      color <- pal(l$d@data[["b"]])
    }

    lon <- l$d$lon
    lat <- l$d$lat

    lon[is.na(radius)]=NA
    lat[is.na(radius)]=NA

    lf <- lf %>%
      addCircleMarkers(
        lng = lon,
        lat = lat,
        radius = radius,
        color = color,
        stroke = l$map_stroke,
        fillOpacity = l$bubble_opacity,
        label = ~labels,
        layerId = ~a
      )

    if (l$theme$legend_show){

      if (is(l$d$b, "numeric") | is(l$d$c, "numeric")){
        lf <- lf %>% lflt_legend_bubbles(sizes = 2*scales::rescale(cuts, to = c(l$min_size, l$max_size)),
                                         labels = cuts,
                                         color = legend_color,
                                         opacity = 1,
                                         position = l$theme$legend_position,
                                         na.label = l$na_label,
                                         title = l$legend_title)
      }

      if (is(l$d$b, "character")) {
        lf <- lf %>% addLegend(pal = pal, values = ~b, opacity = 1,
                               position = l$theme$legend_position,
                               na.label = l$na_label,
                               title = l$legend_title,
                               labFormat = lflt_legend_format(
                                 sample =l$format_num, locale = l$locale,
                                 prefix = l$prefix, suffix = l$suffix,
                                 between = paste0(l$suffix, " - ", l$prefix),
                               ))
      }
    }}

  lf
}


url_logo <- function(logo, background_color) {
  if (grepl("http", logo)) logo_url <- logo
  logo_path <- local_logo_path(logo, background_color)
  logo_url <- knitr::image_uri(f = logo_path)
  logo_url
}

#' Background and branding Map
lflt_background <- function(map, theme) {
print(theme$map_provider_tile)
  if (is.null(theme$map_tiles) & theme$map_provider_tile == "leaflet") {
    lf <- map %>% setMapWidgetStyle(list(background = theme$background_color))
  } else {
     if (theme$map_provider_tile == "leaflet") {
       lf <- map %>%  addProviderTiles(theme$map_tiles)
     } else {
       lf <- map %>% leaflet.esri::addEsriBasemapLayer(esriBasemapLayers[[theme$map_tiles_esri]])
       if (!is.null(theme$map_extra_layout)) {
         lf <- lf %>%
           addEsriFeatureLayer(
           url = theme$map_extra_layout,
           labelProperty = theme$map_name_layout)
       }
     }
  }
  if (theme$branding_include) {
    img <- url_logo(logo = theme$logo, background = theme$background_color)
    lf <- lf %>%
      leafem::addLogo(img,  width = theme$logo_width, height = theme$logo_height, position = "bottomright")
  }
  lf
}

#' Set the bounds of map
lflt_bounds <- function(map, b_box) {

  map %>%
    fitBounds(b_box[1], b_box[2], b_box[3], b_box[4])
}

#' Graticule map
lflt_graticule <- function(map, graticule) {

  if (graticule$map_graticule) {
    map <- map %>%
      addGraticule(interval = graticule$map_graticule_interval,
                   style = list(color = graticule$map_graticule_color, weight = graticule$map_graticule_weight))
  }
  map
}

#' titles map
lflt_titles <- function(map, titles) {

  map %>%
    addControl(titles$caption,
               position = "bottomleft",
               className="map-caption") %>%
    addControl(titles$title,
               position = "topleft",
               className="map-title") %>%
    addControl(titles$subtitle,
               position = "topleft",
               className="map-subtitle")

}


# Find name or id
#' @export
geoType <- function(data, map_name) {

  f <- homodatum::fringe(data)
  nms <- homodatum::fringe_labels(f)
  d <- homodatum::fringe_d(f)

  lfmap <- geodataMeta(map_name)
  centroides <- data_centroid(lfmap$geoname, lfmap$basename)
  vs <- NULL
  values <- intersect(d[["a"]], centroides[["id"]])

  if (identical(values, character(0))||identical(values, numeric(0))) {
    values <- intersect(d[["a"]], centroides[["name"]])
    if(!identical(values, character())) vs <- "Gnm"
  } else {
    vs <- "Gcd"
  }
  vs
}


# fake data
#' @export
fakeData <- function(map_name = NULL, ...) {
  if (is.null(map_name)) return()
  lfmap <- geodataMeta(map_name)
  centroides <- data_centroid(lfmap$geoname, lfmap$basename)

  nsample <- nrow(centroides)
  if (nsample > 30) nsample <- 30
  d <- data.frame(name = sample(centroides$name, nsample), sample_value = rnorm(nsample, 33, 333))
  d
}


# fake data points
#' @export
fakepoints <- function(map_name = NULL, ...) {
  if (is.null(map_name)) return()
  lfmap <- geodataMeta(map_name)
  centroides <- data_centroid(lfmap$geoname, lfmap$basename)

  nsample <- nrow(centroides)
  if (nsample > 30) nsample <- 30
  d <- data.frame(lon = sample(centroides$lon, nsample),
                  lat = sample(centroides$lat, nsample),
                  dim_sample = abs(rnorm(nsample, 33, 333)))
  d
}

# guess ftypes changed cat by Gnm or Gcd
#' @export
guess_ftypes <- function(data, map_name) {
  #data <- sample_data("Glt-Gln-Num-Cat-Num-Num-Cat")
  if (is.null(map_name))
    stop("Please type a map name")
  if (is.null(data)) return()
  data <- fringe(data)
  d <- data$data
  dic <- homodatum::fringe_dic(data, id_letters = TRUE)
  lfmap <- geodataMeta(map_name)
  centroides <- data_centroid(lfmap$geoname, lfmap$basename)
  centroides$id <- iconv(tolower(centroides$id), to = "ASCII//TRANSLIT")
  centroides$name <- iconv(tolower(centroides$name), to = "ASCII//TRANSLIT")



  l_gcd <- map(names(d), function(i){
      if (is.numeric(d[[i]])){
        d[[i]] <- d[[i]]
      } else {
        d[[i]] <- iconv(tolower(d[[i]]), to = "ASCII//TRANSLIT")
      }
      gcd_in <- sum(centroides$id %in%  d[[i]])
      gcd_in > 0
  })
  names(l_gcd) <- names(d)
  this_gcd <- names(which(l_gcd == TRUE))

  if (identical(this_gcd, character())) {
    l_gnm <- map(names(d), function(i){
      if (is.numeric(d[[i]])){
       d[[i]] <- d[[i]]
      } else {
        d[[i]] <- iconv(tolower(d[[i]]), to = "ASCII//TRANSLIT")
      }
      gnm_in <- sum(centroides$name %in%  d[[i]])
      gnm_in > 0
    })
    names(l_gnm) <- names(d)
    this_gnm <- names(which(l_gnm == TRUE))
    if (identical(this_gnm, character())) {
    dic <- dic
    } else {
      dic$hdType[dic$id %in% this_gnm] <- "Gnm"
    }
  } else {
    dic$hdType[dic$id %in% this_gcd] <- "Gcd"
  }


  dic

}


#' Test posibble coords
#' @export

guess_coords <- function(data, map_name) {

  dic <- guess_ftypes(data, map_name)
  data <- fringe(data)
  d <- data$data
  lfmap <- geodataMeta(map_name)
  centroides <- data_centroid(lfmap$geoname, lfmap$basename)

  if ("Num" %in% dic$hdType) {
    d_num <- d[grep("Num", dic$hdType)]
    min_lat <- min(centroides$lat) - 10
    max_lat <- max(centroides$lat) + 10

    l_glt <- map(names(d_num), function(i) {
      min_d <- min(d_num[[i]], na.rm = T)
      max_d <- max(d_num[[i]], na.rm = T)
      if (min_d >= min_lat && max_d <= max_lat) {
        i
      } else {
        return()
      }
    }) %>% unlist()

    dic$hdType[dic$id == l_glt[1]] <- "Glt"

    if ("Num" %in% dic$hdType) {
      d_num <- d[grep("Num", dic$hdType)]
      min_lon <- min(centroides$lon) - 10
      max_lon <- max(centroides$lon) + 10

      l_gln <- map(names(d_num), function(i) {
        min_d <- min(d_num[[i]], na.rm = T)
        max_d <- max(d_num[[i]], na.rm = T)
        if (min_d >= min_lon && max_d <= max_lon) {
          i
        } else {
          return()
        }
      }) %>% unlist()

      dic$hdType[dic$id == l_gln[1]] <- "Gln"
    }

  }

  dic
}
