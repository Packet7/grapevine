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

#ifndef GRAPEVINE_RSA_HPP
#define GRAPEVINE_RSA_HPP

#include <cstdint>
#include <mutex>
#include <string>
#include <thread>

#include <openssl/rsa.h>

namespace grapevine {

    class rsa
    {
        public:
        
            /**
             * Constrcutor
             */
            rsa();
        
            /**
             * Constrcutor
             * @param r The RSA.
             */
            rsa(RSA *);
        
            /**
             * Destructor
             */
            ~rsa();
        
            /**
             * Starts
             */
            void start();
        
            /**
             * Stops
             */
            void stop();
        
            void set_pub(RSA * r);
        
            RSA * pub();
        
            void set_pri(RSA * r);
        
            RSA * pri();
        
            bool operator == (rsa & rhs)const
            {
                return BN_cmp(m_pub->n, rhs.pub()->n) == 0;
            }
        
            /**
             * Generates an RSA key/pair.
             * @param bits
             */
            void generate_key_pair(const std::uint32_t &);
			
			/**
			 * Set the generation handler.
			 * @param f The function.
			 */
			void set_on_generation(const std::function<void ()> &);
			
            /**
             * Computes a signature over the given message.
             * @param r
             * @param message_buf
             * @param message_len
             * @param signature_buf
             * @param signature_len
             */
            static bool sign(
                RSA *, const char *, const std::size_t &, unsigned char *,
                std::size_t &
            );
            
            /**
             * Performs signature verification over the given message.
             * @param r
             * @param message_buf
             * @param message_len
             * @param signature_buf
             * @param signature_len
             */
            static bool verify(
                RSA *, const char *, const std::size_t &, unsigned char *,
                const std::size_t &
            );
        
            /**
             *
             *
             */
            static int asn1_encode(
                RSA * key, char * dest, const std::size_t & dest_len
            );
        
            /**
             *
             * @note Caller is responsible for freeing return value.
             */
            static RSA * asn1_decode(const char * buf, const std::size_t & len);

            static std::shared_ptr<rsa> public_from_pem(char * buf);

            static std::shared_ptr<rsa> private_from_pem(char * buf);

            static void write_to_path(
                RSA * key, const bool & is_public, const std::string & path
            );
        
            static RSA * read_from_path(
                const bool & is_public, const std::string & path
            );
        
            static int seal(
                RSA * key, unsigned char ** ek, int * ekl,
                const char * in, int inl, char * out, int * outl
            );
    
            /**
             * Runs the test case.
             */
            static int run_test();
			
        private:
        
            /**
             * Generates an RSA key/pair.
             * @param bits The number of bits.
             */
            void do_generate_key_pair(const std::uint32_t &);
			
			/**
			 * The generation handler.
			 */
			std::function<void ()> m_on_generation;
        
            /**
             * The rsa.
             */
            RSA * m_rsa;
        
            /**
             * The rsa public portion.
             */
            RSA * m_pub;
        
            /**
             * The rsa private portion.
             */
            RSA * m_pri;
        
        protected:
			
			/**
			 * The generation thread.
			 */
			std::shared_ptr<std::thread> thread_;
    };
    
} // namespace grapevine

#endif // GRAPEVINE_RSA_HPP
