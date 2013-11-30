
#pragma once

#include <cstdint>

#include "GVSearchListBox.h"
#include "GVStack.h"
#include "GVUserProfileWnd.h"

class GVSearchWnd : public Win32xx::CDialog
{
public:
		
	GVSearchWnd(UINT nResID, CWnd* pParent = NULL)
		: Win32xx::CDialog(nResID, pParent)
		, m_userProfileWnd(IDD_DIALOG_USER_PROFILE)
	{
		// ...
	}

	virtual ~GVSearchWnd() {}

	void HandleFindMessage(GVStack::find_message_t & msg);

	private:

		CEdit m_editSearch;
		CButton m_buttonSearch;

		CResizer m_resizer;

		GVSearchListBox m_listBoxSearchResults;

		GVUserProfileWnd m_userProfileWnd;

		std::uint16_t m_transactionId;

protected:

	virtual BOOL OnInitDialog();

	virtual INT_PTR DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam);

	virtual BOOL OnCommand(WPARAM wParam, LPARAM lParam);
};
