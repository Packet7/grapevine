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

#ifndef GRAPEVINE_JSON_ENVELOPE_HPP
#define GRAPEVINE_JSON_ENVELOPE_HPP

#include <string>

#include <openssl/rsa.h>

#include <boost/property_tree/json_parser.hpp>

namespace grapevine {
    
    /**
     * Implements a json envelope.
     */
    class json_envelope
    {
        public:
        
            /**
             * Constructor
             */
            json_envelope();
        
            /**
             * Constructor
             * @param from The from.
             * @param json The JSON.
             */
            json_envelope(const std::string &, const std::string &);
        
            /**
             * Constructor
             * @param owner The stack.
             * @param json The JSON.
             */
            json_envelope(const std::string &);
        
            /**
             * Encodes
             */
            void encode();
        
            /**
             * Decodes
             */
            void decode();
        
            /**
             * The json.
             */
            const std::string & json() const;
        
            /**
             * The type.
             */
            const std::string & type() const;
        
            /**
             * The value.
             */
            const std::string & value() const;
        
            /**
             * The signature uri.
             */
            const std::string & signature_uri() const;
        
            /**
             * If true the contents have been verified.
             */
            const bool & verified() const;
        
            /**
             * Verifies the signature.
             * @param r The rsa.
             */
            bool verify(RSA * r);
        
        private:

            /**
             * Verifies the signature.
             * @param r The rsa.
             * @param value The value to verify.
             * @param signature The signature.
             */
            bool verify(RSA * r, const std::string &, const std::string &);
        
            /**
             * Signs the envelope.
             * @param r The rsa.
             * @param value The value.
             */
            std::string sign(RSA * r, const std::string &);
        
            /**
             * The from.
             */
            std::string m_from;
        
            /**
             * The JSON.
             */
            std::string m_json;
        
            /**
             * The type.
             */
            std::string m_type;
        
            /**
             * The value.
             */
            std::string m_value;
        
            /**
             * The signature uri.
             */
            std::string m_signature_uri;
        
            /**
             * The signature digest.
             */
            std::string m_signature_digest;
        
            /**
             * The signature value.
             */
            std::string m_signature_value;
        
            /**
             * If true the contents have been verified.
             */
            bool m_verified;
        
        protected:
        
            /**
             * The boost::property_tree::ptree.
             */
            boost::property_tree::ptree ptree_;
    };
    
} // namespace grapevine

#endif // GRAPEVINE_JSON_ENVELOPE_HPP
