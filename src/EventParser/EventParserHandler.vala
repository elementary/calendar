// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2015 Mario Guerriero <marioguerriero33@gmail.com>
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE.  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program.  If not, see <http://www.gnu.org/licenses/>

  END LICENSE
***/

namespace Maya.Services {

public class EventParserHandler : GLib.Object {

    public const string FALLBACK_LANG = "en";

    private Gee.HashMap<string, EventParser> handlers;

    public EventParserHandler (string? lang = null) {
        handlers = new Gee.HashMap<string, EventParser> ();

        if (lang == null)
            lang = get_locale ();

        // Grant at least the fallback parser
        register_handler (FALLBACK_LANG, new ParserEn ());
        
        // Register other default parsers
        var parser = new ParserDe ();
        register_handler (parser.get_language (), parser); // de

    }

    public void register_handler (string lang, EventParser parser) {
        handlers.set (lang, parser);
    }
    
    public EventParser get_parser (string lang) {
        if (!handlers.has_key (lang))
            return handlers.get (FALLBACK_LANG);
        return handlers.get (lang);
    }

    public unowned string? get_locale () {
        return Environment.get_variable ("LANGUAGE").split (":")[0];
    }
}

}