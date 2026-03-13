#!/usr/bin/env bun

/**
 * Twitter/X CSV Exporter
 * Fetches tweets from apidance.pro API and exports to CSV
 *
 * Usage:
 *   bun run fetch-tweets.ts --query "#bitcoin" --api-key "YOUR_KEY" --output "tweets.csv"
 *   bun run fetch-tweets.ts --query "from:elonmusk" --api-key "YOUR_KEY" --limit 200
 */

const BASE_URL = "https://api.apidance.pro";

// CLI argument parsing
const args = process.argv.slice(2);
const options: Record<string, string> = {};

for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  if (arg.startsWith("--")) {
    const key = arg.slice(2);
    const nextArg = args[i + 1];
    if (nextArg && !nextArg.startsWith("--")) {
      options[key] = nextArg;
      i++;
    } else {
      options[key] = "true";
    }
  } else if (arg.startsWith("-")) {
    const key = arg.slice(1);
    const nextArg = args[i + 1];
    if (nextArg && !nextArg.startsWith("-")) {
      options[key] = nextArg;
      i++;
    } else {
      options[key] = "true";
    }
  }
}

// Map short options to long options
const shortMap: Record<string, string> = {
  q: "query",
  k: "api-key",
  o: "output",
  l: "limit",
};

for (const [short, long] of Object.entries(shortMap)) {
  if (options[short] !== undefined && options[long] === undefined) {
    options[long] = options[short];
  }
}

const query = options.query || options.q;
const apiKey = options["api-key"] || options.k;
const outputFile = options.output || options.o || "tweets.csv";
const sortBy = options.sort || "Latest";
// Fix 2: --limit controls total tweet count (more useful than per-page count)
const limit = parseInt(options.limit || options.l || "0", 10); // 0 = no limit
// Fix 3: default max-pages reduced from 100 to 10 (~200 tweets) to avoid unexpected quota drain
const maxPages = parseInt(options["max-pages"] || "10", 10);
const followingHandles = options.following ? options.following.split(",").map((h: string) => h.trim()) : [];
const includeNested = options["include-nested"] === "true";

const USAGE = `Usage: bun run fetch-tweets.ts --query <search> --api-key <key> [--output <file>] [--sort Latest|Top] [--limit <total>] [--max-pages <n>] [--following <handles>] [--include-nested]`;

// Validate required arguments
if (!query) {
  console.error("Error: --query is required");
  console.log(USAGE);
  console.log("Example: bun run fetch-tweets.ts --query '#bitcoin since:2026-01-01 until:2026-03-01' --api-key KEY");
  process.exit(1);
}

if (!apiKey) {
  console.error("Error: --api-key is required");
  console.log(USAGE);
  process.exit(1);
}

/**
 * Parse Twitter date format to Date object
 * Format: "Tue Mar 10 11:56:14 +0000 2026"
 */
function parseTwitterDate(dateStr: string): Date {
  return new Date(dateStr);
}

/**
 * Fix 5: Convert Twitter date string to ISO 8601 format for spreadsheet sorting
 */
function toISODate(dateStr: string): string {
  try {
    return new Date(dateStr).toISOString();
  } catch {
    return dateStr;
  }
}

/**
 * Extract hashtags from tweet text
 */
