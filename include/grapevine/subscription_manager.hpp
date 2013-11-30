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

#ifndef GRAPEVINE_SUBSCRIPTION_MANAGER_HPP
#define GRAPEVINE_SUBSCRIPTION_MANAGER_HPP

#include <map>
#include <memory>
#include <mutex>
#include <thread>

#include <boost/asio.hpp>

namespace grapevine {

    class stack_impl;
    
    class subscription_manager
        : public std::enable_shared_from_this<subscription_manager>
    {
        public:
        
            /**
             * A subscription.
             */
            typedef std::map<std::string, std::time_t> subscription_t;
        
            /**
             * Constructor
             * @param ios The boost::asio::io_service.
             * @param owner The stack_impl.
             */
            explicit subscription_manager(
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
        
            void subscribe(const std::string & username);
            void unsubscribe(const std::string & username);
            bool is_subscribed(const std::string & username);
        
            /**
             * The subscriptions.
             */
            const subscription_t & subscriptions() const;
        
        private:
        
            void save();
            void load();
        
            void do_refresh();
        
            /**
             * The refresh interval.
             */
            enum { refresh_interval = 600 };
        
            /**
             * The subscriptions.
             */
            subscription_t m_subscriptions;
        
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
    
} // grapevine

#endif // GRAPEVINE_SUBSCRIPTION_MANAGER_HPP
