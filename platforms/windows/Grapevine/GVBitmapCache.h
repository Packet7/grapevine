
#pragma once

#include <map>
#include <string>

#include "GVGdiPlusBitmap.h"

class GVBitmapCache
{
	public:

		GVBitmapCache()
		{
			GVGdiPlusBitmapResource * bitmapRes = new GVGdiPlusBitmapResource();

			if (bitmapRes->Load(IDR_JPG_AVATAR, L"JPG", 0))
			{
				Gdiplus::Bitmap * gdiPlusBitmap = bitmapRes->Bitmap();
				/*
				if (bitmapRes->Bitmap()->GetWidth() == 36 && bitmapRes->Bitmap()->GetHeight() == 36)
				{
					gdiPlusBitmap = bitmapRes->Bitmap();
				}
				else
				{
					gdiPlusBitmap = bitmapRes->ResizeClone(bitmapRes->Bitmap(), 36, 36);
				}
				*/
				m_cache.insert(std::make_pair(L"default", gdiPlusBitmap));
			}
		}

		static GVBitmapCache & SharedInstance()
		{
			static GVBitmapCache gInstance;

			return gInstance;
		}

		void Insert(
			const std::wstring & key, const char * buf, const std::size_t & len
			)
		{
			GVGdiPlusBitmapResource * bitmapRes = new GVGdiPlusBitmapResource();

			if (bitmapRes->Load(buf, len))
			{
				Gdiplus::Bitmap * gdiPlusBitmap = bitmapRes->ResizeClone(bitmapRes->Bitmap(), 32, 32);

				m_cache.insert(std::make_pair(key, gdiPlusBitmap));
			}

			delete bitmapRes;
		}

		Gdiplus::Bitmap * Find(const std::wstring & key)
		{
			// :TODO: mutex
			auto it = m_cache.find(key);

			if (it == m_cache.end())
			{
				return 0;
			}

			return it->second;
		}

	private:

		std::map<std::wstring, Gdiplus::Bitmap *> m_cache;

	protected:

};