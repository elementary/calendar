//
//  Copyright (C) 2011-2012 Maxwell Barvian
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Maya.View {

/**
 * Represents the header at the top of the calendar grid.
 */
public class Header : Gtk.EventBox {

    private Gtk.Table table;
    private Gtk.Label[] labels;

    public Header () {
        
        table = new Gtk.Table (1, 7, true);

        var style_provider = Util.Css.get_css_provider ();
    
        // EventBox properties
        set_visible_window (true); // needed for style
        get_style_context ().add_provider (style_provider, 600);
        get_style_context ().add_class ("header");
        
        labels = new Gtk.Label[table.n_columns];
        for (int c = 0; c < table.n_columns; c++) {
            labels[c] = new Gtk.Label ("");
            labels[c].draw.connect (on_draw);
            table.attach_defaults (labels[c], c, c + 1, 0, 1);
        }
        
        add (table);
    }
    
    public void update_columns (int week_starts_on) {
        
        var date = Util.strip_time(new DateTime.now_local ());
        date = date.add_days (week_starts_on - date.get_day_of_week ());
        foreach (var label in labels) {
            label.label = date.format ("%A");
            date = date.add_days (1);
        }
    }
    
    private bool on_draw (Gtk.Widget widget, Cairo.Context cr) {
    
        Gtk.Allocation size;
        widget.get_allocation (out size);
        
        // Draw left border
        cr.move_to (0.5, size.height); // start in bottom left. 0.5 accounts for cairo's default stroke offset of 1/2 pixels
        cr.line_to (0.5, 0.5); // move to upper left corner
        
        cr.set_source_rgba (0.0, 0.0, 0.0, 0.25);
        cr.set_line_width (1.0);
        cr.set_antialias (Cairo.Antialias.NONE);
        cr.stroke ();
        
        return false;
    }
}

}
