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

#ifndef Grapevine_version_manager_hpp
#define Grapevine_version_manager_hpp

#include <cstdint>
#include <functional>
#include <map>

#include <boost/asio.hpp>

namespace grapevine {

    class stack_impl;
    
    class version_manager
        : public std::enable_shared_from_this<version_manager>
    {
        public:
        
            /**
             * Constructor
             * @param ios The boost::asio::io_service.
             * @param owner The stack_impl.
             */
            explicit version_manager(boost::asio::io_service &, stack_impl &);
        
            /**
             * Starts
             * @param f The completion handler.
             */
            void start(
                const std::function<void (std::map<std::string, std::string>)> &
            );
        
            /**
             * Stops
             */
            void stop();
        
            /**
             * Performs a version checking operation.
             */
            void check_version();
        
            /**
             * Called when a proxy (response) is received.
             * @param tid The transaction identifier.
             * @param addr The address.
             * @param The port.
             * @param value The value.
             */
            void on_proxy(
                const std::uint16_t & tid, const char * addr,
                const std::uint16_t & port, const std::string & value
            );
        
        private:
        
            /**
             * Performs a version checking operation.
             */
            void do_check_version();
        
            /**
             * Performs a repeating version checking operation.
             * @param interval The interval at which to repeat.
             */
            void do_tick(const std::uint32_t & interval);
        
            /**
             * Handles the json response.
             * @param json The json.
             */
            void handle_json(const std::string & json);
        
            /**
             * The on complete handler.
             */
            std::function<
                void (std::map<std::string, std::string>)
            > m_on_complete;
        
            /**
             * The proxy transaction identifier.
             */
            std::uint16_t m_proxy_tid;
        
            /**
             * The platform.
             */
            std::string m_platform;
        
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
    };
    
} //  namespace grapevine

#endif // Grapevine_version_manager_hpp
