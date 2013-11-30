#pragma once

#include "stdafx.h"

#include <string>

class Registry
{
	public:

		/**
		 * Sets a key/value in the registry.
		 * @param key
		 * @param value
		 */
		static void SetValue(const std::wstring &, const std::wstring &);

		/**
		 * Gets a key/value from the registry.
		 * @param key
		 */
		static std::wstring GetValue(const std::wstring &);

	private:

		// ...

	protected:

		// ...
};
