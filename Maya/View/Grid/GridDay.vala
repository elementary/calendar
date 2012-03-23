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
 * Represents a single day on the grid.
 */
public class GridDay : Gtk.EventBox {

    public DateTime date { get; private set; }

    Gtk.Label label;
    Gtk.VBox vbox;
    VAutoHider event_box;
    Gee.List<EventButton> event_buttons;

    private static const int EVENT_MARGIN = 3;

    public GridDay (DateTime date) {

        this.date = date;
        event_buttons = new Gee.ArrayList<EventButton>();

        var style_provider = Util.Css.get_css_provider ();

        vbox = new Gtk.VBox (false, 0);
        label = new Gtk.Label ("");
        event_box = new VAutoHider ();

        // EventBox Properties
        can_focus = true;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        get_style_context ().add_provider (style_provider, 600);
        get_style_context ().add_class ("cell");

        label.halign = Gtk.Align.END;
        label.get_style_context ().add_provider (style_provider, 600);
        label.name = "date";
        vbox.pack_start (label, false, false, 0);
        vbox.pack_start (event_box, true, true, 0);

        add (Util.set_margins (vbox, EVENT_MARGIN, EVENT_MARGIN, EVENT_MARGIN, EVENT_MARGIN));
        vbox.show ();
        event_box.show ();

        // Signals and handlers
        button_press_event.connect (on_button_press);
    }

    public void add_event(E.CalComponent comp) {
        var button = new EventButton(comp);
        event_box.add (button);

        event_buttons.add (button);
        event_buttons.sort (EventButton.compare_buttons);

        // Reorder the event buttons
        foreach (EventButton evbutton in event_buttons) {
            event_box.reorder_child (evbutton, -1);
        }
    }

    public void remove_event (E.CalComponent comp) {
        foreach(var button in event_buttons) {
            if(comp == button.comp) {
                event_buttons.remove(button);
                button.destroy();
                break;
            }
        }
    }
    
    public void clear_events () {
        foreach(var button in event_buttons) {
            button.destroy();
        }
        event_buttons.clear ();			
    }

    public void update_date (DateTime date) {

        this.date = date;
        label.label = date.get_day_of_month ().to_string ();
    }

    private bool on_button_press (Gdk.EventButton event) {

        grab_focus ();
        return true;
    }
}

}
