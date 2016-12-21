include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = zypen
zypen_FILES = ZYPRootListController.m ZYPOptionsController.m ZYPAboutController.m
zypen_INSTALL_PATH = /Library/PreferenceBundles
zypen_FRAMEWORKS = UIKit Social
zypen_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/zypen.plist$(ECHO_END)
