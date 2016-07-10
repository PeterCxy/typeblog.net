```json
{
  "title": "Makefile构建Android App",
  "url": "build-android-app-with-makefile",
  "date": "2014-08-16",
  "parser": "Markdown"
}
```


好吧，各位已经看到，我最近折腾了各种构建Android App的方法。

但是最后，我还是决定选择 `Makefile` 这个工具。

准确地说，它是 `GNU Makefile`, 也是 `类Unix` 系统下常用的一个构建工具。我选择它的原因非常简单，就是因为它有已经交叉编译好的 `ARM` 平台版本。这意味着，我开学以后可以用手机来方便地编译App了。

之前使用的 `shell` 脚本有很多缺陷，比如说遇到错误的时候不能自动终止编译过程。虽然理论上可以终止，但是那一大坨trap写起来就蛋疼。而且 `shell` 脚本中有些编译中需要使用的功能虽然可以自己实现，但是实现起来很麻烦。而 `Makefile` 中往往直接提供这些功能，直接调用，规则写起来非常简洁，可读性很好。

<!--more-->

### 准备

在这个文章中，我使用到了 `Makefile` 的几个特性。

1. 函数 `wildcard`, 它可以遍历目录下符合一定规则的文件。
2. 函数 `foreach`, 它类似于shell中的 `for ... in ...` 这种写法，同样是遍历功能。
3. 函数 `addprefix`/`addsuffix`, 它可以给一个变量中的每一个成员添加前缀/后缀
4. 虚拟目标，用 `.PHONY:` 可以定义虚拟目标，这样定义出来的目标文件可以不存在。
5. 使用 `define ... endef` 定义变量以供调用。

另外，还用到了一个遍历文件的方法

```makefile
SRC			:= \
	$(foreach dir, \
		$(SRC_DIR), \
		$(foreach srcdir, \
			$(shell find $(dir) -maxdepth 10 -type d), \
			$(wildcard $(srcdir)/*.java) \
		 ) \
	 )
```

这段代码的作用是遍历 `SRC_DIR` 里面（包括10级以下子目录）里面所有的java源码文件。

### 技巧

其实，有些技巧还是挺重要的。

1. 使用时间戳文件来代替生成目标。因为 `Makefile` 的虚拟目标功能使用后无法自动判断文件是否需要更新，而 `javac` 的编译结果又是一堆 `.class` 字节码文件，所以我使用时间戳文件来代替目标文件，这就可以做到按需编译。具体方法可以在接下来的示例里面看见。
2. 在规则里面再次调用 `make` 命令。因为诸如 `DEBUG` 这样的变量在编译不同版本时可能有变化，而且 `R.java` 这样的文件又是编译时生成，无法自动更新源码列表变量，所以我们需要在编译过程中再次调用 `make` 命令本身来生成最终目标。

### 代码

