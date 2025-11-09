/*
 * Simple Nominatim-based ZIP -> city resolver.
 * Uses OpenStreetMap Nominatim public endpoint. This is intended for
 * low-volume lookups (please respect Nominatim usage policy). No API
 * key is required. Results are delivered asynchronously via the
 * provided callback on the main thread.
 */

using GLib;
using Soup;
using Json;

public delegate void GeoLookupResult(string? city, string? error);

public class LocationGeocode : GLib.Object {
    // Asynchronous lookup for a US ZIP code. Calls cb(city, null) on success
    // where city is a human-readable string like "San Francisco, California".
    // On failure calls cb(null, error_message).
    public static void lookup_zip_async(string zip, GeoLookupResult cb) {
        // Spawn a background thread to avoid blocking the UI
        new Thread<void*>("geo-lookup", () => {
            try {
                var session = new Soup.Session();
                // Nominatim search: ask for json, address details, limit results
                string q = zip.strip() + " USA";
                string url = "https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&countrycodes=us&limit=3&q=" + Uri.escape_string(q);

                var msg = new Soup.Message("GET", url);
                // Provide a polite user-agent per Nominatim policy
                msg.request_headers.append("User-Agent", "paperboy/0.1 (contact@paperboy.example)");
                session.send_message(msg);

                if (msg.status_code != 200) {
                    Idle.add(() => { cb(null, "HTTP error " + msg.status_code.to_string()); return false; });
                    return null;
                }

                string body = (string) msg.response_body.flatten().data;
                var parser = new Json.Parser();
                parser.load_from_data(body);
                var root = parser.get_root();
                Json.Array arr = null;
                try {
                    arr = root.get_array();
                } catch (GLib.Error __geo_ex) {
                    Idle.add(() => { cb(null, "Unexpected response format"); return false; });
                    return null;
                }

                if (arr.get_length() == 0) {
                    Idle.add(() => { cb(null, "No results for ZIP"); return false; });
                    return null;
                }

                // Prefer the first result; extract address fields
                var first = arr.get_element(0).get_object();
                if (!first.has_member("address")) {
                    Idle.add(() => { cb(null, "No address in result"); return false; });
                    return null;
                }
                var addr = first.get_object_member("address");
                string city = "";
                if (addr.has_member("city")) city = addr.get_string_member("city");
                else if (addr.has_member("town")) city = addr.get_string_member("town");
                else if (addr.has_member("village")) city = addr.get_string_member("village");
                else if (addr.has_member("county")) city = addr.get_string_member("county");

                string state = "";
                if (addr.has_member("state")) state = addr.get_string_member("state");

                if (city.length > 0 && state.length > 0) {
                    string out = city + ", " + state;
                    // avoid complex casts inside the lambda: capture locals
                    string captured_city = out;
                    string? captured_err = null;
                    Idle.add(() => { cb(captured_city, captured_err); return false; });
                    return null;
                } else if (state.length > 0) {
                    string captured_state = state;
                    string? captured_err2 = null;
                    Idle.add(() => { cb(captured_state, captured_err2); return false; });
                    return null;
                } else {
                    Idle.add(() => { cb(null, "Unable to determine city/state"); return false; });
                    return null;
                }
            } catch (GLib.Error e) {
            }
            return null;
        });
    }
}
