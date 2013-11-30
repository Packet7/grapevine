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

#include <fstream>

#include <boost/asio.hpp>
#include <boost/property_tree/json_parser.hpp>

#include <grapevine/filesystem.hpp>
#include <grapevine/logger.hpp>
#include <grapevine/stack_impl.hpp>
#include <grapevine/subscription_manager.hpp>

using namespace grapevine;

subscription_manager::subscription_manager(
    boost::asio::io_service & ios, stack_impl & owner
    )
    : io_service_(ios)
    , strand_(ios)
    , stack_impl_(owner)
    , timer_(ios)
{
    // ...
}

void subscription_manager::start()
{
    auto self(shared_from_this());
    
    load();
    
    timer_.expires_from_now(std::chrono::milliseconds(500));
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
                    self->do_refresh();
                }
            }
        )
    );
}

void subscription_manager::stop()
{
    timer_.cancel();
}

void subscription_manager::subscribe(const std::string & username)
{
    m_subscriptions[username] = (std::time(0) - refresh_interval);
    
    save();
}

void subscription_manager::unsubscribe(const std::string & username)
{
    m_subscriptions.erase(username);
    
    save();
}

bool subscription_manager::is_subscribed(const std::string & username)
{
    return m_subscriptions.find(username) != m_subscriptions.end();
}

const subscription_manager::subscription_t &
    subscription_manager::subscriptions() const
{
    return m_subscriptions;
}

void subscription_manager::save()
{
    std::stringstream ss;
    
    try
    {
        boost::property_tree::ptree pt;
    
        for (auto & i : m_subscriptions)
        {
            boost::property_tree::ptree subscription;
            
            subscription.add("username", i.first);
            
            pt.push_back(std::make_pair(i.first, subscription));
        }
        
        write_json(ss, pt);
        
        std::ofstream ofs1(
            filesystem::data_path() +
            stack_impl_.username() + "/subscriptions.json"
        );
        
        ofs1 << ss.str();
        
        ofs1.flush();
        
        std::ofstream ofs2(
            filesystem::data_path() +
            stack_impl_.username() + "/subscriptions.json.bak"
        );
        
        ofs2 << ss.str();
        
        ofs2.flush();
    }
    catch (std::exception & e)
    {
        log_error(e.what());
    }
}

void subscription_manager::load()
{
    try
    {
        boost::property_tree::ptree pt;
		
        read_json(
            filesystem::data_path() +
            stack_impl_.username() + "/subscriptions.json", pt
        );
		
        boost::property_tree::ptree::const_iterator it = pt.begin();
        
        for (; it != pt.end(); ++it)
        {
            auto username = it->second.get<std::string> ("username");
            
            log_debug(
                "Subscription manager loaded subscription for " <<
                username << "."
            );
            
            m_subscriptions[username] = (std::time(0) - refresh_interval);
        }
    }
    catch (std::exception & e)
    {
        try
        {
            boost::property_tree::ptree pt;
            
            read_json(
                filesystem::data_path() +
                stack_impl_.username() + "/subscriptions.json.bak", pt
            );
            
            boost::property_tree::ptree::const_iterator it = pt.begin();
            
            for (; it != pt.end(); ++it)
            {
                auto username = it->second.get<std::string> ("username");
                
                log_debug(
                    "Subscription manager loaded subscription for " <<
                    username << " from backup file."
                );
                
                m_subscriptions[username] = (std::time(0) - refresh_interval);
            }
            
            save();
        }
        catch (std::exception & e)
        {
            // ...
        }
    }
}

void subscription_manager::do_refresh()
{
    for (auto & i : m_subscriptions)
    {
        auto elapsed = (std::time(0) - i.second);
        
        if (elapsed >= refresh_interval)
        {
            std::string query;
            
            query += "u=" + i.first;
            
            stack_impl_.find(query, 200);

            i.second = std::time(0);
            
            break;
        }
    }
    
    auto self(shared_from_this());
    
    timer_.expires_from_now(std::chrono::milliseconds(500));
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
                    self->do_refresh();
                }
            }
        )
    );
}
