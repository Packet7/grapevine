
#ifndef DATABASE_STACK_HPP
#define DATABASE_STACK_HPP

#include <cstdint>
#include <list>
#include <string>
#include <vector>

namespace database {

    class stack_impl;
    
    /**
     * The stack.
     */
    class stack
    {
        public:
        
            /**
             * The configuration.
             * @param port The listen port.
             */
            class configuration
            {
                public:
                
                    /**
                     * The operation modes.
                     */
                    typedef enum operation_modes
                    {
                        operation_mode_interface,
                        operation_mode_storage,
                    } operation_mode_t;
                
                    /**
                     * Constructor
                     */
                    configuration()
                        : m_port(0)
                        , m_operation_mode(operation_mode_storage)
                    {
                        // ...
                    }
                
                    /**
                     * Sets the port.
                     * @param val The value.
                     */
                    void set_port(const std::uint16_t & val)
                    {
                        m_port = val;
                    }
                
                    /**
                     * The port.
                     */
                    const std::uint16_t & port() const
                    {
                        return m_port;
                    }
                
                    /**
                     * Sets the operation mode.
                     * @param val The value.
                     */
                    void set_operation_mode(const operation_mode_t & val)
                    {
                        m_operation_mode = val;
                    }
                
                    /**
                     * The operation mode.
                     */
                    const operation_mode_t & operation_mode() const
                    {
                        return m_operation_mode;
                    }
                
                private:
                
                    /**
                     * The port.
                     */
                    std::uint16_t m_port;
                
                    /**
                     * The operation mode.
                     */
                    operation_mode_t m_operation_mode;
                    
                protected:
                
                    // ...
            };
            
            /**
             * Constructor
             */
            stack();
            
            /**
             * Starts the stack.
             * @param config The configuration.
             */
            void start(const configuration &);
            
            /**
             * Stops the stack.
             */
            void stop();
            
            /**
             * Joins the overlay.
			 * @param contacts The bootstrap contacts.
             */
            void join(
                const std::vector< std::pair<std::string, unsigned short> > &
            );
            
			/**
			 * Leaves the overlay.
			 */
			void leave();
        
            /**
             * Performs a store operation.
             * @param query The query.
             */
            std::uint16_t store(const std::string &);
        
            /**
             * Performs a find operation.
             * @param query The query.
             * @param max_results The maximum number of results.
             */
            std::uint16_t find(const std::string &, const std::size_t &);
        
            /**
             * Performs a (tcp) proxy operation given endpoint and buffer.
             * @param addr The address.
             * @param port The port.
             * @param buf The buffer.
             * @param len The length.
             */
            std::uint16_t proxy(
                const char * addr, const std::uint16_t & port,
                const char * buf, const std::size_t & len
            );
        
            /**
             * Returns all of the endpoints in the routing table.
             */
            std::list< std::pair<std::string, std::uint16_t> > endpoints();
        
            /**
             * Called when connected to the network.
             * @param addr The address.
             * @param port The port.
             */
            virtual void on_connected(
                const char * addr, const std::uint16_t & port
            );
        
            /**
             * Called when disconnected from the network.
             * @param addr The address.
             * @param port The port.
             */
            virtual void on_disconnected(
                const char * addr, const std::uint16_t & port
            );
        
            /**
             * Called when a search result is received.
             * @param transaction_id The transaction id.
             * @param query The query.
             */
            virtual void on_find(
                const std::uint16_t & transaction_id,
                const std::string & query
            );
        
            /**
             * Called when a proxy (response) is received.
             * @param tid The transaction identifier.
             * @param addr The address.
             * @param The port.
             * @param value The value.
             */
            virtual void on_proxy(
                const std::uint16_t & tid, const char * addr,
                const std::uint16_t & port, const std::string & value
            );
        
            /**
             * Called when a udp packet doesn't match the protocol fingerprint.
             * @param addr The address.
             * @param port The port.
             * @param buf The buffer.
             * @param len The length.
             */
            virtual void on_udp_receive(
                const char * addr, const std::uint16_t & port, const char * buf,
                const std::size_t & len
            );
        
        private:
        
            // ...
            
        protected:
        
            /**
             * The stack implementation.
             */
            stack_impl * stack_impl_;
    };

} // namespace database

#endif // DATABASE_STACK_HPP
