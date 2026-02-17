/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2026 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Jaap Broekhuizen
 */

public class Maya.View.EventEdition.LocationPanel : Gtk.Box {
    private EventDialog parent_dialog;

    private Gtk.SearchEntry location_entry;
    private Gtk.ListStore location_store;
    private Shumate.SimpleMap simple_map;
    private Shumate.Marker point;
     // Only set the geo property if map_selected is true, this is a smart behavior!
    private bool map_selected = false;
    private GLib.Cancellable search_cancellable;
    private GLib.Cancellable find_cancellable;

    public string location {
        get { return location_entry.get_text (); }
        set { location_entry.set_text (value); }
    }

    public LocationPanel (EventDialog parent_dialog) {
        this.parent_dialog = parent_dialog;

        location_store = new Gtk.ListStore (2, typeof (string), typeof (string));

        var location_completion = new Gtk.EntryCompletion () {
            minimum_key_length = 3,
            model = location_store
        };
        location_completion.set_match_func ((completion, key, iter) => {
            Value val1, val2;
            Gtk.ListStore model = (Gtk.ListStore)completion.get_model ();
            model.get_value (iter, 0, out val1);
            model.get_value (iter, 1, out val2);

            if (val1.get_string ().casefold (-1).contains (key) || val2.get_string ().casefold (-1).contains (key)) {
                return true;
            }

            return false;
        });
        location_completion.set_text_column (0);
        location_completion.set_text_column (1);
        location_completion.match_selected.connect ((model, iter) => suggestion_selected (model, iter));

        location_entry = new Gtk.SearchEntry () {
            completion = location_completion,
            hexpand = true,
            placeholder_text = _("John Smith OR Example St.")
        };
        location_entry.activate.connect (() => {
            compute_location.begin (location_entry.text);
        });

        var location_label = new Granite.HeaderLabel (_("Location:")) {
            mnemonic_widget = location_entry
        };

        simple_map = new Shumate.SimpleMap () {
            map_source = registry.get_by_id (Shumate.MAP_SOURCE_OSM_MAPNIK)
        };

        point = new Shumate.Marker () {
            child = new Gtk.Image.from_icon_name ("location-marker") {
                icon_size = LARGE
            }
        };
        point.draggable = parent_dialog.can_edit;
        point.drag_finish.connect (() => {
            map_selected = true;
            find_location.begin (point.latitude, point.longitude);
        });

        var marker_layer = new Shumate.MarkerLayer.full (simple_map.viewport, SINGLE);
        marker_layer.add_marker (point);

        var view = simple_map.viewport;
        view.zoom_level = 10;

        var map = simple_map.map;
        map.go_to_duration = 500;
        map.add_layer (marker_layer);
        map.center_on (point.latitude, point.longitude);

        load_contact.begin ();

        var frame = new Gtk.Frame (null) {
            child = champlain_embed
        };

        margin_start = 12;
        margin_end = 12;
        orientation = VERTICAL;
        spacing = 6;
        sensitive = parent_dialog.can_edit;
        append (location_label);
        append (location_entry);
        append (frame);

        // Load the location
        if (parent_dialog.ecal != null) {
            unowned ICal.Component comp = parent_dialog.ecal.get_icalcomponent ();
            unowned string location = comp.get_location ();

            if (location != null) {
                location_entry.text = location.dup ();
            }

            ICal.Geo? geo;
            geo = parent_dialog.ecal.get_geo ();

            bool need_relocation = true;
            if (geo != null) {
                var latitude = geo.get_lat ();
                var longitude = geo.get_lon ();
                if (latitude >= Shumate.MIN_LATITUDE && longitude >= Shumate.MIN_LONGITUDE &&
                    latitude <= Shumate.MAX_LATITUDE && longitude <= Shumate.MAX_LONGITUDE) {
                    need_relocation = false;
                    point.latitude = latitude;
                    point.longitude = longitude;
                    if (latitude == 0 && longitude == 0)
                        need_relocation = true;
                }
            }

            if (need_relocation == true) {
                if (location != null && location != "") {
                    compute_location.begin (location_entry.text);
                } else {
                    // Use geoclue to find approximate location
                    discover_location.begin ();
                }
            }
        }

        location_entry.grab_focus ();
    }

    ~LocationPanel () {
        if (search_cancellable != null) {
            search_cancellable.cancel ();
        }

        if (find_cancellable != null) {
            find_cancellable.cancel ();
        }
    }

