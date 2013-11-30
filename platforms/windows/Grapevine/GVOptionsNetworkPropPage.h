
#pragma once

class GVOptionsNetworkPropPage : public Win32xx::CPropertyPage
{
	public:

		GVOptionsNetworkPropPage();

		virtual int OnApply();
		virtual void OnCancel();
		virtual BOOL OnInitDialog();
		virtual int OnOK();

	private:

	protected:
};