function extractHashtags(text: string): string {
  const matches = text.match(/#[a-zA-Z0-9_]+/g);
  return matches ? [...new Set(matches)].join(",") : "";
}

/**
 * Extract mentions from tweet text (excluding the first @ which is usually the reply target)
 */
function extractMentions(text: string): string {
  const matches = text.match(/@[a-zA-Z0-9_]+/g);
  if (!matches) return "";
  // Remove duplicates and return
  const unique = [...new Set(matches)];
  return unique.join(",");
}

/**
 * Escape CSV field
 */
function escapeCSV(field: string | number | boolean | null | undefined): string {
  if (field === null || field === undefined) return "";
  let str = String(field);
  // Replace newlines and carriage returns with space
  str = str.replace(/[\n\r]/g, " ");
  // Escape quotes by doubling them
  str = str.replace(/"/g, '""');
  // Wrap in quotes if contains comma or quote
  if (str.includes(",") || str.includes('"')) {
    return `"${str}"`;
  }
  return str;
}

/**
 * Check API response body for application-level errors
 * The apidance.pro API returns HTTP 200 with {"code":401,...} for auth errors
 */
function checkApiResponseError(data: any): void {
  if (data && data.code && data.code !== 200 && data.code !== 0) {
    throw new Error(`API error ${data.code}: ${data.msg || "Unknown error"}`);
  }
}

/**
 * Fetch tweets from search endpoint
 */
async function fetchTweets(searchQuery: string, cursor?: string): Promise<{ tweets: any[]; nextCursor: string; quotaRemaining?: string }> {
  const params = new URLSearchParams({
    q: searchQuery,
    sort_by: sortBy,
  });

  if (cursor) {
    params.set("cursor", cursor);
  }

  const url = `${BASE_URL}/sapi/Search?${params.toString()}`;

  const response = await fetch(url, {
    headers: {
      apikey: apiKey,
    },
  });

  if (response.status === 404) {
    // No more results
    return { tweets: [], nextCursor: "" };
  }
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`API error ${response.status}: ${errorText}`);
  }

  // Fix 1: Check application-level error codes (API returns HTTP 200 with error body)
  const data = await response.json();
  checkApiResponseError(data);

  // Fix 3: Capture API quota remaining for user visibility
  const quotaRemaining = response.headers.get("x-apikey-reamining") || undefined;

  return {
    tweets: data.tweets || [],
    nextCursor: data.next_cursor_str || "",
    quotaRemaining,
  };
}

/**
 * Check if a user follows another user
 */
async function checkFollowing(sourceId: string, targetHandle: string): Promise<boolean> {
  const url = `${BASE_URL}/1.1/friendships/show.json?source_id=${sourceId}&target_screen_name=${targetHandle}`;

  const response = await fetch(url, {
    headers: {
      apikey: apiKey,
    },
  });

  if (!response.ok) {
    console.error(`  Warning: Failed to check following for ${targetHandle}: ${response.status}`);
    return false;
  }

  const data = await response.json();
  return data.relationship?.source?.following === true;
}

/**
 * Fetch tweet details (replies) for a specific tweet
 */
async function fetchTweetDetails(tweetId: string, cursor?: string): Promise<{ tweets: any[]; nextCursor: string; quotaRemaining?: string }> {
  const params = new URLSearchParams({
    tweet_id: tweetId,
  });

  if (cursor) {
    params.set("cursor", cursor);
  }

  const url = `${BASE_URL}/sapi/TweetDetail?${params.toString()}`;

  const response = await fetch(url, {
    headers: {
      apikey: apiKey,
    },
  });

  if (response.status === 404) {
    // No more results
    return { tweets: [], nextCursor: "" };
  }
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`API error ${response.status}: ${errorText}`);
  }

  // Fix 1: Check application-level error codes
  const data = await response.json();
  checkApiResponseError(data);

  // Fix 3: Capture API quota remaining
  const quotaRemaining = response.headers.get("x-apikey-reamining") || undefined;

  return {
    tweets: data.tweets || [],
    nextCursor: data.next_cursor_str || "",
    quotaRemaining,
  };
}

/**
 * Main function
 */
