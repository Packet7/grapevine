
#include "stdafx.h"
#include "resource.h"

#include <chrono>
#include <future>
#include <string>
#include <thread>

#include "GVStack.h"

GVStack::GVStack()
	: grapevine::stack()
	, Win32xx::CDialog(IDD_DIALOG_SIGN_IN)
	, m_signUpWnd(IDD_DIALOG_SIGN_UP)
	
{
	// ...
}

BOOL GVStack::OnInitDialog()
{
	AttachItem(IDC_EDIT_SIGN_IN_USERNAME, m_editUsername);
	AttachItem(IDC_EDIT_SIGN_IN_PASSWORD, m_editPassword);

	std::wstring wusername = Registry::GetValue(L"username");
	std::wstring wpassword = Registry::GetValue(L"password");

	m_editUsername.SetWindowText(wusername.c_str());
	m_editPassword.SetWindowText(wpassword.c_str());

	return true;
}

INT_PTR GVStack::DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam)
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
		case WM_GV_SIGN_IN:
		{
			SignIn();
		}
		break;
		case WM_GV_SIGN_IN_FAILED:
		{
			MessageBox(L"Sign in failed, invalid credentials.", L"Error", MB_ICONERROR);
		}
		break;
		case WM_GV_SIGNED_UP:
		{
			TRACE(_T("WM_GV_SIGNED_UP\n"));

			if (m_on_sign_up)
			{
				sign_up_t * wparam = (sign_up_t *)wParam;

				if (wparam)
				{
					m_on_sign_up(*wparam);

					delete wparam;
				}
			}
		}
		break;
		case WM_GV_IS_CONNECTED:
		{
			TRACE(_T("WM_GV_IS_CONNECTED\n"));

			std::wstring wusername = Registry::GetValue(L"username");
			std::wstring wpassword = Registry::GetValue(L"password");

			BOOL autoSignIn = wusername.size() > 5 && wpassword.size() > 5;

			if (wusername.size() > 0 && wpassword.size() > 0 && autoSignIn)
			{
				std::string username = Utility::ws2s(wusername);
				std::string password = Utility::ws2s(wpassword);

				std::async(std::launch::async, [this, username, password] ()
				{
					std::this_thread::sleep_for(std::chrono::seconds(1));

					try
					{
						sign_in(username, password);
					}
					catch (std::exception & e)
					{
						e.what();
					}
				});
			}
			else
			{
				ShowWindow(SW_SHOW);
			}

			if (m_on_connected)
			{
				m_on_connected();
			}

			return 0;
		}
		break;
		case WM_GV_IS_DISCONNECTED:
		{
			TRACE(_T("WM_GV_IS_DISCONNECTED\n"));

			if (m_on_disconnected)
			{
				m_on_disconnected();
			}

			return 0;
		}
		break;
		case WM_GV_SIGNED_IN:
		{
			TRACE(_T("WM_GV_SIGNED_IN\n"));

			if (m_on_signed_in)
			{
				m_on_signed_in();
			}
		}
		break;
		case WM_GV_ON_FIND_MESSAGE:
		{
			TRACE(_T("WM_GV_ON_FIND_MESSAGE\n"));

			if (m_on_find_message)
			{
				find_message_t * wparam = (find_message_t *)wParam;

				if (wparam)
				{
					m_on_find_message(*wparam);

					delete wparam;
				}
			}
		}
		break;
		case WM_GV_ON_FIND_PROFILE:
		{
			TRACE(_T("WM_GV_ON_FIND_PROFILE\n"));

			if (m_on_find_profile)
			{
				find_profile_t * wparam = (find_profile_t *)wParam;

				if (wparam)
				{
					m_on_find_profile(*wparam);

					delete wparam;
				}
			}
		}
		break;
		case WM_GV_ON_VERSION:
		{
			TRACE(_T("WM_GV_ON_VERSION\n"));
			
			if (m_on_version)
			{
				version_t * wparam = (version_t *)wParam;

				if (wparam)
				{
					m_on_version(*wparam);

					delete wparam;
				}
			}
		}
		break;
		default:
		break;
	}

	return DialogProcDefault(uMsg, wParam, lParam);
}

BOOL GVStack::OnCommand(WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);

	switch (LOWORD(wParam))
    {
		case ID_SIGN_IN:
		{
			SignIn();

			return TRUE;
		}
		break;
		case ID_SIGN_UP:
		{
			if (!m_signUpWnd.GetHwnd())
			{
				m_signUpWnd.Create();
			}
			m_signUpWnd.ShowWindow();

			return TRUE;
		}
		break;
		default:
			break;
    }

	return FALSE;
}


void GVStack::SignIn()
{
	std::wstring wusername = m_editUsername.GetWindowText();
	std::wstring wpassword = m_editPassword.GetWindowText();

	if (wusername.size() > 0 && wpassword.size() > 0)
	{
		Registry::SetValue(L"username", wusername);
		Registry::SetValue(L"password", wpassword);

		try
		{
			sign_in(Utility::ws2s(wusername), Utility::ws2s(wpassword));
		}
		catch (std::exception & e)
		{
			e.what();
		}
	}
}
