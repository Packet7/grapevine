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
 
#ifndef GRAPEVINE_STACK_HPP
#define GRAPEVINE_STACK_HPP

#include <cstdint>
#include <functional>
#include <list>
#include <map>
#include <string>
#include <vector>

namespace grapevine {

    class stack_impl;
    
    /**
     * The stack.
     */
    class stack
    {
        public:
        
            /**
             * Constructor
             */
            stack();
            
            /**
             * Starts the stack.
             * @param port The listen port.
             */
            void start(const std::uint16_t & port = 0);
            
            /**
             * Stops the stack.
             */
            void stop();
        
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
             * Performs a store operation.
             * @param query The query.
             */
            std::uint16_t store(const std::string &);
        
            /**
             * Performs a find operation.
             * @param query The query.
             * @param max_results The maximum number of results.
             */
            std::uint16_t find(const std::string &, const std::size_t &);
        
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
            ) = 0;
        
            /**
             * Called when disconnected from the network.
             * @param addr The address.
             * @param port The port.
             */
            virtual void on_disconnected(
                const char * addr, const std::uint16_t & port
            ) = 0;
        
            /**
             * Called when sign in has completed.
             * @param status The status.
             */
            virtual void on_sign_in(const std::string &) = 0;
        
            /**
             *
             */
            virtual void on_find_message(
                const std::uint16_t & transaction_id,
                const std::map<std::string, std::string> & pairs,
                const std::vector<std::string> & tags
            ) = 0;
        
            /**
             *
             */
            virtual void on_find_profile(
                const std::uint16_t & transaction_id,
                const std::map<std::string, std::string> & pairs
            ) = 0;
        
            /**
             * Called when a version check completes.
             */
            virtual void on_version(
                const std::map<std::string, std::string> &
            ) = 0;
        
        private:
        
            // ...
            
        protected:
        
            /**
             * The stack implementation.
             */
            stack_impl * stack_impl_;
    };

} // namespace grapevine

#endif // GRAPEVINE_STACK_HPP
