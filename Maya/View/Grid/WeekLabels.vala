namespace Maya.View {

/**
 * Represent the week labels at the left side of the grid.
 */
public class WeekLabels : Gtk.EventBox {

    private Gtk.Table table;
    private Gtk.Label[] labels;

    public WeekLabels () {

        table = new Gtk.Table (1, 6, false);
        table.row_spacing = 1;

        var style_provider = Util.Css.get_css_provider ();

        // EventBox properties
        set_visible_window (true); // needed for style
        get_style_context().add_provider (style_provider, 600);
        get_style_context().add_class ("weeks");

        labels = new Gtk.Label[table.n_columns];
        for (int c = 0; c < table.n_columns; c++) {
            labels[c] = new Gtk.Label ("");
            labels[c].valign = Gtk.Align.START;
            table.attach_defaults (labels[c], 0, 1, c, c + 1);
        }

        add (Util.set_margins (table, 20, 0, 0, 0));
    }

    public void update (DateTime date, bool show_weeks) {

        if (show_weeks) {
            if (!visible)
                show ();

            var next = date;
            foreach (var label in labels) {
                label.label = next.get_week_of_year ().to_string();
                next = next.add_weeks (1);
            }
        } else {
            hide ();
        }
    }
}

}
