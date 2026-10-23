#include "OSC52ClipboardBackend.h"
#include "WinPort.h"
#include <utils.h>

OSC52ClipboardBackend::OSC52ClipboardBackend(IOSC52Interactor *interactor) :
	_interactor(interactor)
{
}

void *OSC52ClipboardBackend::OnClipboardSetData(UINT format, void *data)
{
	if (format == CF_UNICODETEXT) {
		size_t wchar_cnt = WINPORT(ClipboardSize)(data) / sizeof(wchar_t);
		if (wchar_cnt && ((const wchar_t *)data)[wchar_cnt - 1] == 0) {
			--wchar_cnt;	// drop exactly one terminating NUL, embedded NULs are significant
		}

		std::string str;
		Wide2MB((const wchar_t *)data, wchar_cnt, str);
		_interactor->OSC52SetClipboard(str.c_str(), str.size());
	}
	return FSClipboardBackend::OnClipboardSetData(format, data);
}
