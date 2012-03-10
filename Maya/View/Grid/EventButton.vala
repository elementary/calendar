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
    public E.CalComponent comp;
    public signal void removed (E.CalComponent comp);
    public signal void modified (E.CalComponent comp);
    
    Gtk.Label label;
    Gtk.Button close_button;
    Gtk.Button edit_button;
    public EventButton (E.CalComponent comp) {
        
        E.CalComponentText ct;
        this.comp = comp;
        comp.get_summary (out ct);
        label = new Granite.Widgets.WrapLabel(ct.value);
        add (label);
        label.hexpand = true;
        close_button = new Gtk.Button ();
        edit_button = new Gtk.Button ();
        close_button.add (new Gtk.Image.from_stock ("gtk-close", Gtk.IconSize.MENU));
        edit_button.add (new Gtk.Image.from_stock ("gtk-edit", Gtk.IconSize.MENU));
        close_button.set_relief (Gtk.ReliefStyle.NONE);
        edit_button.set_relief (Gtk.ReliefStyle.NONE);
        
        add (edit_button);
        add (close_button);
        
        close_button.clicked.connect( () => { removed(comp); });
        edit_button.clicked.connect( () => { modified(comp); });
    }
}

}
