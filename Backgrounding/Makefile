ARCHS = armv7  arm64

CFLAGS = -I../ -I../Theming/
CFLAGS += -fobjc-arc -O2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ZypenBackgrounding
ZypenBackgrounding_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m) ../Tweak.xm
ZypenBackgrounding_FRAMEWORKS = UIKit CoreGraphics
ZypenBackgrounding_LIBRARIES = applist

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
