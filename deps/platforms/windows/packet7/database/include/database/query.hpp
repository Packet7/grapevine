/**
 * Copyright 2013 Packet7, LLC.
 */

#ifndef database_query_hpp
#define database_query_hpp

#include <map>
#include <string>

namespace database {

    class query
    {
        public:
        
            /**
             * Constructor
             * @param val The value.
             */
            explicit query(const std::string & val);
        
            /**
             * The query string.
             */
            const std::string & str() const;

            /**
             * The kay/value pairs.
             */
            std::map<std::string, std::string> & pairs();
        
        private:
        
            /**
             * URI decodes.
             * @param val The value.
             */
            static std::string uri_decode(const std::string &);
        
            /**
             * URI encodes.
             * @param val The value.
             */
            static std::string uri_encode(const std::string &);
        
            /**
             * The query string.
             */
            std::string m_str;
        
            /**
             * The kay/value pairs.
             */
            std::map<std::string, std::string> m_pairs;
        
        protected:
        
            // ...
    };
    
} // namespace database

#endif // database_query_hpp
