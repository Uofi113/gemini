export ARCHS = armv7 armv7s
export TARGET = iphone:clang:latest:6.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = G6mini

G6mini_FILES = $(wildcard *.m)
G6mini_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore AudioToolbox AVFoundation SystemConfiguration
G6mini_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
G6mini_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/application.mk
