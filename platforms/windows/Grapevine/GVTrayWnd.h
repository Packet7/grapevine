
#pragma once

class GVTrayWnd : public Win32xx::CDialog
{
public:
	GVTrayWnd(UINT nResID, CWnd* pParent = NULL)
		: Win32xx::CDialog(nResID, pParent)
	{
		// ...
	}

	virtual ~GVTrayWnd() {}

	void Show()
	{
		Create();
		ShowWindow();
		ShowTray();
	}

	void ShowTray();

	private:

protected:

	virtual BOOL OnInitDialog();

	virtual void OnTrayIcon(WPARAM wParam, LPARAM lParam);

	virtual INT_PTR DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam);

	virtual BOOL OnCommand(WPARAM wParam, LPARAM lParam);
};
