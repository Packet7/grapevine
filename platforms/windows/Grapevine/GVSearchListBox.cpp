
#include "stdafx.h"
#include "resource.h"

#include <ctime>

#include "GVBitmapCache.h"
#include "GVProfileCache.h"
#include "GVSearchListBox.h"
#include "GVTimelineWnd.h"

void GVSearchListBox::AddItem(GVStack::find_message_t & msg)
{
	std::lock_guard<std::recursive_mutex> l(mutex_);

	auto found = false;

	for (auto & i : m_findMessages)
	{
		if (
			i.pairs[L"u"] == msg.pairs[L"u"] &&
			i.pairs[L"m"] == msg.pairs[L"m"]
			)
		{
			found = true;

			break;
		}
	}

	if (found)
	{
		// ...
	}
	else
	{
		m_findMessages.push_back(msg);

		struct cmp
		{
			bool operator ()
				(GVStack::find_message_t & a, GVStack::find_message_t & b
				)
			{
				return a.pairs[L"__t"] > b.pairs[L"__t"];
			}
		};
#if 1 // sort
		std::sort(m_findMessages.begin(), m_findMessages.end(), cmp());

		//ResetContent();

		while (GetCount())
		{
			DeleteString(0);
		}

		for (auto & i : m_findMessages)
		{
			AddString(L"");
		}
#else
		InsertString(m_findMessages.size() - 1, L"");
#endif
	}
}

void GVSearchListBox::Clear()
{
	std::lock_guard<std::recursive_mutex> l(mutex_);

	ResetContent();
	m_findMessages.clear();
}

#define DEFAULT_ITEM_HEIGHT 56

void GVSearchListBox::MeasureItem(LPMEASUREITEMSTRUCT lpmis)
{
	std::lock_guard<std::recursive_mutex> l(mutex_);

	TRACE(_T("****************** GVSearchListBox::MeasureItem\n"));
#if 1
	auto m = m_findMessages[lpmis->itemID].pairs[L"m"];

	CRect rowRect;
	GetItemRect(lpmis->itemID, &rowRect);

	rowRect.right -= avatar_size + 8 * 2;

	CDC * pDC = GetDC();

	HDC hdc = pDC->GetHDC();

	LOGFONT lFont;

	std::memset(&lFont, 0, sizeof(LOGFONT));

	lFont.lfHeight = 14;
	lFont.lfWeight = FW_NORMAL;

	lstrcpy(lFont.lfFaceName, L"Sans Droid");

	HFONT font = CreateFontIndirect(&lFont);

	SelectObject(hdc, font);

	auto nHeight = pDC->DrawText(m.c_str(), -1, rowRect, DT_WORDBREAK | DT_CALCRECT | DT_EXPANDTABS);

	//log_debug("rowRect.w = " << rowRect.left - rowRect.right << ", nHeight = " << nHeight);

	lpmis->itemHeight += ((nHeight / 1) + (DEFAULT_ITEM_HEIGHT - 22));

	ReleaseDC(pDC);
#else
	auto height = m_findMessages[lpmis->itemID].reserved1;

	if (height < DEFAULT_ITEM_HEIGHT)
	{
		height = DEFAULT_ITEM_HEIGHT;
	}

	lpmis->itemWidth = 250;
	lpmis->itemHeight = height;
#endif
}

void GVSearchListBox::DrawItem(LPDRAWITEMSTRUCT lpdis)
{
	std::lock_guard<std::recursive_mutex> l(mutex_);

	switch (lpdis->itemAction)
	{
		case ODA_DRAWENTIRE:
		{
			if (lpdis->itemState & ODS_SELECTED)
			{
				DrawSelected(lpdis);
			}
			else
			{
				DrawEntire(lpdis);
			}
		}
		break;
		case ODA_SELECT:
		{
			if (lpdis->itemState & ODS_SELECTED)
			{
				DrawSelected(lpdis);
			}
			else
			{
				DrawEntire(lpdis);
			}
		}
		break;
		default:
		break;
	}

	RECT rect(lpdis->rcItem);

	HPEN hpen = CreatePen(PS_SOLID, 1, RGB(248, 248, 248));

	HBRUSH hbrush = CreateSolidBrush(RGB(248, 248, 248));

	SelectObject(lpdis->hDC, hpen);
	SelectObject(lpdis->hDC, hbrush);

	Rectangle(lpdis->hDC, rect.left + 12, rect.bottom - 1, rect.right - 12, rect.bottom);
	
	DeleteObject(hpen);
	DeleteObject(hbrush);

	DrawAvatar(lpdis);
	DrawMessage(lpdis);
	DrawVia(lpdis);
}

