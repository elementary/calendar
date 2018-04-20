[CCode (cprefix = "", lower_case_cprefix = "")]
namespace Posix {
	[CCode (cname = "nl_langinfo",cheader_filename = "langinfo.h")]
	public unowned string nl_langinfo2 (NLTime item);
}
