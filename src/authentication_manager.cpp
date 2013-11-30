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

#include <grapevine/authentication_manager.hpp>
#include <grapevine/constants.hpp>
#include <grapevine/credentials_manager.hpp>
#include <grapevine/crypto.hpp>
#include <grapevine/http_transport.hpp>
#include <grapevine/json_envelope.hpp>
#include <grapevine/logger.hpp>
#include <grapevine/rsa.hpp>
#include <grapevine/stack_impl.hpp>

using namespace grapevine;

authentication_manager::authentication_manager(
    boost::asio::io_service & ios, stack_impl & owner
    )
    : m_proxy_tid(0)
    , io_service_(ios)
    , strand_(ios)
    , stack_impl_(owner)
{
    // ...
}

void authentication_manager::sign_in(
    const std::string & username, const std::string & password,
    const std::string & base64_cert,
    const std::function<void (std::map<std::string, std::string>)> & f
    )
{
    m_on_complete = f;
    
    std::string secret = crypto::hmac_sha512(username, password);
    
    std::string url =
        "https://www." + constants::auth_hostname + "/auth?u=" +
        username + "&s=" + secret
    ;
    std::shared_ptr<http_transport> t =
        std::make_shared<http_transport>(io_service_, url)
    ;
    
    t->set_request_body(base64_cert);
    
    t->headers()["Content-Type"] = "text/plain";
    
    t->start(
        [this, username, secret, base64_cert](
        boost::system::error_code ec, std::shared_ptr<http_transport> t)
        {
            if (ec)
            {
#if 1
                log_info(
                    "Authentication manager failed to connect, trying proxy."
                );
                
                io_service_.post(strand_.wrap(
                    [this, username, secret, base64_cert]()
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
                        pt.put("u", username);
                        
                        /**
                         * Put secret into property tree.
                         */
                        pt.put("s", secret);
                        
                        /**
                         * Put base64_cert into property tree.
                         */
                        pt.put("c", base64_cert);
                        
                        /**
                         * Write property tree to json file.
                         */
                        write_json(body, pt);
                    }
                    catch (std::exception & e)
                    {
                        log_error(
                            "Authentication manager, what = " << e.what() << "."
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
                        ss << "POST" << " "  << "/auth2/" << " HTTP/1.0\r\n";
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
                        log_error("Authentication manager seal failed.");
                    }
                    
                    free(ek[0]);
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
                        "Authentication manager request failed, status "
                        "code = " << t->status_code() << "."
                    );
                }
            }
        }
    );
}

void authentication_manager::on_proxy(
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

void authentication_manager::handle_json(const std::string & json)
{
    std::stringstream ss;
    
    /**
     * Example:
     * {"message":"Success","status":0,"envelope":"eyJ0..."}
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
        
        result["envelope"] = pt.get<std::string> (
            "envelope", ""
        );
        
        if (result["status"] == "0")
        {
            if (result["envelope"].size() > 0)
            {
                /**
                 * Base64 decode the envelope.
                 * Example:
                 *  {
                 *      "type":"application\/json",
                 *      "value":"eyJ1IjoiZ3Jh...I6IjAifQ==",
                 *      "signature":
                 *      {
                 *          "uri":"",
                 *          "digest":"sha512",
                 *          "value":"3SOGROqjk...YqaXefY="
                 *      }
                 *  }
                 */
                std::string envelope = crypto::base64_decode(
                    result["envelope"].data(), result["envelope"].size()
                );
    
                /**
                 * Get the envelope value.
                 */
                std::string value = handle_json_envelope(envelope);
                
                /**
                 * Base64 decode the credentials.
                 */
                std::string credentials = crypto::base64_decode(
                    value.data(), value.size()
                );
                
                if (credentials.size() > 0)
                {
                    std::cout <<
                        "Authentication manager sign in success, message = " <<
                        result["message"] << "." <<
                    std::endl;
                    
                    result["envelope"] = envelope;
                }
                else
                {
                    result["status"] = "-1";
                    result["message"] = "invalid envelope";
                }
            }
            else
            {
                std::cout <<
                    "Authentication manager sign in success, message = " <<
                    result["message"] << "." <<
                std::endl;
            }
        }
        else
        {
            std::cerr <<
                "Authentication manager sign in failure, message = " <<
                result["message"] << ", status = " << result["status"] << "." <<
            std::endl;
        }
    }
    catch (std::exception & e)
    {
        std::cerr <<
            "Authentication manager sign in failure, what = " <<
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

std::string authentication_manager::handle_json_envelope(
    const std::string & envelope
    )
{
    /**
     * Allocate the json_envelope.
     */
    json_envelope env("remove this", envelope);
    
    /**
     * Decode the json_envelope.
     */
    env.decode();
    
    if (env.verify(credentials_manager::ca_rsa()->pub()))
    {
        return env.value();
    }

    return std::string();
}
