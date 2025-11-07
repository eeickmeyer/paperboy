/* Paperboy - A simple news reader application
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

using Gtk;
using Adw;
using Soup;
using Gdk;

 

public class PaperboyApp : Adw.Application {
    public PaperboyApp() {
        GLib.Object(application_id: "org.gnome.Paperboy", flags: ApplicationFlags.FLAGS_NONE);
    }

    protected override void activate() {
        var win = new NewsWindow(this);
        win.present();
        
        var change_source_action = new SimpleAction("change-source", null);
        change_source_action.activate.connect(() => {
            PrefsDialog.show_source_dialog(win);
        });
        this.add_action(change_source_action);
        
        var about_action = new SimpleAction("about", null);
        about_action.activate.connect(() => {
            PrefsDialog.show_about_dialog(win);
        });
        this.add_action(about_action);
    }

}

public static int main(string[] args) {
    var app = new PaperboyApp();
    return app.run(args);
}
