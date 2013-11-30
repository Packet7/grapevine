
#include "stdafx.h"
#include "resource.h"

#include <chrono>
#include <future>
#include <string>
#include <thread>

#include "GVSearchWnd.h"
#include "GVWinApp.h"

void GVSearchWnd::HandleFindMessage(GVStack::find_message_t & msg)
{
	if (msg.transaction_id == m_transactionId)
	{
		m_listBoxSearchResults.AddItem(msg);
	}
}

BOOL GVSearchWnd::OnInitDialog()
{
	AttachItem(IDC_EDIT_SEARCH_SEARCH, m_editSearch);
	AttachItem(IDC_BUTTON_SEARCH_SEARCH, m_buttonSearch);
	AttachItem(IDC_LIST_SEARCH_SEARCH_RESULTS, m_listBoxSearchResults);

	m_resizer.Initialize(this, CRect(0, 0, 30, 20));

	m_resizer.AddChild(
		m_editSearch, Win32xx::Alignment::topright, RD_STRETCH_WIDTH
	);
	m_resizer.AddChild(
		m_buttonSearch, Win32xx::Alignment::topright, 0
	);
	m_resizer.AddChild(
		m_listBoxSearchResults, Win32xx::Alignment::bottomleft,
		RD_STRETCH_WIDTH| RD_STRETCH_HEIGHT
	);

	m_userProfileWnd.Create();

	return true;
}

INT_PTR GVSearchWnd::DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	m_resizer.HandleMessage(uMsg, wParam, lParam);

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
		case WM_MEASUREITEM:
		{
			LPMEASUREITEMSTRUCT lpmis = (LPMEASUREITEMSTRUCT)lParam;

			switch (lpmis->CtlID)
			{
				case IDC_LIST_SEARCH_SEARCH_RESULTS:
				{
					m_listBoxSearchResults.MeasureItem(lpmis);

					return 1;
				}
				break;
				default:
				break;
			}
		}
		break;
		case WM_DRAWITEM:
		{
			LPDRAWITEMSTRUCT lpdis = (LPDRAWITEMSTRUCT)lParam;

			switch (lpdis->CtlID)
			{
				case IDC_LIST_SEARCH_SEARCH_RESULTS:
				{
					m_listBoxSearchResults.DrawItem(lpdis);

					return 1;
				}
				break;
				default:
				break;
			}
		}
		break;
		case WM_CLOSE:
		{
			ShowWindow(SW_HIDE);
			return -1;
		}
		break;
		/*
		case WM_SETFOCUS:
		{
			TRACE(_T("WM_SETFOCUS\n"));
		}
		break;
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
	}

	return DialogProcDefault(uMsg, wParam, lParam);
}

BOOL GVSearchWnd::OnCommand(WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);

	switch (LOWORD(wParam))
    {
		case IDC_BUTTON_SEARCH_SEARCH:
		{
			m_listBoxSearchResults.Clear();

			CString keyword = m_editSearch.GetWindowText();

			std::wstring query = keyword.GetString() + L"=" + keyword.GetString();

			m_transactionId = GVWinApp::g_GVStack->find(Utility::ws2s(query), 50);

			return TRUE;
		}
		break;
		case IDC_LIST_SEARCH_SEARCH_RESULTS:
		{
			switch (HIWORD(wParam))
			{
				case LBN_SELCHANGE:
				{
					auto rowIndex = SendMessage(m_listBoxSearchResults.GetHwnd(), LB_GETCURSEL, 0, 0);

					if (rowIndex > -1)
					{
						auto x = 200;
						auto y = 200;

						auto i = m_listBoxSearchResults.findMessages()[rowIndex];

						auto u = i.pairs[L"u"];

						auto profile = GVProfileCache::SharedInstance().Find(u);

						m_userProfileWnd.SetupProfile(u, profile);
						m_userProfileWnd.SetWindowPos(&wndTopMost, x, y, 310, 220, SWP_SHOWWINDOW | SWP_NOACTIVATE);

						log_debug("~~~~~~~~~~~~~~~~ rowIndex = " << rowIndex << ", x = " << x << ", y = " << y);
					}
					return TRUE;
				}
				break;
			}
		}
		break;
    }

	return FALSE;
}