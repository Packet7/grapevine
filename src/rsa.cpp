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
#include <iostream>
#include <memory>
#include <sstream>

#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/ssl.h>

#include <grapevine/rsa.hpp>

using namespace grapevine;

static std::mutex * g_mutex = 0;

static int rsa_callback(int p, int n, BN_GENCB * arg)
{
    char c = 'B';

    if (p == 0)
	{
		c = '.';
	}
	
    if (p == 1)
	{
		c = '+';
	}
	
    if (p == 2)
	{
		c = '*';
	}
	
    if (p == 3)
	{
		c = '\n';
	}
    
    fputc(c, stderr);
    
    return 1;
}

static void locking_function(int mode, int n, const char * file, int line)
{
	if (mode & CRYPTO_LOCK)
    {
		g_mutex[n].lock();
    }
	else
    {
		g_mutex[n].unlock();
    }
}

static unsigned long id_function(void)
{
	std::ostringstream oss;
	oss << std::this_thread::get_id();
	std::hash<std::string> h;
	return ((unsigned long) h(oss.str()));
}

struct CRYPTO_dynlock_value
{
	std::mutex mutex;
};

static CRYPTO_dynlock_value * dyn_create_function(const char * file, int line)
{
	struct CRYPTO_dynlock_value * value = new CRYPTO_dynlock_value;
    
	if (!value)
    {
		return 0;
    }
    
	return value;
}

static void dyn_lock_function(
    int mode, CRYPTO_dynlock_value * l, const char * file, int line
    )
{
	if (mode & CRYPTO_LOCK)
    {
		l->mutex.lock();
    }
	else
    {
		l->mutex.unlock();
    }
}

static void dyn_destroy_function(
    CRYPTO_dynlock_value * l, const char * file, int line
    )
{
	delete l;
}

static int thread_setup()
{
	g_mutex = new std::mutex[CRYPTO_num_locks()];
    
	if (!g_mutex)
    {
		return 0;
    }
    
	CRYPTO_set_id_callback(id_function);
	CRYPTO_set_locking_callback(locking_function);
	CRYPTO_set_dynlock_create_callback(dyn_create_function);
	CRYPTO_set_dynlock_lock_callback(dyn_lock_function);
	CRYPTO_set_dynlock_destroy_callback(dyn_destroy_function);
	return 1;
}

static int thread_cleanup()
{
	if (!g_mutex)
    {
		return 0;
    }
    
	CRYPTO_set_id_callback(0);
	CRYPTO_set_locking_callback(0);
	CRYPTO_set_dynlock_create_callback(0);
	CRYPTO_set_dynlock_lock_callback(0);
	CRYPTO_set_dynlock_destroy_callback(0);
	delete [] g_mutex;
	g_mutex = 0;
	return 1;
}

rsa::rsa()
    : m_rsa(0)
    , m_pub(0)
    , m_pri(0)
{
    // ...
}

rsa::rsa(RSA * r)
    : m_rsa(r)
    , m_pub(0)
    , m_pri(0)
{
    // ...
}

rsa::~rsa()
{
    if (m_rsa)
    {
        RSA_free(m_rsa);
    }
    
    if (m_pub)
    {
        RSA_free(m_pub);
    }
    
    if (m_pri)
    {
        RSA_free(m_pri);
    }
}

void rsa::start()
{
	static bool g_init = false;

	if (!g_init)
	{
		g_init = true;
		SSL_library_init();
        OpenSSL_add_all_algorithms();
		SSL_load_error_strings();
		thread_setup();
	}
}

void rsa::stop()
{
    // ...
}

RSA * rsa::pub()
{
    return m_rsa ? m_rsa : m_pub;
}

void rsa::set_pub(RSA * r)
{
    m_pub = r;
}

void rsa::set_pri(RSA * r)
{
    m_pri = r;
}

RSA * rsa::pri()
{
    return m_rsa ? m_rsa : m_pri;
}

void rsa::generate_key_pair(const std::uint32_t & bits)
{
	thread_.reset(
		new std::thread(std::bind(&rsa::do_generate_key_pair, this, bits))
	);
}

