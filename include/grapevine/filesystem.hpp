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
 
#ifndef GRAPEVINE_FILESYSTEM_HPP
#define GRAPEVINE_FILESYSTEM_HPP

#include <string>

namespace grapevine {

    class filesystem
    {
        public:
        
            /** 
             * File exists
             */
            static int error_already_exists;
        
            /**
             * Creates the last folder of the given path.
             * @param path The path.
             */
            static int create_path(const std::string & path);
        
            /** 
             * The user data directory.
             */
            static std::string data_path();
        
        private:
        
            /** 
             * The user home directory.
             */
            static std::string home_path();
        
        protected:
        
            // ...
    };
    
} // grapevine

#endif // GRAPEVINE_FILESYSTEM_HPP
