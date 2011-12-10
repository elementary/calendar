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
    public int num_weeks { get; set; default = 6; }

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

    public CalendarModel (Model.SourceManager source_model, Settings.Weekday week_starts_on) {

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

        var sources = source_model.get_enabled_sources();
        foreach (var source in sources) {
            add_source (source);
        }

        // Signals

        source_model.status_changed.connect (on_source_status_changed);
        source_model.source_added.connect (on_source_added);
        source_model.source_removed.connect (on_source_removed);

        notify["month-start"].connect (on_parameter_changed);
        notify["num-weeks"].connect (on_parameter_changed);
        notify["week-starts-on"].connect (on_parameter_changed);
    }

    //--- Public Methods ---//

    public void add_event (E.Source source, E.CalComponent event) {
        debug ("Not Implemented: CalendarModel.add_event");
    }

    public void update_event (E.Source source, E.CalComponent event) {
        debug ("Not Implemented: CalendarModel.modify_event");
    }

    public void remove_event (E.Source source, E.CalComponent event) {
        debug ("Not Implemented: CalendarModel.remove_event");
    }

    //--- Helper Methods ---//

    void compute_ranges () {

        int dow = month_start.get_day_of_week(); 
        int wso = (int) week_starts_on;
        int offset = 0;

        if (wso < dow)
            offset = dow - wso;
        else if (wso > dow)
            offset = 7 + dow - wso;

        var data_range_first = month_start.add_days (-offset);
        var data_range_last = data_range_first.add_weeks(num_weeks-1).add_days(6);

        data_range = new Util.DateRange (data_range_first, data_range_last);

        var month_end = month_start.add_full (0, 1, -1);
        month_range = new Util.DateRange (month_start, month_end);

        debug(@"Date ranges: ($data_range_first <= $month_start < $month_end <= $data_range_last)");
    }

    void load_all_sources () {

        foreach (var source in source_client.keys)
            load_source (source);
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
        var iso_last = E.isodate_from_time_t((ulong) data_range.last.to_unix());

        var query = @"(occur-in-time-range? (make-time \"$iso_first\") (make-time \"$iso_last\"))";

        var client = source_client [source];

        debug("Getting client-view for source '%s'", source.peek_name());

        client.get_view.begin (query, null, (obj, results) => {

            var view = on_client_view_received (results, source, client);

            view.objects_added.connect ((objects) => on_objects_added (source, client, objects));
            view.objects_removed.connect ((objects) => on_objects_removed (source, client, objects));
            view.objects_modified.connect ((objects) => on_objects_modified (source, client, objects));

            view.start ();

            source_view.set (source, view);
        });
    }

    void add_source (E.Source source) {

        debug("Adding source '%s'", source.peek_name());

        var client = new E.CalClient(source, E.CalClientSourceType.EVENTS);
        source_client.set (source, client);

        load_source (source);
    }

    void remove_source (E.Source source) {

        assert (source_view.has_key (source));
        var current_view = source_view [source];
        current_view.stop();
        source_view.unset (source);

        var client = source_client [source];
        client.cancel_all ();
        source_client.unset (source);

        var events = source_events [source].values.read_only_view;
        events_removed (source, events);
        source_events.unset (source);

    }

    void debug_event (E.Source source, E.CalComponent event) {

        unowned iCal.icalcomponent comp = event.get_icalcomponent ();
        debug (@"Event ['$(comp.get_summary())', $(source.peek_name()), $(comp.get_uid()))]");
    }

    //--- Signal Handlers ---//

    void on_parameter_changed () {

        compute_ranges ();
        parameters_changed ();

        load_all_sources ();
    }

    void on_source_status_changed (E.Source source, bool enabled) {

        if (enabled)
            add_source (source);
        else
            remove_source (source);
    }

    void on_source_added (E.SourceGroup group, E.Source source) {

        add_source (source);
    }

    void on_source_removed (E.SourceGroup group, E.Source source) {
        
        remove_source (source);
    }

    E.CalClientView on_client_view_received (AsyncResult results, E.Source source, E.CalClient client) {

        E.CalClientView view;

        try {

            debug (@"Received client-view for source '%s'", source.peek_name());

            bool status = client.get_view.end (results, out view);
            assert (status==true);

        } catch (Error e) {

            critical ("Error loading client-view from source '%s': %s", source.peek_name(), e.message);
        }

        return view;
    }

    void on_objects_added (E.Source source, E.CalClient client, SList<weak iCal.icalcomponent> objects) {

        debug (@"Adding $(objects.length()) events for source '%s'", source.peek_name());

        Gee.Map<string, E.CalComponent> events = source_events [source];

        foreach (var comp in objects) {

            var event = new E.CalComponent ();
            iCal.icalcomponent comp_clone = new iCal.icalcomponent.clone (comp);
            event.set_icalcomponent ((owned) comp_clone);

            debug_event (source, event);

            string uid = comp.get_uid();

            events.set (uid, event);
        };

        events_added (source, events.values.read_only_view);
    }

    void on_objects_modified (E.Source source, E.CalClient client, SList<weak iCal.icalcomponent> objects) {
        
        debug (@"Updating $(objects.length()) events for source '%s'", source.peek_name());
        
        Gee.Collection<E.CalComponent> updated_events = new Gee.ArrayList<E.CalComponent> (
            (EqualFunc) Util.calcomponent_equal_func);

        foreach (var comp in objects) {

            string uid = comp.get_uid();

            E.CalComponent event = source_events [source] [uid];
            updated_events.add (event);

            debug_event (source, event);
        };

        events_updated (source, updated_events.read_only_view);
    }

    void on_objects_removed (E.Source source, E.CalClient client, SList<weak E.CalComponentId?> cids) {

        debug (@"Removing $(cids.length()) events for source '%s'", source.peek_name());

        var events = source_events [source];

        foreach (unowned E.CalComponentId? cid in cids) {

            assert (cid != null);

            E.CalComponent event = events [cid.uid];

            debug_event (source, event);
        }
    }
}

}
