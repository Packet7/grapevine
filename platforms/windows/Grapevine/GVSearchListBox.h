
#pragma once

#include <mutex>
#include <vector>

#include "GVStack.h"

class GVSearchListBox : public Win32xx::CListBox
{
	public:

			void AddItem(GVStack::find_message_t &);
			void Clear();
			void MeasureItem(LPMEASUREITEMSTRUCT lpmis);
			void DrawItem(LPDRAWITEMSTRUCT lpdis);


			std::vector<GVStack::find_message_t> & findMessages()
			{
				return m_findMessages;
			}
	private:

			void DrawSelected(LPDRAWITEMSTRUCT lpdis);
			void DrawEntire(LPDRAWITEMSTRUCT lpdis);
			void DrawAvatar(LPDRAWITEMSTRUCT lpdis);
			void DrawMessage(LPDRAWITEMSTRUCT lpdis);
			void DrawVia(LPDRAWITEMSTRUCT lpdis);

			std::vector<GVStack::find_message_t> m_findMessages;

	protected:

		virtual LRESULT WndProc(UINT uMsg, WPARAM wParam, LPARAM lParam);

		virtual BOOL OnCommand(WPARAM wParam, LPARAM lParam);

		enum { avatar_size = 32 };
		enum { avatar_padding_left = 12 };

		std::recursive_mutex mutex_;
};