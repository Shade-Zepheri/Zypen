ARCHS = armv7 arm64
CFLAGS = -I../ -I../Theming -O2 -fobjc-arc

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ZYFakePhoneMode
ZYFakePhoneMode_FILES = Tweak.xm
ZYFakePhoneMode_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
