ARCHS = armv7 arm64
CFLAGS = -I../ -I../Theming -O2 

include $(THEOS)/makefiles/common.mk

TOOL_NAME = ZypenDaemon
ZypenDaemon_FILES = main.mm
ZypenDaemon_PRIVATE_FRAMEWORKS = Foundation MobileCoreServices

include $(THEOS_MAKE_PATH)/tool.mk
