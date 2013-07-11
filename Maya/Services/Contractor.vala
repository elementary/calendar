//
//  Copyright (C) 2011-2012 Jaap Broekhuizen <jaapz.b@gmail.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
using Granite.Services;

namespace Maya.Services {

    public class Contractor {
        private static Gee.List<Contract> contracts;

        public static Gee.List<Contract> get_services () {
            if (contracts == null) {
                contracts = ContractorProxy.get_contracts_by_mime ("text/calender");
            }
            return contracts;
        }

        public static void execute_service_for_display_name (string display_name, File des_file) {
            foreach (Contract  contract in contracts) {
                if (contract.get_display_name () == display_name) {
                    contract.execute_with_file (des_file);
                    break;
                }
            }
        }
    }

}

