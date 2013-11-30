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

#ifndef Grapevine_sign_up_operation_hpp
#define Grapevine_sign_up_operation_hpp

#include <functional>
#include <map>
#include <string>

#include <boost/asio.hpp>

namespace grapevine {

    class stack_impl;
    
    class sign_up_operation
    {
        public:
        
            /**
             * Constructor
             * @param owner The stack_impl.
             */
            sign_up_operation(stack_impl & owner);
        
            /** 
             * Destructor
             */
            ~sign_up_operation();
        
            /**
             * Starts the operation.
             */
            void start(
                const std::map<std::string, std::string> & url_params,
                const std::function<void (
                const std::map<std::string, std::string> & pairs)> & f
            );
    
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
             * The completion handler.
             */
            std::function<
                void (std::map<std::string, std::string>)
            > m_on_complete;
        
            /**
             * The proxy transaction identifier.
             */
            std::uint16_t m_proxy_tid;
        
        protected:
        
            /**
             * Handles the json response.
             * @param json The json.
             */
            void handle_json(const std::string & json);
        
            /**
             * The stack_impl.
             */
            stack_impl & stack_impl_;
        
            /**
             * The boost::asio::io_service.
             */
            boost::asio::io_service io_service_;
        
            /**
             * The boost::asio::strand.
             */
            boost::asio::strand strand_;
        
            /**
             * The timer.
             */
            boost::asio::basic_waitable_timer<
                std::chrono::steady_clock
            > timeout_timer_;
    };
    
} // grapevine

#endif // Grapevine_sign_up_operation_hpp
