
#pragma once

#include <string>

class GVSignUpWnd : public Win32xx::CDialog
{
	public:
		
		GVSignUpWnd(UINT nResID, CWnd* pParent = NULL)
			: Win32xx::CDialog(nResID, pParent)
		{
			// ...
		}

		virtual ~GVSignUpWnd() {}

		private:

			CEdit m_editUsername;
			CEdit m_editPassword1;
			CEdit m_editPassword2;
			CEdit m_editSecret;

	protected:

		virtual BOOL OnInitDialog();

		virtual INT_PTR DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam);

		virtual BOOL OnCommand(WPARAM wParam, LPARAM lParam);

		void SignUp();
};
