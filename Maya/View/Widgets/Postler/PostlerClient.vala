/*
 Copyright (C) 2011 Christian Dywan <christian@twotoasts.de>

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 See the file COPYING for the full license text.
*/

namespace Postler {

    [DBus (name = "org.elementary.Postler")]
    interface PostlerClient : Object {
        public async abstract int64[] unread_messages (string uri) throws IOError;
        public async abstract GLib.HashTable<string,Variant> get_message (string id,
            char flag) throws IOError;
        public async abstract string[] get_thread (string thread) throws IOError;
        public signal void got_message (GLib.HashTable<string,Variant> message, int64 position);
        public async abstract string[] get_messages (string uri) throws IOError;
        public async abstract string[] autocomplete (string input) throws IOError;
        public signal void progress (string account, string text, double fraction);
        public abstract void receive (string account) throws IOError;
        public signal void received (string account, string error_message);
        public abstract bool fetch (string account) throws IOError;
        public abstract void send (string account, string filename) throws IOError;
        public signal void sent (string account, string filename, string error_message);
        public abstract void quit () throws IOError;
    }

    public class Client : Object {
        static PostlerClient? client = null;

        public Client () {
            if (client != null)
                return;
            try {
                client = Bus.get_proxy_sync (BusType.SESSION,
                                             "org.elementary.Postler",
                                             "/org/elementary/postler");

                /* Ensure Postler is running, ignore errors */
                Process.spawn_async (null, { null, "service" }, null,
                                     SpawnFlags.SEARCH_PATH, null, null);
            } catch (GLib.Error error) { }
        }

        public async string[] autocomplete (string input) throws GLib.Error {
            string[] suggestions;
            try {
                suggestions = yield client.autocomplete (input);
            }
            catch (GLib.Error error) {
                suggestions = {};
            }
            return suggestions;
        }
    }
}
