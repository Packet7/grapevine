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

#include <grapevine/stack.hpp>
#include <grapevine/stack_impl.hpp>

using namespace grapevine;

stack::stack()
    : stack_impl_(0)
{
    // ...
}

void stack::start(const std::uint16_t & port)
{
    if (stack_impl_)
    {
        throw std::runtime_error("Stack is already allocated");
    }
    else
    {
        /**
         * Allocate the stack implementation.
         */
        stack_impl_ = new stack_impl(*this);
        
        /**
         * Start the stack implementation.
         */
        stack_impl_->start(port);
    }
}

void stack::stop()
{
    if (stack_impl_)
    {
        /**
         * Stop the stack implementation.
         */
        stack_impl_->stop();
        
        /**
         * Deallocate the stack implementation.
         */
        delete stack_impl_, stack_impl_ = 0;
    }
    else
    {
        throw std::runtime_error("Stack is not allocated");
    }
}

void stack::sign_up(
    const std::map<std::string, std::string> & url_params,
    const std::function<void (const std::map<std::string, std::string> & pairs)> & f
    )
{
    if (stack_impl_)
    {
        stack_impl_->sign_up(url_params, f);
    }
    else
    {
        throw std::runtime_error("Stack is not allocated");
    }
}

void stack::sign_in(
    const std::string & username, const std::string & password
    )
{
    if (stack_impl_)
    {
        stack_impl_->sign_in(username, password);
    }
    else
    {
        throw std::runtime_error("Stack is not allocated");
    }
}

void stack::sign_out()
{
    if (stack_impl_)
    {
        stack_impl_->sign_out();
    }
    else
    {
        throw std::runtime_error("Stack is not allocated");
    }
}

const std::string & stack::username() const
{
    if (stack_impl_)
    {
        return stack_impl_->username();
    }
    
    static std::string ret;
    
    return ret;
}

const std::map<std::string, std::string> & stack::profile() const
{
    if (stack_impl_)
    {
        return stack_impl_->profile();
    }
    
    static std::map<std::string, std::string> ret;
    
    return ret;
}

const std::vector<std::string> stack::subscriptions() const
{
    if (stack_impl_)
    {
        return stack_impl_->subscriptions();
    }
    
    return std::vector<std::string> ();
}

std::uint16_t stack::store(const std::string & query)
{
    if (stack_impl_)
    {
        return stack_impl_->store(query);
    }
    
    return 0;
}

std::uint16_t stack::find(
    const std::string & query, const std::size_t & max_results
    )
{
    if (stack_impl_)
    {
        return stack_impl_->find(query, max_results);
    }
    
    return 0;
}

void stack::url_get(
    const std::string & url,
    const std::function<void (const std::map<std::string, std::string> &,
    const std::string &)> & f
    )
{
    if (stack_impl_)
    {
        stack_impl_->url_get(url, f);
    }
}

void stack::url_post(
    const std::string & url,
    const std::map<std::string, std::string> & headers,
    const std::string & body,
    const std::function<void (const std::map<std::string, std::string> &,
    const std::string &)> & f
    )
{
    if (stack_impl_)
    {
        stack_impl_->url_post(url, headers, body, f);
    }
}

void stack::subscribe(const std::string & username)
{
    if (stack_impl_)
    {
        stack_impl_->subscribe(username);
    }
}

void stack::unsubscribe(const std::string & username)
{
    if (stack_impl_)
    {
        stack_impl_->unsubscribe(username);
    }
}

bool stack::is_subscribed(const std::string & username)
{
    if (stack_impl_)
    {
        return stack_impl_->is_subscribed(username);
    }
    
    return false;
}

void stack::update()
{
    if (stack_impl_)
    {
        stack_impl_->update();
    }
}

std::uint16_t stack::post(const std::string & message)
{
    if (stack_impl_)
    {
        return stack_impl_->post(message);
    }
    
    return 0;
}

std::uint16_t stack::update_profile(
    const std::map<std::string, std::string> & profile
    )
{
    if (stack_impl_)
    {
        return stack_impl_->update_profile(profile);
    }
    
    return 0;
}
