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

public class Maya.Model.CalendarModel : Object {

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
    public E.SourceRegistry registry { get; private set; }

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

    public signal void connecting (E.Source source, Cancellable cancellable);
    public signal void connected (E.Source source);
    public signal void error_received (string error);

    /* The month_start, num_weeks, or week_starts_on have been changed */
    public signal void parameters_changed ();

    HashTable<string, E.CalClient> source_client;
    HashTable<string, E.CalClientView> source_view;
    HashTable<E.Source, Gee.Map<string, E.CalComponent>> source_events;

    public GLib.Queue<E.Source> calendar_trash;

    private static Maya.Model.CalendarModel? calendar_model = null;

    public static CalendarModel get_default () {
        if (calendar_model == null)
            calendar_model = new CalendarModel ();
        return calendar_model;
    }

    private CalendarModel () {
        // It's dirty, but there is no other way to get it for the moment.
        string output;
        int week_start = 2;
        try {
            GLib.Process.spawn_command_line_sync ("locale first_weekday", out output, null, null);
            week_start = int.parse (output);
        } catch (SpawnError e) {
            critical (e.message);
        }

        switch (week_start) {
        case 1:
            week_starts_on = Maya.Settings.Weekday.SUNDAY;
            break;
        case 2:
            week_starts_on = Maya.Settings.Weekday.MONDAY;
            break;
        case 3:
            week_starts_on = Maya.Settings.Weekday.TUESDAY;
            break;
        case 4:
            week_starts_on = Maya.Settings.Weekday.WEDNESDAY;
            break;
        case 5:
            week_starts_on = Maya.Settings.Weekday.THURSDAY;
            break;
        case 6:
            week_starts_on = Maya.Settings.Weekday.FRIDAY;
            break;
        case 7:
            week_starts_on = Maya.Settings.Weekday.SATURDAY;
            break;
        default:
            week_starts_on = Maya.Settings.Weekday.MONDAY;
            message ("Locale has a bad first_weekday value");
            break;
        }

        this.month_start = Util.get_start_of_month (Settings.SavedState.get_default ().get_page ());
        compute_ranges ();

        source_client = new HashTable<string, E.CalClient> (str_hash, str_equal);
        source_events = new HashTable<E.Source, Gee.Map<string, E.CalComponent>> (Util.source_hash_func, Util.source_equal_func);
        source_view = new HashTable<string, E.CalClientView> (str_hash, str_equal);
        calendar_trash = new GLib.Queue<E.Source> ();

        notify["month-start"].connect (on_parameter_changed);
        try {
            registry = new E.SourceRegistry.sync (null);
            registry.source_removed.connect (remove_source);
            registry.source_changed.connect (on_source_changed);

            // Add sources
            foreach (var source in registry.list_sources (E.SOURCE_EXTENSION_CALENDAR)) {
                E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
                if (cal.selected == true && source.enabled == true) {
                    add_source (source);
                }
            }
        } catch (GLib.Error error) {
            critical (error.message);
        }
    }

    //--- Public Methods ---//

    public void add_event (E.Source source, E.CalComponent event) {
        add_event_async.begin (source, event);
    }

