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
public class ImageParser {
	// Minimal HTML image extractor placeholder. Scans for images hosted on
	// a given host substring and assigns them to articles lacking images.
	public static void extract_article_images_from_html(string html, Gee.ArrayList<Paperboy.NewsArticle> articles, string host_substring) {
		try {
			var img_regex = new Regex("<img[^>]*src=\\\"(https?://[^\\\"]+)\\\"[^>]*>", RegexCompileFlags.DEFAULT);
			MatchInfo m;
			if (!img_regex.match(html, 0, out m)) return;
			var found_urls = new Gee.ArrayList<string>();
			do {
				string src = m.fetch(1);
				if (src.contains(host_substring)) found_urls.add(src);
			} while (m.next());

			if (found_urls.size == 0) return;

			int idx = 0;
			foreach (var article in articles) {
				if (article.image_url == null && idx < found_urls.size) {
					article.image_url = found_urls.get(idx);
					idx++;
				}
				if (idx >= found_urls.size) break;
			}
		} catch (GLib.Error e) {
			// ignore parsing errors
		}
	}

	// Extract image URL from an HTML snippet (like RSS description or content:encoded).
	public static string? extract_image_from_html_snippet(string html_snippet) {
		// Look for common image attributes used by BBC: src, data-src, srcset and data-srcset
		var attr_regex = new Regex("(src|data-src|srcset|data-srcset)=[\"']([^\"']+)[\"']", RegexCompileFlags.DEFAULT);
		MatchInfo m;
		if (!attr_regex.match(html_snippet, 0, out m)) return null;
		do {
			string attr_name = m.fetch(1).down();
			string attr_val = m.fetch(2);
			// For srcset-like attributes, take the first URL (it may contain descriptors)
				if (attr_name.has_suffix("srcset")) {
				// srcset: "url1 1x, url2 2x" -> take url1
				string[] parts = attr_val.split(",");
				if (parts.length > 0) {
					attr_val = parts[0].strip();
					// If there is a descriptor (" 1x"), remove it
                		int space_idx = attr_val.index_of(" ");
                		if (space_idx > 0) attr_val = attr_val.substring(0, space_idx);
				}
			}
			string img_url = attr_val;
			// Decode HTML entities
			img_url = img_url.replace("&amp;", "&");
			img_url = img_url.replace("&lt;", "<");
			img_url = img_url.replace("&gt;", ">");
			img_url = img_url.replace("&quot;", "\"");
			// Basic URL decode for common percent-encodings
			img_url = img_url.replace("%3A", ":");
			img_url = img_url.replace("%2F", "/");
			img_url = img_url.replace("%3F", "?");
			img_url = img_url.replace("%3D", "=");
			img_url = img_url.replace("%26", "&");
			
			// If the URL is protocol-relative, prefer https
			if (img_url.has_prefix("//")) img_url = "https:" + img_url;
			
			// If it's a data URI or clearly invalid, skip
			string img_url_lower = img_url.down();
			if (img_url_lower.has_prefix("data:") || img_url.length < 20) {
				// continue searching
				continue;
			}
			// Filter out icons, logos and tracking pixels but accept common image extensions
			bool is_tracking_pixel = img_url_lower.contains("tracking") || img_url_lower.contains("pixel") || img_url_lower.contains("1x1");
			bool looks_like_image = img_url_lower.contains("jpg") || img_url_lower.contains("jpeg") || img_url_lower.contains("png") || img_url_lower.contains("webp") || img_url_lower.contains("gif");
			if (!is_tracking_pixel && looks_like_image && (img_url.has_prefix("http") || img_url.has_prefix("https:"))) {
				return img_url;
			}
		} while (m.next());
		return null;
	}

	// Fetch Open Graph image and title from an article page and call add_item
	// to silently update the UI (same behavior previously implemented inline).
	public static void fetch_open_graph_image(string article_url, Soup.Session session, AddItemFunc add_item, string current_category, string? source_name) {
		new Thread<void*>("fetch-og-image", () => {
			try {
				var msg = new Soup.Message("GET", article_url);
				msg.request_headers.append("User-Agent", "Mozilla/5.0 (Linux; rv:91.0) Gecko/20100101 Firefox/91.0");
				session.send_message(msg);

				if (msg.status_code == 200) {
					string body = (string) msg.response_body.flatten().data;
					var og_regex = new Regex("<meta[^>]*property=\\\"og:image\\\"[^>]*content=\\\"([^\\\"]+)\\\"", RegexCompileFlags.DEFAULT);
					MatchInfo match_info;
					if (og_regex.match(body, 0, out match_info)) {
						string image_url = match_info.fetch(1);
						string title = "";
						var title_regex = new Regex("<meta[^>]*property=\\\"og:title\\\"[^>]*content=\\\"([^\\\"]+)\\\"", RegexCompileFlags.DEFAULT);
						MatchInfo t_info;
						if (title_regex.match(body, 0, out t_info)) {
							title = t_info.fetch(1);
						}
						if (title.length == 0) {
							var h1_regex = new Regex("<h1[^>]*>([^<]+)</h1>", RegexCompileFlags.DEFAULT);
							MatchInfo h1_info;
							if (h1_regex.match(body, 0, out h1_info)) {
								title = ImageParser.strip_html(h1_info.fetch(1)).strip();
							}
						}
						if (title.length == 0) title = article_url;

						Idle.add(() => {
							add_item(title, article_url, image_url, current_category, source_name);
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

	private static string strip_html(string input) {
		var regex = new Regex("<[^>]+>", RegexCompileFlags.DEFAULT);
		return regex.replace(input, -1, 0, "");
	}
}
}

