/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2013-2025 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

public Maya.Backend get_backend (Module module) {
    debug ("Activating CalDAV Backend");
    var b = new Maya.CalDavBackend ();
    b.ref ();
    return b;
}

public static Maya.Backend backend;

public class Maya.CalDavBackend : GLib.Object, Maya.Backend {

    public CalDavBackend () {
        backend = this;
    }

    public string get_name () {
        return _("CalDAV");
    }

    public string get_uid () {
        return "caldav-stub";
    }

    public Gee.Collection<PlacementWidget> get_new_calendar_widget (E.Source? to_edit = null) {
        var collection = new Gee.LinkedList<PlacementWidget> ();

        bool keep_copy = false;
        if (to_edit != null) {
            E.SourceOffline source_offline = (E.SourceOffline)to_edit.get_extension (E.SOURCE_EXTENSION_OFFLINE);
            keep_copy = source_offline.stay_synchronized;
        }

        var url_entry = new PlacementWidget () {
            column = 1,
            row = 1,
            needed = true,
            ref_name = "url_entry",
            widget = new Gtk.Entry () {
                text = "http://"
            }
        };

        var url_label = new PlacementWidget () {
            column = 0,
            row = 1,
            ref_name = "url_label",
            widget = new Gtk.Label (_("URL")) {
                hexpand = true,
                mnemonic_widget = url_entry.widget,
                xalign = 1.0f
            }
        };

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

        /*var find_button = new PlacementWidget ();
        find_button.widget = new Gtk.Button.with_label (_("Find Calendars"));
        find_button.row = 2;
        find_button.column = 1;
        find_button.ref_name = "search_button";
        collection.add (find_button);
        ((Gtk.Button)find_button.widget).clicked.connect (() => {

        };*/

        var secure_checkbutton = new PlacementWidget () {
            column = 1,
            row = 3,
            ref_name = "secure_checkbutton",
            widget = new Gtk.CheckButton.with_label (_("Use a secure connection"))
        };

        collection.add (secure_checkbutton);
        if (to_edit != null) {
            E.SourceSecurity security = (E.SourceSecurity)to_edit.get_extension (E.SOURCE_EXTENSION_SECURITY);
            ((Gtk.CheckButton)secure_checkbutton.widget).active = security.secure;
        }

        string user = "";
        if (to_edit != null) {
            E.SourceAuthentication auth = (E.SourceAuthentication)to_edit.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
            if (auth.user != null)
                user = auth.user;
        }
        collection.add_all (Maya.DefaultPlacementWidgets.get_user (4, true, user));

        string email = "";
        if (to_edit != null) {
            E.SourceWebdav webdav = (E.SourceWebdav)to_edit.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);
            if (webdav.email_address != null)
                email = webdav.email_address;
        }

        collection.add_all (Maya.DefaultPlacementWidgets.get_email (5, false, email));

        var server_checkbutton = new PlacementWidget ();
        server_checkbutton.widget = new Gtk.CheckButton.with_label (_("Server handles meeting invitations"));
        server_checkbutton.row = 6;
        server_checkbutton.column = 1;
        server_checkbutton.ref_name = "server_checkbutton";
        if (to_edit != null) {
            E.SourceWebdav webdav = (E.SourceWebdav)to_edit.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);
            ((Gtk.CheckButton)server_checkbutton.widget).active = webdav.calendar_auto_schedule;
        }

        collection.add (server_checkbutton);
        return collection;
    }

    public void add_new_calendar (string name, string color, bool set_default, Gee.Collection<PlacementWidget> widgets) {
        try {
            var new_source = new E.Source (null, null);
            new_source.display_name = name;
            new_source.parent = get_uid ();
            E.SourceCalendar cal = (E.SourceCalendar)new_source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            cal.color = color;
            cal.backend_name = "caldav";
            E.SourceWebdav webdav = (E.SourceWebdav)new_source.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);
            E.SourceAuthentication auth = (E.SourceAuthentication)new_source.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
            E.SourceOffline offline = (E.SourceOffline)new_source.get_extension (E.SOURCE_EXTENSION_OFFLINE);
            foreach (var widget in widgets) {
                switch (widget.ref_name) {
                    case "url_entry":
                        webdav.uri = GLib.Uri.parse (((Gtk.Entry)widget.widget).text, GLib.UriFlags.NONE);
                        break;
                    case "user_entry":
                        auth.user = ((Gtk.Entry)widget.widget).text;
                        break;
                    case "email_entry":
                        webdav.email_address = ((Gtk.Entry)widget.widget).text;
                        break;
                    case "server_checkbutton":
                        webdav.calendar_auto_schedule = ((Gtk.CheckButton)widget.widget).active;
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
            E.SourceAuthentication auth = (E.SourceAuthentication)source.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
            E.SourceOffline offline = (E.SourceOffline)source.get_extension (E.SOURCE_EXTENSION_OFFLINE);
            foreach (var widget in widgets) {
                switch (widget.ref_name) {
                    case "url_entry":
                        webdav.uri = GLib.Uri.parse (((Gtk.Entry)widget.widget).text, GLib.UriFlags.NONE);
                        break;
                    case "user_entry":
                        auth.user = ((Gtk.Entry)widget.widget).text;
                        break;
                    case "email_entry":
                        webdav.email_address = ((Gtk.Entry)widget.widget).text;
                        break;
                    case "server_checkbutton":
                        webdav.calendar_auto_schedule = ((Gtk.CheckButton)widget.widget).active;
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
