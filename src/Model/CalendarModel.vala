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

namespace Maya.Model {

public class CalendarModel : Object {

    /* The data_range is the range of dates for which this model is storing
     * data. The month_range is a subset of this range corresponding to the
     * calendar month that is being focused on. In summary:
     *
     * data_range.first <= month_range.first < month_range.last <= data_range.last
     *
     * There is no way to set the ranges publicly. They can only be modified by
     * changing one of the following properties: month_start, num_weeks, and
     * week_starts_on.
    */
    public Util.DateRange data_range { get; private set; }
    public Util.DateRange month_range { get; private set; }

    /* The first day of the month */
    public DateTime month_start { get; set; }

    /* The number of weeks to show in this model */
    public int num_weeks { get; private set; default = 6; }

    /* The start of week, ie. Monday=1 or Sunday=7 */
    public Settings.Weekday week_starts_on { get; set; }

    /* Notifies when events are added, updated, or removed */
    public signal void events_added (E.Source source, Gee.Collection<E.CalComponent> events);
    public signal void events_updated (E.Source source, Gee.Collection<E.CalComponent> events);
    public signal void events_removed (E.Source source, Gee.Collection<E.CalComponent> events);

    /* The month_start, num_weeks, or week_starts_on have been changed */
    public signal void parameters_changed ();

    Gee.Map<E.Source, E.CalClient> source_client;
    Gee.Map<E.Source, E.CalClientView> source_view;
    Gee.Map<E.Source, Gee.Map<string, E.CalComponent>> source_events;
    
    public Gee.LinkedList<E.Source> calendar_trash;

    public CalendarModel (Settings.Weekday week_starts_on) {

        this.month_start = Util.get_start_of_month ();
        this.week_starts_on = week_starts_on;

        compute_ranges ();

        source_client = new Gee.HashMap<E.Source, E.CalClient> (
            (HashFunc) Util.source_hash_func,
            (EqualFunc) Util.source_equal_func,
            null);

        source_events = new Gee.HashMap<E.Source, Gee.Map<string, E.CalComponent>> (
            (HashFunc) Util.source_hash_func,
            (EqualFunc) Util.source_equal_func,
            null);

        source_view = new Gee.HashMap<E.Source, E.CalClientView> (
            (HashFunc) Util.source_hash_func,
            (EqualFunc) Util.source_equal_func,
            null);

        calendar_trash = new Gee.LinkedList<E.Source> ();

        notify["month-start"].connect (on_parameter_changed);
        setup_sources_async.begin ();
    }
    
    public async void setup_sources_async () {
        SourceFunc callback = setup_sources_async.callback;
        Threads.add (() => {
            try {
                var registry = new E.SourceRegistry.sync (null);
                registry.source_disabled.connect (on_source_disabled);
                registry.source_enabled.connect (on_source_enabled);
                registry.source_added.connect (on_source_added);
                registry.source_removed.connect (on_source_removed);
                registry.source_changed.connect (on_source_changed);

                // Add sources
                
                foreach (var source in registry.list_sources(E.SOURCE_EXTENSION_CALENDAR)) {
                    
                    E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
                    if (cal.selected == true) {
                        add_source (source);
                    }
                }
            } catch (GLib.Error error) {
                critical (error.message);
            }
            
            Idle.add ((owned) callback);
        });

        yield;
    }

    //--- Public Methods ---//

    public void add_event (E.Source source, E.CalComponent event) {

        add_event_async.begin (source, event);

    }
    
    private async void add_event_async (E.Source source, E.CalComponent event) {
        SourceFunc callback = add_event_async.callback;
        Threads.add (() => {
            unowned iCal.icalcomponent comp = event.get_icalcomponent();

            debug (@"Adding event '$(comp.get_uid())'");

            E.CalClient client = null;
            lock (source_client) {
                foreach (var entry in source_client.entries) {
                    if (source.uid == ((E.Source)entry.key).uid) {
                        client = entry.value;
                        break;
                    }
                }
            }
            
            if (client != null) {
                try {
                    client = new E.CalClient.connect_sync (source, E.CalClientSourceType.EVENTS);

                    client.create_object.begin (comp, null, (obj, results) =>  {

                        bool status = false;
                        string uid;

                        try {
                            status = client.create_object.end (results, out uid);
                        } catch (Error e) {
                            warning (e.message);
                        }
                    });
                } catch (GLib.Error error) {
                    critical (error.message);
                }
            } else {
                critical ("No calendar was found, event not added");
            }
            
            Idle.add ((owned) callback);
        });

        yield;

    }

