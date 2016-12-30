CFLAGS = -O2 -fobjc-arc -I../ -I../Backgrounding/ -I../Theming/ -Wno-deprecated-declarations
LDFLAGS = -F$(THEOS)/frameworks

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = zypen
zypen_FILES = $(wildcard *.m) $(shell find $(THEOS)/include/SettingsKit -name '*.m') $(wildcard *.xm) $(wildcard ../Theming/*.mm) 
zypen_INSTALL_PATH = /Library/PreferenceBundles
zypen_FRAMEWORKS = UIKit MessageUI Social QuartzCore CoreGraphics
zypen_PRIVATE_FRAMEWORKS = Preferences
zypen_LIBRARIES = applist substrate

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/zypen.plist$(ECHO_END)
