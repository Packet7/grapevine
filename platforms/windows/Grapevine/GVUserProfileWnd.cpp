
#include "stdafx.h"
#include "resource.h"

#include <grapevine/logger.hpp>

#include "GVBitmapCache.h"
#include "GVStack.h"
#include "GVUserProfileWnd.h"
#include "GVWinApp.h"

void GVUserProfileWnd::SetupProfile(
	const std::wstring & username,
	std::map<std::wstring, std::wstring> & profile
	)
{
	m_username = username;
	m_profile = profile;

	std::wstring u = L"@" + username;
	std::wstring f = m_profile[L"f"];

	m_staticUsername.SetWindowText(u.c_str());
	m_staticProfileFullname.SetWindowText(f.c_str());

	if (
		GVWinApp::g_GVStack->is_subscribed(Utility::ws2s(m_username))
		)
	{
		m_subscribeButton.SetWindowText(L"Unsubscribe");
	}
	else
	{
		m_subscribeButton.SetWindowText(L"Subscribe");
	}

	Gdiplus::Bitmap * gdiPlusBitmap = GVBitmapCache::SharedInstance().Find(
		m_profile[L"p"]
	);

	if (gdiPlusBitmap)
	{
		Gdiplus::BitmapData bitmapData;

		HBITMAP hbitmap;

		gdiPlusBitmap->GetHBITMAP(0, &hbitmap);

		SendMessage(
			GetDlgItem(IDC_STATIC_USER_PROFILE_AVATAR)->GetHwnd(),
			STM_SETIMAGE, IMAGE_BITMAP, (LPARAM)hbitmap
		);
	}
	else
	{

	}
}

BOOL GVUserProfileWnd::OnInitDialog()
{
	AttachItem(IDC_STATIC_USER_PROFILE_USERNAME, m_staticUsername);
	AttachItem(IDC_BUTTON_USER_PROFILE_SUBSCRIBE, m_subscribeButton);
	AttachItem(IDC_STATIC_USER_PROFILE_FULLNAME, m_staticProfileFullname);

	//m_subscribeButton.EnableWindow(FALSE);

	return true;
}

INT_PTR GVUserProfileWnd::DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch(uMsg)
	{
		/*
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
		*/
		case WM_ERASEBKGND:
		{
			RECT rc;
			::GetClientRect(m_hWnd, &rc);
			HBRUSH brush = CreateSolidBrush(RGB(255, 255, 255));
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
		case WM_CLOSE:
		{
			ShowWindow(SW_HIDE);
			return -1;
		}
		break;
	}

	return DialogProcDefault(uMsg, wParam, lParam);
}

BOOL GVUserProfileWnd::OnCommand(WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);

	switch (LOWORD(wParam))
    {
		case IDC_BUTTON_USER_PROFILE_SUBSCRIBE:
		{
			if (
				GVWinApp::g_GVStack->is_subscribed(
				std::string(m_username.begin(), m_username.end()))
				)
			{
				GVWinApp::g_GVStack->unsubscribe(
					std::string(m_username.begin(), m_username.end())
				);

				m_subscribeButton.SetWindowText(L"Subscribe");
			}
			else
			{
				GVWinApp::g_GVStack->subscribe(
					std::string(m_username.begin(), m_username.end())
				);

				m_subscribeButton.SetWindowText(L"Unsubscribe");
			}
			return TRUE;
		}
		break;
    }

	return FALSE;
}