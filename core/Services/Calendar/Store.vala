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

public class Calendar.Store : Object {

    /* The data_range is the range of dates for which this model is storing
     * data. The month_range is a subset of this range corresponding to the
     * calendar month that is being focused on. In summary:
     *
     * data_range.first_dt <= month_range.first_dt < month_range.last_dt <= data_range.last_dt
     *
     * There is no way to set the ranges publicly. They can only be modified by
     * changing one of the following properties: month_start, num_weeks, and
     * week_starts_on.
    */
    public Calendar.Util.DateRange data_range { get; private set; }
    public Calendar.Util.DateRange month_range { get; private set; }
    public E.SourceRegistry registry { get; private set; }

    /* The first day of the month */
    public DateTime month_start { get; set; }

    /* The number of weeks to show in this model */
    public int num_weeks { get; private set; default = 6; }

    /* The start of week, ie. Monday=1 or Sunday=7 */
    public GLib.DateWeekday week_starts_on { get; set; default = GLib.DateWeekday.MONDAY; }

    /* The event that is currently dragged */
    public ECal.Component drag_component {get; set;}

    /* Notifies when events are added, updated, or removed */
    public signal void events_added (E.Source source, Gee.Collection<ECal.Component> events);
    public signal void events_updated (E.Source source, Gee.Collection<ECal.Component> events);
    public signal void events_removed (E.Source source, Gee.Collection<ECal.Component> events);

    public signal void connecting (E.Source source, Cancellable cancellable);
    public signal void connected (E.Source source);
    public signal void error_received (string error);

    /* The month_start, num_weeks, or week_starts_on have been changed */
    public signal void parameters_changed ();

    HashTable<string, ECal.Client> source_client;
    HashTable<string, ECal.ClientView> source_view;
    HashTable<E.Source, Gee.TreeMultiMap<string, ECal.Component>> source_events;

    public GLib.Queue<E.Source> calendar_trash;
    private E.CredentialsPrompter credentials_prompter;

    private static Calendar.Store? store = null;
    private static GLib.Settings state_settings;

    public static Calendar.Store get_default () {
        if (store == null)
            store = new Calendar.Store ();
        return store;
    }

    static construct {
        state_settings = new GLib.Settings ("io.elementary.calendar.savedstate");
    }

    private Store () {
        int week_start = Posix.NLTime.FIRST_WEEKDAY.to_string ().data[0];
        if (week_start >= 1 && week_start <= 7) {
            week_starts_on = (GLib.DateWeekday) (week_start - 1);
        }

        this.month_start = Calendar.Util.datetime_get_start_of_month (get_page ());
        compute_ranges ();

        source_client = new HashTable<string, ECal.Client> (str_hash, str_equal);
        source_events = new HashTable<E.Source, Gee.TreeMultiMap<string, ECal.Component>> (Maya.Util.source_hash_func, Calendar.Util.esource_equal_func);
        source_view = new HashTable<string, ECal.ClientView> (str_hash, str_equal);
        calendar_trash = new GLib.Queue<E.Source> ();

        notify["month-start"].connect (on_parameter_changed);
        open.begin ();
    }

    public async void open () {
        try {
            registry = yield new E.SourceRegistry (null);
            credentials_prompter = new E.CredentialsPrompter (registry);
            credentials_prompter.set_auto_prompt (true);
            registry.source_removed.connect (remove_source);
            registry.source_changed.connect (on_source_changed);
            registry.source_added.connect (add_source);

            // Add sources
            registry.list_sources (E.SOURCE_EXTENSION_CALENDAR).foreach ((source) => {
                E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
                if (cal.selected == true && source.enabled == true) {
                    add_source (source);
                }
            });
        } catch (GLib.Error error) {
            critical (error.message);
        }
    }

    //--- Public Methods ---//

    public void add_event (E.Source source, ECal.Component event) {
        add_event_async.begin (source, event);
    }

    public bool calclient_is_readonly (E.Source source) {
        ECal.Client? client;
        lock (source_client) {
            client = source_client.get (source.dup_uid ());
        }
        if (client != null) {
            return client.is_readonly ();
        } else {
            critical ("No calendar client was found");
        }

        return true;
    }

