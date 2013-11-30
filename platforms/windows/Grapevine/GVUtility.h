
#pragma once

#include  <string>

class Utility
{
	public:

		static std::string ws2s(const std::wstring & s)
		{
			int len;
			int slength = (int)s.length() + 1;
			len = WideCharToMultiByte(CP_ACP, 0, s.c_str(), slength, 0, 0, 0, 0); 
			char* buf = new char[len];
			WideCharToMultiByte(CP_ACP, 0, s.c_str(), slength, buf, len, 0, 0); 
			std::string r(buf);
			delete[] buf;
			return r;
		}

		static std::wstring mb2ws(const std::string & s)
		{
			std::wstring ret(s.begin(), s.end()); 

			return ret;
		}

};
