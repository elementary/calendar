//
//  Copyright (C) 2012 Niels Avonds <niels.avonds@gmail.com>
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
class MultiDayEventButton : EventButton {

    Gtk.Label label;

    public MultiDayEventButton (E.CalComponent comp) {
        base (comp);

        label = new Gtk.Label(get_summary ());
        add (label);
        label.hexpand = true;
        label.wrap = false;
        label.show ();
    }

}

}
