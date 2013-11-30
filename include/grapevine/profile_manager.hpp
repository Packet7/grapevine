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

#ifndef Grapevine_profile_manager_hpp
#define Grapevine_profile_manager_hpp

#include <boost/asio.hpp>

#include <cstdint>
#include <map>
#include <mutex>
#include <string>

namespace grapevine {

    class stack_impl;
    
    class profile_manager
        : public std::enable_shared_from_this<profile_manager>
    {
        public:
        
            /**
             * Two hours.
             */
            enum { republish_interval = 3600 * 2 };
        
            /**
             * Constructor
             * @param ios The boost::asio::io_service.
             * @param owner The owner.
             */
            explicit profile_manager(boost::asio::io_service &, stack_impl &);
        
            /**
             * Starts
             */
            void start();
        
            /**
             * Stops
             */
            void stop();
        
            /**
             * Sets the profile.
             */
            void set_profile(const std::map<std::string, std::string> & profile);
        
            /**
             * The profile.
             */
            const std::map<std::string, std::string> & profile() const;
        
            /**
             * Publishes the profile.
             * @param interval The interval.
             */
            std::uint16_t do_publish(
                const std::uint32_t & interval = republish_interval
            );
        
        private:
        
            /**
             * Saves to disk.
             */
            void save();
        
            /**
             * Loads from disk.
             */
            void load();
        
            /**
             * The profile.
             */
            std::map<std::string, std::string> m_profile;
        
        protected:
        
            /**
             * The boost::asio::io_service.
             */
            boost::asio::io_service & io_service_;
        
            /**
             * The boost::asio::strand.
             */
            boost::asio::strand strand_;
        
            /** 
             * The stack_impl.
             */
            stack_impl & stack_impl_;
        
            /**
             * The timer.
             */
            boost::asio::basic_waitable_timer<std::chrono::steady_clock> timer_;
        
            /**
             * The publications mutex.
             */
            mutable std::recursive_mutex mutex_;
    };
    
} // namespace grapevine

#endif // Grapevine_profile_manager_hpp
