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

#include <future>
#include <iostream>

#include <database/query.hpp>

#include <grapevine/authentication_manager.hpp>
#include <grapevine/credentials_manager.hpp>
#include <grapevine/crypto.hpp>
#include <grapevine/filesystem.hpp>
#include <grapevine/http_transport.hpp>
#include <grapevine/logger.hpp>
#include <grapevine/profile_manager.hpp>
#include <grapevine/publish_manager.hpp>
#include <grapevine/sign_up_operation.hpp>
#include <grapevine/stack.hpp>
#include <grapevine/stack_impl.hpp>
#include <grapevine/subscription_manager.hpp>
#include <grapevine/uri.hpp>
#include <grapevine/version_manager.hpp>

using namespace grapevine;

stack_impl::stack_impl(grapevine::stack & owner)
    : database::stack()
    , strand_(io_service_)
    , stack_(owner)
{
    // ...
}

void stack_impl::start(const std::uint16_t & port)
{
    database::stack::configuration config;
 
    config.set_port(port);
    config.set_operation_mode(
        database::stack::configuration::operation_mode_interface
    );
    
    std::vector< std::pair<std::string, std::uint16_t> > contacts;
#if 1
    // windows 1
    contacts.push_back(std::make_pair("23.31.159.163", 40102));
    contacts.push_back(std::make_pair("23.31.159.163", 40104));
    // windows 2
    contacts.push_back(std::make_pair("23.31.159.164", 40102));
    contacts.push_back(std::make_pair("23.31.159.164", 40104));
    // windows 3
    contacts.push_back(std::make_pair("23.31.159.165", 40102));
    contacts.push_back(std::make_pair("23.31.159.165", 40104));
#else // testing
    contacts.push_back(std::make_pair("23.31.159.168", 40002));
    contacts.push_back(std::make_pair("23.31.159.168", 40004));
    contacts.push_back(std::make_pair("23.31.159.168", 40006));
    contacts.push_back(std::make_pair("23.31.159.168", 40008));
    contacts.push_back(std::make_pair("23.31.159.168", 40010));
    contacts.push_back(std::make_pair("23.31.159.168", 40012));
    contacts.push_back(std::make_pair("23.31.159.168", 40014));
#endif
    database::stack::start(config);
    
    database::stack::join(contacts);
}

void stack_impl::sign_up(
    const std::map<std::string, std::string> & url_params,
    const std::function<void (const std::map<std::string, std::string> & pairs)> & f
    )
{
    if (sign_up_operation_)
    {
        // ...
    }
    else
    {
        sign_up_operation_.reset(new sign_up_operation(*this));
    }
    
    std::async(std::launch::async,
        [this, url_params, f] ()
    {
        if (sign_up_operation_)
        {
            sign_up_operation_->start(url_params, f);
        }
    });
}

void stack_impl::sign_in(
    const std::string & username, const std::string & password
    )
{    
    /**
     * Set the username.
     */
    m_username = username;
    
    /**
     * Set the password.
     */
    m_password = password;
    
    try
    {
        create_directories();
    }
    catch (std::exception & e)
    {
        log_error(
            "Stack failed to create directories, what = " << e.what() << "."
        );
    }
    
    /**
     * Allocate the credentials_manager.
     */
    credentials_manager_.reset(new credentials_manager(io_service_, *this));

    /**
     * Set the on started handler.
     */
    credentials_manager_->set_on_started(
        std::bind(&stack_impl::credentials_manager_on_started, this)
    );

    /**
     * Start the credentials_manager.
     */
    credentials_manager_->start();
}

void stack_impl::sign_out()
{
    work_.reset();

    if (credentials_manager_)
    {
        credentials_manager_->stop();
    }
    
    // authentication_manager_->stop();
    
    if (profile_manager_)
    {
        profile_manager_->stop();
    }
    
    if (publish_manager_)
    {
        publish_manager_->stop();
    }
    
    if (subscription_manager_)
    {
        subscription_manager_->stop();
    }
    
    if (version_manager_)
    {
        version_manager_->stop();
    }
    
    authentication_manager_.reset();
    credentials_manager_.reset();
    profile_manager_.reset();
    publish_manager_.reset();
    subscription_manager_.reset();
    version_manager_.reset();
    
    m_username.clear();
    m_password.clear();
    
    try
    {
        if (thread_.joinable())
        {
            //thread_.join();
        }
    
    }
    catch (std::exception & e)
    {
        thread_.detach();
        
        std::cerr << e.what() << std::endl;
    }
}

