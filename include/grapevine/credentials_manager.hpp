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

#ifndef GRAPEVINE_CREDENTIALS_MANAGER_HPP
#define GRAPEVINE_CREDENTIALS_MANAGER_HPP

#include <functional>
#include <map>
#include <memory>
#include <vector>

#include <boost/asio.hpp>

#include <grapevine/rsa.hpp>

namespace grapevine {

    class stack_impl;
    
    class credentials_manager
        : public std::enable_shared_from_this<credentials_manager>
    {
        public:
        
            /**
             * Constructor
             * @param ios The boost::asio::io_service.
             * @param owner The stack_impl.
             */
            explicit credentials_manager(
                boost::asio::io_service &, stack_impl &
            );
        
            /**
             * Starts
             */
            void start();
        
            /**
             * Stops
             */
            void stop();
        
            /**
             * Called when credentials are found.
             * @param The pairs
             */
            void on_find(std::map<std::string, std::string> & pairs);
        
            /**
             * Sets the on started handler.
             * @param f The function.
             */
            void set_on_started(const std::function<void ()> &);
    
            /**
             * Returns a base64 encoded public certificate.
             */
            std::string base64_public_cert();
        
            /**
             * Signs a value with the rsa private portion.
             * @param val The value.
             */
            std::string sign(const std::string &);
        
            /**
             * Verifies a query with the users rsa public portion.
             * @param username The username.
             * @param query The query.
             * @param signature The signature.
             */
            bool verify(
                const std::string &, const std::string &, const std::string &
            );
        
            /**
             * The ca public certificate.
             */
            static std::shared_ptr<rsa> & ca_rsa();
    
            /**
             * Sets the (our) credentials envelope.
             * @param val The value.
             */
            void set_credentials_envelope(const std::string & val);
        
            /**
             * The (our) credentials envelope.
             */
            const std::string & credentials_envelope() const;
        
            /**
             * Stores the (our) credentials.
             */
            void store_credentials();
        
        private:
        
            /**
             * Called when rsa generation completes.
             */
            void rsa_on_generation();
        
            /**
             * The on started handler.
             */
            std::function<void ()> m_on_started;

            /**
             * The ca public certificate.
             */
            static std::shared_ptr<rsa> m_ca_rsa;
    
            /**
             * The (our) credentials envelope.
             */
            std::string m_credentials_envelope;
        
            /**
             * The (theirs) credentials.
             */
            std::map<
                std::string, std::vector< std::shared_ptr<rsa> >
            > m_credentials;
        
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
             * The store credentials timer.
             */
            boost::asio::basic_waitable_timer<
                std::chrono::steady_clock
            > store_credentials_timer_;
        
            /**
             * The rsa.
             */
            std::shared_ptr<rsa> rsa_;
    };
    
} // grapevine

#endif // GRAPEVINE_CREDENTIALS_MANAGER_HPP
