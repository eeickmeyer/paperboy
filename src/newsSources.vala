/*
 * Copyright (C) 2025  Isaac Joseph <calamityjoe87@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

using GLib;
using Tools;

public enum NewsSource {
    BBC,
    GUARDIAN,
    NEW_YORK_TIMES,
    WALL_STREET_JOURNAL,
    REDDIT,
    BLOOMBERG,
    REUTERS,
    NPR,
    FOX
}

public delegate void SetLabelFunc(string text);
public delegate void ClearItemsFunc();
public delegate void AddItemFunc(string title, string url, string? thumbnail_url, string category_id);

public class NewsSources {
    // Entry point
    public static void fetch(
        NewsSource source,
        string current_category,
        string current_search_query,
        Soup.Session session,
        SetLabelFunc set_label,
        ClearItemsFunc clear_items,
        AddItemFunc add_item
    ) {
        // For Bloomberg, always show all categories in the sidebar
        if (source == NewsSource.BLOOMBERG && current_category == "all") {
            string[] bloomberg_categories = { "general", "technology", "us", "science", "sports", "health", "entertainment", "politics", "lifestyle" };
            set_label("Bloomberg — All Categories");
            clear_items();
            foreach (string category in bloomberg_categories) {
                Timeout.add(Random.int_range(200, 1200), () => {
                    fetch_google_domain(category, current_search_query, session, (text) => {}, () => {}, add_item, "bloomberg.com", "Bloomberg");
                    return false;
                });
            }
            return;
        }
        // Handle "all" category by fetching from multiple categories for other sources
        if (current_category == "all") {
            fetch_all_categories(source, current_search_query, session, set_label, clear_items, add_item);
            return;
        }
        switch (source) {
            case NewsSource.GUARDIAN:
                fetch_guardian(current_category, current_search_query, session, set_label, clear_items, add_item);
                break;
            case NewsSource.WALL_STREET_JOURNAL:
                fetch_wsj(current_category, current_search_query, session, set_label, clear_items, add_item);
                break;
            case NewsSource.REDDIT:
                fetch_reddit(current_category, current_search_query, session, set_label, clear_items, add_item);
                break;
            case NewsSource.BBC:
                fetch_bbc(current_category, current_search_query, session, set_label, clear_items, add_item);
                break;
            case NewsSource.NEW_YORK_TIMES:
                fetch_nyt(current_category, current_search_query, session, set_label, clear_items, add_item);
                break;
            case NewsSource.BLOOMBERG:
                fetch_google_domain(current_category, current_search_query, session, set_label, clear_items, add_item, "bloomberg.com", "Bloomberg");
                break;
            case NewsSource.REUTERS:
                fetch_reuters(current_category, current_search_query, session, set_label, clear_items, add_item);
                break;
            case NewsSource.NPR:
                fetch_npr(current_category, current_search_query, session, set_label, clear_items, add_item);
                break;
            case NewsSource.FOX:
                fetch_fox(current_category, current_search_query, session, set_label, clear_items, add_item);
                break;
        }
    }

    // Fetch mixed news from all categories
    private static void fetch_all_categories(
        NewsSource source,
        string current_search_query,
        Soup.Session session,
        SetLabelFunc set_label,
        ClearItemsFunc clear_items,
        AddItemFunc add_item
    ) {
        string source_name = get_source_name(source);
        if (current_search_query.length > 0) {
            set_label(@"Search Results: \"$(current_search_query)\" in All News — $(source_name)");
        } else {
            set_label(@"All News — $(source_name)");
        }
        clear_items();

        // Better randomization: shuffle categories and select a random subset
        string[] all_categories = { "general", 
                                    "technology", 
                                    "us", 
                                    "science", 
                                    "sports", 
                                    "health", 
                                    "entertainment", 
                                    "politics", 
                                    "lifestyle" };
        
        // Shuffle the categories array for random order
        for (int i = all_categories.length - 1; i > 0; i--) {
            int j = Random.int_range(0, i + 1);
            string temp = all_categories[i];
            all_categories[i] = all_categories[j];
            all_categories[j] = temp;
        }
        
        // Select 5-7 categories randomly (not all 9 every time)
        int num_categories = Random.int_range(5, 8);
        string[] selected_categories = new string[num_categories];
        for (int i = 0; i < num_categories; i++) {
            selected_categories[i] = all_categories[i];
        }

        foreach (string category in selected_categories) {
            // Use more varied delays between requests (200ms to 2 seconds)
            Timeout.add(Random.int_range(200, 2000), () => {
                switch (source) {
                    case NewsSource.GUARDIAN:
                        fetch_guardian(category, current_search_query, session, 
                            (text) => { /* Keep "All News" label */ },
                            () => { /* Don't clear items */ }, 
                            add_item);
                        break;
                    case NewsSource.WALL_STREET_JOURNAL:
                        fetch_google_domain(category, current_search_query, session, 
                            (text) => { /* Keep "All News" label */ },
                            () => { /* Don't clear items */ }, 
                            add_item, "wsj.com", "Wall Street Journal");
                        break;
                    case NewsSource.REDDIT:
                        fetch_reddit(category, current_search_query, session, 
                            (text) => { /* Keep "All News" label */ },
                            () => { /* Don't clear items */ }, 
                            add_item);
                        break;
                    case NewsSource.BBC:
                        fetch_bbc(category, current_search_query, session, 
                            (text) => { /* Keep "All News" label */ },
                            () => { /* Don't clear items */ }, 
                            add_item);
                        break;
                    case NewsSource.NEW_YORK_TIMES:
                        fetch_nyt(category, current_search_query, session, 
                            (text) => { /* Keep "All News" label */ },
                            () => { /* Don't clear items */ }, 
                            add_item);
                        break;
                    case NewsSource.BLOOMBERG:
                        fetch_google_domain(category, current_search_query, session, 
                            (text) => { /* Keep "All News" label */ },
                            () => { /* Don't clear items */ }, 
                            add_item, "bloomberg.com", "Bloomberg");
                        break;
                    case NewsSource.REUTERS:
                        fetch_reuters(category, current_search_query, session, 
                            (text) => { /* Keep "All News" label */ },
                            () => { /* Don't clear items */ }, 
                            add_item);
                        break;
                    case NewsSource.NPR:
                        fetch_npr(category, current_search_query, session, 
                            (text) => { /* Keep "All News" label */ },
                            () => { /* Don't clear items */ }, 
                            add_item);
                        break;
                    case NewsSource.FOX:
                        fetch_fox(category, current_search_query, session, 
                            (text) => { /* Keep "All News" label */ },
                            () => { /* Don't clear items */ }, 
                            add_item);
                        break;
                }
                return false; // Don't repeat the timeout
            });
        }
    }

    // Helpers
    // Utility to strip HTML tags from a string (moved here to live with other helpers)
    private static string strip_html(string input) {
        // Remove all tags
        var regex = new Regex("<[^>]+>", RegexCompileFlags.DEFAULT);
        return regex.replace(input, -1, 0, "");
    }
    private static string category_display_name(string cat) {
        switch (cat) {
            case "all": return "All News";
            case "general": return "World News";
            case "us": return "US News";
            case "technology": return "Technology";
            case "science": return "Science";
            case "sports": return "Sports";
            case "health": return "Health";
            case "entertainment": return "Entertainment";
            case "politics": return "Politics";
            case "lifestyle": return "Lifestyle";
        }
        return "News";
    }

    private static string get_source_name(NewsSource source) {
        switch (source) {
            case NewsSource.GUARDIAN:
                return "The Guardian";
            case NewsSource.WALL_STREET_JOURNAL:
                return "Wall Street Journal";
            case NewsSource.BBC:
                return "BBC News";
            case NewsSource.REDDIT:
                return "Reddit";
            case NewsSource.NEW_YORK_TIMES:
                return "New York Times";
            case NewsSource.BLOOMBERG:
                return "Bloomberg";
            case NewsSource.REUTERS:
                return "Reuters";
            case NewsSource.NPR:
                return "NPR";
            case NewsSource.FOX:
                return "Fox News";
            default:
                return "News";
        }
    }


    private static void fetch_google_domain(
        string current_category,
        string current_search_query,
        Soup.Session session,
        SetLabelFunc set_label,
        ClearItemsFunc clear_items,
        AddItemFunc add_item,
        string domain,
        string source_name
    ) {
        string base_url = "https://news.google.com/rss/search";
        string ceid = "hl=en-US&gl=US&ceid=US:en";
        string category_name = category_display_name(current_category);
        string query = @"site:$(domain)";
        if (current_search_query.length > 0) {
            query = query + " " + current_search_query;
        }
        string url = @"$(base_url)?q=$(Uri.escape_string(query))&$(ceid)";
        
        RssParser.fetch_rss_url(url, source_name, category_name, current_category, current_search_query, session, set_label, clear_items, add_item);
    }

    private static void fetch_nyt(
        string current_category,
        string current_search_query,
        Soup.Session session,
        SetLabelFunc set_label,
        ClearItemsFunc clear_items,
        AddItemFunc add_item
    ) {
        string base_url = "https://rss.nytimes.com/services/xml/rss/nyt/";
        string path = "World.xml";
        switch (current_category) {
            case "us":
                path = "US.xml";
                break;
            case "technology":
                path = "Technology.xml";
                break;
            case "science":
                path = "Science.xml";
                break;
            case "sports":
                path = "Sports.xml";
                break;
            case "health":
                path = "Health.xml";
                break;
            case "politics":
            case "entertainment":
            case "lifestyle":
                // Use Google site search for reliable category coverage
                fetch_google_domain(current_category, current_search_query, session, set_label, clear_items, add_item, "nytimes.com", "New York Times");
                return;
            default:
                path = "World.xml";
                break;
        }
        if (current_search_query.length > 0) {
            fetch_google_domain(current_category, current_search_query, session, set_label, clear_items, add_item, "nytimes.com", "New York Times");
            return;
        }
    RssParser.fetch_rss_url(@"$(base_url)$(path)", "New York Times", category_display_name(current_category), current_category, current_search_query, session, set_label, clear_items, add_item);
    }

    private static void fetch_bbc(
        string current_category,
        string current_search_query,
        Soup.Session session,
        SetLabelFunc set_label,
        ClearItemsFunc clear_items,
        AddItemFunc add_item
    ) {
        if (current_search_query.length > 0) {
            fetch_google_domain(current_category, current_search_query, session, set_label, clear_items, add_item, "bbc.co.uk", "BBC News");
            return;
        }
        string url = "https://feeds.bbci.co.uk/news/world/rss.xml";
        switch (current_category) {
            case "technology":
                url = "https://feeds.bbci.co.uk/news/technology/rss.xml";
                break;
            case "science":
                url = "https://feeds.bbci.co.uk/news/science_and_environment/rss.xml";
                break;
            case "sports":
                url = "https://feeds.bbci.co.uk/sport/rss.xml";
                break;
            case "health":
                url = "https://feeds.bbci.co.uk/news/health/rss.xml";
                break;
            case "us":
                url = "https://feeds.bbci.co.uk/news/world/us_and_canada/rss.xml";
                break;
            case "politics":
                url = "https://feeds.bbci.co.uk/news/politics/rss.xml";
                break;
            case "entertainment":
                url = "https://feeds.bbci.co.uk/news/entertainment_and_arts/rss.xml";
                break;
            case "lifestyle":
                // No clear lifestyle feed; use site search to approximate
                fetch_google_domain(current_category, current_search_query, session, set_label, clear_items, add_item, "bbc.co.uk", "BBC News");
                return;
            default:
                url = "https://feeds.bbci.co.uk/news/world/rss.xml";
                break;
        }
    RssParser.fetch_rss_url(url, "BBC News", category_display_name(current_category), current_category, current_search_query, session, set_label, clear_items, add_item);
    }

    private static void fetch_guardian(
        string current_category,
        string current_search_query,
        Soup.Session session,
        SetLabelFunc set_label,
        ClearItemsFunc clear_items,
        AddItemFunc add_item
    ) {
        new Thread<void*>("fetch-news", () => {
            try {
                // No article cache: always fetch fresh Guardian API results
                string base_url = "https://content.guardianapis.com/search?show-fields=thumbnail&page-size=30&api-key=test";
                string url;
                switch (current_category) {
                    case "us":
                        url = base_url + "&section=us-news";
                        break;
                    case "technology":
                        url = base_url + "&section=technology";
                        break;
                    case "science":
                        url = base_url + "&section=science";
                        break;
                    case "sports":
                        url = base_url + "&section=sport";
                        break;
                    case "health":
                        url = base_url + "&tag=society/health";
                        break;
                    case "politics":
                        url = base_url + "&section=politics";
                        break;
                    case "entertainment":
                        url = base_url + "&section=culture";
                        break;
                    case "lifestyle":
                        url = base_url + "&section=lifeandstyle";
                        break;
                    case "general":
                    default:
                        url = base_url + "&section=world";
                        break;
                }
                if (current_search_query.length > 0) {
                    url = url + "&q=" + Uri.escape_string(current_search_query);
                }
                var msg = new Soup.Message("GET", url);
                msg.request_headers.append("User-Agent", "news-vala-gnome/0.1");
                session.send_message(msg);
                if (msg.status_code != 200) {
                    warning("HTTP error: %u", msg.status_code);
                    return null;
                }
                string body = (string) msg.response_body.flatten().data;
                // No article cache in this build; just proceed with parsing and UI update

                var parser = new Json.Parser();
                parser.load_from_data(body);
                var root = parser.get_root();
                var data = root.get_object();
                if (!data.has_member("response")) {
                    return null;
                }
                var response = data.get_object_member("response");
                if (!response.has_member("results")) {
                    return null;
                }
                var results = response.get_array_member("results");

                string category_name = category_display_name(current_category);
                Idle.add(() => {
                    if (current_search_query.length > 0) {
                        set_label(@"Search Results: \"$(current_search_query)\" in $(category_name) — The Guardian");
                    } else {
                        set_label(@"$(category_name) — The Guardian");
                    }
                    clear_items();
                    uint len = results.get_length();
                    for (uint i = 0; i < len; i++) {
                        var article = results.get_element(i).get_object();
                        var title = article.has_member("webTitle") ? article.get_string_member("webTitle") : "No title";
                        var article_url = article.has_member("webUrl") ? article.get_string_member("webUrl") : "";
                        string? thumbnail = null;
                        if (article.has_member("fields")) {
                            var fields = article.get_object_member("fields");
                            if (fields.has_member("thumbnail")) {
                                thumbnail = fields.get_string_member("thumbnail");
                            }
                        }
                        add_item(title, article_url, thumbnail, current_category);
                    }
                    // Attempt to fetch higher-quality images (OG images) for Guardian articles
                    fetch_guardian_article_images(results, session, add_item, current_category);
                    return false;
                });
            } catch (GLib.Error e) { warning("Fetch error: %s", e.message); }
            return null;
        });
    }

    private static void fetch_reddit(
        string current_category,
        string current_search_query,
        Soup.Session session,
        SetLabelFunc set_label,
        ClearItemsFunc clear_items,
        AddItemFunc add_item
    ) {
        new Thread<void*>("fetch-news", () => {
            try {
                string subreddit = "";
                string category_name = "";
                switch (current_category) {
                    case "general":
                        subreddit = "worldnews";
                        category_name = "World News";
                        break;
                    case "us":
                        subreddit = "news";
                        category_name = "US News";
                        break;
                    case "technology":
                        subreddit = "technology";
                        category_name = "Technology";
                        break;
                    case "science":
                        subreddit = "science";
                        category_name = "Science";
                        break;
                    case "sports":
                        subreddit = "sports";
                        category_name = "Sports";
                        break;
                    case "health":
                        subreddit = "health";
                        category_name = "Health";
                        break;
                    case "entertainment":
                        subreddit = "entertainment";
                        category_name = "Entertainment";
                        break;
                    case "politics":
                        subreddit = "politics";
                        category_name = "Politics";
                        break;
                    case "lifestyle":
                        subreddit = "lifestyle";
                        category_name = "Lifestyle";
                        break;
                    default:
                        subreddit = "worldnews";
                        category_name = "World News";
                        break;
                }
                string url = @"https://www.reddit.com/r/$(subreddit)/hot.json?limit=30";
                if (current_search_query.length > 0) {
                    url = @"https://www.reddit.com/r/$(subreddit)/search.json?q=$(Uri.escape_string(current_search_query))&restrict_sr=1&limit=30";
                }
                var msg = new Soup.Message("GET", url);
                msg.request_headers.append("User-Agent", "news-vala-gnome/0.1");
                session.send_message(msg);
                if (msg.status_code != 200) {
                    warning("HTTP error: %u", msg.status_code);
                    return null;
                }
                string body = (string) msg.response_body.flatten().data;

                var parser = new Json.Parser();
                parser.load_from_data(body);
                var root = parser.get_root();
                var data = root.get_object();
                if (!data.has_member("data")) {
                    return null;
                }
                var data_obj = data.get_object_member("data");
                if (!data_obj.has_member("children")) {
                    return null;
                }
                var children = data_obj.get_array_member("children");

                Idle.add(() => {
                    if (current_search_query.length > 0) {
                        set_label(@"Search Results: \"$(current_search_query)\" in $(category_name)");
                    } else {
                        set_label(category_name);
                    }
                    clear_items();
                    uint len = children.get_length();
                    for (uint i = 0; i < len; i++) {
                        var post = children.get_element(i).get_object();
                        var post_data = post.get_object_member("data");
                        var title = post_data.has_member("title") ? post_data.get_string_member("title") : "No title";
                        var post_url = post_data.has_member("url") ? post_data.get_string_member("url") : "";
                        string? thumbnail = null;
                        
                        // Try to get high-quality preview image first
                        if (post_data.has_member("preview")) {
                            var preview = post_data.get_object_member("preview");
                            if (preview.has_member("images")) {
                                var images = preview.get_array_member("images");
                                if (images.get_length() > 0) {
                                    var first_image = images.get_element(0).get_object();
                                    if (first_image.has_member("source")) {
                                        var source = first_image.get_object_member("source");
                                        if (source.has_member("url")) {
                                            string preview_url = source.get_string_member("url");
                                            // Decode HTML entities in URL
                                            thumbnail = preview_url.replace("&amp;", "&");
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Fallback to thumbnail if no preview available
                        if (thumbnail == null && post_data.has_member("thumbnail")) {
                            string thumb = post_data.get_string_member("thumbnail");
                            if (thumb.has_prefix("http") && thumb != "default" && thumb != "self" && thumb != "nsfw") {
                                thumbnail = thumb;
                            }
                        }
                        
                        add_item(title, post_url, thumbnail, current_category);
                    }
                    return false;
                });
            } catch (GLib.Error e) {
                warning("Fetch error: %s", e.message);
            }
            return null;
        });
    }

    private static void fetch_reuters(
        string current_category,
        string current_search_query,
        Soup.Session session,
        SetLabelFunc set_label,
        ClearItemsFunc clear_items,
        AddItemFunc add_item
    ) {
        // Reuters RSS feeds require authentication, so use Google News site search
        fetch_google_domain(current_category, current_search_query, session, set_label, clear_items, add_item, "reuters.com", "Reuters");
    }

    private static void fetch_npr(
        string current_category,
        string current_search_query,
        Soup.Session session,
        SetLabelFunc set_label,
        ClearItemsFunc clear_items,
        AddItemFunc add_item
    ) {
        if (current_search_query.length > 0) {
            fetch_google_domain(current_category, current_search_query, session, set_label, clear_items, add_item, "npr.org", "NPR");
            return;
        }
        string url = "https://feeds.npr.org/1001/rss.xml";
        switch (current_category) {
            case "technology":
                url = "https://feeds.npr.org/1019/rss.xml";
                break;
            case "science":
                url = "https://feeds.npr.org/1007/rss.xml";
                break;
            case "sports":
                url = "https://feeds.npr.org/1055/rss.xml";
                break;
            case "health":
                url = "https://feeds.npr.org/1128/rss.xml";
                break;
            case "us":
                url = "https://feeds.npr.org/1003/rss.xml";
                break;
            case "politics":
                url = "https://feeds.npr.org/1014/rss.xml";
                break;
            case "entertainment":
                url = "https://feeds.npr.org/1008/rss.xml";
                break;
            case "lifestyle":
                url = "https://feeds.npr.org/1053/rss.xml";
                break;
            default:
                url = "https://feeds.npr.org/1001/rss.xml";
                break;
        }
        RssParser.fetch_rss_url(url, "NPR", category_display_name(current_category), current_category, current_search_query, session, set_label, clear_items, add_item);
    }

    private static void fetch_fox(
        string current_category,
        string current_search_query,
        Soup.Session session,
        SetLabelFunc set_label,
        ClearItemsFunc clear_items,
        AddItemFunc add_item
    ) {
        // Use web scraping for Fox News to get better control over content and images
        // Keep the optimized version with reduced delays and limited concurrent requests
        fetch_fox_scrape(current_category, current_search_query, session, set_label, clear_items, add_item);
    }

    private static void fetch_fox_scrape(
        string current_category,
        string current_search_query,
        Soup.Session session,
        SetLabelFunc set_label,
        ClearItemsFunc clear_items,
        AddItemFunc add_item
    ) {
        new Thread<void*>("fetch-fox-scrape", () => {
            try {
                Gee.ArrayList<string> section_urls = new Gee.ArrayList<string>();
                switch (current_category) {
                    case "politics": section_urls.add("https://www.foxnews.com/politics"); break;
                    case "us": section_urls.add("https://www.foxnews.com/us"); break;
                    case "technology":
                        section_urls.add("https://www.foxnews.com/tech");
                        section_urls.add("https://www.foxnews.com/technology");
                        break;
                    case "science": section_urls.add("https://www.foxnews.com/science"); break;
                    case "sports": section_urls.add("https://www.foxnews.com/sports"); break;
                    case "health": section_urls.add("https://www.foxnews.com/health"); break;
                    case "entertainment": section_urls.add("https://www.foxnews.com/entertainment"); break;
                    case "lifestyle": section_urls.add("https://www.foxnews.com/lifestyle"); break;
                    case "general":
                        section_urls.add("https://www.foxnews.com/world");
                        section_urls.add("https://www.foxnews.com");
                        break;
                    default: section_urls.add("https://www.foxnews.com"); break;
                }

                if (current_search_query.length > 0) {
                    Idle.add(() => {
                        set_label(@"No Fox News results for search: \"$(current_search_query)\"");
                        clear_items();
                        return false;
                    });
                    return null;
                }

                Gee.ArrayList<Paperboy.NewsArticle> articles = new Gee.ArrayList<Paperboy.NewsArticle>();
                int max_sections = 2; // Limit to 2 section URLs to avoid long lockups
                int section_count = 0;
                foreach (string candidate_url in section_urls) {
                    if (section_count >= max_sections) break;
                    section_count++;
                    var msg = new Soup.Message("GET", candidate_url);
                    msg.request_headers.append("User-Agent", "Mozilla/5.0 (Linux; rv:91.0) Gecko/20100101 Firefox/91.0");
                    msg.request_headers.append("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
                    msg.request_headers.append("Accept-Language", "en-US,en;q=0.5");
                    msg.request_headers.append("Cache-Control", "no-cache");
                    session.timeout = 8; // 8 second timeout to avoid hanging
                    session.send_message(msg);
                    if (msg.status_code != 200) continue;
                    string body = (string) msg.response_body.flatten().data;

                    var ld_regex = /<script[^>]*type=\"application\/ld\+json\"[^>]*>([\s\S]*?)<\/script>/;
                    MatchInfo ld_info;
                    if (ld_regex.match(body, 0, out ld_info)) {
                        do {
                            string json_ld = ld_info.fetch(1);
                            parse_fox_json_ld(json_ld, articles);
                        } while (ld_info.next());
                    }
                    if (articles.size == 0) {
                        var article_block_regex = /<article[\s\S]*?<\/article>/;
                        MatchInfo block_info;
                        if (article_block_regex.match(body, 0, out block_info)) {
                            int batch_limit = 18; // Limit to 18 articles per section
                            int batch_count = 0;
                            do {
                                if (batch_count >= batch_limit) break;
                                batch_count++;
                                string block = block_info.fetch(0);
                                var headline_regex = /<h2[^>]*>\s*<a[^>]*href=\"(\/[^"]+)\"[^>]*>(.*?)<\/a>\s*<\/h2>/;
                                var headline_h_regex = /<h[1-4][^>]*>\s*<a[^>]*href=\"(\/[^"]+)\"[^>]*>(.*?)<\/a>\s*<\/h[1-4]>/;
                                var anchor_class_regex = /<a[^>]*href=\"(\/[^"]+)\"[^>]*class=\"[^"]*(?:title|headline|story|article)[^"]*\"[^>]*>(.*?)<\/a>/;
                                MatchInfo headline_info;
                                string rel_url = null;
                                string title = null;
                                if (headline_regex.match(block, 0, out headline_info)) {
                                    rel_url = headline_info.fetch(1);
                                    title = headline_info.fetch(2).strip();
                                } else if (headline_h_regex.match(block, 0, out headline_info)) {
                                    rel_url = headline_info.fetch(1);
                                    title = headline_info.fetch(2).strip();
                                } else if (anchor_class_regex.match(block, 0, out headline_info)) {
                                    rel_url = headline_info.fetch(1);
                                    title = headline_info.fetch(2).strip();
                                } else {
                                    var anchor_fallback = /<a[^>]*href=\"(\/[^"]+)\"[^>]*>([^<]{30,}?)<\/a>/;
                                    MatchInfo af_info;
                                    if (anchor_fallback.match(block, 0, out af_info)) {
                                        rel_url = af_info.fetch(1);
                                        title = af_info.fetch(2).strip();
                                    }
                                }
                                if (rel_url != null && title != null) {
                                    string url = rel_url.has_prefix("http") ? rel_url : "https://www.foxnews.com" + rel_url;
                                    if (title.length > 10 && !is_duplicate_url(articles, url)) {
                                        var article = new Paperboy.NewsArticle();
                                        article.title = title;
                                        article.url = url;
                                        var img_regex = /<img[^>]*src=\"(https:\/\/static\.foxnews\.com[^"]+)\"[^>]*alt=\"([^"]*)\"[^>]*>/;
                                        MatchInfo img_info;
                                        if (img_regex.match(block, 0, out img_info)) {
                                            do {
                                                string img_url = img_info.fetch(1);
                                                string alt_text = img_info.fetch(2);
                                                if (!(img_url.contains("og-fox-news.png") || img_url.contains("logo") || img_url.contains("favicon") || alt_text.contains("Fox News"))) {
                                                    article.image_url = img_url;
                                                    break;
                                                }
                                            } while (img_info.next());
                                        }
                                        var p_regex = /<p[^>]*>(.*?)<\/p>/;
                                        MatchInfo p_info;
                                        if (p_regex.match(block, 0, out p_info)) {
                                            string snippet = p_info.fetch(1).strip();
                                            if (snippet.length > 0) {
                                                article.snippet = strip_html(snippet);
                                            }
                                        }
                                        articles.add(article);
                                    }
                                }
                            } while (block_info.next());
                        }
                    }
                    Tools.ImageExtractor.extract_article_images_from_html(body, articles, "static.foxnews.com");
                    if (articles.size > 0) break;
                }
                // UI batching: add articles in small batches with short delays
                Idle.add(() => {
                    string category_name = category_display_name(current_category) + " — Fox News";
                    if (current_search_query.length > 0) {
                        set_label(@"Search Results: \"$(current_search_query)\" in $(category_name)");
                    } else {
                        set_label(category_name);
                    }
                    clear_items();
                    int ui_limit = 16;
                    int ui_count = 0;
                    int total = articles.size;
                    int count = 0;
                    foreach (var article in articles) {
                        if (count >= ui_limit) break;
                        Idle.add(() => {
                            add_item(article.title, article.url, article.image_url, current_category);
                            return false;
                        });
                        count++;
                    }
                    fetch_fox_article_images(articles, session, add_item, current_category);
                    return false;
                });
            } catch (GLib.Error e) {
                warning("Error parsing Fox News HTML: %s", e.message);
                Idle.add(() => {
                    set_label("Fox News: Error loading articles");
                    clear_items();
                    return false;
                });
            }
            return null;
        });
    }

    private static void parse_fox_json_ld(string json_content, Gee.ArrayList<Paperboy.NewsArticle> articles) {
        try {
            var parser = new Json.Parser();
            parser.load_from_data(json_content);
            var root = parser.get_root();
            
            if (root.get_node_type() == Json.NodeType.ARRAY) {
                var array = root.get_array();
                foreach (var element in array.get_elements()) {
                    parse_fox_json_article(element.get_object(), articles);
                }
            } else if (root.get_node_type() == Json.NodeType.OBJECT) {
                parse_fox_json_article(root.get_object(), articles);
            }
        } catch (GLib.Error e) {
            // JSON parsing failed, ignore
        }
    }

    private static void parse_fox_json_article(Json.Object obj, Gee.ArrayList<Paperboy.NewsArticle> articles) {
    if (obj.has_member("@type") && obj.get_string_member("@type") == "NewsArticle") {
            if (obj.has_member("headline") && obj.has_member("url")) {
                string title = obj.get_string_member("headline");
                string url = obj.get_string_member("url");
                
                if (title.length > 10 && !is_duplicate_url(articles, url)) {
                    var article = new Paperboy.NewsArticle();
                    article.title = title;
                    article.url = url;
                    
                    // Try to get image from JSON-LD
                    if (obj.has_member("image")) {
                        var image_node = obj.get_member("image");
                        if (image_node.get_node_type() == Json.NodeType.OBJECT) {
                            var image_obj = image_node.get_object();
                            if (image_obj.has_member("url")) {
                                article.image_url = image_obj.get_string_member("url");
                            }
                        } else if (image_node.get_node_type() == Json.NodeType.ARRAY) {
                            var image_array = image_node.get_array();
                            if (image_array.get_length() > 0) {
                                var first_image = image_array.get_element(0);
                                if (first_image.get_node_type() == Json.NodeType.OBJECT) {
                                    var img_obj = first_image.get_object();
                                    if (img_obj.has_member("url")) {
                                        article.image_url = img_obj.get_string_member("url");
                                    }
                                }
                            }
                        }
                    }
                    
                    articles.add(article);
                }
            }
        }
    }

    private static bool is_duplicate_url(Gee.ArrayList<Paperboy.NewsArticle> articles, string url) {
        foreach (var article in articles) {
            if (article.url == url) {
                return true;
            }
        }
        return false;
    }


    private static void fetch_fox_article_images(
    Gee.ArrayList<Paperboy.NewsArticle> articles,
        Soup.Session session,
        AddItemFunc add_item,
        string current_category
    ) {
        // Fetch images for articles that don't have them yet, but limit to first
        // few articles to reduce overall load latency. Call the per-article
        // fetcher directly since it spawns its own background thread.
        int count = 0;
        // OG image fetching for missing images is handled elsewhere; do not call extract_article_images_from_html here.
        foreach (var article in articles) {
            if (article.image_url == null && count < 6) {
                // Placeholder for future OG image fetch logic if needed
                count++;
            }
        }
    }

    private static void fetch_guardian_article_images(
        Json.Array results,
        Soup.Session session,
        AddItemFunc add_item,
        string current_category
    ) {
        // results is the Guardian API 'results' array; fetch OG images for first few
        // articles (lower concurrency to speed up perceived load). We spawn
        // fetch threads immediately; the fetch function itself runs in a
        // background thread so no additional scheduling is necessary.
        int count = 0;
        uint len = results.get_length();
        for (uint i = 0; i < len && count < 6; i++) {
            var article = results.get_element(i).get_object();
            if (article.has_member("webUrl")) {
                string url = article.get_string_member("webUrl");
                // fetch_guardian_article_image spawns its own thread, so call directly
                fetch_guardian_article_image(url, session, add_item, current_category);
                count++;
            }
        }
    }

    private static void fetch_guardian_article_image(
        string article_url,
        Soup.Session session,
        AddItemFunc add_item,
        string current_category
    ) {
        new Thread<void*>("fetch-guardian-image", () => {
            try {
                var msg = new Soup.Message("GET", article_url);
                msg.request_headers.append("User-Agent", "Mozilla/5.0 (Linux; rv:91.0) Gecko/20100101 Firefox/91.0");
                session.send_message(msg);

                if (msg.status_code == 200) {
                    string body = (string) msg.response_body.flatten().data;
                    // Look for Open Graph image meta tag
                    var og_regex = /<meta[^>]*property="og:image"[^>]*content="([^"]+)"/;
                    MatchInfo match_info;
                    if (og_regex.match(body, 0, out match_info)) {
                        string image_url = match_info.fetch(1);
                        // Guardian OG image discovered; update UI silently
                        // Update UI by calling add_item with image_url - title/url unknown here, so call add_item with empty title
                        // Instead, try to extract the headline to pass through
                        string title = "";
                        var title_regex = /<meta[^>]*property="og:title"[^>]*content="([^"]+)"/;
                        MatchInfo t_info;
                        if (title_regex.match(body, 0, out t_info)) {
                            title = t_info.fetch(1);
                        }
                        if (title.length == 0) {
                            // Try h1
                            var h1_regex = /<h1[^>]*>([^<]+)<\/h1>/;
                            MatchInfo h1_info;
                            if (h1_regex.match(body, 0, out h1_info)) {
                                title = strip_html(h1_info.fetch(1)).strip();
                            }
                        }
                        if (title.length == 0) title = article_url; // fallback

                        Idle.add(() => {
                            add_item(title, article_url, image_url, current_category);
                            return false;
                        });
                    }
                }
            } catch (GLib.Error e) {
                // ignore
            }
            return null;
        });
    }


        /* Wall Street Journal scraper: attempt to extract recent articles and images
        * We intentionally keep this conservative: try JSON-LD first (structured data),
        * fall back to article/anchor heuristics, and then attempt to fetch images
        * from individual article pages for missing thumbnails. WSJ is often
        * paywalled; this scraper will simply skip articles that are inaccessible.
        */
    private static void fetch_wsj(
        string current_category,
        string current_search_query,
        Soup.Session session,
        SetLabelFunc set_label,
        ClearItemsFunc clear_items,
        AddItemFunc add_item
    ) {
        // Always use Google News RSS to discover WSJ articles for any category
        // Use Google News RSS to discover WSJ articles for any category
        // After RSS fetch, try to fetch homepage images and match to articles
        RssParser.fetch_rss_url(
            "https://news.google.com/rss/search?q=" + Uri.escape_string("site:wsj.com" + (current_search_query.length > 0 ? " " + current_search_query : "")) + "&hl=en-US&gl=US&ceid=US:en",
            "Wall Street Journal",
            category_display_name(current_category),
            current_category,
            current_search_query,
            session,
            set_label,
            clear_items,
            add_item
        );

        // Optionally, fetch homepage images and match to articles (requires article list)
        // This step can be added after RSS parsing if you refactor RssParser to expose the article list.
    }

    private static void fetch_wsj_article_images(
    Gee.ArrayList<Paperboy.NewsArticle> articles,
        Soup.Session session,
        AddItemFunc add_item,
        string current_category
    ) {
        int count = 0;
        foreach (var article in articles) {
            if (article.image_url == null && count < 6) {
                fetch_wsj_article_image(article, session, add_item, current_category);
                count++;
            }
        }
    }

    private static void fetch_wsj_article_image(
    Paperboy.NewsArticle article,
        Soup.Session session,
        AddItemFunc add_item,
        string current_category
    ) {
        // Function removed as requested; no longer calls extract_first_image_url_from_html
    }




}
