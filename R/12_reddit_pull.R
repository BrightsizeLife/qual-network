# Reddit connector
# Requires: REDDIT_CLIENT_ID, REDDIT_SECRET, REDDIT_USER_AGENT env vars
library(httr)
library(jsonlite)

pull_reddit <- function(config) {
  if (!config$enabled) {
    cat("reddit: disabled\n")
    return(NULL)
  }

  # Check for required env vars
  client_id <- Sys.getenv("REDDIT_CLIENT_ID")
  client_secret <- Sys.getenv("REDDIT_SECRET")
  user_agent <- Sys.getenv("REDDIT_USER_AGENT")

  if (nchar(client_id) == 0 || nchar(client_secret) == 0 || nchar(user_agent) == 0) {
    cat("reddit: disabled (missing REDDIT_CLIENT_ID, REDDIT_SECRET, or REDDIT_USER_AGENT)\n")
    return(NULL)
  }

  cat("reddit: authenticating...\n")

  # Get OAuth token
  token_resp <- tryCatch({
    POST(
      "https://www.reddit.com/api/v1/access_token",
      authenticate(client_id, client_secret),
      body = list(grant_type = "client_credentials"),
      user_agent(user_agent),
      encode = "form",
      timeout(30)
    )
  }, error = function(e) {
    cat(sprintf("reddit: auth error: %s\n", e$message))
    return(NULL)
  })

  if (is.null(token_resp) || status_code(token_resp) != 200) {
    cat(sprintf("reddit: auth failed (HTTP %s)\n", if (!is.null(token_resp)) status_code(token_resp) else "error"))
    return(NULL)
  }

  token_data <- content(token_resp, as = "parsed")
  access_token <- token_data$access_token

  if (is.null(access_token)) {
    cat("reddit: failed to get access token\n")
    return(NULL)
  }

  cat("reddit: pulling posts...\n")

  all_posts <- list()
  max_posts_per_sub <- ceiling(config$max_posts / length(config$subreddits))

  for (subreddit in config$subreddits) {
    tryCatch({
      # Get hot posts from subreddit
      url <- sprintf("https://oauth.reddit.com/r/%s/hot", subreddit)
      resp <- GET(
        url,
        add_headers(Authorization = paste("Bearer", access_token)),
        user_agent(user_agent),
        query = list(limit = min(100, max_posts_per_sub)),
        timeout(30)
      )

      if (status_code(resp) != 200) {
        cat(sprintf("reddit: HTTP %d for r/%s\n", status_code(resp), subreddit))
        next
      }

      data <- content(resp, as = "parsed")
      posts <- data$data$children

      if (length(posts) == 0) {
        cat(sprintf("reddit: no posts from r/%s\n", subreddit))
        next
      }

      for (post in posts) {
        item <- post$data

        all_posts[[length(all_posts) + 1]] <- list(
          id = item$name,  # fullname (e.g., t3_xxxxx)
          title = if (!is.null(item$title)) item$title else "",
          selftext = if (!is.null(item$selftext)) item$selftext else "",
          url = if (!is.null(item$url)) item$url else "",
          permalink = if (!is.null(item$permalink)) paste0("https://reddit.com", item$permalink) else "",
          author = if (!is.null(item$author)) item$author else "[deleted]",
          score = if (!is.null(item$score)) item$score else 0,
          num_comments = if (!is.null(item$num_comments)) item$num_comments else 0,
          created_utc = if (!is.null(item$created_utc)) item$created_utc else NA_real_,
          subreddit = subreddit
        )
      }

      cat(sprintf("reddit: fetched %d posts from r/%s\n", length(posts), subreddit))

      # Rate limiting
      Sys.sleep(1)

    }, error = function(e) {
      cat(sprintf("reddit: error with r/%s: %s\n", subreddit, e$message))
    })

    if (length(all_posts) >= config$max_posts) break
  }

  if (length(all_posts) == 0) {
    cat("reddit: no posts retrieved\n")
    return(NULL)
  }

  # Normalize to schema
  df <- data.frame(
    entity = sapply(all_posts, function(x) x$id),
    source = "reddit",
    meta_data = sapply(all_posts, function(x) {
      toJSON(list(
        url = x$permalink,
        author = x$author,
        created_utc = if (!is.na(x$created_utc)) format(as.POSIXct(x$created_utc, origin="1970-01-01", tz="UTC"), "%Y-%m-%dT%H:%M:%SZ") else NA_character_,
        score = x$score,
        num_comments = x$num_comments,
        reactions = NA_integer_,
        origin = paste0("r/", x$subreddit)
      ), auto_unbox = TRUE)
    }),
    text = sapply(all_posts, function(x) {
      if (nchar(x$selftext) > 0) {
        paste0(x$title, " — ", x$selftext)
      } else {
        x$title
      }
    }),
    stringsAsFactors = FALSE
  )

  cat(sprintf("reddit: retrieved %d posts\n", nrow(df)))
  return(df)
}
