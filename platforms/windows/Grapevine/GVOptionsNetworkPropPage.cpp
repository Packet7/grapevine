
#include "stdafx.h"
#include "resource.h"

#include "GVOptionsNetworkPropPage.h"
#include "GVWinApp.h"

GVOptionsNetworkPropPage::GVOptionsNetworkPropPage()
	: Win32xx::CPropertyPage(IDD_PROPPAGE_OPTIONS_NETWORK, L"Network")
{
	// ...
}

int GVOptionsNetworkPropPage::OnApply()
{
	CString port = GetDlgItemText(IDC_EDIT_OPTIONS_NETWORK_PORT);

	if (port.GetLength() > 0)
	{
		Registry::SetValue(L"port", port.GetString());
	}

	return 1;
}

void GVOptionsNetworkPropPage::OnCancel()
{
	GVGetWinApp().optionsWnd().ShowWindow(SW_HIDE);
}

BOOL GVOptionsNetworkPropPage::OnInitDialog()
{
	auto port = Registry::GetValue(L"port");

	if (port.size() > 0)
	{
		SetDlgItemText(IDC_EDIT_OPTIONS_NETWORK_PORT, port.c_str());
	}

	return TRUE;
}

int GVOptionsNetworkPropPage::OnOK()
{
	CString port = GetDlgItemText(IDC_EDIT_OPTIONS_NETWORK_PORT);

	if (port.GetLength() > 0)
	{
		Registry::SetValue(L"port", port.GetString());
	}

	GetParent()->ShowWindow(SW_HIDE);

	return 1;
}
