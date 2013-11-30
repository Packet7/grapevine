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
#include <grapevine/crypto.hpp>
#include <grapevine/credentials_manager.hpp>
#include <grapevine/http_transport.hpp>
#include <grapevine/logger.hpp>
#include <grapevine/sign_up_operation.hpp>
#include <grapevine/stack_impl.hpp>

using namespace grapevine;

sign_up_operation::sign_up_operation(stack_impl & owner)
    : m_proxy_tid(0)
    , stack_impl_(owner)
    , strand_(io_service_)
    , timeout_timer_(io_service_)
{
    // ...
}

sign_up_operation::~sign_up_operation()
{
    // ...
}

void sign_up_operation::start(
    const std::map<std::string, std::string> & url_params,
    const std::function<void (const std::map<std::string, std::string> & pairs)> & f
    )
{
    m_on_complete = f;
    
    io_service_.reset();
    
    timeout_timer_.expires_from_now(std::chrono::seconds(15));
    timeout_timer_.async_wait(
        strand_.wrap(
            [this](boost::system::error_code ec)
            {
                if (ec)
                {
                    // ...
                }
                else
                {
                    if (m_on_complete)
                    {
                        m_on_complete(std::map<std::string, std::string> ());
                    }
    
                    io_service_.stop();
                }
            }
        )
    );
    
    auto params = url_params;
    
    auto u = params["u"];
    auto p = params["p"];
    auto s = params["s"];
    
    std::string url =
        "https://www." + constants::auth_hostname +
        "/register/?u=" + u + "&p=" + p + "&ss=" + s
    ;
    
    std::shared_ptr<http_transport> t =
        std::make_shared<http_transport>(io_service_, url)
    ;

    t->start(
        [this, u, p, s](
        boost::system::error_code ec, std::shared_ptr<http_transport> t)
        {
            timeout_timer_.cancel();
            
            if (ec)
            {
#if 1
                log_info(
                    "Sign up failed to connect, trying proxy."
                );
                
                io_service_.post(strand_.wrap(
                    [this, u, p, s]()
                {
                    std::stringstream body;
                    
                    try
                    {
                        /**
                         * Allocate empty property tree object.
                         */
                        boost::property_tree::ptree pt;
                        
                        /**
                         * Put username into property tree.
                         */
                        pt.put("u", u);
                        
                        /**
                         * Put password into property tree.
                         */
                        pt.put("p", p);
                        
                        /**
                         * Put secret into property tree.
                         */
                        pt.put("s", s);
                        
                        /**
                         * Write property tree to json file.
                         */
                        write_json(body, pt);
                    }
                    catch (std::exception & e)
                    {
                        log_error(
                            "Sign up, what = " << e.what() << "."
                        ); 
                    }

                    std::string encrypted(body.str().size(), 0);
                    
                    unsigned char * ek[1];
                    
                    ek[0] = (unsigned char *)malloc(
                        RSA_size(credentials_manager::ca_rsa()->pub())
                    );
                    
                    int ekl;
                    int outl;
                    
                    if (
                        rsa::seal(credentials_manager::ca_rsa()->pub(), ek, &ekl,
                        body.str().data(), body.str().size(),
                        (char *)encrypted.data(), &outl)
                        )
                    {
                        std::string key(reinterpret_cast<char *>(ek[0]), ekl);
                        
                        std::stringstream sealed;
                        
                        try
                        {
                            /**
                             * Allocate empty property tree object.
                             */
                            boost::property_tree::ptree pt;
                            
                            /**
                             * Put key into property tree.
                             */
                            pt.put("k", crypto::base64_encode(
                                key.data(), key.size())
                            );
                            
                            /**
                             * Put encrypted into property tree.
                             */
                            pt.put("e", crypto::base64_encode(
                                encrypted.data(), encrypted.size())
                            );
                            
                            /**
                             * Write property tree to json file.
                             */
                            write_json(sealed, pt);
                        }
                        catch (std::exception & e)
                        {
                            log_error(e.what());
                        }
                        
                        std::stringstream ss;
                        ss << "POST" << " "  << "/register2/" << " HTTP/1.0\r\n";
                        ss << "Host: " << constants::auth_hostname << "\r\n";
                        ss << "Accept: */*\r\n";
                        ss << "Connection: close\r\n";
                        ss << "Content-Length: " << sealed.str().size() << "\r\n";
                        ss << "\r\n";
                        ss << sealed.str();

                        m_proxy_tid = stack_impl_.proxy(
                            constants::auth_address.c_str(), 80,
                            ss.str().data(), ss.str().size()
                        );
                    }
                    else
                    {
                        log_error("Sign up seal failed.");
                    }
                    
                    free(ek[0]);
                }));
#endif
            }
            else
            {
                if (t->status_code() == 200)
                {
                    timeout_timer_.cancel();
                    
                    /**
                     * Handle the json.
                     */
                    handle_json(t->response_body());
                }
                else
                {
                    log_error(
                        "Sign up request failed, status "
                        "code = " << t->status_code() << "."
                    );
                    
                    if (m_on_complete)
                    {
                        m_on_complete(std::map<std::string, std::string> ());
                    }
                    
                    io_service_.stop();
                }
            }
        }
    );

    io_service_.run();
}

void sign_up_operation::on_proxy(
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

void sign_up_operation::handle_json(const std::string & json)
{
    std::stringstream ss;

    /**
     * Example:
     * {"message":"Success","status":0}
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
        
        if (result["status"] == "0")
        {
            // ...
        }
        else
        {
            log_error(
                "Sign up operation failure, message = " <<
                result["message"] << ", status = " << result["status"] << "."
            );
        }
    }
    catch (std::exception & e)
    {
        log_error("Sign up operation failure, what = " << e.what() << ".");
        
        result["status"] = "-1";
        result["message"] = e.what();
    }
    
    if (m_on_complete)
    {
        m_on_complete(result);
    }
}
