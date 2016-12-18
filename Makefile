ARCHS = arm64
CFLAGS += -fobjc-arc -O2 -Wno-deprecated-declarations -ferror-limit=200
TARGET = iphone:9.2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Zypen
Zypen_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m) \
		$(wildcard Gestures/*.xm) $(wildcard Gestures/*.mm) $(wildcard Gestures/*.m) \
		$(wildcard ReachApp/*.xm) $(wildcard ReachApp/*.mm) $(wildcard ReachApp/*.m) \
		$(wildcard widgets/Reachability/*.xm) $(wildcard widgets/Reachability/*.mm) $(wildcard widgets/Reachability/*.m) \
		$(wildcard Messaging/*.xm) $(wildcard Messaging/*.mm) $(wildcard Messaging/*.m)
Zypen_FRAMEWORKS = UIKit QuartzCore CoreGraphics CoreImage
Zypen_PRIVATE_FRAMEWORKS = GraphicsServices BackBoardServices AppSupport IOKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += zypen
include $(THEOS_MAKE_PATH)/aggregate.mk
