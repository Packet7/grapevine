
#include "stdafx.h"
#include "resource.h"

#define _USE_MATH_DEFINES // for C
#include <math.h>

#include "GVBitmapCache.h"
#include "GVProfileCache.h"
#include "GVGdiPlusBitmap.h"
#include "GVTimelineWnd.h"
#include "GVWinApp.h"

bool IsCompositionEnabled()
{
	HRESULT hr;
	BOOL bEnabled;
	hr = DwmIsCompositionEnabled(&bEnabled);
	return SUCCEEDED(hr) && bEnabled;
}

GVTimelineWnd::GVTimelineWnd(UINT nResID, CWnd* pParent)
	: Win32xx::CDialog(nResID, pParent)
	, m_composeWnd(IDD_DIALOG_COMPOSE)
	, m_editProfileWnd(IDD_DIALOG_EDIT_PROFILE)
	, m_userProfileWnd(IDD_DIALOG_USER_PROFILE)
	, m_messageWnd(IDD_DIALOG_MESSAGE)
	, m_searchTransactionId(-1)
	, mode_(mode_timeline)
{
	// ...
}

void GVTimelineWnd::HandleFindMessage(GVStack::find_message_t & msg)
{
	// :TODO: make sure this is set to -1 when not in search mode
	if (m_searchTransactionId == msg.transaction_id && mode_ == mode_search)
	{
		m_listBoxSearchResults.AddItem(msg);
	}
	else
	{
		m_listBoxSubsciptions.AddItem(msg);
	}
}

void GVTimelineWnd::Search(CString & str)
{
	if (str.GetLength() > 0)
	{
		CString query(str);

		std::wstring queryString;

		if (query[0] == L'@')
		{
			query.Remove(L"@");

			queryString += L"u";;
			queryString += L"=";
			queryString += query.GetString();
		}
		else if (query[0] == L'#')
		{
			query.Remove(L"#");

			queryString += query.GetString();
			queryString += L"=";
			queryString += query.GetString();
		}
		else
		{
			queryString = query + L"=" + query;
		}

		if (mode_ == mode_timeline)
		{
			mode_ = mode_search;

			m_listBoxSubsciptions.ShowWindow(SW_HIDE);
			m_editSearch.ShowWindow();
			m_buttonSearch.ShowWindow();
			m_listBoxSearchResults.ShowWindow();

			m_editSearch.SetWindowText(str);
		}
		else if (mode_ == mode_search)
		{
			m_editSearch.SetWindowText(str);
		}

		m_listBoxSearchResults.Clear();

		m_searchTransactionId = GVWinApp::g_GVStack->find(
			Utility::ws2s(queryString), 50
		);
	}
}

#ifndef HINST_THISCOMPONENT
EXTERN_C IMAGE_DOS_HEADER __ImageBase;
#define HINST_THISCOMPONENT ((HINSTANCE)&__ImageBase)
#endif

BOOL GVTimelineWnd::OnInitDialog()
{
	AttachItem(IDC_SYSLINK_SEARCH, m_searchSysLink);
	AttachItem(IDC_SYSLINK_COMPOSE, m_composeSysLink);

	m_resizer.Initialize(this, CRect(0, 0, 30, 20)); 
	m_resizer.AddChild(m_searchSysLink, topright, 0);
	m_resizer.AddChild(m_composeSysLink, topright, 0);

	m_composeWnd.Create();
	m_editProfileWnd.Create();
	m_userProfileWnd.Create();
	m_messageWnd.Create();

	AttachItem(IDC_LIST_TIMELINE_SUBSCRIPTIONS, m_listBoxSubsciptions);
	AttachItem(IDC_EDIT_SEARCH_SEARCH, m_editSearch);
	AttachItem(IDC_BUTTON_SEARCH_SEARCH, m_buttonSearch);
	AttachItem(IDC_LIST_SEARCH_SEARCH_RESULTS, m_listBoxSearchResults);

	m_resizer.AddChild(
		m_listBoxSubsciptions, Win32xx::Alignment::bottomleft,
		RD_STRETCH_WIDTH| RD_STRETCH_HEIGHT
	);
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

	return true;
}