这是我用来编译 [BlackLight](https://github.com/PaperAirplane-Dev-Team/BlackLight) 的 `Makefile` 示例。

```makefile
# Makefile for BlackLight
# Build tools
AAPT		:= aapt				# Android Asset Packaging Tool
JAVAC		:= javac			# Java Compiler
DX			:= dx				# Dex tool
JARSIGNER	:= jarsigner		# Jar signing tool
ZIPALIGN	:= zipalign			# Zip aligning tool
MAKE		:= make				# GNU Make tool
ADB			:= adb				# Android Debug Bridge
PM			:= /system/bin/pm	# Package Manager on Android
# You do not need PM if you are building on PC.

# Build configs
BUILD_DIR	:= build
BIN_DIR		:= $(BUILD_DIR)/bin
GEN_DIR		:= $(BUILD_DIR)/gen
CLASSES_DIR	:= $(BIN_DIR)/classes
APK_NAME	:= build.apk
DEX_NAME	:= classes.dex
OUT_DEX		:= $(BIN_DIR)/$(DEX_NAME)
OUT_APK		:= $(BIN_DIR)/$(APK_NAME)
# Path to directories that contain source
# Including source directories of library projects
SRC_DIR		:= \
	src \
	libs/SlidingUpPanel/src \
	libs/SystemBarTint/src \
	libs/SwipeBackLayout/library/src/main/java
# Timestamp file of java sources
# Just a fake "target", doesn't matter in fact
SRC_TS		:= $(BUILD_DIR)/sources.ts
# Path to directories containing resources
# Including library projects
RES_DIR		:= \
	res \
	libs/SlidingUpPanel/res \
	libs/SwipeBackLayout/library/src/main/res
# Timestamp file of resources
RES_TS		:= $(BUILD_DIR)/resources.ts
# External packages that need to generate R.java under.
# Usually these are library projects' package names.
# If a library does not contain any resource
# We do not need to put it here.
EXT_PKG		:= \
	com.sothree.slidinguppanel.library \
	me.imid.swipebacklayout.lib
# Include all jar libraries needed
# Including android.jar
# Please set the $ANDROID_JAR environment variable
# Pointing to your android.jar
JAR_LIB		:= \
	$(ANDROID_JAR) \
	libs/android-support-v4.jar \
	libs/gson-2.2.2.jar \
	libs/SlidingUpPanel/libs/nineoldandroids-2.4.0.jar
# Asset directory
ASSET		:= assets
# Packages that need to generate BuildConfig.java for.
# If a library needs BuildConfig.java,
# Please put it here also.
PACKAGE		:= us.shandian.blacklight
# Timestamp file of BuildConfig
PKG_TS		:= $(BUILD_DIR)/buildconfig.ts
# The main AndroidManifest
MANIFEST	:= AndroidManifest.xml

# Keystores
KEY_DEBUG	:= keystore/debug.keystore # Provided by Android SDK
KEY_RELEASE	:= keystore/publish.keystore
KEY_ALIAS	:= peter # Key alias for relase keystore

# Source list
SRC			:= \
	$(foreach dir, \
		$(SRC_DIR), \
		$(foreach srcdir, \
			$(shell find $(dir) -maxdepth 10 -type d), \
			$(wildcard $(srcdir)/*.java) \
		 ) \
	 )
GEN			:= $(foreach srcdir, $(shell find $(GEN_DIR) -maxdepth 10 -type d),$(wildcard $(srcdir)/*.java))
RES			:= \
	$(foreach dir, \
		$(RES_DIR), \
		$(foreach srcdir, \
			$(shell find $(dir) -maxdepth 10 -type d), \
			$(wildcard $(srcdir)/*.*) \
		 ) \
	 )

# Some stuff
EMPTY		:=
SPACE		:= $(EMPTY) $(EMPTY)
TAB			:= $(EMPTY)	$(EMPTY)
COLON		:= $(EMPTY):$(EMPTY)
POINT		:= $(EMPTY).$(EMPTY)
SLASH		:= $(EMPTY)/$(EMPTY)

# Resource arguments for aapt
AAPT_RES	:= $(addprefix -S , $(RES_DIR))
AAPT_EXT	:= $(subst $(TAB),$(EMPTY),\
	$(subst $(SPACE),$(COLON),$(EXT_PKG)))

# Classpath arguments for javac
JAVAC_CLASS	:= $(subst $(TAB),$(EMPTY),\
	$(subst $(SPACE),$(COLON),$(JAR_LIB)))

# Default DEBUG Flag
ifndef DEBUG
	DEBUG	:= true
endif

# Make rules
define gen-cfg
	@mkdir -p $(GEN_DIR)/$1
	@echo -e "package $(PACKAGE);\npublic class BuildConfig {\n	public static final boolean DEBUG=$(DEBUG);\n}" > "$(GEN_DIR)/$1/BuildConfig.java"
endef

define target
	@echo -e "\033[36mBuilding target:\033[0m $1"
endef

define build-info
	@echo -e "\033[33mNOTICE: Please always do 'make clean' before you build release package!\033[0m"
	@echo -e "\033[32mNOTICE: Ignore any warnings reported by 'find'. That doesn't matter.\033[0m"
	@echo -e "\033[36mTarget apk path:\033[0m  $(OUT_APK)"
endef

.PHONY: clean pre merge debug_make release_make debug release install
# Clean up 
clean:
	$(call target, Clean)
	@rm -rf $(BUILD_DIR)

# Prepare build dir
pre:
	$(call build-info)
	$(call target, Environment)
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(GEN_DIR)
	@mkdir -p $(CLASSES_DIR)

# Generate resources
$(RES_TS): $(RES) $(MANIFEST)
	$(call target, Resources)
	@$(AAPT) p -m -M $(MANIFEST) -A $(ASSET) -I $(ANDROID_JAR) $(AAPT_RES) --extra-packages $(AAPT_EXT) --auto-add-overlay -J $(GEN_DIR) -F $(OUT_APK) -f
	@echo $(shell date) > $@

# Generate build config
$(PKG_TS):
	$(call target, BuildConfig)
	$(foreach pkg, $(PACKAGE), $(call gen-cfg,$(subst $(POINT),$(SLASH),$(pkg))))
	@echo $(shell date) > $@

# Call javac to build classes
$(SRC_TS): $(SRC) $(GEN)
	$(call target, Classes)
	@$(JAVAC) -encoding utf-8 -cp $(JAVAC_CLASS) -d $(CLASSES_DIR) $(SRC) $(GEN)
	@echo $(shell date) > $@

# Convert the classes to dex format
$(OUT_DEX): $(SRC_TS)
	$(call target, Dex)
	@$(DX) --dex --no-strict --output=$(OUT_DEX) $(CLASSES_DIR) $(subst $(ANDROID_JAR) ,$(EMPTY),$(JAR_LIB))

# Merge the dex into apk
merge: $(OUT_DEX)
	$(call target, Merge)
	$(shell $(AAPT) r $(OUT_APK) $(DEX_NAME) > /dev/null)
	@cd $(BIN_DIR) && $(AAPT) a $(APK_NAME) $(DEX_NAME)

# Debug package (do not zipalign)
debug_make: pre $(RES_TS) $(PKG_TS)
	@$(MAKE) merge DEBUG=true
	$(call target, Debug)
	@$(JARSIGNER) -keystore $(KEY_DEBUG) -storepass android -sigalg MD5withRSA -digestalg SHA1 $(OUT_APK) my_alias

# Release package (zipalign)
release_make: pre $(RES_TS) $(PKG_TS)
	@$(MAKE) merge DEBUG=false
	$(call target, Release)
	@$(JARSIGNER) -keystore $(KEY_RELEASE) -sigalg MD5withRSA -digestalg SHA1 $(OUT_APK) $(KEY_ALIAS)
	@$(ZIPALIGN) 4 $(OUT_APK) $(OUT_APK)_zipalign
	@rm -r $(OUT_APK)
	@mv $(OUT_APK)_zipalign $(OUT_APK)

# Wrapper for debug build
debug:
	@$(MAKE) debug_make DEBUG=true

# Wrapper for release build
release:
	@$(MAKE) release_make DEBUG=false

# Install on phone
install:
	$(call target, Install)
	@if [ -f $(PM) ]; then \
		$(PM) install -r $(OUT_APK);\
	else \
		$(ADB) install -r $(OUT_APK);\
	fi
```

上面的规则目前支持:

1. 定义源码路径
2. 引入预编译库文件
3. 引入资源目录
4. 引入支持库项目源码
5. assets
6. 调试版和发布版分开编译分开签名
7. 对发布版执行zipalign

其中，有关 `SRC_TS` `PKG_TS` `RES_TS` 的规则都是我上面提到的用时间戳代替目标文件。注意，规则里必须用 `echo` 来创建这个目标文件，这样，在你只修改了源码的时候，资源文件和 `BuildConfig` 就不需要重新编译。否则，`make` 将仍然不能按需编译。

虚拟规则 `debug` `release` 就是用了我提到的再次调用 `make` 本身的方法来定义 `DEBUG` 变量。这个变量是用于生成 `BuildConfig.java` 的，可能在源码里用到。而在 `debug_make` 和 `release_make` 两个规则里面调用 `make` 则是为了重新生成源码列表。

上面的规则其实大部分需要修改的部分都被我定义为变量了，如果你需要用来编译自己的项目，只需要修改开头定义的变量即可，多半是引用的库文件、包名、资源目录、签名文件之类的，我的注释也非常详细，相信有一点基础的人都能看懂。哦对了，我没有定义 `aidl` 文件的编译规则，如果你用到了，只需要依葫芦画瓢，简单添加一条规则即可。

### 总结

1. `GNU Make` 有编译好的ARM版本，可以在手机或平板电脑上编译。
2. `Makefile` 可以自动检测需要重新编译的内容，只编译需要的部分。
3. 通过 `Makefile` 的强大功能，所有配置都可以在文件开头的变量中定义，而不需修改具体规则，且规则的实现比之前的shell脚本简洁很多。你可以对比我之前写的shell编译脚本。
4. `make` 可以自动捕捉编译中的错误并及时停止编译。虽然shell也能实现，但是要写一坨 `trap`, 反正我是懒得写……所以用shell编译的时候一直不能在出现问题的时候即时中断。
5. `Makefile` 的编译流程和依赖关系真的比 `shell` 要清晰得多。
6. 使用 `vim` 的 `javacomplete` 插件编辑代码前，可以用 `make res` `make cfg` 来生成 `R.java` 和 `BuildConfig.java`, 供自动完成插件调用。

### 鸣谢

1. [Google](https://www.google.com)
2. [Android Application Build using Makefiles](http://androidappdevlopment.blogspot.com/2012/05/android-application-build-using.html)
