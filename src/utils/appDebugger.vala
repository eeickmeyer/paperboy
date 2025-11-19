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

/* 
 * Small centralized app debugger helper so logging can be reused across
 * modules without duplicating file IO logic.
 */

using GLib;

public class AppDebugger : GLib.Object {
    // Append a debug line to the provided path. Best-effort; swallow errors.
    public static void append_debug_log(string path, string line) {
        try {
            string p = path;
            string old = "";
            try { GLib.FileUtils.get_contents(p, out old); } catch (GLib.Error e) { old = ""; }
            string outc = old + line + "\n";
            GLib.FileUtils.set_contents(p, outc);
        } catch (GLib.Error e) {
            // best-effort logging only
        }
    }

    // Return true when PAPERBOY_DEBUG is enabled in the environment.
    public static bool debug_enabled() {
        try {
            string? v = GLib.Environment.get_variable("PAPERBOY_DEBUG");
            return v != null && v.length > 0;
        } catch (GLib.Error e) {
            return false;
        }
    }

    // Log a line only when debug is enabled. Swallows errors.
    public static void log_if_enabled(string path, string line) {
        try {
            if (debug_enabled()) append_debug_log(path, line);
        } catch (GLib.Error e) {
            // best-effort
        }
    }

    // Small helper to join a Gee.ArrayList<string> for debug output
    public static string array_join(Gee.ArrayList<string>? list) {
        if (list == null) return "(null)";
        string out = "";
        try {
            foreach (var s in list) {
                if (out.length > 0) out += ",";
                out += s;
            }
        } catch (GLib.Error e) { return "(error)"; }
        return out;
    }
}
