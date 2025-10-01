# Hacker News connector
# Pulls from HN API (no auth required)
library(httr)
library(jsonlite)

pull_hn <- function(config) {
  if (!config$enabled) {
    cat("hackernews: disabled\n")
    return(NULL)
  }

  cat("hackernews: pulling stories...\n")

  all_posts <- list()
  max_posts <- config$max_posts

  # Determine which endpoint to use
  endpoints <- list()
  if (config$endpoints$top) endpoints <- c(endpoints, "top")
  if (config$endpoints$new) endpoints <- c(endpoints, "new")

  if (length(endpoints) == 0) {
    cat("hackernews: no endpoints enabled\n")
    return(NULL)
  }

  for (endpoint in endpoints) {
    tryCatch({
      # Get story IDs
      url <- sprintf("https://hacker-news.firebaseio.com/v0/%sstories.json", endpoint)
      resp <- GET(url, timeout(30))

      if (status_code(resp) != 200) {
        cat(sprintf("hackernews: HTTP %d for %s endpoint\n", status_code(resp), endpoint))
        next
      }

      story_ids <- content(resp, as="parsed")
      story_ids <- head(story_ids, max_posts)

      cat(sprintf("hackernews: fetching %d items from %s...\n", length(story_ids), endpoint))

      # Fetch each story
      for (id in story_ids) {
        tryCatch({
          item_url <- sprintf("https://hacker-news.firebaseio.com/v0/item/%d.json", id)
          item_resp <- GET(item_url, timeout(10))

          if (status_code(item_resp) == 200) {
            item <- content(item_resp, as="parsed")

            # Only include stories (not comments, polls, etc)
            if (!is.null(item$type) && item$type == "story") {
              all_posts[[length(all_posts) + 1]] <- list(
                id = as.character(item$id),
                title = if (!is.null(item$title)) item$title else "",
                text = if (!is.null(item$text)) item$text else "",
                url = if (!is.null(item$url)) item$url else sprintf("https://news.ycombinator.com/item?id=%d", item$id),
                author = if (!is.null(item$by)) item$by else NA_character_,
                score = if (!is.null(item$score)) item$score else 0,
                descendants = if (!is.null(item$descendants)) item$descendants else 0,
                time = if (!is.null(item$time)) item$time else NA_integer_,
                origin = endpoint
              )
            }
          }

          # Rate limiting: small delay
          Sys.sleep(0.05)

        }, error = function(e) {
          cat(sprintf("hackernews: error fetching item %d: %s\n", id, e$message))
        })

        if (length(all_posts) >= max_posts) break
      }

    }, error = function(e) {
      cat(sprintf("hackernews: error with %s endpoint: %s\n", endpoint, e$message))
    })

    if (length(all_posts) >= max_posts) break
  }

  if (length(all_posts) == 0) {
    cat("hackernews: no posts retrieved\n")
    return(NULL)
  }

  # Normalize to schema
  df <- data.frame(
    entity = sapply(all_posts, function(x) x$id),
    source = "hackernews",
    meta_data = sapply(all_posts, function(x) {
      toJSON(list(
        url = x$url,
        author = x$author,
        created_utc = if (!is.na(x$time)) format(as.POSIXct(x$time, origin="1970-01-01", tz="UTC"), "%Y-%m-%dT%H:%M:%SZ") else NA_character_,
        score = x$score,
        num_comments = x$descendants,
        reactions = NA_integer_,
        origin = x$origin
      ), auto_unbox = TRUE)
    }),
    text = sapply(all_posts, function(x) {
      if (nchar(x$text) > 0) {
        paste0(x$title, " — ", x$text)
      } else {
        x$title
      }
    }),
    stringsAsFactors = FALSE
  )

  cat(sprintf("hackernews: retrieved %d posts\n", nrow(df)))
  return(df)
}