void rsa::do_generate_key_pair(const std::uint32_t & bits)
{
    BN_GENCB cb;

    BIO * bio_err = 0;
    
    BN_GENCB_set(&cb, rsa_callback, bio_err);

    BIGNUM * e = BN_new();

    if (e)
    {
        if (BN_set_word(e, 65537))
        {
            m_rsa = RSA_new();

            if (m_rsa)
            {
                if (RSA_generate_key_ex(m_rsa, bits, e, &cb) == -1)
                {
                    RSA_free(m_rsa), m_rsa = 0;
                }
                else
                {
					if (m_on_generation && RSA_check_key(m_rsa))
					{
						m_on_generation();
					}
#if 0
					RSA_print_fp(stdout, m_rsa, 0);
#endif
                }
            }
        }

        BN_free(e);
    }

    if (!m_rsa)
    {
        std::cerr <<
            __FUNCTION__ << ": error = " <<
            ERR_error_string(ERR_get_error(), 0) <<
        std::endl;
    }

    thread_->detach();
	thread_.reset();
}

void rsa::set_on_generation(const std::function<void ()> & func)
{
	m_on_generation = func;
}

bool rsa::sign(
    RSA * r, const char * message_buf, const std::size_t & message_len,
    unsigned char * signature_buf, std::size_t & signature_len
    )
{
    const EVP_MD * m = EVP_get_digestbyname("sha512");
    EVP_MD_CTX ctx;
    unsigned char * digest = (unsigned char *)malloc(EVP_MAX_MD_SIZE);
    unsigned int digest_len;
    
    EVP_DigestInit(&ctx, m);
    EVP_DigestUpdate(&ctx, message_buf, message_len);
    EVP_DigestFinal(&ctx, digest, &digest_len);
    
    int ret = RSA_sign(
        NID_sha512, digest, digest_len, signature_buf,
        (unsigned int *)&signature_len, r
    );
    
    free(digest);
    
    if (!ret)
    {
		char reason[120];
		
		ERR_error_string(ERR_get_error(), reason);

        return false;
    }
    
    return ret == 1;
}

bool rsa::verify(
    RSA * r, const char * message_buf, const std::size_t & message_len,
    unsigned char * signature_buf, const std::size_t & signature_len
    )
{
    const EVP_MD * m = EVP_get_digestbyname("sha512");
    EVP_MD_CTX ctx;
    unsigned char * digest = (unsigned char *)malloc(EVP_MAX_MD_SIZE);
    unsigned int digest_len;
    
    EVP_DigestInit(&ctx, m);
    EVP_DigestUpdate(&ctx, message_buf, message_len);
    EVP_DigestFinal(&ctx, digest, &digest_len);

    int ret = RSA_verify(
        NID_sha512, digest, digest_len, signature_buf, signature_len, r
    );
    
    free(digest);
    
    if (!ret)
    {
		char reason[120];
		
		ERR_error_string(ERR_get_error(), reason);

        return false;
    }
    
    return ret == 1;
}

int rsa::asn1_encode(RSA * key, char * dest, const std::size_t & dest_len)
{
	unsigned char * buf, * cp;
   
	int len = i2d_RSAPublicKey(key, 0);
   
   	if (len < 0 || len > (int)dest_len)
   	{
		return -1;
   	}
    
    cp = buf = new unsigned char[len + 1];
   
   	len = i2d_RSAPublicKey(key, &cp);
   
	if (len < 0)
	{
   		std::cerr << "Error asn1 encoding public key." << std::endl;
   		
   		delete buf, buf = 0;
   		
     	return -1;
   	}

	std::memcpy(dest, buf, len);
	
	delete buf, buf = 0;
	
	return len;
}
 
RSA * rsa::asn1_decode(const char * buf, const std::size_t & len)
{
	RSA * ret = 0;
	unsigned char * tmp;
	const unsigned char * cp;
	
	cp = tmp = new unsigned char[len];
 	
 	std::memcpy(tmp, buf, len);
 	
   	ret = d2i_RSAPublicKey(0, &cp, len);
   	
   	delete tmp, tmp = 0;
   	
  	if (!ret)
  	{
    	std::cout << "Error decoding asn1 public key." << std::endl;
    	
    	return 0;
   	}
   	
	return ret;
}

