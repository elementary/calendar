[Compact]
[CCode (free_function="icalcomponent_free", copy_function="icalcomponent_clone", cheader_filename = "libical/ical.h")]
public class icalcomponent {
    public icalcomponent.vevent ();
    /*string get_description();
    void set_description(string description);*/
    public string description { get; set; }
    public string relcalid { get; set; }
}
