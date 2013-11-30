
#pragma once

class GVComposeWnd : public Win32xx::CDialog
{
public:
		
	GVComposeWnd(UINT nResID, CWnd* pParent = NULL)
		: Win32xx::CDialog(nResID, pParent)
	{
		// ...
	}

	virtual ~GVComposeWnd() {}

	private:

		CEdit m_editMessage;
		CButton m_buttonPublish;
protected:

	virtual BOOL OnInitDialog();

	virtual INT_PTR DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam);

	virtual BOOL OnCommand(WPARAM wParam, LPARAM lParam);

	void ShortenUrls();
};
