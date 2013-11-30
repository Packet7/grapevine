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

#ifndef GRAPEVINE_HTTP_TRANSPORT_HPP
#define GRAPEVINE_HTTP_TRANSPORT_HPP

#include <chrono>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <sstream>

#if (defined __IPHONE_OS_VERSION_MAX_ALLOWED)
#import <CFNetwork/CFSocketStream.h>
#endif // __IPHONE_OS_VERSION_MAX_ALLOWED

#include <boost/asio.hpp>
#include <boost/asio/ssl.hpp>

namespace grapevine {

    class http_transport
        : public std::enable_shared_from_this<http_transport>
    {
        public:
        
            /**
             * Constructor
             * @param ios The boost::asio::io_service.
             * @param url The url.
             */
            explicit http_transport(
                boost::asio::io_service &, const std::string &
            );

            /**
             * Destructor
             */
            ~http_transport();
        
            /**
             * Starts the transport.
             * f The completion handler.
             */
            void start(
                const std::function<void (boost::system::error_code,
                std::shared_ptr<http_transport>)> &
            );
        
            /**
             * Stops the transport.
             */
            void stop();
        
            /**
             * If true the connection is secure.
             */
            const bool & secure() const;
        
            /**
             * The url.
             */
            const std::string & url() const;
        
            /**
             * The hostname.
             */
            const std::string & hostname() const;
        
            /**
             * The path.
             */
            const std::string & path() const;
        
            /**
             * The status code.
             */
            const std::int32_t & status_code() const;
        
            /**
             * The headers.
             */
            std::map<std::string, std::string> & headers();
        
            /**
             * Set the request body.
             * @param val The value.
             */
            void set_request_body(const std::string &);
        
            /**
             * The request body.
             */
            const std::string & request_body() const;
        
            /**
             * The response body.
             */
            const std::string response_body() const;

            /**
             * Runs the test case.
             */
            static int run_test();
        
        private:
        
            void do_connect(boost::asio::ip::tcp::resolver::iterator endpoint_iterator);
        
            void do_write(boost::asio::streambuf & buf);
        
            /**
             * If true the connection is secure.
             */
            bool m_secure;
        
            /**
             * The method.
             */
            std::string m_method;
        
            /**
             * The url.
             */
            std::string m_url;
        
            /**
             * The hostname.
             */
            std::string m_hostname;
        
            /**
             * The path.
             */
            std::string m_path;
        
            /**
             * The status code.
             */
            std::int32_t m_status_code;
        
            /**
             * The headers.
             */
            std::map<std::string, std::string> m_headers;
        
            /**
             * The request body.
             */
            std::string m_request_body;
        
            /**
             * The response body.
             */
            std::stringstream m_response_body;
        
            /**
             * The completion handler.
             */
            std::function<
                void (boost::system::error_code, std::shared_ptr<http_transport>)
            > m_on_complete;
        
        protected:
        
            /**
             * The maximum redirects.
             */
            enum { max_redirects = 10 };
            
            /**
             * Follows a redirect.
             */
            void follow_redirect(const std::string & url);
        
            /**
             * Parses the url into hostname, path and url parameters.
             */
            void parse_url();
        
            /**
             * Generates the request.
             */
            void generate_request();
        
            /**
             * Set's up the socket for VoIP operation on iOS.
             */
            void set_voip();
        
            /**
             * char2hex
             */
            std::string char2hex(char);
        
            /**
             * urlencode
             */
            std::string urlencode(const std::string &);
        
            /**
             * Handles the status line.
             */
            void handle_status_line();
        
            /**
             * Handles the headers.
             */
            void handle_headers();
        
            /**
             * Handles the body.
             */
            void handle_body();
        
            /**
             * The boost::asio::io_service.
             */
            boost::asio::io_service & io_service_;
        
            /**
             * The boost::asio::strand.
             */
            boost::asio::strand strand_;
        
            /**
             * The timeout timer.
             */
            boost::asio::basic_waitable_timer<
                std::chrono::steady_clock
            > timeout_timer_;
        
            /**
             * The ssl socket.
             */
            std::shared_ptr<
                boost::asio::ssl::stream<boost::asio::ip::tcp::socket>
            > ssl_socket_;
        
            /**
             * The request.
             */
            std::unique_ptr<boost::asio::streambuf> request_;
        
            /**
             * The response.
             */
            std::unique_ptr<boost::asio::streambuf> response_;
        
            /**
             * The number of redirects so far.
             */
            std::uint8_t redirects_;
#if (defined __IPHONE_OS_VERSION_MAX_ALLOWED)
            /**
             * Read and Write streams for background voip usage on iOS.
             */
            CFReadStreamRef readStreamRef_;
            CFWriteStreamRef writeStreamRef_;
#endif // __IPHONE_OS_VERSION_MAX_ALLOWED
    };
    
} // namespace grapevine

#endif // GRAPEVINE_HTTP_TRANSPORT_HPP
