
#pragma once

#include <string>

class GVMessageWnd : public Win32xx::CDialog
{
public:
		
	GVMessageWnd(UINT nResID, CWnd* pParent = NULL)
		: Win32xx::CDialog(nResID, pParent)
	{
		// ...
	}

	virtual ~GVMessageWnd() {}

	private:

protected:

	virtual BOOL OnInitDialog();

	virtual INT_PTR DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam);

	virtual BOOL OnCommand(WPARAM wParam, LPARAM lParam);
};
