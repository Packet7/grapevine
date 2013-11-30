
#include "stdafx.h"
#include "resource.h"

#include <chrono>
#include <future>
#include <string>
#include <thread>

#include "GVSignUpWnd.h"
#include "GVUtility.h"
#include "GVWinApp.h"

BOOL GVSignUpWnd::OnInitDialog()
{
	AttachItem(IDC_EDIT_SIGNUP_USERNAME, m_editUsername);
	AttachItem(IDC_EDIT_SIGNUP_PASSWORD1, m_editPassword1);
	AttachItem(IDC_EDIT_SIGNUP_PASSWORD2, m_editPassword2);
	AttachItem(IDC_EDIT_SIGNUP_SECRET, m_editSecret);
	
	return true;
}

INT_PTR GVSignUpWnd::DialogProc(UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch(uMsg)
	{
		case WM_ERASEBKGND:
		{
			RECT rc;
			::GetClientRect(m_hWnd, &rc);
			HBRUSH brush = CreateSolidBrush(RGB(255,255,255));
			FillRect((HDC)wParam, &rc, brush);
			DeleteObject(brush);
			return TRUE;
		}
		break;
		case WM_CTLCOLORSTATIC:
		{
			static HBRUSH hBrush = CreateSolidBrush(RGB(255, 255, 255));
			DWORD CtrlID = ::GetDlgCtrlID((HWND)lParam); //Window Control ID
			HDC hdcStatic = (HDC) wParam;
			SetTextColor(hdcStatic, RGB(0,0,0));
			SetBkColor(hdcStatic, RGB(255, 255, 255));
			return (INT_PTR)hBrush;
		}
		break;
		default:
		break;
	}

	return DialogProcDefault(uMsg, wParam, lParam);
}

BOOL GVSignUpWnd::OnCommand(WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);

	switch (LOWORD(wParam))
    {
		case IDC_BUTTON_SIGN_UP:
		{
			SignUp();
		}
		break;
		default:
		break;
    }

	return FALSE;
}

void GVSignUpWnd::SignUp()
{
	auto username = m_editUsername.GetWindowText();
	auto password1 = m_editPassword1.GetWindowText();
	auto password2 = m_editPassword2.GetWindowText();
	auto secret = m_editSecret.GetWindowText();

	if (username.GetLength() < 5)
	{
		MessageBox(L"Username must be at least 5 characters.", L"Error", MB_ICONERROR);
	}
	else if (password1 != password2)
	{
		MessageBox(L"Passwords do not match.", L"Error", MB_ICONERROR);
	}
	else if (
		password1.GetLength() < 5 || password2.GetLength() < 5
		)
	{
		MessageBox(L"Password must be at least 5 characters.", L"Error", MB_ICONERROR);
	}
	else if (secret.GetLength() < 5)
	{
		MessageBox(L"Secret must be at least 5 characters.", L"Error", MB_ICONERROR);
	}
	else
	{
		GVWinApp::g_GVStack->m_on_sign_up = [this, username, password1] (GVStack::sign_up_t msg)
		{
			if (msg.pairs[L"status"] == L"0")
			{
				GVWinApp::g_GVStack->m_editUsername.SetWindowText(username.c_str());
				GVWinApp::g_GVStack->m_editPassword.SetWindowText(password1.c_str());

				ShowWindow(SW_HIDE);

				GVWinApp::g_GVStack->PostMessage(WM_GV_SIGN_IN, 0, 0);
			}
			else
			{
				std::wstring message =
					L"Sign up failed, " + msg.pairs[L"message"] + L"."
				;

				MessageBox(message.c_str(), L"Error", MB_ICONERROR);
			}
		};

		GVWinApp::g_GVStack->sign_up(
			Utility::ws2s(username.GetString()), Utility::ws2s(password1.GetString()),
			Utility::ws2s(secret.GetString())
		);
	}
}
