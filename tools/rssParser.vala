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

using Soup;
using Xml;
using Gee;

public class RssParser {
    
    public static void parse_rss_and_display(
        string body,
        string source_name,
        string category_name,
        string category_id,
        string current_search_query,
        SetLabelFunc set_label,
        ClearItemsFunc clear_items,
        AddItemFunc add_item
    ) {
        try {
            Xml.Doc* doc = Xml.Parser.parse_memory(body, (int) body.length);
            if (doc == null) {
                warning("RSS parse failed");
                return;
            }

            var items = new Gee.ArrayList<Gee.ArrayList<string?>>();
            Xml.Node* root = doc->get_root_element();
            for (Xml.Node* ch = root->children; ch != null; ch = ch->next) {
                if (ch->type == Xml.ElementType.ELEMENT_NODE && (ch->name == "channel" || ch->name == "feed")) {
                    for (Xml.Node* it = ch->children; it != null; it = it->next) {
                        if (it->type == Xml.ElementType.ELEMENT_NODE && (it->name == "item" || it->name == "entry")) {
                            string? title = null;
                            string? link = null;
                            string? thumb = null;
                            for (Xml.Node* c = it->children; c != null; c = c->next) {
                                if (c->type == Xml.ElementType.ELEMENT_NODE) {
                                    if (c->name == "title") {
                                        title = c->get_content();
                                    } else if (c->name == "link") {
                                        Xml.Attr* href = c->properties;
                                        while (href != null) {
                                            if (href->name == "href") {
                                                link = href->children != null ? (string) href->children->content : null;
                                                break;
                                            }
                                            href = href->next;
                                        }
                                        if (link == null) {
                                            link = c->get_content();
                                        }
                                    } else if (c->name == "enclosure") {
                                        Xml.Attr* a = c->properties;
                                        while (a != null) {
                                            if (a->name == "url") {
                                                thumb = a->children != null ? (string) a->children->content : null;
                                                break;
                                            }
                                            a = a->next;
                                        }
                                    } else if (c->name == "thumbnail" && c->ns != null && c->ns->prefix == "media") {
                                        Xml.Attr* a2 = c->properties;
                                        while (a2 != null) {
                                            if (a2->name == "url") {
                                                thumb = a2->children != null ? (string) a2->children->content : null;
                                                break;
                                            }
                                            a2 = a2->next;
                                        }
                                    } else if (c->name == "content" && c->ns != null && c->ns->prefix == "media") {
                                        Xml.Attr* a3 = c->properties;
                                        while (a3 != null) {
                                            if (a3->name == "url" && thumb == null) {
                                                string? media_url = a3->children != null ? (string) a3->children->content : null;
                                                if (media_url != null && (media_url.has_suffix(".jpg") || media_url.has_suffix(".png") || media_url.has_suffix(".jpeg") || media_url.has_suffix(".webp"))) {
                                                    thumb = media_url;
                                                }
                                                break;
                                            }
                                            a3 = a3->next;
                                        }
                                    } else if (c->name == "description" && thumb == null) {
                                        // Sometimes images are in the description as HTML
                                        string? desc = c->get_content();
                                        if (desc != null) {
                                            thumb = extract_image_from_html_snippet(desc);
                                        }
                                    } else if (c->name == "encoded" && c->ns != null && c->ns->prefix == "content" && thumb == null) {
                                        // Check content:encoded for images (used by NPR and others)
                                        string? content = c->get_content();
                                        if (content != null) {
                                            thumb = extract_image_from_html_snippet(content);
                                        }
                                    }
                                }
                            }
                            if (title != null && link != null) {
                                var row = new Gee.ArrayList<string?>();
                                row.add(title);
                                row.add(link);
                                row.add(thumb);
                                items.add(row);
                            }
                        }
                    }
                }
            }

            Idle.add(() => {
                if (current_search_query.length > 0) {
                    set_label(@"Search Results: \"$(current_search_query)\" in $(category_name) — $(source_name)");
                } else {
                    set_label(@"$(category_name) — $(source_name)");
                }

                clear_items();
                foreach (var row in items) {
                    add_item(row[0] ?? "No title", row[1] ?? "", row[2], category_id);
                }
                return false;
            });
        } catch (GLib.Error e) {
            warning("RSS parse/display error: %s", e.message);
        }
    }

