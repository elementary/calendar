// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
 * Copyright 2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.0
 */

public Maya.Backend get_backend (Module module) {
    debug ("Activating Web Backend");
    var b = new Maya.WebBackend ();
    b.ref ();
    return b;
}

private static Maya.Backend backend;

public class Maya.WebBackend : GLib.Object, Maya.Backend {

    public WebBackend () {
        backend = this;
    }

    public string get_name () {
        return _("On the web");
    }

    public string get_uid () {
        return "webcal-stub";
    }

    public Gee.Collection<PlacementWidget> get_new_calendar_widget (E.Source? to_edit = null) {
        var collection = new Gee.LinkedList<PlacementWidget> ();

        bool keep_copy = false;
        if (to_edit != null) {
            E.SourceOffline source_offline = (E.SourceOffline)to_edit.get_extension (E.SOURCE_EXTENSION_OFFLINE);
            keep_copy = source_offline.stay_synchronized;
        }

        var url_entry = new PlacementWidget ();
        url_entry.widget = new Gtk.Entry () {
            placeholder_text = "https://example.com"
        };
        url_entry.ref_name = "url_entry";
        url_entry.needed = true;

        var url_label = new PlacementWidget ();
        url_label.widget = new Granite.HeaderLabel (_("URL")) {
            mnemonic_widget = url_entry.widget
        };
        url_label.ref_name = "url_label";

        collection.add (Maya.DefaultPlacementWidgets.get_keep_copy (0, keep_copy));
        collection.add (url_label);
        collection.add (url_entry);
        if (to_edit != null) {
            E.SourceWebdav webdav = (E.SourceWebdav)to_edit.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);
            var uri = webdav.dup_uri ();
            if (uri.get_port () != 80) {
                ((Gtk.Entry)url_entry.widget).text = "%s://%s:%u%s".printf (uri.get_scheme (), uri.get_host (), uri.get_port (), uri.get_path ());
            } else {
                ((Gtk.Entry)url_entry.widget).text = "%s://%s%s".printf (uri.get_scheme (), uri.get_host (), uri.get_path ());
            }
        }

        return collection;
    }

    public void add_new_calendar (string name, string color, bool set_default, Gee.Collection<PlacementWidget> widgets) {
        try {
            var new_source = new E.Source (null, null) {
                display_name = name
            };
            new_source.parent = get_uid ();
            E.SourceCalendar cal = (E.SourceCalendar)new_source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            cal.color = color;
            cal.backend_name = "webcal";
            E.SourceWebdav webdav = (E.SourceWebdav)new_source.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);
            // This creates the extension which we need, but we don't need to do anything with it
            new_source.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
            E.SourceOffline offline = (E.SourceOffline)new_source.get_extension (E.SOURCE_EXTENSION_OFFLINE);
            foreach (var widget in widgets) {
                switch (widget.ref_name) {
                    case "url_entry":
                        webdav.uri = GLib.Uri.parse (((Gtk.Entry)widget.widget).text, GLib.UriFlags.NONE);
                        break;
                    case "keep_copy":
                        offline.set_stay_synchronized (((Gtk.CheckButton)widget.widget).active);
                        break;
                }
            }

            var calmodel = Calendar.EventStore.get_default ();
            var registry = calmodel.registry;
            var list = new List<E.Source> ();
            list.append (new_source);
            registry.create_sources_sync (list);
            calmodel.add_source (new_source);
            if (set_default) {
                registry.default_calendar = new_source;
            }

        } catch (GLib.Error error) {
            critical (error.message);
        }
    }

    public void modify_calendar (string name, string color, bool set_default, Gee.Collection<PlacementWidget> widgets, E.Source source) {
        try {
            source.display_name = name;
            E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            cal.color = color;
            E.SourceWebdav webdav = (E.SourceWebdav)source.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);
            // This creates the extension which we need, but we don't need to do anything with it
            source.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
            E.SourceOffline offline = (E.SourceOffline)source.get_extension (E.SOURCE_EXTENSION_OFFLINE);
            foreach (var widget in widgets) {
                switch (widget.ref_name) {
                    case "url_entry":
                        webdav.uri = GLib.Uri.parse (((Gtk.Entry)widget.widget).text, GLib.UriFlags.NONE);
                        break;
                    case "keep_copy":
                        offline.set_stay_synchronized (((Gtk.CheckButton)widget.widget).active);
                        break;
                }
            }

            source.write.begin (null);
            if (set_default) {
                var registry = new E.SourceRegistry.sync (null);
                registry.default_calendar = source;
            }

        } catch (GLib.Error error) {
            critical (error.message);
        }
    }
}
