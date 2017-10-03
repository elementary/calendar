
namespace Maya.Settings {
    public class WeekSettings : Granite.Services.Settings {
        private static WeekSettings? instance = null;

        public bool show_weeks{ get; set; }

        public WeekSettings () {
            base ("org.pantheon.desktop.wingpanel.indicators.datetime");
        }

        public static WeekSettings get_default () {
            if (instance == null) {
                instance = new WeekSettings ();
            }

            return instance;
        }
    }
}