std::shared_ptr<rsa> rsa::public_from_pem(char * buf)
{
    RSA * ret = 0;
    
    BIO * bio = BIO_new_mem_buf(buf, -1);
    
    if (!bio)
    {
        ERR_print_errors_fp(stdout);
        
        return std::shared_ptr<rsa> ();
    }

    X509 * x = PEM_read_bio_X509(bio, 0, 0, 0);
    
    BIO_free(bio);
    
    if (!x)
    {
        ERR_print_errors_fp(stdout);
        
        return std::shared_ptr<rsa> ();
    }

    EVP_PKEY * pkey = X509_get_pubkey(x);
    
    X509_free(x);
    
    if (!pkey)
    {
        ERR_print_errors_fp(stdout);
        
        return std::shared_ptr<rsa> ();
    }
    
    ret = EVP_PKEY_get1_RSA(pkey);
    
    EVP_PKEY_free(pkey);
    
    if (!ret)
    {
        ERR_print_errors_fp(stdout);
        
        return std::shared_ptr<rsa> ();
    }
    
    return std::make_shared<rsa> (ret);
}

std::shared_ptr<rsa> rsa::private_from_pem(char * buf)
{
    RSA * ret = 0;
    
    BIO * bio = BIO_new_mem_buf(buf, -1);
    
    if (!bio)
    {
        ERR_print_errors_fp(stdout);
        
        return std::shared_ptr<rsa> ();
    }

    EVP_PKEY * pkey = PEM_read_bio_PrivateKey(bio, 0, 0, 0);
    
    BIO_free(bio);
    
    if (!pkey)
    {
        ERR_print_errors_fp(stdout);
        
        return std::shared_ptr<rsa> ();
    }

    ret = EVP_PKEY_get1_RSA(pkey);
    
    EVP_PKEY_free(pkey);
    
    if (!ret)
    {
        ERR_print_errors_fp(stdout);
        
        return std::shared_ptr<rsa> ();
    }
    
    return std::make_shared<rsa> (ret);
}

void rsa::write_to_path(
	RSA * key, const bool & is_public, const std::string & path
	)
{
	assert(key);
	
	FILE * fp;
	EVP_CIPHER * enc = 0;
	
	fp = fopen(path.c_str() , "w");

	if (fp)
	{
		if (is_public)
		{
			PEM_write_RSAPublicKey(fp, key);
		}
		else
		{
			PEM_write_RSAPrivateKey(fp, key, enc, 0, 0, 0, 0);
		}
		
        fflush(fp);
		fclose(fp);
	}
	else
	{
		throw std::runtime_error("failed to open file for writing");
	}
}

RSA * rsa::read_from_path(
    const bool & is_public, const std::string & path
    )
{
	RSA * rsa = 0;
	FILE * fp;
	
	fp = fopen(path.c_str() , "r");

	if (fp)
	{
		if (is_public)
		{
			PEM_read_RSAPublicKey(fp, &rsa, 0, 0);
#if 0
            if (rsa)
            {
                RSA_print_fp(stdout, rsa, 0);
            }
#endif
		}
		else
		{
			PEM_read_RSAPrivateKey(fp, &rsa, 0, 0);
#if 0
            if (rsa)
            {
                RSA_print_fp(stdout, rsa, 0);
            }
#endif
		}
		
		fclose(fp);
	}
	else
	{
		throw std::runtime_error("failed to open file for reading");
	}
	
	return rsa;
}

int rsa::seal(
    RSA * key, unsigned char ** ek, int * ekl,
    const char * in, int inl, char * out, int * outl
    )
{
    int ret = -1;
    
    EVP_CIPHER_CTX ctx;
    
    EVP_PKEY ** keys = (EVP_PKEY **)malloc(sizeof(EVP_PKEY) * 1);

    keys[0] = EVP_PKEY_new();
    
    EVP_PKEY_set1_RSA(keys[0], key);
    
    EVP_SealInit(&ctx, EVP_rc4(), ek, ekl, 0 /* iv */, keys, 1);

    EVP_SealUpdate(
        &ctx, (unsigned char *)out, outl, (const unsigned char *)in, inl
    );
    
    ret = EVP_SealFinal(&ctx, (unsigned char *)out, outl);
    
    EVP_PKEY_free(keys[0]);
    
    return ret;
}

int rsa::run_test()
{
    return 0;
}
