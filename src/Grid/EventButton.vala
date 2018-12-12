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

public class Maya.View.EventButton : Gtk.Revealer {
    public signal void edition_request ();

    public E.CalComponent comp { get; construct set; }
    public GLib.DateTime date { get; construct; }

    private Gtk.Label label;
    private Gtk.StyleContext grid_style_context;

    public EventButton (E.CalComponent comp, GLib.DateTime date) {
        Object (
             comp: comp,
             date: date
         );
    }

    construct {
        transition_type = Gtk.RevealerTransitionType.CROSSFADE;

        var event_image = new Gtk.Image.from_icon_name ("office-calendar-symbolic", Gtk.IconSize.MENU);

        var label_event_box = new Gtk.EventBox ();
        label_event_box.add (event_image);

        label = new Gtk.Label (get_summary ());
        label.hexpand = true;
        label.ellipsize = Pango.EllipsizeMode.END;
        label.xalign = 0;
        label.show ();

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/calendar/AgendaEventRow.css");

        var internal_grid = new Gtk.Grid ();
        internal_grid.column_spacing = 6;
        internal_grid.add (label_event_box);
        internal_grid.add (label);

        grid_style_context = internal_grid.get_style_context ();
        grid_style_context.add_class ("event");
        grid_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var event_box = new Gtk.EventBox ();
        event_box.events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        event_box.events |= Gdk.EventMask.SCROLL_MASK;
        event_box.events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
        event_box.add (internal_grid);

        add (event_box);

        label_event_box.scroll_event.connect ((event) => {
            return GesturesUtils.on_scroll_event (event);
        });

        event_box.button_press_event.connect ((event) => {
            if (event.type == Gdk.EventType.2BUTTON_PRESS && event.button == Gdk.BUTTON_PRIMARY) {
                edition_request ();
            } else if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == Gdk.BUTTON_SECONDARY) {
                E.Source src = comp.get_data ("source");

                bool sensitive = src.writable == true && Model.CalendarModel.get_default ().calclient_is_readonly (src) == false;

                var edit_item = new Gtk.MenuItem.with_label (_("Edit…"));
                edit_item.activate.connect (() => { edition_request (); });
                edit_item.sensitive = sensitive;

                Gtk.Menu menu = new Gtk.Menu ();
                menu.attach_to_widget (this, null);
                menu.append (edit_item);

                Gtk.MenuItem remove_item;
                if (comp.has_recurrences ()) {
                    remove_item = new Gtk.MenuItem.with_label (_("Remove Event"));

                    var exception_item = new Gtk.MenuItem.with_label (_("Remove Occurrence"));
                    exception_item.activate.connect (add_exception);
                    exception_item.sensitive = sensitive;

                    menu.append (exception_item);
                } else {
                    remove_item = new Gtk.MenuItem.with_label (_("Remove"));
                }

                remove_item.sensitive = sensitive;
                remove_item.activate.connect (remove_event);

                menu.append (remove_item);

                menu.popup_at_pointer (event);
                menu.show_all ();
            } else {
                return false;
            }

            return true;
        });

        Gtk.TargetEntry dnd = {"binary/calendar", 0, 0};
        Gtk.TargetEntry dnd2 = {"text/uri-list", 0, 0};
        Gtk.drag_source_set (event_box, Gdk.ModifierType.BUTTON1_MASK, {dnd, dnd2}, Gdk.DragAction.MOVE);

        event_box.drag_data_get.connect ( (ctx, sel, info, time) => {
            Model.CalendarModel.get_default ().drag_component = comp;
            unowned iCal.Component icalcomp = comp.get_icalcomponent ();
            unowned string ical_str = icalcomp.as_ical_string ();
            sel.set_text (ical_str, ical_str.length);
            try {
                var path = GLib.Path.build_filename (GLib.Environment.get_tmp_dir (), icalcomp.get_summary () + ".ics");
                var file = File.new_for_path (path);
                if (file.replace_contents (ical_str.data, null, false, FileCreateFlags.PRIVATE, null))
                    sel.set_uris ({file.get_uri ()});
            } catch (Error e) {
                critical (e.message);
            }
        });

        E.Source source = comp.get_data ("source");

        var cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        reload_css (cal.dup_color ());

        cal.notify["color"].connect (() => {
            reload_css (cal.dup_color ());
        });
    }

    public void update (E.CalComponent event) {
       this.comp = comp;
       label.label = get_summary ();
    }

    public string get_summary () {
        return comp.get_summary ().value;
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

    private void reload_css (string background_color) {
        var provider = new Gtk.CssProvider ();
        try {
            var colored_css = EVENT_CSS.printf (background_color);
            provider.load_from_data (colored_css, colored_css.length);

            grid_style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            critical (e.message);
        }
    }
}
