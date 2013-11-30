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

#include <iostream>
#include <regex>

#include <grapevine/credentials_manager.hpp>
#include <grapevine/crypto.hpp>
#include <grapevine/publish_manager.hpp>
#include <grapevine/stack_impl.hpp>
#include <grapevine/uri.hpp>

using namespace grapevine;

publish_manager::publish_manager(
    boost::asio::io_service & ios, stack_impl & owner
    )
    : io_service_(ios)
    , strand_(ios)
    , stack_impl_(owner)
    , timer_(ios)
{
    // ...
}

void publish_manager::start()
{
    auto self(shared_from_this());
    
    timer_.expires_from_now(std::chrono::seconds(60));
    timer_.async_wait(
        strand_.wrap(
            [this, self](boost::system::error_code ec)
            {
                if (ec)
                {
                    // ...
                }
                else
                {
                    self->do_update();
                }
            }
        )
    );
}

void publish_manager::stop()
{
    timer_.cancel();
}

std::uint16_t publish_manager::publish(
    const std::string & message, const std::time_t & timestamp,
    const std::time_t & lifetime
    )
{
    bool exists = false;
    
    for (auto & i : publications_)
    {
        if (i.message == message)
        {
            exists = true;
            break;
        }
    }
    
    if (!exists)
    {
        /**
         * Allocate the publication.
         */
        publication_t pub;
        
        /**
         * Set the message and time.
         */
        pub.message = message;
        pub.time_published = timestamp;
        pub.time_republished = std::time(0);
        
        std::lock_guard<std::recursive_mutex> l(publications_mutex_);
        
        /**
         * Retain for re-publication.
         */
        publications_.push_back(pub);
        
        /**
         * Build the query.
         */
        std::string query = build_query(message, timestamp, lifetime);
        
        /**
         * Store the query.
         */
        return stack_impl_.store(query);
    }
    
    return 0;
}

std::string publish_manager::build_query(
    const std::string & message, const std::time_t & timestamp,
    const std::time_t & lifetime
    )
{
    std::string query;
    
    /**
     * The username.
     */
    query += "u=" + stack_impl_.username();
    
    /**
     * The message.
     */
    query += "&m=" + uri::encode(message);
    
    /**
     * Sign the query.
     * __s = signature
     */
    std::string signature = stack_impl_.credentials_manager_->sign(query);
    
    /**
     * The signature.
     */
    query += "&__s=" + uri::encode(crypto::base64_encode(
        signature.data(), signature.size())
    );
    
    /**
     * The timestamp.
     */
    query += "&__t=" + std::to_string(timestamp);
    
    std::vector<std::string> tags;
    
    /**
     * Check for hash tags.
     */
    std::regex base_regex1("(^|\\s)#(\\w*[a-zA-Z_]+\\w*)");
    
    for (
        std::sregex_iterator i(message.begin(), message.end(), base_regex1);
        i != std::sregex_iterator(); ++i
        )
    {
        tags.push_back((*i)[2]);
    }
    
    std::regex base_regex2("(^|\\s)@(\\w*[a-zA-Z_]+\\w*)");
    
    for (
        std::sregex_iterator i(message.begin(), message.end(), base_regex2);
        i != std::sregex_iterator(); ++i
        )
    {
        tags.push_back((*i)[2]);
    }
    
    for (auto & i : tags)
    {
        query += "&" + uri::encode(i) + "=" + uri::encode(i);
    }
    
    /**
     * 72 hours
     * @note Must always be last.
     */
    query += "&_l=" + std::to_string(lifetime);
    
    return query;
}

void publish_manager::do_update()
{
    std::lock_guard<std::recursive_mutex> l(publications_mutex_);
    
    for (auto & i : publications_)
    {
        std::time_t published = std::time(0) - i.time_published;
        
        /**
         * Do not republish expired publications.
         */
        if (published >= expire_time)
        {
            std::cout << "skipping expired pub" << std::endl;
            
            continue;
        }
        
        std::time_t republished = std::time(0) - i.time_republished;
        
        if (republished > republish_time)
        {
            std::time_t new_expire = (expire_time - published);
            
            /**
             * Do not republish if the new expire time is less than 6 hours.
             */
            if (new_expire > 60 * 60 * 6)
            {
                std::cout <<
                    "Time to republish, republished = " << republished <<
                    ", new lifetime = " << new_expire <<
                std::endl;
            
                /**
                 * Reset the time republished.
                 */
                i.time_republished = std::time(0);

                /**
                 * Build the query.
                 */
                std::string query = build_query(
                    i.message, i.time_published, new_expire
                );
                
                /**
                 * Store the query.
                 */
                stack_impl_.store(query);
            }
        }
    }
    
    auto it = publications_.begin();
    
    while (it != publications_.end())
    {
        std::time_t published = std::time(0) - it->time_published;
        
        if (published >= expire_time)
        {
            it = publications_.erase(it);
        }
        else
        {
            ++it;
        }
    }
    
    auto self(shared_from_this());
    
    timer_.expires_from_now(std::chrono::seconds(60));
    timer_.async_wait(
        strand_.wrap(
            [this, self](boost::system::error_code ec)
            {
                if (ec)
                {
                    // ...
                }
                else
                {
                    self->do_update();
                }
            }
        )
    );
}