INT_PTR GVTimelineWnd::DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam)
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
		case WM_MEASUREITEM:
		{
			LPMEASUREITEMSTRUCT lpmis = (LPMEASUREITEMSTRUCT)lParam;

			switch (lpmis->CtlID)
			{
				case IDC_LIST_TIMELINE_SUBSCRIPTIONS:
				{
					m_listBoxSubsciptions.MeasureItem(lpmis);

					return TRUE;
				}
				break;
				case IDC_LIST_SEARCH_SEARCH_RESULTS:
				{
					m_listBoxSearchResults.MeasureItem(lpmis);

					return TRUE;
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
				case IDC_LIST_TIMELINE_SUBSCRIPTIONS:
				{
					m_listBoxSubsciptions.DrawItem(lpdis);

					return 1;
				}
				break;
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
		case WM_ACTIVATE:
		{
			if (LOWORD(wParam) == WA_ACTIVE)
			{
				// ...
			}
			else 
			{
				CPoint cursorPos = GetCursorPos();

				//ScreenToClient(cursorPos);
				/*
				if (m_messageWnd.GetHwnd())
				{
					CRect clientRect = m_messageWnd.GetClientRect();

					if (cursorPos.x > clientRect.right || cursorPos.y > clientRect.bottom)
					{
						m_messageWnd.ShowWindow(SW_HIDE);
					}
				}
				*/
				/*
				if (m_userProfileWnd.GetHwnd())
				{
					m_userProfileWnd.ShowWindow(SW_HIDE);
				}
				*/
			}
		}
		break;
		case WM_CLOSE:
		{
			m_userProfileWnd.ShowWindow(SW_HIDE);
			m_messageWnd.ShowWindow(SW_HIDE);
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

					if (wcscmp(item.szID, L"profile") == 0)
					{
						CRect rect = m_editProfileWnd.GetClientRect();

						ClientToScreen(rect);

						enum { edit_profile_wnd_width = 340 };
						enum { edit_profile_wnd_height = 270 };
						enum { edit_profile_wnd_offset_y = 32 };

						m_editProfileWnd.SetWindowPos(
							0, rect.left - edit_profile_wnd_width / 2,
							rect.top + edit_profile_wnd_offset_y, edit_profile_wnd_width,
							edit_profile_wnd_height, 0
						);

						m_editProfileWnd.ShowWindow();
					}
					else if (wcscmp(item.szID, L"search") == 0)
					{
						if (mode_ == mode_timeline)
						{
							mode_ = mode_search;

							m_listBoxSubsciptions.ShowWindow(SW_HIDE);
							m_editSearch.ShowWindow();
							m_buttonSearch.ShowWindow();
							m_listBoxSearchResults.ShowWindow();
						}
						else if (mode_ == mode_search)
						{
							mode_ = mode_timeline;

							m_listBoxSubsciptions.ShowWindow();
							m_editSearch.ShowWindow(SW_HIDE);
							m_buttonSearch.ShowWindow(SW_HIDE);
							m_listBoxSearchResults.ShowWindow(SW_HIDE);
							m_listBoxSearchResults.Clear();
						}
					}
					else if (wcscmp(item.szID, L"compose") == 0)
					{
						CRect rect = m_composeWnd.GetClientRect();

						ClientToScreen(rect);

						enum { compose_wnd_width = 300 };
						enum { compose_wnd_height = 180 };
						enum { compose_wnd_offset_y = 32 };

						m_composeWnd.SetWindowPos(
							0, rect.left + GetClientRect().right - compose_wnd_width / 2,
							rect.top + compose_wnd_offset_y, compose_wnd_width,
							compose_wnd_height, 0
						);

						m_composeWnd.ShowWindow();
					}
				}
				break;
				default:
				break;
			}
		}
		break;
		default:
		break;
	}

	return DialogProcDefault(uMsg, wParam, lParam);
}

