namespace Maya.Model {

class CalendarModel : Object {

    public DateTime target { get; set; }
    public DateWeekday week_starts_on { get; set; }
    public int num_weeks { get; set; default = 5; }

    public DateTime cal_date_start { get; private set; }
    public DateTime cal_date_end { get; private set; }

    Gee.Map<E.Source, E.CalClient> source_client;
    Gee.Map<E.Source, Gee.Set<E.CalComponent>> source_events;

    public signal void source_loaded(E.Source source);
    //public signal void events_added();
    //public signal void events_modified();
    //public signal void events_removed();

    public CalendarModel (Gee.Collection<E.Source> sources, DateTime target, DateWeekday week_starts_on) {

        this.target = target;
        this.week_starts_on = week_starts_on;

        source_client = new Gee.HashMap<E.Source, E.CalClient> ();
        source_events = new Gee.HashMap<E.Source, Gee.Set<E.CalComponent>> ();
        
        // create clients for each source
        foreach (var source in sources) {

            var client = new E.CalClient(source, E.CalClientSourceType.EVENTS);
            source_client.set (source, client);
        }

        set_date_ranges ();
        load_events ();

        notify["target"].connect (on_target_changed);
        notify["week_starts_on"].connect (on_week_starts_on_changed);
    }

    void set_date_ranges () {

        int dow = target.get_day_of_week(); 
        int wso = (int) week_starts_on;
        int offset = 0;

        if (wso < dow)
            offset = dow - wso;
        else if (wso > wso)
            offset = 7 + dow - wso;

        cal_date_start = target.add_days (-offset);
        cal_date_end = cal_date_start.add_weeks(num_weeks-1).add_days(6);

        debug(@"Date ranges set (f:$cal_date_start <= t:$target <= l:$cal_date_end)");
    }

    void load_events () {
        
        var iso_first = E.isodate_from_time_t((ulong) cal_date_start.to_unix());
        var iso_last = E.isodate_from_time_t((ulong) cal_date_end.to_unix());

        var query = @"(occur-in-time-range? (make-time \"$iso_first\") (make-time \"$iso_last\"))";

        foreach (var source in source_client.keys) {

            debug("Loading events for source '%s'", source.peek_name());

            var client = source_client.get (source);

            client.get_object_list_as_comps.begin(query, null, (obj, results) => {
                on_events_received (results, source, client);
            });
        }
    }

    void on_events_received (AsyncResult results, E.Source source, E.CalClient client) {

        GLib.SList<E.CalComponent> ecalcomps;

        try {

            var status = client.get_object_list_as_comps.end(results, out ecalcomps);
            assert (status==true);

        } catch (Error e) {

            debug("Error loading events from source '%s': %s", source.peek_name(), e.message);
        }

        debug (@"Received $(ecalcomps.length()) events for source '%s'", source.peek_name());

        Gee.Set<E.CalComponent> events = new Gee.HashSet<E.CalComponent>();
        ecalcomps.foreach ((ecalcomp) => events.add (ecalcomp));

        source_events.set (source, events);

        source_loaded (source);
    }

    void on_target_changed () { // TODO
    }

    void on_week_starts_on_changed () { // TODO
    }

    //--- SIGNAL HANDLERS ---//
    // on_e_cal_client_view_objects_added
    // on_e_cal_client_view_objects_removed
    // on_e_cal_client_view_objects_modified

    void dump () {
    

    }
}

}
