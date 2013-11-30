// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#include "targetver.h"

#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
// Windows Header Files:
#include <windows.h>

// C RunTime Header Files
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <tchar.h>


// TODO: reference additional headers your program requires here

#include <Shellapi.h>

#include <Dwmapi.h>

#include <vector>
#include <map>
#include <string>
#include <sstream>		// Add support for stringstream
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <tchar.h>

#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <wchar.h>
#include <math.h>

#include <d2d1.h>
#include <d2d1helper.h>
#include <dwrite.h>
#include <wincodec.h>

#include <gdiplus.h>

#include <controls.h>
#include <dialog.h>
//#include <docking.h>
//#include <file.h>
#include <frame.h>
//#include <gdi.h>
#include <listview.h>
//#include <mdi.h>
#include <propertysheet.h>
//#include <rebar.h>
//#include <ribbon.h>
//#include <socket.h>
#include <statusbar.h>
#include <stdcontrols.h>
#include <toolbar.h>
#include <treeview.h>
//#include <webbrowser.h>
#include <wincore.h>

#include <grapevine/logger.hpp>

#include "GVProfileCache.h"
#include "GVRegistry.h"
#include "GVStack.h"
#include "GVUtility.h"

template<class Interface>
inline void
SafeRelease(
    Interface **ppInterfaceToRelease
    )
{
    if (*ppInterfaceToRelease != NULL)
    {
        (*ppInterfaceToRelease)->Release();

        (*ppInterfaceToRelease) = NULL;
    }
}

#pragma comment(lib, "Dwmapi.lib ")

static HRESULT EnableBlurBehind(HWND hwnd)
{
   HRESULT hr = S_OK;

   // Create and populate the Blur Behind structure
   DWM_BLURBEHIND bb = {0};

   // Enable Blur Behind and apply to the entire client area
   bb.dwFlags = DWM_BB_ENABLE;
   bb.fEnable = true;
   bb.hRgnBlur = NULL;

   // Apply Blur Behind
   hr = DwmEnableBlurBehindWindow(hwnd, &bb);

   if (SUCCEEDED(hr))
   {
	   // ...
   }

   return hr;
}