void GVSearchListBox::DrawSelected(LPDRAWITEMSTRUCT lpdis)
{
	RECT rect(lpdis->rcItem);

	HPEN hpen = CreatePen(PS_SOLID, 1, RGB(248, 248, 248));

	HBRUSH hbrush = CreateSolidBrush(RGB(248, 248, 248));

	SelectObject(lpdis->hDC, hpen);
	SelectObject(lpdis->hDC, hbrush);

	Rectangle(lpdis->hDC, rect.left, rect.top, rect.right, rect.bottom);

	DeleteObject(hpen);
	DeleteObject(hbrush);

	DrawAvatar(lpdis);
	DrawMessage(lpdis);
	DrawVia(lpdis);
}

void GVSearchListBox::DrawEntire(LPDRAWITEMSTRUCT lpdis)
{
	RECT rect(lpdis->rcItem);

	HPEN hpen = CreatePen(PS_SOLID, 1, RGB(255, 255, 255));

	HBRUSH hbrush = CreateSolidBrush(RGB(255, 255, 255));

	SelectObject(lpdis->hDC, hpen);
	SelectObject(lpdis->hDC, hbrush);

	Rectangle(lpdis->hDC, rect.left, rect.top, rect.right, rect.bottom);

	DeleteObject(hpen);
	DeleteObject(hbrush);
	
	DrawAvatar(lpdis);
	DrawMessage(lpdis);
	DrawVia(lpdis);
}

void GVSearchListBox::DrawAvatar(LPDRAWITEMSTRUCT lpdis)
{
	if (m_findMessages.size() > 0 && m_findMessages.size() >= lpdis->itemID)
	{
		RECT rect(lpdis->rcItem);

		Gdiplus::Graphics g(lpdis->hDC);

		Gdiplus::Rect r(
			rect.left + avatar_padding_left,
			rect.top + DEFAULT_ITEM_HEIGHT / 2 - avatar_size / 2,
			avatar_size, avatar_size
		);

		auto u = m_findMessages[lpdis->itemID].pairs[L"u"];

		auto p = GVProfileCache::SharedInstance().Find(u)[L"p"];


		if (
			Gdiplus::Bitmap * bitmapAvatar = GVBitmapCache::SharedInstance().Find(p)
			)
		{
			g.DrawImage(bitmapAvatar, r);
		}
		else
		{
			if (
				Gdiplus::Bitmap * bitmapAvatar =
				GVBitmapCache::SharedInstance().Find(L"default")
				)
			{
				g.DrawImage(bitmapAvatar, r);
			}
			else
			{
				// ...
			}
		}
	}
}

void GVSearchListBox::DrawMessage(LPDRAWITEMSTRUCT lpdis)
{
	if (m_findMessages.size() > 0 && m_findMessages.size() >= lpdis->itemID)
	{
		RECT rect(lpdis->rcItem);

		HDC hdc = lpdis->hDC;

		LOGFONT lFont;

		std::memset(&lFont, 0, sizeof(LOGFONT));

		lFont.lfHeight = 14;
		lFont.lfWeight = FW_NORMAL;

		lstrcpy(lFont.lfFaceName, L"Sans Droid");

		HFONT font = CreateFontIndirect(&lFont);

		SelectObject(hdc, font);

		if (lpdis->itemState & ODS_SELECTED)
		{
			SetTextColor(hdc, RGB(128, 128, 128));
		}
		else
		{
			SetTextColor(hdc, RGB(128, 128, 128));
		}
    
		SetBkMode(hdc, TRANSPARENT);
    
		auto m = m_findMessages[lpdis->itemID].pairs[L"m"];

		if (m.size() > 0)
		{
			enum { text_padding_right = 12 };

			RECT dest(rect);
			dest.left += 56;
			dest.top += 12;
			dest.right -= text_padding_right;

			DrawText(hdc, m.c_str(), m.size(), &dest, DT_WORDBREAK | DT_EXPANDTABS);
		}

		DeleteObject(font);
	}
}