    public void update_event (E.Source source, E.CalComponent event, E.CalObjModType mod_type) {

        unowned iCal.icalcomponent comp = event.get_icalcomponent();

        debug (@"Updating event '$(comp.get_uid())' [mod_type=$(mod_type)]");

        E.CalClient client = null;
        lock (source_client) {
            foreach (var entry in source_client.entries) {
                if (source.uid == ((E.Source)entry.key).uid) {
                    client = entry.value;
                    break;
                }
            }
        }
        client.modify_object.begin (comp, mod_type, null, (obj, results) =>  {

            bool status = false;

            try {
                status = client.modify_object.end (results);
            } catch (Error e) {
                warning (e.message);
            }
        });
    }

    public void remove_event (E.Source source, E.CalComponent event, E.CalObjModType mod_type) {

        unowned iCal.icalcomponent comp = event.get_icalcomponent();

        string uid = comp.get_uid ();
        string? rid = event.has_recurrences() ? null : event.get_recurid_as_string();

        debug (@"Removing event '$uid'");
        
        E.CalClient client = null;
        lock (source_client) {
            foreach (var entry in source_client.entries) {
                if (source.uid == ((E.Source)entry.key).uid) {
                    client = entry.value;
                    break;
                }
            }
        }
        client.remove_object.begin (uid, rid, mod_type, null, (obj, results) =>  {

            bool status = false;

            try {
                status = client.remove_object.end (results);
            } catch (Error e) {
                warning (e.message);
            }
        });
    }

    //--- Helper Methods ---//

    void compute_ranges () {

        var month_end = month_start.add_full (0, 1, -1);
        month_range = new Util.DateRange (month_start, month_end);

        int dow = month_start.get_day_of_week();
        int wso = (int) week_starts_on;
        int offset = 0;

        if (wso < dow)
            offset = dow - wso;
        else if (wso > dow)
            offset = 7 + dow - wso;

        var data_range_first = month_start.add_days (-offset);

        dow = month_end.get_day_of_week();
        wso = (int) (week_starts_on + 6);

        // WSO must be between 1 and 7
        if (wso > 7)
            wso = wso - 7;

        offset = 0;

        if (wso < dow)
            offset = 7 + wso - dow;
        else if (wso > dow)
            offset = wso - dow;

        var data_range_last = month_end.add_days(offset);

        data_range = new Util.DateRange (data_range_first, data_range_last);
        num_weeks = data_range.to_list ().size / 7;

        debug(@"Date ranges: ($data_range_first <= $month_start < $month_end <= $data_range_last)");
    }

    public void load_all_sources () {
        
        lock (source_client) {
            foreach (var source in source_client.keys) {
                load_source (source);
            }
        }
    }

    void load_source (E.Source source) {

        // create empty source-event map

        Gee.Map<string, E.CalComponent> events = new Gee.HashMap<string, E.CalComponent> (
            (HashFunc) Util.string_hash_func,
            (EqualFunc) Util.string_equal_func,
            (EqualFunc) Util.calcomponent_equal_func);

        source_events.set (source, events);

        // query client view

        var iso_first = E.isodate_from_time_t((ulong) data_range.first.to_unix());
        var iso_last = E.isodate_from_time_t((ulong) data_range.last.add_days(1).to_unix());

        var query = @"(occur-in-time-range? (make-time \"$iso_first\") (make-time \"$iso_last\"))";

        E.CalClient client = null;
        lock (source_client) {
            foreach (var entry in source_client.entries) {
                if (source.uid == ((E.Source)entry.key).uid) {
                    client = entry.value;
                    break;
                }
            }
        }

        debug("Getting client-view for source '%s'", source.dup_display_name ());

        client.get_view.begin (query, null, (obj, results) => {

            var view = on_client_view_received (results, source, client);

            view.objects_added.connect ((objects) => on_objects_added (source, client, objects));
            view.objects_removed.connect ((objects) => on_objects_removed (source, client, objects));
            view.objects_modified.connect ((objects) => on_objects_modified (source, client, objects));

            try {
                view.start ();
            } catch (Error e) {
                warning (e.message);
            }

            source_view.set (source, view);
        });
    }

    public void add_source (E.Source source) {

        add_source_async.begin (source);
    }
    
    private async void add_source_async (E.Source source) {
        Threads.add (() => {
            debug("Adding source '%s'", source.dup_display_name());
            try {
                var client = new E.CalClient.connect_sync (source, E.CalClientSourceType.EVENTS);
                lock (source_client) {
                    source_client.set (source, client);
                }
            } catch (Error e) {
                warning (e.message);
            }
            
            Idle.add( () => {
                load_source (source);
                return false;
            });
        });

        yield;
    }

