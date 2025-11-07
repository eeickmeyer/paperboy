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
using Paperboy;

namespace Tools {
    public class ImageExtractor {
    public static void extract_article_images_from_html(string html_content, Gee.ArrayList<Paperboy.NewsArticle> articles, string domain, string[] skip_keywords = null) {
            // Look for image tags with absolute URLs for the given domain
            string img_pattern = "<img[^>]*src=\\\"(https://" + domain + "[^\\\"]+)\\\"[^>]*alt=\\\"([^\\\"]*)\\\"[^>]*>";
            var img_regex = new Regex(img_pattern, RegexCompileFlags.CASELESS);
            MatchInfo match_info;

            if (img_regex.match(html_content, 0, out match_info)) {
                do {
                    string img_url = match_info.fetch(1);
                    string alt_text = match_info.fetch(2);

                    // Skip images with known keywords (icons, logos, favicons, etc.)
                    bool skip = false;
                    string[] default_keywords = { "icon", "logo", "favicon", "sprite", "og-", "apple-touch" };
                    string[] keywords = skip_keywords != null ? skip_keywords : default_keywords;
                    foreach (string kw in keywords) {
                        if (img_url.down().contains(kw) || alt_text.down().contains(kw)) {
                            skip = true;
                            break;
                        }
                    }
                    if (skip) continue;

                    // Try to match image to article by alt text similarity
                    foreach (var article in articles) {
                        if (article.image_url == null) {
                            // Simple keyword matching between alt text and article title
                            string[] alt_words = alt_text.down().split(" ");
                            string[] title_words = article.title.down().split(" ");
                            int matches = 0;
                            foreach (string alt_word in alt_words) {
                                if (alt_word.length > 3) {
                                    foreach (string title_word in title_words) {
                                        if (title_word.length > 3 && alt_word.contains(title_word)) {
                                            matches++;
                                            break;
                                        }
                                    }
                                }
                            }
                            // If we find some keyword matches, use this image
                            if (matches >= 1) {
                                article.image_url = img_url;
                                break;
                            }
                        }
                    }
                } while (match_info.next());
            }

            // Also look for data-src attributes (lazy loaded images)
            string lazy_pattern = "<img[^>]*data-src=\\\"(https://" + domain + "[^\\\"]+)\\\"[^>]*alt=\\\"([^\\\"]*)\\\"[^>]*>";
            var lazy_img_regex = new Regex(lazy_pattern, RegexCompileFlags.CASELESS);
            if (lazy_img_regex.match(html_content, 0, out match_info)) {
                do {
                    string img_url = match_info.fetch(1);
                    string alt_text = match_info.fetch(2);
                    bool skip = false;
                    string[] default_keywords = { "icon", "logo", "favicon", "sprite", "og-", "apple-touch" };
                    string[] keywords = skip_keywords != null ? skip_keywords : default_keywords;
                    foreach (string kw in keywords) {
                        if (img_url.down().contains(kw) || alt_text.down().contains(kw)) {
                            skip = true;
                            break;
                        }
                    }
                    if (skip) continue;

                    foreach (var article in articles) {
                        if (article.image_url == null) {
                            string[] alt_words = alt_text.down().split(" ");
                            string[] title_words = article.title.down().split(" ");
                            int matches = 0;
                            foreach (string alt_word in alt_words) {
                                if (alt_word.length > 3) {
                                    foreach (string title_word in title_words) {
                                        if (title_word.length > 3 && alt_word.contains(title_word)) {
                                            matches++;
                                            break;
                                        }
                                    }
                                }
                            }
                            if (matches >= 1) {
                                article.image_url = img_url;
                                break;
                            }
                        }
                    }
                } while (match_info.next());
            }
        }
    }
}
