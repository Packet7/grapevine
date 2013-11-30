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

#ifndef GRAPEVINE_AUTHENTICATION_MANAGER_HPP
#define GRAPEVINE_AUTHENTICATION_MANAGER_HPP

#include <cstdint>
#include <functional>
#include <string>

#include <boost/asio.hpp>

namespace grapevine {

    class stack_impl;
    
    class authentication_manager
    {
        public:
        
            /**
             * Constructor
             * @param ios The boost::asio::io_service.
             * @param owner The stack_impl.
             */
            explicit authentication_manager(
                boost::asio::io_service & ios, stack_impl &
            );
        
            /**
             * Signs into the network.
             * @param username The username.
             * @param password The password.
             * @param base64_cert the base64 encoded public certificate.
             */
            void sign_in(
                const std::string & username, const std::string & password,
                const std::string & base64_cert,
                const std::function<void (std::map<std::string, std::string>)> &
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
             * Handles the json response.
             * @param json The json.
             */
            void handle_json(const std::string & json);

            /**
             * Handles the json envelope.
             * @param envelope The envelope.
             * @return The envelope value.
             */
            std::string handle_json_envelope(const std::string &);

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
    };
    
} // namespace grapevine

#endif // GRAPEVINE_AUTHENTICATION_MANAGER_HPP