const std::map<std::string, std::string> & stack_impl::profile() const
{
    if (profile_manager_)
    {
        return profile_manager_->profile();
    }
    
    static std::map<std::string, std::string> ret;
    
    return ret;
}

const std::vector<std::string> stack_impl::subscriptions() const
{
    std::vector<std::string> ret;
    
    if (subscription_manager_)
    {
        for (auto & i : subscription_manager_->subscriptions())
        {
            ret.push_back(i.first);
        }
    }

    return ret;
}

void stack_impl::url_get(
    const std::string & url,
    const std::function<void (const std::map<std::string, std::string> &,
    const std::string &)> & f
    )
{
    std::shared_ptr<http_transport> t =
        std::make_shared<http_transport>(io_service_, url)
    ;

    t->start(
        [this, f](
        boost::system::error_code ec, std::shared_ptr<http_transport> t)
    {
        if (ec)
        {
            f(std::map<std::string, std::string> (), std::string());
		}
		else
		{
            f(t->headers(), t->response_body());
		}
	});
}

void stack_impl::url_post(
    const std::string & url,
    const std::map<std::string, std::string> & headers,
    const std::string & body,
    const std::function<void (const std::map<std::string, std::string> &,
    const std::string &)> & f
    )
{
    std::shared_ptr<http_transport> t =
        std::make_shared<http_transport>(io_service_, url)
    ;

    t->headers() = headers;
    
    t->set_request_body(body);
    
    t->start(
        [this, f](
        boost::system::error_code ec, std::shared_ptr<http_transport> t)
    {
        if (ec)
        {
            f(std::map<std::string, std::string> (), std::string());
		}
		else
		{
            f(t->headers(), t->response_body());
		}
	});
}

void stack_impl::subscribe(const std::string & username)
{
    if (subscription_manager_)
    {
        subscription_manager_->subscribe(username);
    }
}

void stack_impl::unsubscribe(const std::string & username)
{
    if (subscription_manager_)
    {
        subscription_manager_->unsubscribe(username);
    }
}

bool stack_impl::is_subscribed(const std::string & username)
{
    if (subscription_manager_)
    {
        return subscription_manager_->is_subscribed(username);
    }
    
    return false;
}

void stack_impl::update()
{
    assert(0);
}

std::vector<std::string> split(const std::string & s, char seperator)
{
   std::vector<std::string> output;

    std::string::size_type prev_pos = 0, pos = 0;

    while ((pos = s.find(seperator, pos)) != std::string::npos)
    {
        std::string substring(s.substr(prev_pos, pos - prev_pos));

        output.push_back(substring);

        prev_pos = ++pos;
    }

    output.push_back(s.substr(prev_pos, pos-prev_pos));

    return output;
}

std::uint16_t stack_impl::post(const std::string & message)
{
    if (publish_manager_)
    {
        return publish_manager_->publish(
            message, std::time(0), publish_manager::expire_time
        );
    }
    
    return 0;
}

std::uint16_t stack_impl::update_profile(
    const std::map<std::string, std::string> & profile
    )
{
    if (profile_manager_)
    {
        /**
         * Set the profile.
         */
        profile_manager_->set_profile(profile);
        
        /** 
         * Perform a publish operation.
         */
        return profile_manager_->do_publish();
    }
    
    return 0;
}

void stack_impl::on_connected(const char * addr, const std::uint16_t & port)
{
    stack_.on_connected(addr, port);
}

void stack_impl::on_disconnected(const char * addr, const std::uint16_t & port)
{
    stack_.on_disconnected(addr, port);
}

