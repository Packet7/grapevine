
#pragma once

#include <cstdint>
#include <list>

#include "GVComposeWnd.h"
#include "GVEditProfileWnd.h"
#include "GVUserProfileWnd.h"
#include "GVMessageWnd.h"
#include "GVSearchListBox.h"
#include "GVSearchWnd.h"
#include "GVStack.h"

class GVTimelineWnd : public Win32xx::CDialog
{
public:
		
	GVTimelineWnd(UINT nResID, CWnd* pParent = NULL);

	virtual ~GVTimelineWnd() {}

		void HandleFindMessage(GVStack::find_message_t & msg);

		void Search(CString & str);

		void Reset()
		{
			m_find_messages.clear();
		}

	private:

		CResizer m_resizer;

		CWnd m_searchSysLink;
		CWnd m_composeSysLink;
		CListBox m_SubscriptionslistBox;
		CListView m_timelineListView;

		GVSearchListBox m_listBoxSubsciptions;
		CEdit m_editSearch;
		CButton m_buttonSearch;
		GVSearchListBox m_listBoxSearchResults;

		GVComposeWnd m_composeWnd;

		GVEditProfileWnd m_editProfileWnd;
		GVUserProfileWnd m_userProfileWnd;
		GVMessageWnd m_messageWnd;

		CWnd m_fooWnd;

		class message_entry_t
		{
			public:

				GVStack::find_message_t findMessage;
		};

		std::vector<message_entry_t> m_find_messages;

		std::int32_t m_searchTransactionId;

protected:

	virtual BOOL OnInitDialog();

	virtual INT_PTR DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam);

	virtual BOOL OnCommand(WPARAM wParam, LPARAM lParam);

		enum
		{
			mode_timeline,
			mode_search,
		} mode_;
};
