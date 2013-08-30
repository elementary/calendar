// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013 Maya Developers (http://launchpad.net/maya)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

public class Maya.CalDavBackend : GLib.Object, Maya.Backend {
    
    public string get_name () {
        return _("CalDAV");
    }
    
    public string get_uid () {
        return "caldav-stub";
    }
    
    public Gee.Collection<PlacementWidget> get_new_calendar_widget (E.Source? to_edit = null) {
        var collection = new Gee.LinkedList<PlacementWidget> ();
        
        var url_label = new PlacementWidget ();
        url_label.widget = new Gtk.Label (_("URL:"));
        ((Gtk.Label) url_label.widget).expand = true;
        ((Gtk.Label) url_label.widget).xalign = 1;
        url_label.row = 0;
        url_label.column = 0;
        url_label.ref_name = "url_label";
        collection.add (url_label);
        
        var url_entry = new PlacementWidget ();
        url_entry.widget = new Gtk.Entry ();
        url_entry.row = 0;
        url_entry.column = 1;
        url_entry.ref_name = "url_entry";
        collection.add (url_entry);
        
        var secure_checkbutton = new PlacementWidget ();
        secure_checkbutton.widget = new Gtk.CheckButton.with_label (_("Use a secure connection"));
        secure_checkbutton.row = 1;
        secure_checkbutton.column = 1;
        secure_checkbutton.ref_name = "secure_checkbutton";
        collection.add (secure_checkbutton);
        
        var user_label = new PlacementWidget ();
        user_label.widget = new Gtk.Label (_("User:"));
        ((Gtk.Label) user_label.widget).xalign = 1;
        user_label.row = 3;
        user_label.column = 0;
        user_label.ref_name = "user_label";
        collection.add (user_label);
        
        var user_entry = new PlacementWidget ();
        user_entry.widget = new Gtk.Entry ();
        user_entry.row = 3;
        user_entry.column = 1;
        user_entry.ref_name = "user_entry";
        collection.add (user_entry);
        
        var email_label = new PlacementWidget ();
        email_label.widget = new Gtk.Label (_("Email:"));
        ((Gtk.Label) email_label.widget).xalign = 1;
        email_label.row = 5;
        email_label.column = 0;
        email_label.ref_name = "email_label";
        collection.add (email_label);
        
        var email_entry = new PlacementWidget ();
        email_entry.widget = new Gtk.Entry ();
        email_entry.row = 5;
        email_entry.column = 1;
        email_entry.ref_name = "email_entry";
        collection.add (email_entry);
        
        var server_checkbutton = new PlacementWidget ();
        server_checkbutton.widget = new Gtk.CheckButton.with_label (_("Server handles meeting invitations"));
        server_checkbutton.row = 6;
        server_checkbutton.column = 1;
        server_checkbutton.ref_name = "server_checkbutton";
        collection.add (server_checkbutton);
        
        return collection;
    }
    public void add_new_calendar (string name, string color, Gee.Collection<PlacementWidget> widgets) {
        var new_source = new E.Source (null, null);
        new_source.display_name = name;
        new_source.parent = get_uid ();
        E.SourceCalendar cal = (E.SourceCalendar)new_source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
        cal.color = color;
        cal.backend_name = "caldav";
        E.SourceWebdav webdav = (E.SourceWebdav)new_source.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);
        E.SourceAuthentication auth = (E.SourceAuthentication)new_source.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
        
        foreach (var widget in widgets) {
            switch (widget.ref_name) {
                case "url_entry":
                    webdav.soup_uri = new Soup.URI (((Gtk.Entry)widget.widget).text);
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
            }
        }
        var registry = new E.SourceRegistry.sync (null);
        registry.commit_source_sync (new_source);
    }
}
