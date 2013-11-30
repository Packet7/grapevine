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

#ifndef GRAPEVINE_PUBLISH_MANAGER_HPP
#define GRAPEVINE_PUBLISH_MANAGER_HPP

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include <boost/asio.hpp>

namespace grapevine {

    class stack_impl;
    
    class publish_manager
        : public std::enable_shared_from_this<publish_manager>
    {
        public:
        
            enum { expire_time = 259200 };
        
            enum { republish_time = 21600 };
        
            /**
             * Constructor
             * @param ios The boost::asio::io_service.
             * @param owner The owner.
             */
            explicit publish_manager(boost::asio::io_service &, stack_impl &);
        
            /**
             * Starts
             */
            void start();
        
            /**
             * Stops
             */
            void stop();
        
            std::uint16_t publish(
                const std::string & message,
                const std::time_t & timestamp,
                const std::time_t & lifetime
            );

        private:
        
            std::string build_query(
                const std::string & message,
                const std::time_t & timestamp,
                const std::time_t & lifetime
            );
        
            void do_update();
        
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
             * @param message The original message.
             * @param time The time published.
             */
            typedef struct
            {
                std::string message;
                std::time_t time_published;
                std::time_t time_republished;
            } publication_t;
        
            /**
             * The publications.
             */
            std::vector<publication_t> publications_;
        
            /**
             * The publications mutex.
             */
            std::recursive_mutex publications_mutex_;
    };
    
} // namespace grapevine

#endif // GRAPEVINE_PUBLISH_MANAGER_HPP