void stack_impl::on_find(
    const std::uint16_t & transaction_id, const std::string & query_string
    )
{
#define IGNORE_UNVERIFIED_QUERIES 0

    std::lock_guard<std::recursive_mutex> l(mutex_);
    
    /**
     * Allocate the query.
     */
    database::query q(query_string);
    
    /**
     * c = credentials
     * u = user
     * m = message
     * a = age
     * g = gender
     * l = location
     * p = photo
     * d = description
     * f = fullname
     * w = web
     * t = timestamp
     * Message:
     * u=luke&m=I%20took%20the%20cat%20to%20the%20vet%20today.
     * &kittens=kittens&cats=cats&animals=animals
     * Profile:
     * u=luke&f=Luke%20Skywalker&a=26&g=m&l=0&p=http://foo.com/me.png&d=Jedi%20Knight
     */
    
    /**
     * Check that it is a message or profile or credentials.
     */
    if (
        q.pairs().find("u") != q.pairs().end() &&
        q.pairs().find("m") != q.pairs().end()
        )
    {
        std::map<std::string, std::string> pairs;
        
        std::vector<std::string> tags;
        
        for (auto & i : q.pairs())
        {
            if (i.first == "u" || i.first == "m")
            {
                continue;
            }
            
            if (
                i.first == "lifetime" || i.first == "expires" ||
                i.first[0] == '_'
                )
            {
                // ...
            }
            else
            {
                tags.push_back(i.second);
            }
        }
        
        pairs["u"] = q.pairs()["u"];
        pairs["m"] = q.pairs()["m"];
        pairs["__s"] = q.pairs()["__s"];
        pairs["__t"] = q.pairs()["__t"];
        
        if (q.pairs().find("__t") != q.pairs().end())
        {
            pairs["__t"] = q.pairs()["__t"];
        }
        
        if (q.pairs().find("_l") != q.pairs().end())
        {
            pairs["_l"] = q.pairs()["_l"];
        }
        
        if (q.pairs().find("_e") != q.pairs().end())
        {
            pairs["_e"] = q.pairs()["_e"];
        }
        
        if (credentials_manager_)
        {
            std::string query = query_string;
            
            auto i = query.find_first_of("_");
            
            if (i != std::string::npos)
            {
                query = query.substr(0, i - 1);
            }

            std::string signature = q.pairs()["__s"];
            
            signature = uri::decode(crypto::base64_decode(
                signature.data(), signature.size())
            );

            if (
                credentials_manager_->verify(q.pairs()["u"], query, signature)
                )
            {
                pairs["__v"] = "1";
            }
            else
            {
                log_debug(
                    "**************** MESSAGE VERIFICATION FAILED: " <<
                    q.pairs()["u"]
                );

#if (defined IGNORE_UNVERIFIED_QUERIES && IGNORE_UNVERIFIED_QUERIES)
                return;
#else
                pairs["__v"] = "0";
#endif // IGNORE_UNVERIFIED_QUERIES
            }
        }
        /**
         * Callback
         */
        stack_.on_find_message(transaction_id, pairs, tags);

        // :TODO: Consider queueing these.
        
        /**
         * If the publication is ours, republish it.
         */
        if (m_username == q.pairs()["u"])
        {
            std::time_t timestamp = std::atoi(q.pairs()["__t"].c_str());
            std::time_t lifetime = std::atoi(q.pairs()["_e"].c_str());
            
            if (publish_manager_)
            {
                publish_manager_->publish(q.pairs()["m"], timestamp, lifetime);
            }
        }
    }
    else if (
        q.pairs().find("u") != q.pairs().end() &&
        q.pairs().find("c") != q.pairs().end()
        )
    {
        log_debug(
            "Stack found credentials for " << q.pairs()["u"] << "."
        );
        
        credentials_manager_->on_find(q.pairs());
    }
    else if (q.pairs().find("u") != q.pairs().end())
    {
        std::map<std::string, std::string> pairs;
        
        /**
         * a = age
         * b = bio
         * f = fullname
         * g = gender
         * l = location
         * p = photo
         * u = username
         */
        pairs["b"] = q.pairs()["b"];
        pairs["u"] = q.pairs()["u"];
        pairs["a"] = q.pairs()["a"];
        pairs["g"] = q.pairs()["g"];
        pairs["l"] = q.pairs()["l"];
        pairs["p"] = q.pairs()["p"];
        pairs["f"] = q.pairs()["f"];
        pairs["__t"] = q.pairs()["__t"];
        pairs["_e"] = q.pairs()["_e"];
        
        if (credentials_manager_)
        {
            std::string query = query_string;
            
            auto i = query.find_first_of("_");
            
            if (i != std::string::npos)
            {
                query = query.substr(0, i - 1);
            }
            
            std::string signature = q.pairs()["__s"];
            
            signature = uri::decode(crypto::base64_decode(
                signature.data(), signature.size())
            );
            
            if (
                credentials_manager_->verify(q.pairs()["u"], query, signature)
                )
            {
                pairs["__v"] = "1";
            }
            else
            {
                log_debug(
                    "**************** PROFILE VERIFICATION FAILED: " <<
                    q.pairs()["u"]
                );
                
#if (defined IGNORE_UNVERIFIED_QUERIES && IGNORE_UNVERIFIED_QUERIES)
                return;
#else
                pairs["__v"] = "0";
#endif // IGNORE_UNVERIFIED_QUERIES
            }
        }
        
        stack_.on_find_profile(transaction_id, pairs);
    }
}