    private async void add_event_async (E.Source source, E.CalComponent event) {
        SourceFunc callback = add_event_async.callback;
        Threads.add (() => {
            unowned iCal.Component comp = event.get_icalcomponent();
            debug (@"Adding event '$(comp.get_uid())'");
            E.CalClient client;
            lock (source_client) {
                client = source_client.get (source.dup_uid ());
            }

            if (client != null) {
                try {
                    client = new E.CalClient.connect_sync (source, E.CalClientSourceType.EVENTS);
                    client.create_object.begin (comp, null, (obj, results) => {
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
        unowned iCal.Component comp = event.get_icalcomponent();
        debug (@"Updating event '$(comp.get_uid())' [mod_type=$(mod_type)]");

        E.CalClient client;
        lock (source_client) {
            client = source_client.get (source.dup_uid ());
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
        unowned iCal.Component comp = event.get_icalcomponent();
        string uid = comp.get_uid ();
        string? rid = event.has_recurrences() ? null : event.get_recurid_as_string();
        debug (@"Removing event '$uid'");
        E.CalClient client;
        lock (source_client) {
            client = source_client.get (source.dup_uid ());
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

    public void trash_calendar (E.Source source) {
        calendar_trash.push_tail (source);
        remove_source (source);
    }

    public void restore_calendar () {
        if (calendar_trash.is_empty ())
            return;

        var source = calendar_trash.pop_tail ();
        add_source (source);
    }

    public void delete_trashed_calendars () {
        E.Source source = calendar_trash.pop_tail ();
        while (source != null) {
            source.remove.begin (null);
            source = calendar_trash.pop_tail ();
        }
    }

    public void change_month (int relative) {
        month_start = month_start.add_months (relative);
    }

    public void change_year (int relative) {
        month_start = month_start.add_years (relative);
    }

    public void load_all_sources () {
        lock (source_client) {
            foreach (var id in source_client.get_keys ()) {
                var source = registry.ref_source (id);
                E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
                if (cal.selected == true && source.enabled == true) {
                    load_source (source);
                }
            }
        }
    }

    public void add_source (E.Source source) {
        add_source_async.begin (source);
    }

    public void remove_source (E.Source source) {
        debug ("Removing source '%s'", source.dup_display_name());
        // Already out of the model, so do nothing
        var uid = source.dup_uid ();
        if (!source_view.contains (uid))
            return;

        var current_view = source_view.get (uid);
        try {
            current_view.stop ();
        } catch (Error e) {
            warning (e.message);
        }

        source_view.remove (uid);
        lock (source_client) {
            source_client.remove (uid);
        }

        var events = source_events.get (source).values.read_only_view;
        events_removed (source, events);
        source_events.remove (source);
    }

    //--- Helper Methods ---//

    private void compute_ranges () {
        Settings.SavedState.get_default ().month_page = month_start.format ("%Y-%m");
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

    private void load_source (E.Source source) {
        // create empty source-event map
        Gee.Map<string, E.CalComponent> events = new Gee.HashMap<string, E.CalComponent> (
            (Gee.HashDataFunc<string>?) Util.string_hash_func,
            (Gee.EqualDataFunc<E.CalComponent>?) Util.string_equal_func,
            (Gee.EqualDataFunc<E.CalComponent>?) Util.calcomponent_equal_func);
        source_events.set (source, events);
        // query client view
        var iso_first = E.isodate_from_time_t((ulong) data_range.first.to_unix());
        var iso_last = E.isodate_from_time_t((ulong) data_range.last.add_days(1).to_unix());
        var query = @"(occur-in-time-range? (make-time \"$iso_first\") (make-time \"$iso_last\"))";

        E.CalClient client;
        lock (source_client) {
            client = source_client.get (source.dup_uid ());
        }

        if (client == null)
            return;

        debug ("Getting client-view for source '%s'", source.dup_display_name ());
        client.get_view.begin (query, null, (obj, results) => {
            var view = on_client_view_received (results, source, client);
            view.objects_added.connect ((objects) => on_objects_added (source, client, objects));
            view.objects_removed.connect ((objects) => on_objects_removed (source, client, objects));
            view.objects_modified.connect ((objects) => on_objects_modified (source, client, objects));
            try {
                view.start ();
            } catch (Error e) {
                critical (e.message);
            }

            source_view.set (source.dup_uid (), view);
        });
    }

    private async void add_source_async (E.Source source) {
        Threads.add (() => {
            debug ("Adding source '%s'", source.dup_display_name ());
            try {
                var cancellable = new GLib.Cancellable ();
                connecting (source, cancellable);
                var client = new E.CalClient.connect_sync (source, E.CalClientSourceType.EVENTS, cancellable);
                source_client.insert (source.dup_uid (), client);
            } catch (Error e) {
                error_received (e.message);
            }

            Idle.add (() => {
                connected (source);
                load_source (source);
                return false;
            });
        });

        yield;
    }

    private void debug_event (E.Source source, E.CalComponent event) {
        unowned iCal.Component comp = event.get_icalcomponent ();
        debug (@"Event ['$(comp.get_summary())', $(source.dup_display_name()), $(comp.get_uid()))]");
    }

    //--- Signal Handlers ---//
    private void on_parameter_changed () {
        compute_ranges ();
        parameters_changed ();
        load_all_sources ();
    }

    private void on_source_changed (E.Source source) {
        
    }

    private E.CalClientView on_client_view_received (AsyncResult results, E.Source source, E.CalClient client) {
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

    private void on_objects_added (E.Source source, E.CalClient client, SList<weak iCal.Component> objects) {
        debug (@"Received $(objects.length()) added event(s) for source '%s'", source.dup_display_name());
        Gee.Map<string, E.CalComponent> events = source_events.get (source);
        var added_events = new Gee.ArrayList<E.CalComponent> ((Gee.EqualDataFunc<E.CalComponent>?) Util.calcomponent_equal_func);
        foreach (var comp in objects) {
            var event = new E.CalComponent ();
            iCal.Component comp_clone = new iCal.Component.clone (comp);
            event.set_icalcomponent ((owned) comp_clone);
            debug_event (source, event);
            string uid = comp.get_uid();
            events.set (uid, event);
            added_events.add (event);
        };

        events_added (source, added_events.read_only_view);
    }

    private void on_objects_modified (E.Source source, E.CalClient client, SList<weak iCal.Component> objects) {
        debug (@"Received $(objects.length()) modified event(s) for source '%s'", source.dup_display_name ());
        var updated_events = new Gee.ArrayList<E.CalComponent> ((Gee.EqualDataFunc<E.CalComponent>?) Util.calcomponent_equal_func);
        foreach (weak iCal.Component comp in objects) {
            string uid = comp.get_uid ();
            E.CalComponent event = source_events.get (source).get (uid);
            event.set_icalcomponent (new iCal.Component.clone (comp));
            updated_events.add (event);
            debug_event (source, event);
        };

        events_updated (source, updated_events.read_only_view);
    }

    private void on_objects_removed (E.Source source, E.CalClient client, SList<weak E.CalComponentId?> cids) {
        debug (@"Received $(cids.length()) removed event(s) for source '%s'", source.dup_display_name ());
        var events = source_events.get (source);
        var removed_events = new Gee.ArrayList<E.CalComponent> ((Gee.EqualDataFunc<E.CalComponent>?) Util.calcomponent_equal_func);
        foreach (unowned E.CalComponentId? cid in cids) {
            assert (cid != null);
            E.CalComponent event = events.get (cid.uid);
            removed_events.add (event);
            debug_event (source, event);
        }

        events_removed (source, removed_events.read_only_view);
    }
}