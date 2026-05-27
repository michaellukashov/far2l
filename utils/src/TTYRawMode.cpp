#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include "TTYRawMode.h"

TTYRawMode::TTYRawMode(int std_in, int std_out)
{
	// try first stdout, but if it fails - try stdin
	// this helps to work with specific cases of redirected
	// output, like working with tee
	if (tcgetattr(std_out, &_ts) != 0) {
		if (tcgetattr(std_in, &_ts) != 0) {
			return;
		}
		_fd = dup(std_in);
	} else {
		_fd = dup(std_out);
	}
	if (_fd == -1) {
		fprintf(stderr, "TTYRawMode: dup failed: %s\n", strerror(errno));
		return;
	}

	struct termios ts_ne = _ts;
	cfmakeraw(&ts_ne);
	// Explicitly clear all flags that could interfere with control character
	// passing. cfmakeraw() only clears a subset; some systems may have
	// additional flags that prevent raw byte delivery.
	// See termios(3) and cfmakeraw(3) for flag definitions.
	ts_ne.c_iflag &= ~(IGNBRK | BRKINT | IGNPAR | PARMRK | INPCK | ISTRIP
		| INLCR | IGNCR | ICRNL | IUCLC | IXON | IXANY | IXOFF | IMAXBEL | IUTF8);
	ts_ne.c_oflag &= ~(OPOST | OLCUC | ONLCR | OCRNL | ONOCR | ONLRET
		| OFILL | OFDEL | NLDLY | CRDLY | TABDLY | BSDLY | VTDLY | FFDLY);
	ts_ne.c_lflag &= ~(ISIG | ICANON | IEXTEN | ECHO | ECHOE | ECHOK
		| ECHONL | NOFLSH | TOSTOP | ECHOCTL | ECHOPRT | ECHOKE
		| FLUSHO | PENDIN);
	ts_ne.c_cflag &= ~(CSIZE | PARENB | PARODD | HUPCL | CSTOPB | CRTSCTS);
	ts_ne.c_cflag |= CS8 | CREAD | CLOCAL;
	ts_ne.c_cc[VMIN] = 1;
	ts_ne.c_cc[VTIME] = 0;
	if (tcsetattr( _fd, TCSADRAIN, &ts_ne ) != 0) {
		fprintf(stderr, "TTYRawMode: tcsetattr failed on fd=%d: %s\n", _fd, strerror(errno));
		close(_fd);
		_fd = -1;
	}
}

TTYRawMode::~TTYRawMode()
{
	if (_fd != -1) {
		if (tcsetattr(_fd, TCSADRAIN, &_ts) != 0) {
			perror("~TTYRawMode - tcsetattr");
		}
		close(_fd);
	}
}
