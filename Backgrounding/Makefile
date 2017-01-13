ARCHS = armv7 arm64

CFLAGS = -I../ -I../Theming/ -O2 -Wno-deprecated-declarations

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ZypenBackgrounding
ZypenBackgrounding_FILES = $(wildcard *.xm) ../Tweak.xm
ZypenBackgrounding_FRAMEWORKS = UIKit CoreGraphics
ZypenBackgrounding_LIBRARIES = applist

BackgroundModeTogglerActivator.xm_CFLAGS = -fno-objc-arc
IconIndicator.xm_CFLAGS = -fno-objc-arc
SpringBoard.xm_CFLAGS = -fno-objc-arc
SpringBoard_UIAppCustomBackgroundModes.xm_CFLAGS = -fno-objc-arc
UnlimitedBackgrounding.xm_CFLAGS = -fobjc-arc
ZYBackgrounder.xm_CFLAGS = -fno-objc-arc
Tweak.xm_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
