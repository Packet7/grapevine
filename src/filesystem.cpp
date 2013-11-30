/**
 * Copyright (C) 2013 Packet7, LLC.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#include <cassert>
#include <cstdlib>

#include <boost/asio.hpp>
#include <boost/format.hpp>

#include <grapevine/filesystem.hpp>
#include <grapevine/logger.hpp>

using namespace grapevine;

#if (defined _MSC_VER)
#include "Shlobj.h"
#define ERRNO GetLastError()
static int _mkdir(const char * path)
{
    std::wstring directory(path, path + strlen(path));

    return SHCreateDirectoryEx(NULL, directory.c_str(), NULL );
}
#define CREATE_DIRECTORY(P) _mkdir(P)
#else
#include <sys/stat.h>
#define ERRNO errno
#define ERROR_ALREADY_EXISTS EEXIST
static int _mkdir(const char * dir)
{
    char tmp[256];
    char * p = NULL;
    size_t len;
 
    snprintf(tmp, sizeof(tmp),"%s",dir);
    len = strlen(tmp);
    
    if (tmp[len - 1] == '/')
    {
        tmp[len - 1] = 0;
    }
    
    for (p = tmp + 1; *p; p++)
    {
        if (*p == '/')
        {
            *p = 0;

            mkdir(tmp, S_IRWXU);

            *p = '/';
        }
    }
    
    return mkdir(tmp, S_IRWXU);
}
#define CREATE_DIRECTORY(P) _mkdir(P)
#endif

int filesystem::error_already_exists = ERROR_ALREADY_EXISTS;

int filesystem::create_path(const std::string & path)
{
    if (CREATE_DIRECTORY(path.c_str()) == 0)
    {
        return 0;
    }
    
    return ERRNO;
}

std::string filesystem::data_path()
{
    static const std::string bundle_id = "am.grapevine.grapevine";
    std::string ret;
#if (defined _MSC_VER)
    ret += getenv("APPDATA");
    ret += "\\" + bundle_id + "\\";
#elif (defined __APPLE__)
    ret = home_path();
    ret += "Library/";
    ret += "Application Support/";
    ret += bundle_id + "/";
#elif (defined __ANDROID__)
    ret = home_path() + bundle_id + "/";
#else
    ret = home_path();
    ret += "." + bundle_id + "/data/";
#endif
    return ret;
}

std::string filesystem::home_path()
{
    std::string ret;
#if (defined __ANDROID__)
    static const std::string android_package = "am.grapevine.grapevine";
    ret = "/data/data/" + android_package;
#else
    if (std::getenv("HOME"))
    {
        ret = std::getenv("HOME");
    }
    else if (std::getenv("USERPOFILE"))
    {
        ret = std::getenv("USERPOFILE");
    }
    else if (std::getenv("HOMEDRIVE") && std::getenv("HOMEPATH"))
    {
        ret = (
            boost::format("%1%%2%") % std::getenv("HOMEDRIVE") %
            std::getenv("HOMEPATH")
        ).str();
    }
    else
    {
        ret = ".";
    }
#endif // __ANDROID__
#if (defined _MSC_VER)
    return ret + "\\";
#else
    return ret + "/";
#endif
}
