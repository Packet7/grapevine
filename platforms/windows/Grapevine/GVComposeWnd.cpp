
#include "stdafx.h"
#include "resource.h"

#include <chrono>
#include <future>
#include <string>
#include <thread>

#include <boost/property_tree/json_parser.hpp>

#include "GVComposeWnd.h"
#include "GVWinApp.h"

BOOL GVComposeWnd::OnInitDialog()
{
	AttachItem(IDC_EDIT_COMPOSE_MESSAGE, m_editMessage);
	AttachItem(IDC_BUTTON_COMPOSE_PUBLISH, m_buttonPublish);
	
	m_buttonPublish.EnableWindow(FALSE);

	return true;
}

INT_PTR GVComposeWnd::DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch(uMsg)
	{
		case WM_ERASEBKGND:
		{
			RECT rc;
			::GetClientRect(m_hWnd, &rc);
			HBRUSH brush = CreateSolidBrush(RGB(255,255,255));
			FillRect((HDC)wParam, &rc, brush);
			DeleteObject(brush);
			return TRUE;
		}
		break;
		case WM_CTLCOLORSTATIC:
		{
			static HBRUSH hBrush = CreateSolidBrush(RGB(255, 255, 255));
			DWORD CtrlID = ::GetDlgCtrlID((HWND)lParam); //Window Control ID
			HDC hdcStatic = (HDC) wParam;
			SetTextColor(hdcStatic, RGB(0,0,0));
			SetBkColor(hdcStatic, RGB(255, 255, 255));
			return (INT_PTR)hBrush;
		}
		break;
		case WM_SETFOCUS:
		{
			TRACE(_T("WM_SETFOCUS\n"));
		}
		break ;
		case WM_KILLFOCUS:
		{
			TRACE(_T("WM_KILLFOCUS\n"));
		}
		break;
		case WM_ACTIVATE:
		{
			if (LOWORD(wParam) == WA_ACTIVE)
			{
				TRACE(_T("WA_ACTIVE\n"));
			}
			else 
			{
				TRACE(_T("INACTIVE\n"));

				ShowWindow(SW_HIDE);
			}
		}
		break;
	}

	return DialogProcDefault(uMsg, wParam, lParam);
}

BOOL GVComposeWnd::OnCommand(WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);

	switch (LOWORD(wParam))
    {
		case IDC_BUTTON_COMPOSE_PUBLISH:
		{
			ShortenUrls();

			std::async(std::launch::async, [this] ()
			{
				std::this_thread::sleep_for(std::chrono::seconds(1));

				CString message = m_editMessage.GetWindowText();

				TRACE(message.c_str());

				if (GVWinApp::g_GVStack)
				{
					std::string message(
						message.GetString().begin(), message.GetString().end()
					);

					GVWinApp::g_GVStack->post(message);
				}
			});

			m_editMessage.SetWindowTextW(L"");
			m_editMessage.UpdateWindow();

			m_buttonPublish.EnableWindow(FALSE);

			ShowWindow(SW_HIDE);

			/**
			 * Perform a lookup on ourselves after a delay.
			 */
			std::async(std::launch::async, [] ()
			{
				std::this_thread::sleep_for(std::chrono::seconds(2));

				std::string query = "u=" + GVWinApp::g_GVStack->username();

				GVWinApp::g_GVStack->find(query, 50);
			});

			return TRUE;
		}
		break;
		case IDC_BUTTON_COMPOSE_CANCEL:
		{
			m_editMessage.SetWindowTextW(L"");
			m_editMessage.UpdateWindow();

			m_buttonPublish.EnableWindow(FALSE);

			ShowWindow(SW_HIDE);
			
			return TRUE;
		}
		break;
		case IDC_EDIT_COMPOSE_MESSAGE:
		{
			//	:FIXME: EN_CHANGE 
			m_buttonPublish.EnableWindow(
				m_editMessage.GetWindowTextLength() > 0 &&
				m_editMessage.GetWindowTextLength() <= 140
			);

			auto message = m_editMessage.GetWindowText().GetString();

			if (message.size() == 0)
			{
				return FALSE;
			}

			wchar_t c = message[message.size() - 1];

			if (c != L' ')
			{
				return FALSE;
			}

			log_debug("****** SHOULD TRY SHORTEN ****** ");

			ShortenUrls();
		}
		break;
    }

	return FALSE;
}
void GVComposeWnd::ShortenUrls()
{
	auto message = m_editMessage.GetWindowText().GetString();

	std::istringstream iss(Utility::ws2s(message));

	std::vector<std::string> tokens;
	std::copy(std::istream_iterator<std::string>(iss),
		std::istream_iterator<std::string>(),
		std::back_inserter<std::vector<std::string> >(tokens)
	);

	for (auto & i : tokens)
	{
		log_debug("***** token = " << i);

		if (
			(i.find("http://") != std::string::npos ||
			i.find("https://") != std::string::npos) && 
			i.find("goo.gl") == std::string::npos && 
			i.find("grp.yt") == std::string::npos
			)
		{
			log_debug("****** SHORTENING ****** ");

			std::map<std::string, std::string> headers;

			headers["Content-Type"] = "application/json";

			std::string body = "{\"longUrl\":\"" + i + "\"}";
#if 1
			GVWinApp::g_GVStack->url_post("http://grp.yt/", headers, body,
				[this, message, i] (const std::map<std::string, std::string> & headers,
				const std::string & body
				)
			{
				if (body.size() > 0)
				{
					std::stringstream json;

					json << body;

					boost::property_tree::ptree ptree;

					try
					{
						read_json(json, ptree);
					}
					catch (std::exception & e)
					{

					}

					auto shortUrl = Utility::mb2ws(
						ptree.get<std::string> ("id", "")
					);

					if (shortUrl.size() > 0)
					{
						std::wstring shortMessage = message;

						auto it = shortMessage.find(Utility::mb2ws(i));

						shortMessage.replace(it, it + i.size(), shortUrl);
								
						/**
						 * :NOTE: We are in the stack thread but SetWindowText
						 * is supposed to be thread-safe.
						 */
						m_editMessage.SetWindowText(shortMessage.c_str());
						m_editMessage.SetSel(shortMessage.size(), shortMessage.size(), TRUE);
					}
				}
				else
				{
					// ...
				}
			});
#endif
			/**
				* Only shorten one url per key stroke.
				*/
			break;
		}
	}
}
