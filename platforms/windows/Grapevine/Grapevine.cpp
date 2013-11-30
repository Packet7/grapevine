// Grapevine.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include "Grapevine.h"
#include "GVWinApp.h"

int APIENTRY WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
	try
	{
		// Start Win32++
		GVWinApp theApp;

		// Run the application
		return theApp.Run();
	}
	catch (std::exception & e)
	{
		e.what();
		return -1;
	}
}