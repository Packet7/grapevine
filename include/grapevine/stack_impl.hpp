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

#ifndef GRAPEVINE_STACK_IMPL_HPP
#define GRAPEVINE_STACK_IMPL_HPP

#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>

#include <boost/asio.hpp>

#include <database/stack.hpp>

namespace grapevine {

    class authentication_manager;
    class credentials_manager;
    class profile_manager;
    class publish_manager;
    class sign_up_operation;
    class stack;
    class subscription_manager;
    class version_manager;
    
    /**
     * The stack implementation.
     */
    class stack_impl : public database::stack
    {
        public:
        
            /**
             * Constructor
             * @param owner The stack.
             */
            stack_impl(grapevine::stack &);
            
            /**
             * Starts the stack.
             * @param port The listen port.
             */
            void start(const std::uint16_t &);
        
            /**
             * Signs up for the network.
             * @param url_params The url paramaters.
             * @param f The completion handler.
             */
            void sign_up(
                const std::map<std::string, std::string> &,
                const std::function<void (
                const std::map<std::string, std::string> & pairs)> &
            );
            
            /**
             * Signs into the network.
             * @@param username The username.
             * @param password The password.
             */
            void sign_in(const std::string &, const std::string &);
        
            /**
             * Signs out of the network.
             */
            void sign_out();
        
            /**
             * The username.
             */
            const std::string & username() const;
        
            /**
             * The profile.
             */
            const std::map<std::string, std::string> & profile() const;
        
            /**
             * The subscriptions.
             */
            const std::vector<std::string> subscriptions() const;
        
            /**
             * Performs an http get operation toward the url.
             * @param url The url.
             * @param f The function.
             */
            void url_get(
                const std::string & url,
                const std::function<void (const std::map<std::string,
                std::string> &, const std::string &)> & f
            );
        
            /**
             * Performs an http post operation toward the url.
             * @param url The url.
             * @param headers The headers.
             * @param body The body.
             * @param f The function.
             */
            void url_post(
                const std::string & url,
                const std::map<std::string, std::string> & headers,
                const std::string & body,
                const std::function<void (const std::map<std::string,
                std::string> &,
                const std::string &)> & f
            );
            
            /**
             * Subscribes to a username.
             * @param username The username.
             */
            void subscribe(const std::string &);
        
            /**
             * Unsubscribes from a username.
             * @param username The username.
             */
            void unsubscribe(const std::string &);
        
            /**
             * Returns true if the username is subscribed.
             * @param username The username.
             */
            bool is_subscribed(const std::string &);
        
            /**
             * Refreshes the subscriptions.
             */
            void update();
        
            /**
             * Posts a message.
             * @param message The message.
             */
            std::uint16_t post(const std::string & message);
        
            /**
             * Updates a profile.
             * @param profile The profile.
             */
            std::uint16_t update_profile(
                const std::map<std::string, std::string> & profile
            );
        
            /**
             * Called when connected to the network.
             * @param addr The address.
             * @param port The port.
             */
            virtual void on_connected(
                const char * addr, const std::uint16_t & port
            );
        
            /**
             * Called when disconnected from the network.
             * @param addr The address.
             * @param port The port.
             */
            virtual void on_disconnected(
                const char * addr, const std::uint16_t & port
            );
        
            /**
             * Called when a search result is received.
             * @param transaction_id The transaction id.
             * @param query The query.
             */
            virtual void on_find(
                const std::uint16_t & transaction_id,
                const std::string & query
            );
        
            /**
             * Called when a proxy (response) is received.
             * @param tid The transaction identifier.
             * @param addr The address.
             * @param The port.
             * @param value The value.
             */
            virtual void on_proxy(
                const std::uint16_t & tid, const char * addr,
                const std::uint16_t & port, const std::string & value
            );
        
            /**
             * Called when a udp packet doesn't match the protocol fingerprint.
             * @param addr The address.
             * @param port The port.
             * @param buf The buffer.
             * @param len The length.
             */
            virtual void on_udp_receive(
                const char * addr, const std::uint16_t & port, const char * buf,
                const std::size_t & len
            );
            
        private:
        
            friend class publish_manager;
            friend class profile_manager;
        
            /**
             * The username.
             */
            std::string m_username;
        
            /**
             * The password.
             */
            std::string m_password;
        
        protected:

            /**
             * Creates suport directories.
             */
            void create_directories();
        
            /**
             * Called when the credentials_manager has started.
             */
            void credentials_manager_on_started();
        
            /**
             * The stack.
             */
            grapevine::stack & stack_;
        
            /**
             * The boost::asio::io_service.
             */
            boost::asio::io_service io_service_;
        
            /**
             * The boost::asio::strand.
             */
            boost::asio::strand strand_;
        
            /**
             * The boost::asio::io_service::work.
             */
            std::shared_ptr<boost::asio::io_service::work> work_;
        
            /**
             * The thread.
             */
            std::thread thread_;
        
            /**
             * The std::recursive_mutex.
             */
            std::recursive_mutex mutex_;
        
            /**
             * The sign_up_operation.
             */
            std::shared_ptr<sign_up_operation> sign_up_operation_;
            
            /**
             * The authentication_manager.
             */
            std::shared_ptr<authentication_manager> authentication_manager_;
        
            /**
             * The credentials_manager.
             */
            std::shared_ptr<credentials_manager> credentials_manager_;
        
            /**
             * The profile_manager.
             */
            std::shared_ptr<profile_manager> profile_manager_;
        
            /**
             * The publish_manager.
             */
            std::shared_ptr<publish_manager> publish_manager_;
        
            /**
             * The subscription_manager.
             */
            std::shared_ptr<subscription_manager> subscription_manager_;
        
            /**
             * The version_manager.
             */
            std::shared_ptr<version_manager> version_manager_;
    };
    
} // namespace grapevine

#endif // GRAPEVINE_STACK_IMPL_HPP
