
#include "stdafx.h"
#include "resource.h"

#include <ctime>

#include "GVWinApp.h"
#include "GVBitmapCache.h"
#include "GVOptionsNetworkPropPage.h"
#include "GVProfileCache.h"

#pragma comment(lib, "comctl32.lib")

GVStack * GVWinApp::g_GVStack;

static ULONG_PTR g_gdiplusToken;

GVWinApp::GVWinApp()
	: m_signedIn(FALSE)
	, m_gvTrayWnd(IDD_DIALOG_TRAY)
	, m_gvTimelineWnd(IDD_DIALOG_TIMELINE)
{
	Gdiplus::GdiplusStartupInput gdiplusStartupInput;
	Gdiplus::GdiplusStartup(&g_gdiplusToken, &gdiplusStartupInput, NULL);

	//SetProcessDPIAware();
}

BOOL GVWinApp::InitInstance()
{
	g_GVStack = new GVStack();

	g_GVStack->Create();

	TRACE(_T("Starting stack...\n"));

	g_GVStack->m_on_connected = [this]()
	{
		// ...
	};

	g_GVStack->m_on_disconnected = [this]()
	{
		// ...
	};

	m_gvTimelineWnd.Create();

	g_GVStack->m_on_signed_in = [this]()
	{
		m_signedIn = TRUE;
		g_GVStack->ShowWindow(SW_HIDE);
		m_gvTimelineWnd.ShowWindow();
	};

	g_GVStack->m_on_version = [this](GVStack::version_t msg)
	{
		if (msg.pairs[L"upgrade"] == L"1" && msg.pairs[L"required"] == L"1")
		{
			MessageBox(
				m_gvTrayWnd.GetHwnd(), L"A required update is available.",
				L"Required Update", MB_ICONINFORMATION
			);

			// :FIXME: "open" doesn't seem to work? So, lets do this hack.
			ShellExecute(0, 0, L"open", L"http://grapevine.am/?platform=windows", 0, SW_SHOWMAXIMIZED);
			ShellExecute(0, 0, L"chrome.exe", L"http://grapevine.am/?platform=windows", 0, SW_SHOWMAXIMIZED);
			ShellExecute(0, 0, L"firefox.exe", L"http://grapevine.am/?platform=windows", 0, SW_SHOWMAXIMIZED);

			ExitProcess(0);
		}
		else if (msg.pairs[L"upgrade"] == L"1")
		{
			MessageBox(
				m_gvTrayWnd.GetHwnd(), L"An update is available.", L"Update",
				MB_ICONINFORMATION
			);
		}
	};

	std::uint16_t port = atoi(Utility::ws2s(Registry::GetValue(L"port")).c_str());

	if (port < 49152)
	{
		std::srand(std::clock());

		port = (std::rand() % (65535 - 49152 + 1)) + 49152;

		Registry::SetValue(L"port", std::to_wstring(port));
	}

	g_GVStack->start(port);
	
	g_GVStack->m_on_find_message = 
		[this] (GVStack::find_message_t & msg)
	{
		m_gvTimelineWnd.HandleFindMessage(msg);
	};
	
	g_GVStack->m_on_find_profile = 
		[this] (GVStack::find_profile_t & msg)
	{
		auto u = msg.pairs[L"u"];

		GVProfileCache::SharedInstance().Insert(u, msg.pairs);

		auto p = msg.pairs[L"p"];

		if (p.size() > 0)
		{
			// :TODO: use latest profile timestamp
			if (GVBitmapCache::SharedInstance().Find(p) == 0)
			{
				std::string narrowp(p.begin(), p.end());

				g_GVStack->url_get(narrowp,
					[this, p] (const std::map<std::string, std::string> & headers, const std::string & body)
				{
					if (body.size() > 0)
					{
						GVBitmapCache::SharedInstance().Insert(p, body.data(), body.size());
					}
				});
			}
		}
	};

	m_gvTrayWnd.Show();
	m_gvTrayWnd.ShowWindow(SW_HIDE);

	return TRUE;
}

void GVWinApp::SignOut()
{
	m_signedIn = FALSE;
	Registry::SetValue(L"username", L"");
	Registry::SetValue(L"password", L"");
	g_GVStack->sign_out();
	m_gvTimelineWnd.ShowWindow(SW_HIDE);
	m_gvTimelineWnd.Reset();
	g_GVStack->ShowWindow(SW_SHOW);
}

void GVWinApp::Search(CString & str)
{
	if (m_signedIn)
	{
		m_gvTimelineWnd.Search(str);
	}
}

void GVWinApp::ShowMainWindow()
{
	if (m_signedIn)
	{
		m_gvTimelineWnd.ShowWindow();
	}
}

CPropertySheet & GVWinApp::optionsWnd()
{
	if (!m_optionsWnd)
	{
		GVOptionsNetworkPropPage * pageNetwork = new GVOptionsNetworkPropPage();

		m_optionsWnd.AddPage(pageNetwork);
		m_optionsWnd.Create();
		m_optionsWnd.CenterWindow();
		m_optionsWnd.SetWindowText(L"Options");
		m_optionsWnd.ShowWindow(SW_HIDE);
	}

	return m_optionsWnd;
}

GVWinApp::~GVWinApp()
{
	// :FIXME:
	//g_GVStack->stop();

	Gdiplus::GdiplusShutdown(g_gdiplusToken);
}
