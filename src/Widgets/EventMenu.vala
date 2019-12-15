/*
 * Copyright 2011-2018 elementary, Inc. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Maxwell Barvian
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.EventMenu : Gtk.Menu {
    public ECal.Component comp { get; construct set; }

    public EventMenu (ECal.Component comp) {
        Object (
             comp: comp
         );
    }

    construct {
        E.Source src = comp.get_data ("source");
        bool can_modify_cal = Model.CalendarModel.get_default ().calclient_is_readonly (src) == false;
        bool sensitive = src.writable && can_modify_cal;

        var edit_item = new Gtk.MenuItem.with_label (_("Edit…"));
        edit_item.sensitive = sensitive;

        Gtk.MenuItem remove_item;
        if (comp.has_recurrences ()) {
            remove_item = new Gtk.MenuItem.with_label (_("Remove Event"));

            var exception_item = new Gtk.MenuItem.with_label (_("Remove Occurrence"));
            exception_item.activate.connect (add_exception);
            exception_item.sensitive = sensitive;

            append (exception_item);
        } else {
            remove_item = new Gtk.MenuItem.with_label (_("Remove"));
        }

        remove_item.sensitive = sensitive;
        remove_item.activate.connect (remove_event);

        var dup_item = new Gtk.MenuItem.with_label (_("Duplicate"));
        dup_item.sensitive = can_modify_cal;

        append (remove_item);
        append (dup_item);
        append (edit_item);

        remove_item.activate.connect (remove_event);
        dup_item.activate.connect (duplicate_event);

        edit_item.activate.connect (() => {
            ((Maya.Application) GLib.Application.get_default ()).window.on_modified (comp);
        });
    }

    private void remove_event () {
        var calmodel = Model.CalendarModel.get_default ();
        calmodel.remove_event (comp.get_data<E.Source> ("source"), comp, ECal.ObjModType.ALL);
    }

    private void duplicate_event () {
        // Generate a new unique ID for the new event
        var now = new DateTime.now_local ();
        var uid = "%ld-%u".printf ((long)now.to_unix (), GLib.Random.next_int ());

        // Make a duplicate of the event with the new unique ID
        var dup = comp;
        dup.set_uid (uid);

        // Store the duplicated event in the calendar
        var calmodel = Model.CalendarModel.get_default ();
        calmodel.add_event (comp.get_data<E.Source> ("source"), dup);
    }

    private void add_exception () {
        var calmodel = Model.CalendarModel.get_default ();
        calmodel.remove_event (comp.get_data<E.Source> ("source"), comp, ECal.ObjModType.THIS);
    }
}
