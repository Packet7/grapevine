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

#include <cassert>

#include <grapevine/certificates.hpp>
#include <grapevine/credentials_manager.hpp>
#include <grapevine/crypto.hpp>
#include <grapevine/json_envelope.hpp>
#include <grapevine/filesystem.hpp>
#include <grapevine/logger.hpp>
#include <grapevine/stack_impl.hpp>
#include <grapevine/uri.hpp>

using namespace grapevine;

std::shared_ptr<rsa> credentials_manager::m_ca_rsa = rsa::public_from_pem(
    certificates::ca_public_pem
);

credentials_manager::credentials_manager(
    boost::asio::io_service & ios, stack_impl & owner
    )
    : stack_impl_(owner)
    , io_service_(ios)
    , strand_(ios)
    , store_credentials_timer_(ios)
{
    // ...
}

void credentials_manager::start()
{
    assert(m_ca_rsa);
    
    RSA * pub = 0;
    RSA * pri = 0;
    
    try
    {
        pub = rsa::read_from_path(
            true, filesystem::data_path() +
            stack_impl_.username() + "/public.pem"
        );
    }
    catch (std::exception & e)
    {
        // ...
    }
    
    try
    {
        pri = rsa::read_from_path(
            false, filesystem::data_path() +
            stack_impl_.username() + "/private.pem"
        );
    }
    catch (std::exception & e)
    {
        // ...
    }
    
    if (pub && pri)
    {
        /**
         * Allocate the rsa.
         */
        rsa_ = std::make_shared<rsa>();
        
        /**
         * Start the rsa.
         */
        rsa_->start();
        
        /**
         * Set the public portion.
         */
        rsa_->set_pub(pub);
        
        /**
         * Set the private portion.
         */
        rsa_->set_pri(pri);
        
        if (m_on_started)
        {
            m_on_started();
        }
    }
    else
    {    
        /**
         * Allocate the rsa.
         */
        rsa_ = std::make_shared<rsa>();
        
        /** 
         * Set the on generation callback.
         */
        rsa_->set_on_generation(
            std::bind(&credentials_manager::rsa_on_generation, this)
        );
        
        /**
         * Start the rsa.
         */
        rsa_->start();
        
        /**
         * Generate a 1024-bit key/pair.
         */
        rsa_->generate_key_pair(1024);
    }
}

void credentials_manager::stop()
{
    store_credentials_timer_.cancel();
    
    /**
     * Stop the rsa.
     */
    if (rsa_)
    {
        rsa_->stop();
    }
}

void credentials_manager::on_find(
    std::map<std::string, std::string> & pairs
    )
{
    auto u = pairs["u"];
    auto c = uri::decode(
        crypto::base64_decode(pairs["c"].data(), pairs["c"].size())
    );
    
    json_envelope env(u, c);
    
    env.decode();
    
    if (env.verify(m_ca_rsa->pri()))
    {
        std::string json_credentials = env.json();
        
        std::stringstream ss;
        
        ss << json_credentials;
        
        try
        {
            /**
             * Allocate empty property tree object.
             */
            boost::property_tree::ptree pt;
            
            read_json(ss, pt);
            
            /**
             * Get u from the property tree.
             */
            auto u = pt.get<std::string> ("u");
            
            /**
             * Get c from the property tree
             */
            auto c = pt.get<std::string> ("c");
            
            /**
             * Get e from the property tree
             */
            auto e = pt.get<std::string> ("e");
            
            (void)e;
            
            /**
             * Base64 decode the credentials.
             */
            c = crypto::base64_decode(c.data(), c.size());
            
            /**
             * ASN1 decode the credentials.
             */
            auto rsa_pub = std::make_shared<rsa> (
                rsa::asn1_decode(c.data(), c.size())
            );
            
            assert(rsa_pub->pub());
            
            /**
             * Retain the credentials.
             */
            auto it = m_credentials.find(u);
            
            if (it == m_credentials.end())
            {
                std::vector< std::shared_ptr<rsa> > rsa_pubs;
                
                rsa_pubs.push_back(rsa_pub);
                
                m_credentials.insert(std::make_pair(u, rsa_pubs));
            }
            else
            {
                /**
                 * Check to make sure the rsa doesn't already exist.
                 */
                bool found = false;
                
                for (auto & i : it->second)
                {
                    if (i == rsa_pub)
                    {
                        found = true;
                        break;
                    }
                }
                
                if (!found)
                {
                    it->second.push_back(rsa_pub);
                }
            }
        }
        catch (std::exception & e)
        {
            log_error(
                "Credentials manager, what = " << e.what() << "."
            ); 
        }
    }
    else
    {
        // :FIXME: log error, ca verify failed
        assert(0);
    }
}

