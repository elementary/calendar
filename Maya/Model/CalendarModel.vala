namespace Maya.Model {

class CalendarModel : Object {

    public int month { get; private set; }
    public int year { get; private set; }
    public DateTime date_first { get; private set; }
    public DateTime date_last { get; private set; }

    public signal void updated();

    public signal void events_added();
    public signal void events_modified();
    public signal void events_removed();

    // SEE UTILITIES.VALA

    public Gee.HashMap<DateTime, Gee.HashMultiMap<E.Source, iCal.icalcomponent>> events;

    public CalendarModel () {
    }

    // 2011-11-16 -> 2011-11-23
    //public Gee.List<iCal.icalcomponent> get_events (DateTime start, DateTime end) {
    //}

    //--- SIGNAL HANDLERS ---//
    // on_e_cal_client_view_objects_added
    // on_e_cal_client_view_objects_removed
    // on_e_cal_client_view_objects_modified
}

}
