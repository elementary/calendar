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
 * Represent the week labels at the left side of the grid.
 */
public class WeekLabels : Gtk.EventBox {

    private Gtk.Grid day_grid;
    private Gtk.Label[] labels;
    private int nr_of_weeks;

    public WeekLabels () {

        no_show_all = true;

        day_grid = new Gtk.Grid ();
        set_nr_of_weeks (5);
        day_grid.insert_row (1);
        day_grid.set_column_homogeneous (true);
        day_grid.set_row_homogeneous (true);
        day_grid.row_spacing = 0;
        day_grid.show ();

        var style_provider = Util.Css.get_css_provider ();

        // EventBox properties
        set_visible_window (true); // needed for style
        get_style_context().add_provider (style_provider, 600);
        get_style_context().add_class ("weeks");

        add (day_grid);
    }

    public void update (DateTime date, int nr_of_weeks) {

        update_nr_of_labels (nr_of_weeks);

        if (Settings.SavedState.get_default ().show_weeks) {
            if (!visible)
                show ();

            var next = date;
            // Find the beginning of the week which is apparently always a monday
            int days_to_add = (8 - next.get_day_of_week()) % 7;
            next = next.add_days(days_to_add);
            foreach (var label in labels) {
                label.label = next.get_week_of_year ().to_string();
                next = next.add_weeks (1);
            }
        } else {
            hide ();
        }
    }

    public void set_nr_of_weeks (int new_number) {
        day_grid.insert_row (new_number);
        nr_of_weeks = new_number;
    }

    public int get_nr_of_weeks () {
        return nr_of_weeks;
    }

    void update_nr_of_labels (int nr_of_weeks) {
        // Destroy all the old ones

        if (labels != null)
            foreach (var label in labels)
                label.destroy ();

        // Create new labels
        labels = new Gtk.Label[nr_of_weeks];
        for (int c = 0; c < nr_of_weeks; c++) {
            labels[c] = new Gtk.Label ("");
            labels[c].valign = Gtk.Align.START;
            labels[c].width_chars = 2;
            labels[c].draw.connect (on_draw);
            day_grid.attach (labels[c], 0, c, 1, 1);
            labels[c].show ();
        }
    }

    private bool on_draw (Gtk.Widget widget, Cairo.Context cr) {

        Gtk.Allocation size;
        widget.get_allocation (out size);

        // Draw left and top black strokes
        cr.move_to (0, 0); // start on upper left. 0.5 accounts for cairo's default stroke offset of 1/2 pixels
        cr.line_to (size.width + 0.5, 0.5); // move to upper right corner

        cr.set_source_rgba (0.0, 0.0, 0.0, 0.25);
        cr.set_line_width (1.0);
        cr.set_antialias (Cairo.Antialias.NONE);
        cr.stroke ();
        return false;
    }

}

}