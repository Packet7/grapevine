
#include "stdafx.h"
#include "resource.h"

#include <chrono>
#include <future>
#include <string>
#include <thread>

#include "GVEditProfileWnd.h"
#include "GVWinApp.h"

BOOL GVEditProfileWnd::OnInitDialog()
{
	AttachItem(IDC_EDIT_EDIT_PROFILE_FULLNAME, m_editFullname);
	AttachItem(IDC_EDIT_EDIT_PROFILE_LOCATION, m_editLocation);
	AttachItem(IDC_EDIT_EDIT_PROFILE_PHOTO, m_editPhoto);
	AttachItem(IDC_EDIT_EDIT_PROFILE_WEB, m_editWeb);
	AttachItem(IDC_EDIT_EDIT_PROFILE_BIO, m_editBio);

	return true;
}

INT_PTR GVEditProfileWnd::DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam)
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

				auto profile = GVWinApp::g_GVStack->profile();

				auto f = Utility::mb2ws(profile["f"]);

				if (f.size() > 0)
				{
					m_editFullname.SetWindowText(f.c_str());
				}

				auto l = Utility::mb2ws(profile["l"]);

				if (l.size() > 0)
				{
					m_editLocation.SetWindowText(l.c_str());
				}

				auto p = Utility::mb2ws(profile["p"]);

				if (p.size() > 0)
				{
					m_editPhoto.SetWindowText(p.c_str());
				}

				auto w = Utility::mb2ws(profile["w"]);

				if (w.size() > 0)
				{
					m_editWeb.SetWindowText(w.c_str());
				}

				auto b = Utility::mb2ws(profile["b"]);

				if (b.size() > 0)
				{
					m_editBio.SetWindowText(b.c_str());
				}
			}
			else 
			{
				TRACE(_T("INACTIVE\n"));

				ShowWindow(SW_HIDE);

				m_editFullname.SetWindowText(L"");
				m_editLocation.SetWindowText(L"");
				m_editPhoto.SetWindowText(L"");
				m_editWeb.SetWindowText(L"");
				m_editBio.SetWindowText(L"");
			}
		}
		break;
	}

	return DialogProcDefault(uMsg, wParam, lParam);
}

BOOL GVEditProfileWnd::OnCommand(WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);

	switch (LOWORD(wParam))
    {
		case IDC_BUTTON_EDIT_PROFILE_PUBLISH:
		{
			CString f = m_editFullname.GetWindowText();
			CString l = m_editLocation.GetWindowText();
			CString p = m_editPhoto.GetWindowText();
			CString w = m_editWeb.GetWindowText();
			CString b = m_editBio.GetWindowText();

			std::map<std::string, std::string> profile;

			profile["f"] = Utility::ws2s(f.GetString());
			profile["l"] = Utility::ws2s(l.GetString());
			profile["p"] = Utility::ws2s(p.GetString());
			profile["w"] = Utility::ws2s(w.GetString());
			profile["b"] = Utility::ws2s(b.GetString());

			GVWinApp::g_GVStack->update_profile(profile);

			ShowWindow(SW_HIDE);

			return TRUE;
		}
		break;
		case IDC_BUTTON_EDIT_PROFILE_CANCEL:
		{
			ShowWindow(SW_HIDE);
			
			return TRUE;
		}
		break;
    }

	return FALSE;
}