
#pragma once

#include "stdafx.h"

class GVGdiPlusBitmap
{
public:
	Gdiplus::Bitmap* m_pBitmap;

public:
	GVGdiPlusBitmap()							{ m_pBitmap = NULL; }
	GVGdiPlusBitmap(LPCWSTR pFile)				{ m_pBitmap = NULL; Load(pFile); }
	virtual ~GVGdiPlusBitmap()					{ Empty(); }

	void Empty()								{ delete m_pBitmap; m_pBitmap = NULL; }

	bool Load(LPCWSTR pFile)
	{
		Empty();
		m_pBitmap = Gdiplus::Bitmap::FromFile(pFile);
		return m_pBitmap->GetLastStatus() == Gdiplus::Ok;
	}

    Gdiplus::Bitmap * Bitmap() { return m_pBitmap; }

	operator Gdiplus::Bitmap*() const			{ return m_pBitmap; }

    /**
     * Resizes a bitmap maintaining aspect ratio.
     */
    static Gdiplus::Bitmap* ResizeClone(Gdiplus::Bitmap * bmp, INT width, INT height)
    {
        UINT o_height = bmp->GetHeight();
        UINT o_width = bmp->GetWidth();
        INT n_width = width;
        INT n_height = height;
        double ratio = ((double)o_width) / ((double)o_height);
        if (o_width > o_height) {
            // Resize down by width
            n_height = static_cast<UINT>(((double)n_width) / ratio);
        } else {
            n_width = static_cast<UINT>(n_height * ratio);
        }

        Gdiplus::Bitmap* newBitmap = new Gdiplus::Bitmap(n_width, n_height, bmp->GetPixelFormat());
        Gdiplus::Graphics graphics(newBitmap);
		
		//graphics.SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBilinear);
        graphics.DrawImage(bmp, 0, 0, n_width, n_height);
        return newBitmap;
    }

    /**
     * Gets an encoder CLSID from a mime-type.
     */
    static int GetEncoderClsid(const WCHAR* form, CLSID* pClsid)
    {
        UINT num;
        UINT size;
        Gdiplus::ImageCodecInfo* pImageCodecInfo=NULL;
        Gdiplus::GetImageEncodersSize(&num,&size);
        if(size==0)
            return -1;
        pImageCodecInfo=(Gdiplus::ImageCodecInfo*)(malloc(size));
        if(pImageCodecInfo==NULL)
            return -1;
        Gdiplus::GetImageEncoders(num,size,pImageCodecInfo);
        for(UINT j=0;j<num;j++)
        {
            if(wcscmp(pImageCodecInfo[j].MimeType,form)==0)
            {
                *pClsid = pImageCodecInfo[j].Clsid;
                free(pImageCodecInfo);
                return j;
            }
        }
        free(pImageCodecInfo);
        return -1;
    }
};


class GVGdiPlusBitmapResource : public GVGdiPlusBitmap
{
protected:
	HGLOBAL m_hBuffer;

public:
	GVGdiPlusBitmapResource()					{ m_hBuffer = NULL; }
	GVGdiPlusBitmapResource(LPCTSTR pName, LPCTSTR pType = RT_RCDATA, HMODULE hInst = NULL)
												{ m_hBuffer = NULL; Load(pName, pType, hInst); }
	GVGdiPlusBitmapResource(UINT id, LPCTSTR pType = RT_RCDATA, HMODULE hInst = NULL)
												{ m_hBuffer = NULL; Load(id, pType, hInst); }
	GVGdiPlusBitmapResource(UINT id, UINT type, HMODULE hInst = NULL)
												{ m_hBuffer = NULL; Load(id, type, hInst); }
	virtual ~GVGdiPlusBitmapResource()			{ Empty(); }

	void Empty();

	bool Load(LPCTSTR pName, LPCTSTR pType = RT_RCDATA, HMODULE hInst = NULL);
	bool Load(UINT id, LPCTSTR pType = RT_RCDATA, HMODULE hInst = NULL)
												{ return Load(MAKEINTRESOURCE(id), pType, hInst); }
	bool Load(UINT id, UINT type, HMODULE hInst = NULL)
												{ return Load(MAKEINTRESOURCE(id), MAKEINTRESOURCE(type), hInst); }

	inline bool Load(const char * buf, const std::size_t & len);
};

inline void GVGdiPlusBitmapResource::Empty()
{
	GVGdiPlusBitmap::Empty();
	if (m_hBuffer)
	{
		::GlobalUnlock(m_hBuffer);
		::GlobalFree(m_hBuffer);
		m_hBuffer = NULL;
	} 
}

inline bool GVGdiPlusBitmapResource::Load(LPCTSTR pName, LPCTSTR pType, HMODULE hInst)
{
	Empty();

	HRSRC hResource = ::FindResource(hInst, pName, pType);
	if (!hResource)
		return false;
	
	DWORD imageSize = ::SizeofResource(hInst, hResource);
	if (!imageSize)
		return false;

	const void* pResourceData = ::LockResource(::LoadResource(hInst, hResource));
	if (!pResourceData)
		return false;

	m_hBuffer  = ::GlobalAlloc(GMEM_MOVEABLE, imageSize);
	if (m_hBuffer)
	{
		void* pBuffer = ::GlobalLock(m_hBuffer);
		if (pBuffer)
		{
			CopyMemory(pBuffer, pResourceData, imageSize);

			IStream* pStream = NULL;
			if (::CreateStreamOnHGlobal(m_hBuffer, FALSE, &pStream) == S_OK)
			{
				m_pBitmap = Gdiplus::Bitmap::FromStream(pStream);
				pStream->Release();
				if (m_pBitmap)
				{ 
					if (m_pBitmap->GetLastStatus() == Gdiplus::Ok)
						return true;

					delete m_pBitmap;
					m_pBitmap = NULL;
				}
			}
			::GlobalUnlock(m_hBuffer);
		}
		::GlobalFree(m_hBuffer);
		m_hBuffer = NULL;
	}
	return false;
}

inline bool GVGdiPlusBitmapResource::Load(const char * buf, const std::size_t & len)
{
	Empty();

	m_hBuffer  = ::GlobalAlloc(GMEM_MOVEABLE, len);

	if (m_hBuffer)
	{
		void* pBuffer = ::GlobalLock(m_hBuffer);
		if (pBuffer)
		{
			CopyMemory(pBuffer, buf, len);

			IStream * pStream = NULL;
			if (::CreateStreamOnHGlobal(m_hBuffer, FALSE, &pStream) == S_OK)
			{
				m_pBitmap = Gdiplus::Bitmap::FromStream(pStream);
				pStream->Release();
				if (m_pBitmap)
				{ 
					if (m_pBitmap->GetLastStatus() == Gdiplus::Ok)
						return true;

					delete m_pBitmap;
					m_pBitmap = NULL;
				}
			}
			::GlobalUnlock(m_hBuffer);
		}
		::GlobalFree(m_hBuffer);
		m_hBuffer = NULL;
	}
	return false;
}