async function main() {
  console.log(`Searching for: "${query}"`);
  console.log(`Sorting by: ${sortBy}`);
  console.log(`Output file: ${outputFile}`);
  if (limit > 0) console.log(`Limit: ${limit} tweets`);
  if (followingHandles.length > 0) {
    console.log(`Following checks: ${followingHandles.join(", ")}`);
  }
  console.log("---");

  let allTweets: any[] = [];
  let cursor = "";
  let pageCount = 0;
  let prevCursor = "";
  let consecutiveEmptyPages = 0;
  const seenTweetIds = new Set<string>();

  // Check if query is a tweet ID (numeric only)
  const isTweetId = /^\d+$/.test(query.trim());

  try {
    do {
      pageCount++;
      if (pageCount > maxPages) {
        console.log(`Reached max pages limit (${maxPages}), stopping...`);
        break;
      }
      console.log(`Fetching page ${pageCount}...`);

      let result;
      if (isTweetId) {
        // Treat as tweet ID for details/replies
        result = await fetchTweetDetails(query.trim(), cursor || undefined);
      } else {
        // Regular search
        result = await fetchTweets(query, cursor || undefined);
      }

      // Fix 3: Show API quota remaining on first page
      if (pageCount === 1 && result.quotaRemaining) {
        console.log(`  API quota remaining: ${result.quotaRemaining}`);
      }

      // Stop if no tweets returned in the API response (not filtered)
      if (!result.tweets || result.tweets.length === 0) {
        console.log("No more tweets to fetch, stopping...");
        break;
      }

      // Stop if cursor hasn't changed (stuck in loop)
      if (prevCursor && result.nextCursor === prevCursor) {
        console.log("Cursor unchanged, stopping pagination...");
        break;
      }
      prevCursor = result.nextCursor;

      // Now deduplicate - only add tweets we haven't seen before
      const newTweets = result.tweets.filter((tweet) => {
        if (seenTweetIds.has(tweet.tweet_id)) return false;
        seenTweetIds.add(tweet.tweet_id);
        return true;
      });

      // Check if we got new tweets - if not, continue to next page
      if (newTweets.length === 0 && result.tweets.length > 0) {
        consecutiveEmptyPages++;
        // Stop after 3 consecutive pages with no new tweets
        if (consecutiveEmptyPages >= 3) {
          console.log(`  No new tweets for ${consecutiveEmptyPages} consecutive pages, stopping...`);
          break;
        }
        if (result.nextCursor) {
          console.log(`  No new tweets in this batch (all duplicates), continuing to next page...`);
          prevCursor = result.nextCursor;
          cursor = result.nextCursor;
          continue;
        } else {
          console.log("  No new tweets and no more pages, stopping...");
          break;
        }
      }

      // Reset counter when we get new tweets
      consecutiveEmptyPages = 0;

      allTweets = allTweets.concat(newTweets);
      console.log(`  Found ${newTweets.length} tweets (total: ${allTweets.length})`);

      // Fix 2: Stop early if we've reached the --limit
      if (limit > 0 && allTweets.length >= limit) {
        allTweets = allTweets.slice(0, limit);
        console.log(`Reached limit of ${limit} tweets, stopping...`);
        break;
      }

      cursor = result.nextCursor;
    } while (cursor);

    console.log(`\nTotal tweets collected: ${allTweets.length}`);

    // Filter to direct replies only (unless --include-nested is specified)
    // Only applies when querying by tweet ID (TweetDetail endpoint for replies)
    let filteredTweets = allTweets;
    if (!includeNested && isTweetId) {
      const originalTweetId = query.trim();
      filteredTweets = allTweets.filter((tweet) => {
        const relatedId = tweet.related_tweet_id;
        // Direct replies have related_tweet_id equal to the original tweet ID
        return relatedId === originalTweetId;
      });
      console.log(`Filtered to direct replies only: ${filteredTweets.length} of ${allTweets.length} tweets`);
    }

    allTweets = filteredTweets;

    // Sort by date (newest first)
    allTweets.sort((a, b) => parseTwitterDate(b.created_at).getTime() - parseTwitterDate(a.created_at).getTime());

    if (allTweets.length === 0) {
      console.log("No tweets found matching your criteria.");
      process.exit(0);
    }

    // Generate CSV
    // Fix 6: Add tweet_id_raw and author_url as plain-value companions to the formula columns
    const headers = [
      "tweet_id",       // =HYPERLINK formula (clickable link)
      "tweet_id_raw",   // plain tweet ID string (for programmatic use)
      "created_at",
      "text",
      "author_name",    // =HYPERLINK formula (clickable link)
      "author_url",     // plain profile URL (for programmatic use)
      "author_handle",
      "author_id",
      "author_followers",
      "author_following",
      "author_verified",
      "author_location",
      "favorite_count",
      "retweet_count",
      "reply_count",
      "quote_count",
      "view_count",
      "is_retweet",
      "is_reply",
      "is_quote",
      "related_tweet_id",
      "media_type",
      "media_urls",
      "urls",
      "hashtags",
      "mentions",
      ...followingHandles.map((h) => `following_${h}`),
    ];

    const csvRows = [headers.join(",")];

    // Fix 8: corrected type (was Record<string, Record<string, boolean>>)
    const followingCache: Record<string, boolean> = {};

    for (const tweet of allTweets) {
      const user = tweet.user || {};
      const authorId = user.id_str || user.id;

      // Check following status for each handle if needed
      const followingStatus: boolean[] = [];
      if (followingHandles.length > 0 && authorId) {
        for (const handle of followingHandles) {
          const cacheKey = `${authorId}_${handle}`;
          let isFollowing: boolean;

          if (followingCache[cacheKey] !== undefined) {
            isFollowing = followingCache[cacheKey];
          } else {
            isFollowing = await checkFollowing(authorId, handle);
            followingCache[cacheKey] = isFollowing;
          }
          followingStatus.push(isFollowing);
        }
      }

      // Fix 4: escape quotes in author name before embedding in HYPERLINK formula
      const escapedName = (user.name || "").replace(/"/g, '""');
      const tweetLink = `=HYPERLINK("https://x.com/i/status/${tweet.tweet_id}","${tweet.tweet_id}")`;
      const authorLink = `=HYPERLINK("https://x.com/i/user/${authorId}","${escapedName}")`;
      const authorUrl = `https://x.com/i/user/${authorId}`;

      const row = [
        escapeCSV(tweetLink),
        escapeCSV(tweet.tweet_id),                           // Fix 6: tweet_id_raw
        escapeCSV(toISODate(tweet.created_at)),              // Fix 5: ISO 8601 date
        escapeCSV(tweet.text),
        escapeCSV(authorLink),
        escapeCSV(authorUrl),                                // Fix 6: author_url
        escapeCSV(user.screen_name),
        escapeCSV(authorId),
        escapeCSV(user.followers_count),
        escapeCSV(user.friends_count),
        escapeCSV(user.verified),
        escapeCSV(user.location),
        escapeCSV(tweet.favorite_count),
        escapeCSV(tweet.retweet_count),
        escapeCSV(tweet.reply_count),
        escapeCSV(tweet.quote_count),
        escapeCSV(tweet.view_count),
        escapeCSV(tweet.is_retweet),
        escapeCSV(tweet.is_reply),
        escapeCSV(tweet.is_quote),
        escapeCSV(tweet.related_tweet_id),
        escapeCSV(tweet.media_type),
        escapeCSV(tweet.medias ? tweet.medias.join(",") : ""),
        escapeCSV(tweet.urls ? tweet.urls.join(",") : ""),
        escapeCSV(extractHashtags(tweet.text)),
        escapeCSV(extractMentions(tweet.text)),
        ...followingStatus.map((f) => escapeCSV(f)),
      ];

      csvRows.push(row.join(","));
    }

    // Fix 7: prepend UTF-8 BOM so Windows Excel opens without encoding issues
    const csvContent = "\ufeff" + csvRows.join("\n");
    await Bun.write(outputFile, csvContent);

    console.log(`\nSuccessfully exported ${allTweets.length} tweets to ${outputFile}`);
  } catch (error) {
    console.error("Error:", error instanceof Error ? error.message : error);
    process.exit(1);
  }
}

main();
