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
    public E.CalComponent comp { get; construct set; }
    public GLib.DateTime date { get; construct; }

    public EventMenu (E.CalComponent comp, GLib.DateTime date) {
        Object (
             comp: comp,
             date: date
         );
    }

    construct {
        E.Source src = comp.get_data ("source");
        bool sensitive = src.writable == true && Model.CalendarModel.get_default ().calclient_is_readonly (src) == false;

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

        append (remove_item);
        append (edit_item);

        remove_item.activate.connect (remove_event);

        edit_item.activate.connect (() => {
            ((Maya.Application) GLib.Application.get_default ()).window.on_modified (comp);
        });
    }

    private void remove_event () {
        var calmodel = Model.CalendarModel.get_default ();
        calmodel.remove_event (comp.get_data<E.Source> ("source"), comp, E.CalObjModType.ALL);
    }

    private void add_exception () {
        unowned iCal.Component comp_ical = comp.get_icalcomponent ();
        iCal.Component ical = new iCal.Component.clone (comp_ical);

        var exdate = new iCal.Property (iCal.PropertyKind.EXDATE);
        exdate.set_exdate (Util.date_time_to_ical (date, null));
        ical.add_property (exdate);
        comp.set_icalcomponent ((owned) ical);

        var calmodel = Model.CalendarModel.get_default ();
        calmodel.update_event (comp.get_data<E.Source> ("source"), comp, E.CalObjModType.ALL);
    }
}