    public void remove_source (E.Source source) {

        // Already out of the model, so do nothing
        if (!source_view.has_key (source))
            return;

        var current_view = source_view.get (source);

        try {
            current_view.stop();
        } catch (Error e) {
            warning (e.message);
        }
        source_view.unset (source);

        E.CalClient client = null;
        lock (source_client) {
        foreach (var entry in source_client.entries) {
            if (source.uid == ((E.Source)entry.key).uid) {
                client = entry.value;
                break;
            }
        }
        source_client.unset (source);
        }

        var events = source_events.get (source).values.read_only_view;
        events_removed (source, events);
        source_events.unset (source);

    }

    void debug_event (E.Source source, E.CalComponent event) {

        unowned iCal.icalcomponent comp = event.get_icalcomponent ();
        debug (@"Event ['$(comp.get_summary())', $(source.dup_display_name()), $(comp.get_uid()))]");
    }

    //--- Signal Handlers ---//

    void on_parameter_changed () {

        compute_ranges ();
        parameters_changed ();

        load_all_sources ();
    }

    /*void on_event_added (AsyncResult results, E.Source source, E.CalClient client) {

        try {

            string uid;
            bool status = client.create_object.end (results, out uid);
            assert (status==true);

            warning ("Created new event '%s' in source '%s'", uid, source.peek_name());

        } catch (Error e) {

            warning ("Error adding new event to source '%s': %s", source.peek_name(), e.message);
        }

    }*/

    void on_source_enabled (E.Source source) {
        
        add_source (source);
    }

    void on_source_disabled (E.Source source) {
        
        remove_source (source);
    }

    void on_source_added (E.Source source) {
        
        add_source (source);
    }

    void on_source_removed (E.Source source) {
        
        remove_source (source);
    }

    void on_source_changed (E.Source source) {
        
    }

    E.CalClientView on_client_view_received (AsyncResult results, E.Source source, E.CalClient client) {

        E.CalClientView view;

        try {

            debug (@"Received client-view for source '%s'", source.dup_display_name());

            bool status = client.get_view.end (results, out view);
            assert (status==true);

        } catch (Error e) {

            critical ("Error loading client-view from source '%s': %s", source.dup_display_name(), e.message);
        }

        return view;
    }

    void on_objects_added (E.Source source, E.CalClient client, SList<weak iCal.icalcomponent> objects) {

        debug (@"Received $(objects.length()) added event(s) for source '%s'", source.dup_display_name());

        Gee.Map<string, E.CalComponent> events = source_events.get (source);

        Gee.ArrayList<E.CalComponent> added_events = new Gee.ArrayList<E.CalComponent> (
            (EqualFunc) Util.calcomponent_equal_func);

        foreach (var comp in objects) {

            var event = new E.CalComponent ();
            iCal.icalcomponent comp_clone = new iCal.icalcomponent.clone (comp);
            event.set_icalcomponent ((owned) comp_clone);

            debug_event (source, event);

            string uid = comp.get_uid();

            events.set (uid, event);
            added_events.add (event);
        };

        events_added (source, added_events.read_only_view);
    }

    void on_objects_modified (E.Source source, E.CalClient client, SList<weak iCal.icalcomponent> objects) {

        debug (@"Received $(objects.length()) modified event(s) for source '%s'", source.dup_display_name ());

        Gee.Collection<E.CalComponent> updated_events = new Gee.ArrayList<E.CalComponent> (
            (EqualFunc) Util.calcomponent_equal_func);

        foreach (var comp in objects) {

            string uid = comp.get_uid();

            E.CalComponent event = source_events.get (source).get(uid);
            updated_events.add (event);

            debug_event (source, event);
        };

        events_updated (source, updated_events.read_only_view);
    }

    void on_objects_removed (E.Source source, E.CalClient client, SList<weak E.CalComponentId?> cids) {

        debug (@"Received $(cids.length()) removed event(s) for source '%s'", source.dup_display_name ());

        var events = source_events.get (source);
        Gee.Collection<E.CalComponent> removed_events = new Gee.ArrayList<E.CalComponent> (
            (EqualFunc) Util.calcomponent_equal_func);

        foreach (unowned E.CalComponentId? cid in cids) {

            assert (cid != null);

            E.CalComponent event = events.get (cid.uid);
            removed_events.add (event);

            debug_event (source, event);
        }
        events_removed (source, removed_events.read_only_view);
    }
    
    public void delete_calendar (E.Source source) {
        calendar_trash.add (source);
        remove_source (source);
    }
    
    public void restore_calendar () {
        if (calendar_trash.is_empty)
            return;
        var source = calendar_trash.poll_tail ();
        add_source (source);
    }
    
    public void do_real_deletion () {
        foreach (var source in calendar_trash) {
            try {
                source.remove.begin (null);
            } catch (Error error) {
                critical (error.message);
            }
        }
    }
}

}