void credentials_manager::set_on_started(const std::function<void ()> & f)
{
    m_on_started = f;
}

std::string credentials_manager::base64_public_cert()
{
    std::string ret;
    
    /**
     * Allocate the certificate buffer (DER).
     */
    char buf[1024];
    
    /**
     * Encode the certificate (asn1/DER).
     */
    int len = rsa::asn1_encode(rsa_->pub(), buf, sizeof(buf));

    assert(len < sizeof(buf));
    
    /**
     * Base64 encode the certificate.
     */
    ret = crypto::base64_encode(buf, len);
    
    return ret;
}

std::string credentials_manager::sign(const std::string & val)
{
    std::string ret;

    /**
     * Get the signature length.
     */
    std::size_t signature_length = RSA_size(rsa_->pri());
    
    /**
     * Allocate the signature.
     */
    ret.resize(signature_length);
    
    /**
     * Calculate the signature.
     */
    rsa::sign(
        rsa_->pri(), val.data(), val.size(),
        reinterpret_cast<unsigned char *> (const_cast<char *> (
        ret.data())), signature_length
    );

    return ret;
}

bool credentials_manager::verify(
    const std::string & username, const std::string & query,
    const std::string & signature
    )
{
    bool ret = false;
    
    auto it = m_credentials.find(username);
    
    if (it != m_credentials.end())
    {
        for (auto & i : it->second)
        {
            if (
                rsa::verify(i->pub(), query.data(), query.size(),
                reinterpret_cast<unsigned char *> (const_cast<char *> (
                signature.data())), signature.size())
                )
            {
                ret = true;
                
                break;
            }
        }
    }

    return ret;
}

std::shared_ptr<rsa> & credentials_manager::ca_rsa()
{
    return m_ca_rsa;
}

void credentials_manager::set_credentials_envelope(const std::string & val)
{
    m_credentials_envelope = val;
}
        
const std::string & credentials_manager::credentials_envelope() const
{
    return m_credentials_envelope;
}

void credentials_manager::store_credentials()
{
    /**
     * Store the credentials.
     */
    std::string query;
    
    /**
     * The username.
     */
    query += "u=" + stack_impl_.username();
    
    /**
     * The message.
     */
    query += "&c=" + uri::encode(crypto::base64_encode(
        m_credentials_envelope.data(), m_credentials_envelope.size())
    );
    
    /**
     * Sign the query.
     * __s = signature
     */
    std::string signature = sign(query);
    
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

    /**
     * Store the query.
     */
    stack_impl_.store(query);

    auto self(shared_from_this());

    store_credentials_timer_.expires_from_now(std::chrono::seconds(3600));
    store_credentials_timer_.async_wait(
        strand_.wrap(
            [this, self](boost::system::error_code ec)
            {
                if (ec)
                {
                    // ...
                }
                else
                {
                    store_credentials();
                }
            }
        )
    );
}

void credentials_manager::rsa_on_generation()
{
    rsa::write_to_path(
        rsa_->pub(), true, filesystem::data_path() +
        stack_impl_.username() + "/public.pem"
    );
    rsa::write_to_path(
        rsa_->pri(), false, filesystem::data_path() +
        stack_impl_.username() + "/private.pem"
    );
    
    if (m_on_started)
    {
        m_on_started();
    }
}
