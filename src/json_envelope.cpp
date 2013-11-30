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

#include <grapevine/crypto.hpp>
#include <grapevine/json_envelope.hpp>
#include <grapevine/rsa.hpp>

using namespace grapevine;

json_envelope::json_envelope(
    const std::string & from, const std::string & json
    )
    : m_from(from)
    , m_json(json)
    , m_verified(false)
{
    // ...
}

json_envelope::json_envelope(const std::string & json)
    : m_signature_digest("sha256")
    , m_type("application/json")
    , m_value(json)
    , m_verified(false)
{
    // ...
}

void json_envelope::encode()
{
    /**
     * Put the type into property tree.
     */
    ptree_.put("type", m_type);

    /**
     * Base64 encode the value.
     */
    m_value = crypto::base64_encode(m_value.data(), m_value.size());
    
    /**
     * Put the value into property tree.
     */
    ptree_.put("value", m_value);
    
    /**
     * Put the uri into property tree.
     */
    ptree_.put("signature.uri", "");
    
    /**
     * Put the digest into property tree.
     */
    ptree_.put("signature.digest", m_signature_digest);
#if (! defined _MSC_VER)
    #warning :TODO: sign the envelope with non-null
#endif
    std::string signature = sign(0, m_value);
    
    /**
     * Calculate the signature value.
     */
    m_signature_value = crypto::base64_encode(
        signature.data(), signature.size()
    );
    
    /**
     * Put the signature into property tree.
     */
    ptree_.put("signature.value", m_signature_value);
    
    /**
     * The std::stringstream.
     */
    std::stringstream ss;
    
    /**
     * Write property tree to json file.
     */
    write_json(ss, ptree_, false);
    
    /**
     * Assign the json.
     */
    m_json = ss.str();
}
        
void json_envelope::decode()
{
    /**
     * Allocate the json.
     */
    std::stringstream json;
    
    /**
     * Read the json into the stream.
     */
    json << m_json;
    
    /**
     * Load the json stream and put it's contents into the property tree. If
     * reading fails an exception is thrown.
     */
    read_json(json, ptree_);
    
    /**
     * Get the type.
     */
    m_type = ptree_.get<std::string> ("type", "");
    
    /**
     * Get the value.
     */
    m_value = ptree_.get<std::string> ("value", "");
    
    /**
     * Base64 decode the value.
     */
    m_json = crypto::base64_decode(m_value.data(), m_value.size());
    
    /**
     * Get the signature uri.
     */
    m_signature_uri = ptree_.get<std::string> ("signature.uri", "");
    
    /**
     * Get the signature digest.
     */
    m_signature_digest = ptree_.get<std::string> ("signature.digest", "");
    
    /**
     * Get the signature value.
     */
    std::string signature_value = ptree_.get<std::string> ("signature.value", "");
    
    /**
     * Get the signature value.
     */
    m_signature_value = crypto::base64_decode(
        signature_value.data(), signature_value.size()
    );
    
    std::cout << " val = " << m_signature_value << ", size = " << m_signature_value.size() << "\n";
}

const std::string & json_envelope::json() const
{
    return m_json;
}

const std::string & json_envelope::type() const
{
    return m_type;
}

const std::string & json_envelope::value() const
{
    return m_value;
}

const std::string & json_envelope::signature_uri() const
{
    return m_signature_uri;
}

const bool & json_envelope::verified() const
{
    return m_verified;
}

bool json_envelope::verify(RSA * r)
{
    if (!m_verified)
    {
        /**
         * Verify the value.
         */
        m_verified = verify(r, m_value, m_signature_value);
    }
    
    return m_verified;
}

bool json_envelope::verify(
    RSA * r, const std::string & value, const std::string & signature
    )
{
    return rsa::verify(
        r, value.data(), value.size(),
        (unsigned char *)signature.data(),
        signature.size()
    );
}

std::string json_envelope::sign(RSA * r, const std::string & value)
{
    // :TODO:
    
    return false;
}