    private async void add_event_async (E.Source source, ECal.Component event) {
        unowned ICal.Component comp = event.get_icalcomponent ();
        debug (@"Adding event '$(comp.get_uid())'");
        ECal.Client? client;
        lock (source_client) {
            client = source_client.get (source.get_uid ());
        }

        if (client != null) {
            try {
                string? uid;
#if E_CAL_2_0
                yield client.create_object (comp, ECal.OperationFlags.NONE, null, out uid);
#else
                yield client.create_object (comp, null, out uid);
#endif
                if (uid != null) {
                    comp.set_uid (uid);
                }
            } catch (GLib.Error error) {
                critical (error.message);
            }
        } else {
            critical ("No calendar was found, event not added");
        }
    }

    public void update_event (E.Source source, ECal.Component event, ECal.ObjModType mod_type) {
        unowned ICal.Component comp = event.get_icalcomponent ();
        debug (@"Updating event '$(comp.get_uid())' [mod_type=$(mod_type)]");
        ECal.Client? client;
        lock (source_client) {
            client = source_client.get (source.get_uid ());
        }

#if E_CAL_2_0
        client.modify_object.begin (comp, mod_type, ECal.OperationFlags.NONE, null, (obj, results) => {
#else
        client.modify_object.begin (comp, mod_type, null, (obj, results) => {
#endif
            try {
                client.modify_object.end (results);
            } catch (Error e) {
                warning (e.message);
            }
        });
    }

    public void remove_event (E.Source source, ECal.Component event, ECal.ObjModType mod_type) {
        unowned ICal.Component comp = event.get_icalcomponent ();
        string uid = comp.get_uid ();
        string? rid = null;

        if (event.has_recurrences () && mod_type != ECal.ObjModType.ALL) {
            rid = event.get_recurid_as_string ();
            debug (@"Removing recurrent event '$rid'");
        }

        debug (@"Removing event '$uid'");
        ECal.Client client;
        lock (source_client) {
            client = source_client.get (source.get_uid ());
        }

#if E_CAL_2_0
        client.remove_object.begin (uid, rid, mod_type, ECal.OperationFlags.NONE, null, (obj, results) => {
#else
        client.remove_object.begin (uid, rid, mod_type, null, (obj, results) => {
#endif
            try {
                client.remove_object.end (results);
            } catch (Error e) {
                warning (e.message);
            }
        });
    }

    public void trash_calendar (E.Source source) {
        calendar_trash.push_tail (source);
        remove_source (source);
        source.set_enabled (false);
    }

    public void restore_calendar () {
        if (calendar_trash.is_empty ())
            return;

        var source = calendar_trash.pop_tail ();
        source.set_enabled (true);
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
        debug ("Removing source '%s'", source.dup_display_name ());
        // Already out of the model, so do nothing
        unowned string uid = source.get_uid ();
        if (!source_view.contains (uid)) {
            return;
        }

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

        var events = source_events.get (source).get_values ().read_only_view;
        events_removed (source, events);
        source_events.remove (source);
    }

    public Gee.Collection<ECal.Component> get_events () {
        Gee.ArrayList<ECal.Component> events = new Gee.ArrayList<ECal.Component> ();
        registry.list_sources (E.SOURCE_EXTENSION_CALENDAR).foreach ((source) => {
            E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            if (cal.selected == true && source.enabled == true) {
                events.add_all (source_events.get (source).get_values ().read_only_view);
            }
        });
        return events;
    }

    //--- Helper Methods ---//

    private DateTime get_page () {
        var month_page = state_settings.get_string ("month-page");
        if (month_page == null || month_page == "") {
            return new DateTime.now_local ();
        }

        var numbers = month_page.split ("-", 2);
        var dt = new DateTime.local (int.parse (numbers[0]), 1, 1, 0, 0, 0);
        dt = dt.add_months (int.parse (numbers[1]) - 1);
        return dt;
    }

    private void compute_ranges () {
        state_settings.set_string ("month-page", month_start.format ("%Y-%m"));

        var month_end = month_start.add_full (0, 1, -1);
        month_range = new Calendar.Util.DateRange (month_start, month_end);

        int dow = month_start.get_day_of_week ();
        int wso = (int) week_starts_on;
        int offset = 0;

        if (wso < dow) {
            offset = dow - wso;
        } else if (wso > dow) {
            offset = 7 + dow - wso;
        }

        var data_range_first = month_start.add_days (-offset);

        dow = month_end.get_day_of_week ();
        wso = (int) (week_starts_on + 6);

        // WSO must be between 1 and 7
        if (wso > 7)
            wso = wso - 7;

        offset = 0;

        if (wso < dow)
            offset = 7 + wso - dow;
        else if (wso > dow)
            offset = wso - dow;

        var data_range_last = month_end.add_days (offset);

        data_range = new Calendar.Util.DateRange (data_range_first, data_range_last);
        num_weeks = data_range.to_list ().size / 7;

        debug (@"Date ranges: ($data_range_first <= $month_start < $month_end <= $data_range_last)");
    }

    private void load_source (E.Source source) {
        // create empty source-event map
        var events = new Gee.TreeMultiMap<string, ECal.Component> (
            (GLib.CompareDataFunc<string>?) GLib.strcmp,
            (GLib.CompareDataFunc<ECal.Component>?) Calendar.Util.ecalcomponent_compare_func);
        source_events.set (source, events);
        // query client view
        var iso_first = ECal.isodate_from_time_t ((time_t) data_range.first_dt.to_unix ());
        var iso_last = ECal.isodate_from_time_t ((time_t) data_range.last_dt.add_days (1).to_unix ());
        var query = @"(occur-in-time-range? (make-time \"$iso_first\") (make-time \"$iso_last\"))";

        ECal.Client client;
        lock (source_client) {
            client = source_client.get (source.dup_uid ());
        }

        if (client == null)
            return;

        debug ("Getting client-view for source '%s'", source.dup_display_name ());
        client.get_view.begin (query, null, (obj, results) => {
            ECal.ClientView view;
            debug ("Received client-view for source '%s'", source.dup_display_name ());
            try {
                client.get_view.end (results, out view);
                view.objects_added.connect ((objects) => on_objects_added (source, client, objects));
                view.objects_removed.connect ((objects) => on_objects_removed (source, client, objects));
                view.objects_modified.connect ((objects) => on_objects_modified (source, client, objects));
                view.start ();
            } catch (Error e) {
                critical ("Error from source '%s': %s", source.dup_display_name (), e.message);
            }

            source_view.set (source.dup_uid (), view);
        });
    }


    private async void add_source_async (E.Source source) {
        debug ("Adding source '%s'", source.dup_display_name ());
        try {
            var cancellable = new GLib.Cancellable ();
            connecting (source, cancellable);
            var client = (ECal.Client) yield ECal.Client.connect (source, ECal.ClientSourceType.EVENTS, 30, cancellable);
            source_client.insert (source.get_uid (), client);
        } catch (Error e) {
            error_received (e.message);
        }

        Idle.add (() => {
            connected (source);
            load_source (source);
            return false;
        });
    }

    private void debug_event (E.Source source, ECal.Component event, string message = "") {
        unowned ICal.Component comp = event.get_icalcomponent ();
        debug (@"$(message) Event ['$(comp.get_summary())', $(source.dup_display_name()), UID $(comp.get_uid()), START $(comp.get_dtstart().as_ical_string ()), RID %s )]", event.get_id ().get_rid ());
    }

    //--- Signal Handlers ---//
    private void on_parameter_changed () {
        compute_ranges ();
        parameters_changed ();
        load_all_sources ();
    }

    private void on_source_changed (E.Source source) {

    }

#if E_CAL_2_0
    private void on_objects_added (E.Source source, ECal.Client client, SList<ICal.Component> objects) {
#else
    private void on_objects_added (E.Source source, ECal.Client client, SList<weak ICal.Component> objects) {
#endif
        debug (@"Received $(objects.length()) added event(s) for source '%s'", source.dup_display_name ());
        var events = source_events.get (source);
        var added_events = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Calendar.Util.ecalcomponent_equal_func);

        objects.foreach ((comp) => {
            unowned string uid = comp.get_uid ();
#if E_CAL_2_0
            client.generate_instances_for_object_sync (comp, (time_t) data_range.first_dt.to_unix (), (time_t) data_range.last_dt.to_unix (), null, (comp, start, end) => {
                var event = new ECal.Component.from_icalcomponent (comp);
#else
            client.generate_instances_for_object_sync (comp, (time_t) data_range.first_dt.to_unix (), (time_t) data_range.last_dt.to_unix (), (event, start, end) => {
#endif
                debug_event (source, event, "ADDED");
                event.set_data<E.Source> ("source", source);
                events.set (uid, event);
                added_events.add (event);
                return true;
            });
        });

        events_added (source, added_events.read_only_view);
    }

#if E_CAL_2_0
    private void on_objects_modified (E.Source source, ECal.Client client, SList<ICal.Component> objects) {
#else
    private void on_objects_modified (E.Source source, ECal.Client client, SList<weak ICal.Component> objects) {
#endif
        debug (@"Received $(objects.length()) modified event(s) for source '%s'", source.dup_display_name ());
        var updated_events = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Calendar.Util.ecalcomponent_equal_func);
        var removed_events = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Calendar.Util.ecalcomponent_equal_func);
        var added_events = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Calendar.Util.ecalcomponent_equal_func);

        objects.foreach ((comp) => {
            unowned string uid = comp.get_uid ();
            var events_for_source = source_events.get (source);
            var events_for_uid = events_for_source.get (uid);
            if (events_for_uid.size > 1 ||
                events_for_uid.to_array ()[0].get_icalcomponent ().get_recurrenceid ().as_ical_string () != null ||
                comp.get_recurrenceid ().as_ical_string () != null) {

                /* Either original or new event is recurring: rebuild our set of recurrences with new data */
                events_for_source.remove_all (uid);
                foreach (ECal.Component event in events_for_uid) {
                    debug_event (source, event, "MODIFIED - ORIGINAL");
                    removed_events.add (event);
                }

#if E_CAL_2_0
                client.generate_instances_for_object_sync (comp, (time_t) data_range.first_dt.to_unix (), (time_t) data_range.last_dt.to_unix (), null, (comp, start, end) => {
                    var event = new ECal.Component.from_icalcomponent (comp);
#else
                client.generate_instances_for_object_sync (comp, (time_t) data_range.first_dt.to_unix (), (time_t) data_range.last_dt.to_unix (), (event, start, end) => {
#endif
                    event.set_data<E.Source> ("source", source);
                    debug_event (source, event, "MODIFIED - GENERATED");
                    events_for_source.set (uid, event);
                    added_events.add (event);
                    return true;
                });
            } else {
                debug_event (source, events_for_uid.to_array ()[0], "MODIFIED - UPDATED");
                updated_events.add (events_for_uid.to_array ()[0]);
            }
        });

        events_removed (source, removed_events.read_only_view);
        events_added (source, added_events.read_only_view);
        events_updated (source, updated_events.read_only_view);
    }

#if E_CAL_2_0
    private void on_objects_removed (E.Source source, ECal.Client client, SList<ECal.ComponentId?> cids) {
#else
    private void on_objects_removed (E.Source source, ECal.Client client, SList<weak ECal.ComponentId?> cids) {
#endif
        debug (@"Received $(cids.length()) removed event(s) for source '%s'", source.dup_display_name ());
        var events = source_events.get (source);
        var removed_events = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Calendar.Util.ecalcomponent_equal_func);
        cids.foreach ((cid) => {
            if (cid == null)
                return;

            var comps = events.get (cid.get_uid ());
            events.remove_all (cid.get_uid ());
            foreach (ECal.Component event in comps) {
                removed_events.add (event);
                debug_event (source, event);
            }
        });

        events_removed (source, removed_events.read_only_view);
    }
}
