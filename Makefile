ARCHS = armv7 arm64
CFLAGS = -I./ -Iwidgets/ -Iwidgets/Core/ -Iwidgets/Reachability/ -IReachApp/ -IGestures/ -IWindows/ -IMessaging/ -IKeyboard/ -ITheming/ -IBackgrounding/
CFLAGS += -fobjc-arc -O2 -Wno-deprecated-declarations
TARGET = iphone:9.2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Zypen
Zypen_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m) \
		$(wildcard Gestures/*.xm) $(wildcard Gestures/*.mm) $(wildcard Gestures/*.m) \
		$(wildcard ReachApp/*.xm) $(wildcard ReachApp/*.mm) $(wildcard ReachApp/*.m) \
		$(wildcard widgets/*.xm) $(wildcard widgets/*.mm) $(wildcard widgets/*.m) \
		$(wildcard widgets/Core/*.xm) $(wildcard widgets/Core/*.mm) $(wildcard widgets/Core/*.m) \
		$(wildcard widgets/Reachability/*.xm) $(wildcard widgets/Reachability/*.mm) $(wildcard widgets/Reachability/*.m) \
		$(wildcard Messaging/*.xm) $(wildcard Messaging/*.mm) $(wildcard Messaging/*.m) \
		$(wildcard Keyboard/*.xm) $(wildcard Keyboard/*.mm) $(wildcard Keyboard/*.m) \
		$(wildcard Windows/*.xm) $(wildcard Windows/*.mm) $(wildcard Windows/*.m) \
		$(wildcard Theming/*.xm) $(wildcard Theming/*.mm) $(wildcard Theming/*.m)
Zypen_FRAMEWORKS = UIKit QuartzCore CoreGraphics CoreImage
Zypen_PRIVATE_FRAMEWORKS = GraphicsServices BackBoardServices AppSupport IOKit
Zypen_LIBRARIES = applist rocketbootstrap

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += zypen
SUBPROJECTS += Backgrounding
SUBPROJECTS += ZYFakePhoneMode
SUBPROJECTS += ZY_assertiond

include $(THEOS_MAKE_PATH)/aggregate.mk