    public static void fetch_rss_url(
        string url,
        string source_name,
        string category_name,
        string category_id,
        string current_search_query,
        Soup.Session session,
        SetLabelFunc set_label,
        ClearItemsFunc clear_items,
        AddItemFunc add_item
    ) {
        new Thread<void*>("fetch-rss", () => {
            try {
                var msg = new Soup.Message("GET", url);
                msg.request_headers.append("User-Agent", "news-vala-gnome/0.1");
                session.send_message(msg);
                if (msg.status_code != 200) {
                    warning("HTTP %u for RSS", msg.status_code);
                    return null;
                }
                string body = (string) msg.response_body.flatten().data;
                parse_rss_and_display(body, source_name, category_name, category_id, current_search_query, set_label, clear_items, add_item);
            } catch (GLib.Error e) {
                warning("RSS fetch error: %s", e.message);
            }
            return null;
        });
    }

    // Extract image URL from HTML snippet (like RSS description or content:encoded)
    public static string? extract_image_from_html_snippet(string html_snippet) {
        // Look for img tags in the snippet
        int search_pos = 0;
        
        while (search_pos < html_snippet.length) {
            int img_pos = html_snippet.index_of("<img", search_pos);
            if (img_pos == -1) break;
            
            int src_start = html_snippet.index_of("src=\"", img_pos);
            if (src_start == -1) {
                src_start = html_snippet.index_of("src='", img_pos);
                if (src_start != -1) src_start += 5;
            } else {
                src_start += 5;
            }
            
            if (src_start != -1) {
                int src_end = html_snippet.index_of("\"", src_start);
                if (src_end == -1) {
                    src_end = html_snippet.index_of("'", src_start);
                }
                
                if (src_end != -1) {
                    string img_url = html_snippet.substring(src_start, src_end - src_start);
                    
                    // Decode HTML entities in the URL
                    img_url = img_url.replace("&amp;", "&");
                    img_url = img_url.replace("&lt;", "<");
                    img_url = img_url.replace("&gt;", ">");
                    img_url = img_url.replace("&quot;", "\"");
                    
                    // Basic URL decoding for NPR-style URLs
                    img_url = img_url.replace("%3A", ":");
                    img_url = img_url.replace("%2F", "/");
                    img_url = img_url.replace("%3F", "?");
                    img_url = img_url.replace("%3D", "=");
                    img_url = img_url.replace("%26", "&");
                    
                    // Check if this is a NPR-style resizing URL with nested image URL
                    if (img_url.contains("?url=http")) {
                        int url_param_start = img_url.index_of("?url=") + 5;
                        if (url_param_start > 4 && url_param_start < img_url.length) {
                            string nested_url = img_url.substring(url_param_start);
                            // If the nested URL looks like a proper image URL, use it instead
                            if (nested_url.length > 30 && nested_url.has_prefix("http")) {
                                img_url = nested_url;
                            }
                        }
                    }
                    
                    string img_url_lower = img_url.down();
                    
                    // Enhanced filtering to skip unwanted images but allow more legitimate ones
                    bool is_tracking_pixel = img_url_lower.contains("tracking") || 
                                           img_url_lower.contains("pixel") ||
                                           img_url_lower.contains("1x1") ||
                                           img_url.length < 30;
                    
                    bool is_valid_image = img_url.length > 30 && 
                        !img_url_lower.contains("icon") && 
                        !img_url_lower.contains("logo") && 
                        !is_tracking_pixel &&
                        (img_url.has_prefix("http") || img_url.has_prefix("//")) &&
                        (img_url_lower.contains("jpg") || img_url_lower.contains("jpeg") || 
                         img_url_lower.contains("png") || img_url_lower.contains("webp") || 
                         img_url_lower.contains("gif")); // Must be an actual image format
                    
                    if (is_valid_image) {
                        return img_url.has_prefix("//") ? "https:" + img_url : img_url;
                    }
                }
            }
            
            search_pos = img_pos + 4; // Move past this <img tag
        }
        return null;
    }
}