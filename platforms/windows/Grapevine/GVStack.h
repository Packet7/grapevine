
#pragma once

#include <cstdint>
#include <functional>
#include <map>
#include <vector>

#include <grapevine/stack.hpp>

#include "GVSignUpWnd.h"
#include "GVUtility.h"

#pragma comment(lib, "libdatabase.lib")
#pragma comment(lib, "libgrapevine.lib")
#pragma comment(lib, "libboost_system.lib")
#pragma comment(lib, "libminiupnpc.lib")
#pragma comment(lib, "iphlpapi.lib")
#pragma comment(lib, "d2d1.lib")
#pragma comment(lib, "dwrite.lib")
#pragma comment(lib, "windowscodecs.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3d10_1.lib")
#pragma comment (lib,"Gdiplus.lib")

enum
{
	WM_GV_IS_CONNECTED = WM_APP + 1001,
	WM_GV_SIGN_IN,
	WM_GV_SIGNED_UP,
	WM_GV_IS_DISCONNECTED,
	WM_GV_SIGNED_IN,
	WM_GV_SIGN_IN_FAILED,
	WM_GV_ON_FIND_MESSAGE,
	WM_GV_ON_FIND_PROFILE,
	WM_GV_ON_VERSION,
};

class GVStack
	: public grapevine::stack
	, public Win32xx::CDialog
{
	public:

			class sign_up_t
			{
				public:

					std::map<std::wstring, std::wstring> pairs;
			};

			class find_message_t
			{
				public:

					find_message_t()
						: reserved1(0)
						, transaction_id(0)
					{
						// ...
					}

					std::size_t reserved1;
					std::uint16_t transaction_id;
					std::map<std::wstring, std::wstring> pairs;
					std::vector<std::wstring> tags;
			};

			class find_profile_t
			{
				public:

					std::uint16_t transaction_id;
					std::map<std::wstring, std::wstring> pairs;
			};

			class version_t
			{
				public:

					std::map<std::wstring, std::wstring> pairs;
			};

			std::function<void (sign_up_t msg)> m_on_sign_up;
			std::function<void ()> m_on_connected;
			std::function<void ()> m_on_disconnected;
			std::function<void ()> m_on_signed_in;
			std::function<void (find_message_t msg)> m_on_find_message;
			std::function<void (find_profile_t msg)> m_on_find_profile;
			std::function<void (version_t msg)> m_on_version;
			

			/**
			 * Constructor
			 */
			GVStack();

			/**
			 * Signs up for the network.
			 * @param username The username.
			 * @param password The password.
			 * @param secret The secret.
			 */
			void sign_up(const std::string & username, const std::string & password, const std::string & secret)
			{
				std::map<std::string, std::string> url_params;

				url_params["u"] = username;
				url_params["p"] = password;
				url_params["ss"] = secret;

				grapevine::stack::sign_up(url_params,
					[this](const std::map<std::string, std::string> & response)
				{
					auto pairs = response;

					log_debug("status = " << pairs["status"] << ", message = " << pairs["message"]);

					sign_up_t * wparam = new sign_up_t;

					for (auto & i : pairs)
					{
						wparam->pairs.insert(std::make_pair(Utility::mb2ws(i.first), Utility::mb2ws(i.second)));
					}

					PostMessage(GetHwnd(), WM_GV_SIGNED_UP, (WPARAM)wparam, 0);
				});
			}

            /**
             * Called when connected to the network.
             * @param addr The address.
             * @param port The port.
             */
            virtual void on_connected(
                const char * addr, const std::uint16_t & port
            )
			{
				PostMessage(GetHwnd(), WM_GV_IS_CONNECTED, 0, 0);
			}
        
            /**
             * Called when disconnected from the network.
             * @param addr The address.
             * @param port The port.
             */
            virtual void on_disconnected(
                const char * addr, const std::uint16_t & port
            )
			{
				PostMessage(GetHwnd(), WM_GV_IS_DISCONNECTED, 0, 0);
			}
        
            /**
             * Called when sign in has completed.
             * @param status The status.
             */
            virtual void on_sign_in(const std::string & status)
			{
				if (status == "0 Success")
				{
					PostMessage(GetHwnd(), WM_GV_SIGNED_IN, 0, 0);
				}
				else
				{
					PostMessage(GetHwnd(), WM_GV_SIGN_IN_FAILED, 0, 0);
				}
			}

            virtual void on_find_message(
                const std::uint16_t & transaction_id,
                const std::map<std::string, std::string> & pairs,
                const std::vector<std::string> & tags
				)
			{
				find_message_t * wparam = new find_message_t;

				wparam->transaction_id = transaction_id;

				for (auto & i : pairs)
				{
					wparam->pairs.insert(std::make_pair(Utility::mb2ws(i.first), Utility::mb2ws(i.second)));
				}

				// :TODO: tags

				PostMessage(GetHwnd(), WM_GV_ON_FIND_MESSAGE, (WPARAM)wparam, 0);
			}
        
            virtual void on_find_profile(
                const std::uint16_t & transaction_id,
                const std::map<std::string, std::string> & pairs
				)
			{
				find_profile_t * wparam = new find_profile_t;

				wparam->transaction_id = transaction_id;

				for (auto & i : pairs)
				{
					wparam->pairs.insert(std::make_pair(Utility::mb2ws(i.first), Utility::mb2ws(i.second)));
				}

				PostMessage(GetHwnd(), WM_GV_ON_FIND_PROFILE, (WPARAM)wparam, 0);
			}

			virtual void on_version(const std::map<std::string, std::string> & pairs)
			{
				version_t * wparam = new version_t;

				for (auto & i : pairs)
				{
					wparam->pairs.insert(std::make_pair(Utility::mb2ws(i.first), Utility::mb2ws(i.second)));
				}

				PostMessage(GetHwnd(), WM_GV_ON_VERSION, (WPARAM)wparam, 0);
			}

			Win32xx::CEdit m_editUsername;
			Win32xx::CEdit m_editPassword;

			GVSignUpWnd m_signUpWnd;

	private:

		virtual BOOL OnInitDialog();

		virtual INT_PTR DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam);

		virtual BOOL OnCommand(WPARAM wParam, LPARAM lParam);

		void SignIn();

	protected:
};
