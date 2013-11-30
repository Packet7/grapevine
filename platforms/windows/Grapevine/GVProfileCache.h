
#pragma once

#include <map>
#include <string>

class GVProfileCache
{
	public:

		GVProfileCache()
		{
			// ...
		}

		static GVProfileCache & SharedInstance()
		{
			static GVProfileCache gInstance;

			return gInstance;
		}

		void Insert(
			const std::wstring & username,
			const std::map<std::wstring, std::wstring> & profile
			)
		{
			// :TODO: mutex
			m_cache[username] = profile;
		}

		std::map<std::wstring, std::wstring> Find(const std::wstring & key)
		{
			// :TODO: mutex
			auto it = m_cache.find(key);

			if (it == m_cache.end())
			{
				return std::map<std::wstring, std::wstring> ();
			}

			return it->second;
		}

	private:

		std::map<std::wstring, std::map<std::wstring, std::wstring> > m_cache;

	protected:

};