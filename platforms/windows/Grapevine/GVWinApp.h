
#pragma once

#include "GVTrayWnd.h"

#include "GVStack.h"
#include "GVTimelineWnd.h"

class GVWinApp : public Win32xx::CWinApp
{
	public:
		
		GVWinApp(); 
		
		virtual ~GVWinApp();
		
		virtual BOOL InitInstance();
		//CMyDialog & GetDialog() {return m_MyDialog;}

		void SignOut();

		void Search(CString & str);

		void ShowMainWindow();

		CPropertySheet & optionsWnd();

		static GVStack * g_GVStack;

	private:

		BOOL m_signedIn;

		GVTrayWnd m_gvTrayWnd;

		GVTimelineWnd m_gvTimelineWnd;

		CPropertySheet m_optionsWnd;

	protected:

		// ...
};

inline GVWinApp & GVGetWinApp() { return *((GVWinApp*)Win32xx::GetApp()); }
