
#include "stdafx.h"
#include "resource.h"

#include "GVMessageWnd.h"
#include "GVWinApp.h"

BOOL GVMessageWnd::OnInitDialog()
{
	return true;
}

INT_PTR GVMessageWnd::DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam)
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
		case WM_CLOSE:
		{
			ShowWindow(SW_HIDE);
			return -1;
		}
		break;
		case WM_NOTIFY:
		{
			switch (((LPNMHDR)lParam)->code)
			{
				case NM_CLICK:
				case NM_RETURN:
				{
					PNMLINK pNMLink = (PNMLINK)lParam;
					LITEM item = pNMLink->item;

					std::wstring url(CString(item.szUrl).GetString());

					auto it = url.find(L"grapevine://");

					if (it != std::wstring::npos)
					{
						auto query = url.substr(wcslen(L"grapevine://"));

						log_debug("query = " << Utility::ws2s(query));

						if (query.size() > 0)
						{
							if (query[0] == L'@')
							{
								GVGetWinApp().Search(CString(query.c_str()));
							}
							else if (query[0] == L'#')
							{
								GVGetWinApp().Search(CString(query.c_str()));
							}
						}
					}
					else
					{
						ShellExecute(NULL, L"open", item.szUrl, NULL, NULL, SW_SHOW);
					}
				}
				break;
				default:
				break;
			}
		}
		break;
	}

	return DialogProcDefault(uMsg, wParam, lParam);
}

BOOL GVMessageWnd::OnCommand(WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);

	switch (LOWORD(wParam))
    {

    }

	return FALSE;
}