BOOL GVTimelineWnd::OnCommand(WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);

	switch (LOWORD(wParam))
    {
		case IDC_BUTTON_SEARCH_SEARCH:
		{
			CString keyword = m_editSearch.GetWindowText();

			Search(keyword);

			return TRUE;
		}
		break;
		case IDC_LIST_TIMELINE_SUBSCRIPTIONS:
		{
			switch (HIWORD(wParam))
			{
				case LBN_SELCHANGE:
				{
					auto rowIndex = SendMessage(m_listBoxSubsciptions.GetHwnd(), LB_GETCURSEL, 0, 0);

					if (rowIndex > -1)
					{
						CRect itemRect;
						
						m_listBoxSubsciptions.GetItemRect(rowIndex, itemRect);

						ClientToScreen(itemRect);

						auto x = itemRect.left - 310 - 16;
						auto y = itemRect.top;

						auto i = m_listBoxSubsciptions.findMessages()[rowIndex];

						auto u = i.pairs[L"u"];

						auto profile = GVProfileCache::SharedInstance().Find(u);

						m_userProfileWnd.SetupProfile(u, profile);
						m_userProfileWnd.SetWindowPos(&wndTop, x, y, 310, 220, SWP_SHOWWINDOW | SWP_NOACTIVATE);
						m_messageWnd.SetWindowPos(&wndTop, x, y + 228, 310, 100, SWP_SHOWWINDOW | SWP_NOACTIVATE);

						/** */

						std::wstring message;

						message += i.pairs[L"m"];

						std::wstring tmp;

						BOOL insideAt = FALSE;
						BOOL insideHash = FALSE;
						BOOL insideHTTP = FALSE;

						std::wstring currentUsername;
						std::wstring currentHash;
						std::wstring currentUrl;

						auto it = message.begin();

						for (;;)
						{
							if (it == message.end())
							{
								if (insideHTTP)
								{
									insideHTTP = FALSE;

									tmp += L"\">" + currentUrl + L"</a>";
								}
								else if (insideAt)
								{
									insideAt = FALSE;

									tmp += L"\">@" + currentUsername + L"</a>";
								}
								else if (insideHash)
								{
									insideHash = FALSE;

									tmp += L"\">#" + currentHash + L"</a>";
								}

								break;
							}
							else if (*it == ' ')
							{
								if (insideHTTP)
								{
									insideHTTP = FALSE;

									tmp += L"\">" + currentUrl + L"</a>";

									currentUrl.clear();
								}
								else if (insideAt)
								{
									insideAt = FALSE;

									tmp += L"\">@" + currentUsername + L"</a>";

									currentUsername.clear();
								}
								else if (insideHash)
								{
									insideHash = FALSE;

									tmp += L"\">#" + currentHash + L"</a>";

									currentHash.clear();
								}

								tmp += *it;
							}
							else if (
								(*(it)  == 'h' || *(it)  == 'H') && (*(it + 1) == 't' || *(it + 1) == 'T') &&
								(*(it + 2)  == 't' || *(it + 2)  == 'T') && (*(it + 3) == 'p' || *(it + 3) == 'P') &&
								(*(it + 4) == 's' || *(it + 4) == 'S')
								)
							{
								++it, ++it, ++it, ++it, ++it, ++it, ++it;

								insideHTTP = TRUE;

								tmp += L"<a href=\"https://";
							}
							else if (
								(*(it)  == 'h' || *(it)  == 'H') && (*(it + 1) == 't' || *(it + 1) == 'T') &&
								(*(it + 2)  == 't' || *(it + 2)  == 'T') && (*(it + 3) == 'p' || *(it + 3) == 'P')
								)
							{
								++it, ++it, ++it, ++it, ++it, ++it;

								insideHTTP = TRUE;

								tmp += L"<a href=\"http://";
							}
							else if (*it == '@')
							{
								insideAt = TRUE;

								tmp += L"<a href=\"grapevine://@";
							}
							else if (*it == '#')
							{
								insideHash = TRUE;
	
								tmp += L"<a href=\"grapevine://#";
							}
							else
							{
								if (insideHTTP)
								{
									currentUrl += *it;
								}
								else if (insideAt)
								{
									currentUsername += *it;
								}
								else if (insideHash)
								{
									currentHash += *it;
								}

								tmp += *it;
							}

							++it;
						}

						::SetWindowText(
							::GetDlgItem(m_messageWnd, IDC_SYSLINK_CURRENT_CONTENT), tmp.c_str()
						);
					}
					return TRUE;
				}
				break;
			}
		}
		break;
		case IDC_LIST_SEARCH_SEARCH_RESULTS:
		{
			switch (HIWORD(wParam))
			{
				case LBN_SELCHANGE:
				{
					auto rowIndex = SendMessage(
						m_listBoxSearchResults.GetHwnd(), LB_GETCURSEL, 0, 0
					);

					if (rowIndex > -1)
					{
						CRect itemRect;
						
						m_listBoxSearchResults.GetItemRect(rowIndex, itemRect);

						ClientToScreen(itemRect);

						auto x = itemRect.left - 310 - 16;
						auto y = itemRect.top;

						auto i = m_listBoxSearchResults.findMessages()[rowIndex];

						auto u = i.pairs[L"u"];

						auto profile = GVProfileCache::SharedInstance().Find(u);

						m_userProfileWnd.SetupProfile(u, profile);
						m_userProfileWnd.SetWindowPos(&wndTop, x, y, 310, 220, SWP_SHOWWINDOW | SWP_NOACTIVATE);
						m_messageWnd.SetWindowPos(&wndTop, x, y + 228, 310, 100, SWP_SHOWWINDOW | SWP_NOACTIVATE);

						/** */

						std::wstring message;

						message += i.pairs[L"m"];

						std::wstring tmp;

						BOOL insideAt = FALSE;
						BOOL insideHash = FALSE;

						std::wstring currentUsername;
						std::wstring currentHash;

						auto it = message.begin();

						for (;;)
						{
							if (it == message.end())
							{
								if (insideAt)
								{
									insideAt = FALSE;

									tmp += L"\">@" + currentUsername + L"</a>";
								}
								else if (insideHash)
								{
									insideHash = FALSE;

									tmp += L"\">#" + currentHash + L"</a>";
								}

								break;
							}
							else if (*it == ' ')
							{
								if (insideAt)
								{
									insideAt = FALSE;

									tmp += L"\">@" + currentUsername + L"</a>";

									currentUsername.clear();
								}
								else if (insideHash)
								{
									insideHash = FALSE;

									tmp += L"\">#" + currentHash + L"</a>";

									currentHash.clear();
								}

								tmp += *it;
							}
							else if (*it == '@')
							{
								insideAt = TRUE;

								tmp += L"<a href=\"grapevine://@";
							}
							else if (*it == '#')
							{
								insideHash = TRUE;
	
								tmp += L"<a href=\"grapevine://#";
							}
							else
							{
								if (insideAt)
								{
									currentUsername += *it;
								}
								else if (insideHash)
								{
									currentHash += *it;
								}

								tmp += *it;
							}

							++it;
						}

						::SetWindowText(
							::GetDlgItem(m_messageWnd, IDC_SYSLINK_CURRENT_CONTENT), tmp.c_str()
						);
					}
					return TRUE;
				}
				break;
			}
		}
		break;
		default:
		break;
    }

	return FALSE;
}