void stack_impl::on_proxy(
    const std::uint16_t & tid, const char * addr,
    const std::uint16_t & port, const std::string & value
    )
{
    if (sign_up_operation_)
    {
        sign_up_operation_->on_proxy(tid, addr, port, value);
    }
    
    if (authentication_manager_)
    {
        authentication_manager_->on_proxy(tid, addr, port, value);
    }
    
    if (version_manager_)
    {
        version_manager_->on_proxy(tid, addr, port, value);
    }
}

void stack_impl::on_udp_receive(
    const char * addr, const std::uint16_t & port, const char * buf,
    const std::size_t & len
    )
{
    // ...
}

const std::string & stack_impl::username() const
{
    return m_username;
}

void stack_impl::create_directories()
{
    std::string path = filesystem::data_path() + m_username;
    
    log_info(
        "Stack creating path = " << path << "."
    );

    auto result = filesystem::create_path(path);
    
    if (result == 0 || result == filesystem::error_already_exists)
    {
        log_none("Stack, path already exists.");
    }
    else
    {
        throw std::runtime_error(
            "failed to create path " + filesystem::data_path()
        );
    }
}

void stack_impl::credentials_manager_on_started()
{
    /**
     * Reset the boost::asio::io_service.
     */
    io_service_.reset();
    
    /**
     * Allocate the boost::asio::io_service::work.
     */
    work_.reset(new boost::asio::io_service::work(io_service_));

    if (thread_.joinable())
    {
        thread_.join();
    }

    /**
     * Allocate the thread.
     */
    thread_ = std::thread(
        [this]()
        {
            for (;;)
            {
                try
                {
                    io_service_.run();
                    
                    if (!work_)
                    {
                        break;
                    }
                }
                catch (const boost::system::system_error & e)
                {
                    // ...
                }
            }
        }
    );
    
    /**
     * Allocate the authentication_manager.
     */
    authentication_manager_.reset(
        new authentication_manager(io_service_, *this)
    );

    /**
     * Allocate the version_manager.
     */
    version_manager_.reset(
        new version_manager(io_service_, *this)
    );
    
    /**
     * Get the base64 encoded der representation of the public certificate.
     */
    std::string base64_cert = credentials_manager_->base64_public_cert();
 
    /**
     * Sign into the network.
     */
    authentication_manager_->sign_in(
        m_username, m_password, base64_cert,
        [this] (std::map<std::string, std::string> result)
        {
            if (result.empty())
            {
                /**
                 * Callback
                 */
                stack_.on_sign_in("-1 unknown");
                
                /**
                 * Sign out.
                 */
                io_service_.post(
                    strand_.wrap(std::bind(&stack_impl::sign_out, this))
                );
            }
            else if (result["status"] == "0")
            {
                /**
                 * If the server returned a credentials envelope set it in the
                 * credentials manager.
                 * @note Remove this check once credentials are required.
                 */
                if (result.find("envelope") != result.end())
                {
                    credentials_manager_->set_credentials_envelope(
                        result["envelope"]
                    );
                    
                    /**
                     * Inform the credentials_manager to begin storing our
                     * credentials in the database.
                     */
                    credentials_manager_->store_credentials();
                }
                
                /**
                 * Allocate the profile_manager.
                 */
                profile_manager_.reset(new profile_manager(io_service_, *this));
                
                /**
                 * Allocate the publish_manager.
                 */
                publish_manager_.reset(
                    new publish_manager(io_service_, *this)
                );
                
                /**
                 * Allocate the subscription manager.
                 */
                subscription_manager_.reset(
                    new subscription_manager(io_service_, *this)
                );

                /**
                 * Callback
                 */
                stack_.on_sign_in(result["status"] + " " + result["message"]);
            
                /**
                 * Start the profile_manager.
                 */
                profile_manager_->start();
                
                /**
                 * Start the publish_manager.
                 */
                publish_manager_->start();
                
                /**
                 * Start the subscription_manager.
                 */
                subscription_manager_->start();
            }
            else /* Failure */
            {
                /**
                 * Callback
                 */
                stack_.on_sign_in(result["status"] + " " + result["message"]);
                
                /**
                 * Sign out.
                 */
                io_service_.post(
                    strand_.wrap(std::bind(&stack_impl::sign_out, this))
                );
            }
        }
    );
    
    /**
     * Start the version_manager.
     */
    version_manager_->start(
        [this] (std::map<std::string, std::string> result)
    {
        stack_.on_version(result);
    });
}
