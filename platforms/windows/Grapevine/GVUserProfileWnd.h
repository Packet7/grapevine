
#pragma once

#include <string>

class GVUserProfileWnd : public Win32xx::CDialog
{
public:
		
	GVUserProfileWnd(UINT nResID, CWnd* pParent = NULL)
		: Win32xx::CDialog(nResID, pParent)
	{
		// ...
	}

	virtual ~GVUserProfileWnd() {}

		void SetupProfile(
			const std::wstring & username,
			std::map<std::wstring, std::wstring> & profile
		);

	private:

		CButton m_subscribeButton;
		CStatic m_staticUsername;
		CStatic m_staticProfileFullname;

		std::wstring m_username;
		std::map<std::wstring, std::wstring> m_profile;

protected:

	virtual BOOL OnInitDialog();

	virtual INT_PTR DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam);

	virtual BOOL OnCommand(WPARAM wParam, LPARAM lParam);
};
