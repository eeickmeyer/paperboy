/*
 * Utility for stripping HTML and decoding common entities.
 * Extracted from articleWindow to be reusable across the project.
 */

public class HtmlUtils {
    
    public static string strip_html(string s) {
        var sb = new StringBuilder();
        bool intag = false;
        for (int i = 0; i < s.length; i++) {
            char c = s[i];
            if (c == '<') { intag = true; continue; }
            if (c == '>') { intag = false; continue; }
            if (!intag) sb.append_c(c);
        }
        string out = sb.str;

        // First decode numeric HTML entities (both decimal and hexadecimal)
        out = out.replace("&#x27;", "'");   // apostrophe
        out = out.replace("&#X27;", "'");   // apostrophe (uppercase)
        out = out.replace("&#x22;", "\"");  // quotation mark
        out = out.replace("&#X22;", "\"");  // quotation mark (uppercase)
        out = out.replace("&#x26;", "&");   // ampersand
        out = out.replace("&#X26;", "&");   // ampersand (uppercase)
        out = out.replace("&#x3C;", "<");   // less than
        out = out.replace("&#X3C;", "<");   // less than (uppercase)
        out = out.replace("&#x3E;", ">");   // greater than
        out = out.replace("&#X3E;", ">");   // greater than (uppercase)
        out = out.replace("&#x20;", " ");   // space  
        out = out.replace("&#X20;", " ");   // space (uppercase)
        out = out.replace("&#x2019;", "'"); // right single quotation mark
        out = out.replace("&#X2019;", "'"); // right single quotation mark (uppercase)
        // left single quotation mark (e.g. &#x2018; / &#8216;)
        out = out.replace("&#x2018;", "'");
        out = out.replace("&#X2018;", "'");
        out = out.replace("&#8216;", "'");
        out = out.replace("&#8217;", "'");
        // Some feeds use a three-digit decimal entity with a leading zero (e.g. &#039;)
        // Normalize that common variant to an apostrophe as well.
        out = out.replace("&#039;", "'");
        out = out.replace("&#x201C;", "\""); // left double quotation mark
        out = out.replace("&#X201C;", "\""); // left double quotation mark (uppercase)
        out = out.replace("&#x201D;", "\""); // right double quotation mark
        out = out.replace("&#X201D;", "\""); // right double quotation mark (uppercase)
        // Decimal variants for left/right double quotation marks (e.g. &#8220; / &#8221;)
        out = out.replace("&#8220;", "\"");
        out = out.replace("&#8221;", "\"");
        out = out.replace("&#x2013;", "–"); // en dash
        out = out.replace("&#X2013;", "–"); // en dash (uppercase)
        out = out.replace("&#x2014;", "—"); // em dash
        out = out.replace("&#X2014;", "—"); // em dash (uppercase)

        // Common invisible / zero-width characters that appear in some feeds
        out = out.replace("&#x200B;", ""); // zero-width space
        out = out.replace("&#X200B;", ""); // zero-width space (uppercase X)
        out = out.replace("&#8203;", ""); // zero-width space (decimal)
        // Also remove any literal ZERO WIDTH chars that may have survived
        out = out.replace("\u200B", "");
        out = out.replace("\uFEFF", ""); // zero-width no-break space / BOM

        // Then decode named HTML entities
        out = out.replace("&amp;", "&");
        out = out.replace("&lt;", "<");
        out = out.replace("&gt;", ">");
        out = out.replace("&quot;", "\"");
        out = out.replace("&#39;", "'");
        out = out.replace("&apos;", "'");
        out = out.replace("&nbsp;", " ");
        out = out.replace("&mdash;", "—");
        out = out.replace("&ndash;", "–");
        out = out.replace("&hellip;", "…");
        out = out.replace("&rsquo;", "'");
        out = out.replace("&lsquo;", "'");
        out = out.replace("&rdquo;", "\"");
        out = out.replace("&ldquo;", "\"");

        // Clean whitespace
        out = out.replace("\n", " ").replace("\r", " ").replace("\t", " ");
        // collapse multiple spaces
        while (out.index_of("  ") >= 0) out = out.replace("  ", " ");
        return out.strip();
    }
}
