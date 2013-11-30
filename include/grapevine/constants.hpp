/**
 * Copyright (C) 2013 Packet7, LLC.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#ifndef Grapevine_Header_h
#define Grapevine_Header_h

#include <string>

namespace grapevine {
  
    namespace constants
    {
        /**
         * The stack version.
         */
        enum { stack_version = 17 };
        
        static const std::string auth_address = "72.47.228.69";
        static const std::string auth_hostname = "grapevine.am";
    }
}

#endif
