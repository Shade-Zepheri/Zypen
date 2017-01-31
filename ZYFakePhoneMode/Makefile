ARCHS = armv7 arm64
CFLAGS = -I../ -I../Theming -O2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ZypenFakePhoneMode
ZypenFakePhoneMode_FILES = Tweak.xm
ZypenFakePhoneMode_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
