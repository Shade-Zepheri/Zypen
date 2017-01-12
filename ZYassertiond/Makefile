ARCHS = armv7 arm64
CFLAGS = -fobjc-arc -O2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ZypenAssertiondHooks
ZypenAssertiondHooks_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
