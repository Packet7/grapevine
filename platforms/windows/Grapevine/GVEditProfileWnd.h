
#pragma once

class GVEditProfileWnd : public Win32xx::CDialog
{
public:
		
	GVEditProfileWnd(UINT nResID, CWnd* pParent = NULL)
		: Win32xx::CDialog(nResID, pParent)
	{
		// ...
	}

	virtual ~GVEditProfileWnd() {}

	private:

		CEdit m_editFullname;
		CEdit m_editLocation;
		CEdit m_editPhoto;
		CEdit m_editWeb;
		CEdit m_editBio;

protected:

	virtual BOOL OnInitDialog();

	virtual INT_PTR DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam);

	virtual BOOL OnCommand(WPARAM wParam, LPARAM lParam);
};
