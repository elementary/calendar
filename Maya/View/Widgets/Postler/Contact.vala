/*
 Copyright (C) 2011 Christian Dywan <christian@twotoasts.de>

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 See the file COPYING for the full license text.
*/

namespace Maya.View.Widgets {
    public class Contact {
        public string display_name;
        public GLib.File? avatar;

        public Contact (string display_name, GLib.File? avatar) {
            this.display_name = display_name;
            this.avatar = avatar;
        }

        internal static string[] parse (string address)
            ensures (result[0] != null && result[1] != null) {
            if (address.length < 1) {
                GLib.critical ("parse: assertion '!address.length < 1' failed");
                return { address, address };
            }

            if (!(">" in address && "<" in address))
                return { address, address };

            long greater = address.length - 1;
            while (address[greater] != '>')
                greater--;
            long lower = greater;
            while (address[lower] != '<')
                lower--;

            string recipient = address.slice (lower + 1, greater);
            if (recipient.has_prefix ("mailto:"))
                recipient = recipient.substring (7, -1);
            if (lower == 0)
                return { recipient, recipient };
            if (">" in recipient)
                return { recipient, recipient };

            /* Remove double or single quotes around the name */
            long first = address.has_prefix ("'") || address.has_prefix ("\"") ? 1 : 0;
            return { address.substring (first, lower - 1)
                .replace ("\\\"", "`")
                .replace ("' ", "").replace ("\"", "").chomp (), recipient };
        }

        public static string address_from_string (string contact) {
            return parse (contact)[1];
        }

        public static string name_from_string (string contact) {
            return parse (contact)[0];
        }

        public static bool equal (string contact, string? other)
            requires (contact.chr (-1, '<') == null) {
            if (other == null)
                return false;
            if (other.chr (-1, '<') == null && contact == other)
                return true;
            if (contact == address_from_string (other))
                return true;
            return false;
        }
    }
}