    /**
     * Save the values in the dialog into the component.
     */
    public void save () {
        // Save the location
        unowned ICal.Component comp = parent_dialog.ecal.get_icalcomponent ();
        string location = location_entry.text;

        comp.set_location (location);
        if (map_selected == true) {
            // First, clear the geo
            int count = comp.count_properties (ICal.PropertyKind.GEO_PROPERTY);

            for (int i = 0; i < count; i++) {
                ICal.Property remove_prop;
                remove_prop = comp.get_first_property (ICal.PropertyKind.GEO_PROPERTY);
                comp.remove_property (remove_prop);
            }

            // Add the comment
            var property = new ICal.Property (ICal.PropertyKind.GEO_PROPERTY);
            var geo = new ICal.Geo (point.latitude, point.longitude);
            property.set_geo (geo);
            comp.add_property (property);
        }
    }

    private async void compute_location (string loc) {
        if (search_cancellable != null)
            search_cancellable.cancel ();
        search_cancellable = new GLib.Cancellable ();
        var forward = new Geocode.Forward.for_string (loc);
        try {
            forward.set_answer_count (1);
            var places = yield forward.search_async (search_cancellable);
            foreach (var place in places) {
                point.latitude = place.location.latitude;
                point.longitude = place.location.longitude;
                Idle.add (() => {
                    if (search_cancellable.is_cancelled () == false)
                        champlain_embed.champlain_view.go_to (point.latitude, point.longitude);
                    return false;
                });
            }

            if (loc == location_entry.text)
                map_selected = true;

            location_entry.has_focus = true;
        } catch (Error error) {
            debug (error.message);
        }
    }

    private async void find_location (double latitude, double longitude) {
        if (find_cancellable != null) {
            find_cancellable.cancel ();
        }

        find_cancellable = new GLib.Cancellable ();
        Geocode.Location location = new Geocode.Location (latitude, longitude);
        var reverse = new Geocode.Reverse.for_location (location);

        try {
            var address = yield reverse.resolve_async (find_cancellable);
            var builder = new StringBuilder ();
            if (address.street != null) {
                builder.append (address.street);
                add_address_line (builder, address.town);
                add_address_line (builder, address.county);
                add_address_line (builder, address.postal_code);
                add_address_line (builder, address.country);
            } else {
                builder.append (address.name);
                add_address_line (builder, address.country);
            }

            location_entry.text = builder.str;
        } catch (Error error) {
            debug (error.message);
        }
    }

    private async void discover_location () {
        if (search_cancellable != null) {
            search_cancellable.cancel ();
        }

        search_cancellable = new GLib.Cancellable ();
        try {
            var simple = yield new GClue.Simple ("io.elementary.calendar", GClue.AccuracyLevel.CITY, null);

            point.latitude = simple.location.latitude;
            point.longitude = simple.location.longitude;
            Idle.add (() => {
                if (search_cancellable.is_cancelled () == false)
                    champlain_embed.champlain_view.go_to (point.latitude, point.longitude);
                return false;
            });

        } catch (Error e) {
            /* Do NOT attempt a fallback. User intent is that they not be located.
             * Attempting to locate anyway is perceived as a breach of consent
             * https://github.com/elementary/calendar/issues/540
             */
            warning ("Failed to connect to GeoClue2 service: %s", e.message);
            return;
        }
    }

    private void add_address_line (StringBuilder sb, string? text) {
        if (text != null) {
             sb.append (", ");
             sb.append (text);
        }
    }

    /**
     * Filter all contacts with address information and
     * add them to the location store.
     */
    private async void add_contacts_store (Gee.Map<string, Folks.Individual> contacts) {
        Gtk.TreeIter contact;
        var map_iterator = contacts.map_iterator ();
        while (map_iterator.next ()) {
            foreach (var address in map_iterator.get_value ().postal_addresses) {
                location_store.append (out contact);
                location_store.set (contact, 0, map_iterator.get_value ().full_name, 1, address.value.street);
            }
        }
    }

    /**
     * Load the backend and call add_contacts_store with all
     * contacts.
     */
    private async void load_contact () {
        var aggregator = Folks.IndividualAggregator.dup ();

        if (aggregator.is_prepared) {
            add_contacts_store.begin (aggregator.individuals);
        } else {
            aggregator.notify["is-quiescent"].connect (() => {
                add_contacts_store.begin (aggregator.individuals);
            });

            aggregator.prepare.begin ();
        }
    }

    private bool suggestion_selected (Gtk.TreeModel model, Gtk.TreeIter iter) {
        Value address;
        model.get_value (iter, 1, out address);
        location_entry.set_text (address.get_string ());
        compute_location.begin (address.get_string ());
        return true;
    }
}
