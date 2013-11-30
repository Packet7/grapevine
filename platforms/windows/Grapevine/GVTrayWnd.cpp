
#include "stdafx.h"
#include "resource.h"
#include "GVTrayWnd.h"
#include "GVWinApp.h"

static const int MSG_TRAYICON = WM_USER + 1;

void GVTrayWnd::ShowTray()
{
    NOTIFYICONDATA nid = { 0 };
    nid.cbSize = sizeof(NOTIFYICONDATA);
    nid.hWnd = m_hWnd;
    nid.uID = IDW_MAIN;
    nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
    nid.uCallbackMessage = MSG_TRAYICON;
	nid.hIcon = (HICON) (::LoadImage (GetModuleHandle(NULL), MAKEINTRESOURCE (IDI_SMALL), IMAGE_ICON,
		::GetSystemMetrics (SM_CXSMICON), ::GetSystemMetrics (SM_CYSMICON), 0));

	lstrcpy(nid.szTip, _T("Grapevine"));

    Shell_NotifyIcon(NIM_ADD, &nid);
}

BOOL GVTrayWnd::OnInitDialog()
{
	SetIconLarge(IDI_GRAPEVINE);
	SetIconSmall(IDI_SMALL);

	return true;
}

void GVTrayWnd::OnTrayIcon(WPARAM wParam, LPARAM lParam)
{
    if (wParam != IDW_MAIN)
		return;

	if (lParam == WM_LBUTTONUP)
    {
		GVGetWinApp().ShowMainWindow();
    }
    else if (lParam == WM_RBUTTONUP)
    {
		CMenu TopMenu(IDC_GRAPEVINE);
		CMenu* pSubMenu = TopMenu.GetSubMenu(0);

        SetForegroundWindow();
		CPoint pt = GetCursorPos();
		UINT uSelected = pSubMenu->TrackPopupMenu(
			TPM_RETURNCMD | TPM_NONOTIFY, pt.x, pt.y, this, NULL
		);

		switch (uSelected)
		{
			case IDM_FILE_EXIT:
			{
				auto result = MessageBox(
					L"Staying online greatly benefits the network.",
					L"Are you sure you want to quit?", MB_YESNO | MB_ICONQUESTION
				);

				if (result == IDYES)
				{
					GVWinApp::g_GVStack->sign_out();

					Destroy();
				}
			}
			break;
			case ID_TOOLS_OPTIONS:
			{
				GVGetWinApp().optionsWnd().ShowWindow();
			}
			break;
			case ID_FILE_SIGNOUT:
			{
				GVGetWinApp().SignOut();
			}
			break;
		}
    }
}

INT_PTR GVTrayWnd::DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch(uMsg)
	{
		case WM_CLOSE:
		{
			ShowWindow(SW_HIDE);
			return -1;
		}
		break;
		case WM_DESTROY:
		{
			NOTIFYICONDATA nid = { 0 };
			nid.cbSize = sizeof(NOTIFYICONDATA);
			nid.hWnd = m_hWnd;
			nid.uID = IDW_MAIN;
			Shell_NotifyIcon(NIM_DELETE, &nid);
			::PostQuitMessage(0);
			return 0;
		}
		break;
		case MSG_TRAYICON:
		{
			OnTrayIcon(wParam, lParam);
		}
		break;
	}

	return DialogProcDefault(uMsg, wParam, lParam);
}

BOOL GVTrayWnd::OnCommand(WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);

	switch (LOWORD(wParam))
    {

    }

	return FALSE;
}