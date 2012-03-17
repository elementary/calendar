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
 * Represents a single event on the grid.
 */
class EventButton : Gtk.Grid {
    public E.CalComponent comp {get; private set;}
    
    Gtk.Label label;

    public EventButton (E.CalComponent comp) {
        
        E.CalComponentText ct;
        this.comp = comp;
        comp.get_summary (out ct);
        label = new Granite.Widgets.WrapLabel(ct.value);
        add (label);
        label.hexpand = true;
        label.wrap = false;
    }

    /**
     * Compares the given buttons according to date.
     */
    public static CompareFunc<EventButton> compare_buttons = (button1, button2) => {
        var comp1 = button1.comp;
        var comp2 = button2.comp;

        return Util.compare_events (comp1, comp2);
    };

}

}
