[CCode (cprefix = "", lower_case_cprefix = "")]
namespace Posix {
	[CCode (cheader_filename = "langinfo.h", cname = "nl_item", cprefix = "_NL_TIME_", has_type_id = false)]
	public enum NLTime {
		WEEK_NDAYS,
		WEEK_1STDAY,
		WEEK_1STWEEK,
		FIRST_WEEKDAY,
		FIRST_WORKDAY,
		CAL_DIRECTION,
		TIMEZONE
	}
	[CCode (cname = "nl_langinfo",cheader_filename = "langinfo.h")]
	public unowned string nl_langinfo2 (NLTime item);
}
