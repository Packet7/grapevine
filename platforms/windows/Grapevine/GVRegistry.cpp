
#include "stdafx.h"

#include "GVRegistry.h"

#define DMKEY L"Software\\Grapevine"

void Registry::SetValue(const std::wstring & key, const std::wstring & value)
{
	DWORD rc; 
	HKEY dmKey; 

	rc = RegOpenKeyEx(HKEY_CURRENT_USER, DMKEY, 0, KEY_ALL_ACCESS, &dmKey); 

	if (rc != ERROR_SUCCESS)
	{ 
		DWORD dwDisposition;

		rc = RegCreateKeyEx(
			HKEY_CURRENT_USER, DMKEY, 0, NULL, REG_OPTION_NON_VOLATILE, 
			KEY_ALL_ACCESS, NULL, &dmKey, &dwDisposition
		);
	} 

	RegSetValueEx(
		dmKey, key.c_str(), 0, REG_SZ, (LPBYTE)value.c_str(),
		(lstrlen(value.c_str()) + 1) * sizeof(wchar_t)
	); 
}

std::wstring Registry::GetValue(const std::wstring & key)
{
	HKEY dmKey;
	DWORD dwType;
	wchar_t buf[2048];

	DWORD len = sizeof(buf);

	DWORD rc = RegOpenKeyEx(HKEY_CURRENT_USER, DMKEY, 0, KEY_ALL_ACCESS, &dmKey);

	if (rc != ERROR_SUCCESS)
	{
		return std::wstring ();
	}

	rc = RegQueryValueEx(dmKey, key.c_str(), 0, &dwType, (LPBYTE)buf, &len);

	if (rc == ERROR_SUCCESS)
	{
		return std::wstring(buf, len);
	}

	return std::wstring ();
}
