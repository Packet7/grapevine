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

#include <grapevine/constants.hpp>
#include <grapevine/http_transport.hpp>
#include <grapevine/logger.hpp>
#include <grapevine/stack_impl.hpp>
#include <grapevine/version_manager.hpp>

using namespace grapevine;

version_manager::version_manager(
    boost::asio::io_service & ios, stack_impl & owner
    )
    : m_proxy_tid(0)
#if (defined _WIN32 || defined WIN32) || (defined _WIN64 || defined WIN64)
    , m_platform("windows")
#elif (defined __IPHONE_OS_VERSION_MIN_REQUIRED)
    , m_platform("ios")
#elif (defined __APPLE__)
    , m_platform("osx")
#elif (defined __ANDROID__)
    , m_platform("android")
#else
    , m_platform("linux")
#endif
    , io_service_(ios)
    , strand_(ios)
    , stack_impl_(owner)
    , timer_(ios)
{
    // ...
}

void version_manager::start(
    const std::function<void (std::map<std::string, std::string>)> & f
    )
{
    m_on_complete = f;

    auto self(shared_from_this());
    
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
                    do_tick(86400);
                }
            }
        )
    );
}

void version_manager::stop()
{
    timer_.cancel();
}

void version_manager::check_version()
{
    auto self(shared_from_this());
    
    io_service_.post(strand_.wrap(
        [this, self]()
    {
        do_check_version();
    }));
}

void version_manager::on_proxy(
    const std::uint16_t & tid, const char * addr,
    const std::uint16_t & port, const std::string & value
    )
{
    if (m_proxy_tid == tid)
    {
        m_proxy_tid = 0;
        
        /**
         * Handle the json.
         */
        handle_json(value);
    }
}

void version_manager::do_check_version()
{
    std::string url =
        "https://www." + constants::auth_hostname +
        "/version/?p=" + m_platform +
        "&s=" + std::to_string(constants::stack_version)
    ;
    
    std::shared_ptr<http_transport> t =
        std::make_shared<http_transport>(io_service_, url)
    ;

    t->start(
        [this](
        boost::system::error_code ec, std::shared_ptr<http_transport> t)
        {
            if (ec)
            {
#if 1
                log_info(
                    "Version manager failed to connect, trying proxy."
                );
                
                io_service_.post(strand_.wrap(
                    [this]()
                {
                    std::stringstream ss;
                    ss <<
                        "GET" << " "  << "/version2/?p=" << m_platform <<
                        "&s=" << std::to_string(constants::stack_version) <<
                        " HTTP/1.0\r\n"
                    ;
                    ss << "Host: " << constants::auth_hostname << "\r\n";
                    ss << "Accept: */*\r\n";
                    ss << "Connection: close\r\n";
                    ss << "\r\n";

                    m_proxy_tid = stack_impl_.proxy(
                        constants::auth_address.c_str(), 80,
                        ss.str().data(), ss.str().size()
                    );
                }));
#endif
            }
            else
            {
                if (t->status_code() == 200)
                {
                    /**
                     * Handle the json.
                     */
                    handle_json(t->response_body());
                }
                else
                {
                    log_error(
                        "Version manager request failed, status "
                        "code = " << t->status_code() << "."
                    );
                }
            }
        }
    );
}

void version_manager::do_tick(const std::uint32_t & interval)
{
    do_check_version();

    if (interval > 0)
    {
        auto self(shared_from_this());
        
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
                        do_tick(interval);
                    }
                }
            )
        );
    }
}

void version_manager::handle_json(const std::string & json)
{
    std::stringstream ss;

    /**
     * Example:
     * {"message":"Success","status":0,"upgrade":"1","required":"0"}
     */
    ss << json;

    /**
     * Allocate empty property tree object.
     */
    boost::property_tree::ptree pt;
    
    std::map<std::string, std::string> result;
    
    try
    {
        /**
         * Read the json.
         */
        read_json(ss, pt);

        result["status"] = pt.get<std::string> (
            "status", ""
        );
        result["message"] = pt.get<std::string> (
            "message", ""
        );
        result["upgrade"] = pt.get<std::string> (
            "upgrade", ""
        );
        result["required"] = pt.get<std::string> (
            "required", ""
        );
        
        if (result["status"] == "0")
        {
            if (result["upgrade"] == "1")
            {
                log_info("Version manager upgrade available.");
                
                if (result["required"] == "1")
                {
                    log_info(
                        "Version manager upgrade required, message = " <<
                        result["message"] << "."
                    );
                }
            }
        }
        else
        {
            std::cerr <<
                "Version manager check failure, message = " <<
                result["message"] << ", status = " << result["status"] << "." <<
            std::endl;
        }
    }
    catch (std::exception & e)
    {
        std::cerr <<
            "Version manager check failure, what = " <<
            e.what() << "." <<
        std::endl;
        
        result["status"] = "-1";
        result["message"] = e.what();
    }
    
    if (m_on_complete)
    {
        m_on_complete(result);
    }
}
