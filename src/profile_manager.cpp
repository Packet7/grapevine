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

#include <boost/asio.hpp>
#include <boost/property_tree/json_parser.hpp>

#include <grapevine/crypto.hpp>
#include <grapevine/credentials_manager.hpp>
#include <grapevine/filesystem.hpp>
#include <grapevine/logger.hpp>
#include <grapevine/profile_manager.hpp>
#include <grapevine/stack_impl.hpp>
#include <grapevine/uri.hpp>

using namespace grapevine;

profile_manager::profile_manager(
    boost::asio::io_service & ios, stack_impl & owner
    )
    : stack_impl_(owner)
    , io_service_(ios)
    , strand_(ios)
    , timer_(ios)
{
    // ...
}

void profile_manager::start()
{
    auto self(shared_from_this());
    
    load();
    
    timer_.expires_from_now(std::chrono::seconds(8));
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
                    do_publish(republish_interval);
                }
            }
        )
    );
}

void profile_manager::stop()
{
    timer_.cancel();
    
    save();
}

void profile_manager::set_profile(
    const std::map<std::string, std::string> & profile
    )
{
    std::lock_guard<std::recursive_mutex> l(mutex_);
    
    m_profile = profile;
    
    save();
}

const std::map<std::string, std::string> & profile_manager::profile() const
{
    std::lock_guard<std::recursive_mutex> l(mutex_);
    
    return m_profile;
}

std::uint16_t profile_manager::do_publish(const std::uint32_t & interval)
{
    log_debug(
        "Profile manager is publishing profile, interval = " << interval << "."
    );
    
    if (!stack_impl_.username().empty())
    {
        auto self(shared_from_this());
        
        std::string query;
        
        /**
         * The username.
         */
        query += "u=" + stack_impl_.username();
        
        std::lock_guard<std::recursive_mutex> l(mutex_);
        
        for (auto & i : m_profile)
        {
            query += "&" +
                uri::encode(i.first) + "=" + uri::encode(i.second)
            ;
        }
        
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
        query += "&__t=" + std::to_string(std::time(0));
        
        /**
         * 72 hours
         */
        query += "&_l=259200";

        log_debug("query = " << query);
        
        timer_.expires_from_now(std::chrono::seconds(interval));
        timer_.async_wait(
            strand_.wrap(
                [this, self, interval](boost::system::error_code ec)
                {
                    if (ec)
                    {
                        // ...
                    }
                    else
                    {
                        do_publish(interval);
                    }
                }
            )
        );
    
        return stack_impl_.store(query);
    }
    
    return 0;
}

void profile_manager::save()
{
    std::stringstream ss;
    
    try
    {
        std::lock_guard<std::recursive_mutex> l(mutex_);
        
        boost::property_tree::ptree pt;
        
        for (auto & i : m_profile)
        {
            pt.add(i.first, i.second);
        }
        
        write_json(ss, pt);
        
        std::ofstream ofs1(
            filesystem::data_path() +
            stack_impl_.username() + "/profile.json"
        );
        
        ofs1 << ss.str();
        
        ofs1.flush();
        
        std::ofstream ofs2(
            filesystem::data_path() +
            stack_impl_.username() + "/profile.json.bak"
        );
        
        ofs2 << ss.str();
        
        ofs2.flush();
    }
    catch (std::exception & e)
    {
        log_error(e.what());
    }
}

void profile_manager::load()
{
    std::lock_guard<std::recursive_mutex> l(mutex_);
    
    std::stringstream ss;
    
    try
    {
        boost::property_tree::ptree pt;

        read_json(
            filesystem::data_path() +
            stack_impl_.username() + "/profile.json", pt
        );
		
        boost::property_tree::ptree::const_iterator it = pt.begin();
        
        for (; it != pt.end(); ++it)
        {
            log_none(
                "Profile manager loaded "  << it->first << ":" <<
                it->second.get_value<std::string>() << "."
            );
            
            auto value = it->second.get_value<std::string>();
            
            if (value.size() > 0)
            {
                m_profile[it->first] = value;
            }
            
            log_debug(
                "Profile manager loaded profile from file."
            );
        }
    }
    catch (std::exception & e)
    {
        try
        {
            boost::property_tree::ptree pt;

            read_json(
                filesystem::data_path() +
                stack_impl_.username() + "/profile.json.bak", pt
            );
            
            boost::property_tree::ptree::const_iterator it = pt.begin();
            
            for (; it != pt.end(); ++it)
            {
                log_none(
                    "Profile manager loaded "  << it->first << ":" <<
                    it->second.get_value<std::string>() << "."
                );
                
                auto value = it->second.get_value<std::string>();
                
                if (value.size() > 0)
                {
                    m_profile[it->first] = value;
                }
            }
            
            log_debug(
                "Profile manager loaded profile from backup file."
            );
            
            save();
        }
        catch (std::exception & e)
        {
            log_error(e.what());
        }
    }
}