void GVSearchListBox::DrawVia(LPDRAWITEMSTRUCT lpdis)
{
	if (m_findMessages.size() > 0 && m_findMessages.size() >= lpdis->itemID)
	{
		RECT rect(lpdis->rcItem);

		HDC hdc = lpdis->hDC;

		LOGFONT lFont;

		std::memset(&lFont, 0, sizeof(LOGFONT));

		lFont.lfHeight = 14;
		lFont.lfWeight = FW_NORMAL;

		lstrcpy(lFont.lfFaceName, L"Sans Droid");

		HFONT font = CreateFontIndirect(&lFont);

		SelectObject(hdc, font);

		if (lpdis->itemState & ODS_SELECTED)
		{
			SetTextColor(hdc, RGB(128, 128, 128));
		}
		else
		{
			SetTextColor(hdc, RGB(128, 128, 128));
		}
    
		SetBkMode(hdc, TRANSPARENT);
    
		auto u = m_findMessages[lpdis->itemID].pairs[L"u"];

		if (u.size() > 0)
		{
			auto profile = GVProfileCache::SharedInstance().Find(u);

			auto f = profile[L"f"];

			auto __t = atol(Utility::ws2s(m_findMessages[lpdis->itemID].pairs[L"__t"]).c_str());

			auto time = std::time(0) - __t;

			BOOL isSecs = FALSE, isMins = FALSE, isHours = FALSE, isExpired = FALSE;

			if (time > 60 * 60 * 72)
			{
				isExpired = TRUE;
			}
			else if (time > 60 * 60)
			{
				isHours = TRUE;

				time = time / 60 / 60;
			}
			else if (time > 60)
			{
				isMins = TRUE;

				time = time / 60;
			}
			else
			{
				isSecs = TRUE;
			}

			time = max(1, time);

			std::wstring timeFormat;

			if (isSecs)
			{
				timeFormat = L"seconds";
			}
			else if (isMins)
			{
				timeFormat = L"minutes";
			}
			else if (isHours)
			{
				timeFormat = L"hours";
			}

			std::wstring formatted(
				std::to_wstring(time) + + L" " + timeFormat + L" ago via " + (f.size() > 0 ? f : u)
			);

			enum { text_padding_right = 12 };

			RECT dest(rect);
			dest.left += 56;
			dest.top = rect.bottom - 28;
			dest.right -= text_padding_right;
			DrawText(hdc, formatted.c_str(), formatted.size(), &dest, DT_WORDBREAK);
		}

		DeleteObject(font);
	}
}

LRESULT GVSearchListBox::WndProc(UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch(uMsg)
	{
		case WM_LBUTTONDOWN:
		{
#if 0
			//auto rowIndex = SendMessage(m_hWnd, LB_GETCURSEL, 0, 0);

			auto x = LOWORD(lParam);
            auto y = HIWORD(lParam);


			//D2D1::Point2U p2u(LOWORD(x), HIWORD(y))

			auto xPixels = x * 72 / 96;
			auto yPixels = y * 72 / 96;

			LONG_PTR rowIndex = LOWORD(SendMessage(m_hWnd, LB_ITEMFROMPOINT, (WPARAM)xPixels, (LPARAM)yPixels));

			 if (rowIndex == LB_ERR)
				break;
			//log_debug("~~~~~~~~~~~~~~~~ GVSearchListBox::WndProc click rowIndex = " << rowIndex);



			log_debug("~~~~~~~~~~~~~~~~ rowIndex = " << rowIndex << ", x = " << x << ", y = " << y);
#endif
		}
		break;
		default:
		break;
	}

	return WndProcDefault(uMsg, wParam, lParam);
}


BOOL GVSearchListBox::OnCommand(WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);

	switch (LOWORD(wParam))
    {
		default:
		break;
    }

	return FALSE;
}