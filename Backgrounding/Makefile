ARCHS = armv7 arm64

CFLAGS = -I../ -I../Theming/
CFLAGS += -fno-objc-arc -O2 -Wno-deprecated-declarations

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ZypenBackgrounding
ZypenBackgrounding_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m) ../Tweak.xm
ZypenBackgrounding_FRAMEWORKS = UIKit CoreGraphics
ZypenBackgrounding_LIBRARIES = applist
UnlimitedBackgrounding.xm_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
