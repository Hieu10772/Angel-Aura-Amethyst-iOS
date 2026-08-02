# Prerequisite variables
SOURCEDIR := src
OUTPUTDIR := build

SOURCES := $(shell find $(SOURCEDIR) -type f -name '*.java')
CLASSES := $(SOURCES:$(SOURCEDIR)/%.java=$(OUTPUTDIR)/%.class)

TARGETS := $(shell find $(SOURCEDIR) -mindepth 1 -maxdepth 1 -type d)
TARGETS := $(TARGETS:$(SOURCEDIR)/%=$(OUTPUTDIR)/%.jar)
TARGETS += $(OUTPUTDIR)/lwjgl-3.3.3.jar $(OUTPUTDIR)/lwjgl-3.3.6.jar $(OUTPUTDIR)/lwjgl-3.4.1.jar $(OUTPUTDIR)/cacio-init-agent.jar

# Add all jars to classpath and allow compiling with private API
JCFLAGS := -cp "$(subst $() $(),:,$(wildcard $(SOURCEDIR)/*/):$(wildcard libs/*/*.jar))" -XDignore.symbol.file

all: $(TARGETS)
	
# Sometimes the CI produces empty class file resulting in broken jar, so we check and abort here
check_empty_classes:
	@set -e
	@echo "Checking for empty class files"
	$(eval EMPTY_CLASSES := $(shell find $(OUTPUTDIR) -name '*.class' -size 0 | grep -v '\$$' || true))
	@if [ -n "$(EMPTY_CLASSES)" ]; then \
		echo "Error: found empty class files: $(EMPTY_CLASSES)"; \
		exit 1; \
	fi

# Rules for building java class
$(CLASSES): $(OUTPUTDIR)/%.class: $(SOURCEDIR)/%.java
	@set -e
	$(eval TARGET=$(word 2, $(subst /, ,$@)))
	@mkdir -p $(OUTPUTDIR)/classes
	@mkdir -p $(dir $@)
	@echo "Compiling $<"
	@$(BOOTJDK)/javac $(JCFLAGS) -d $(OUTPUTDIR)/classes $<
	@find "$(OUTPUTDIR)/classes/$(dir $(subst $(OUTPUTDIR)/$(TARGET)/,,$@))" -maxdepth 1 -name "$(notdir $(basename $@))*" -exec cp {} "$(dir $@)" \;

$(OUTPUTDIR)/launcher.jar: $(CLASSES)
	@set -e
	@echo "Creating $@"
	@cp -r $(SOURCEDIR)/launcher/META-INF $(basename $@)/ 2>/dev/null || true
	@find $(basename $@) -name '*.class' -size 0 | grep -v '\$$' && { echo "Error: found empty class files"; exit 1; } || true
	@$(BOOTJDK)/jar -cf $@ -C $(basename $@) .

# Build LWJGL 3.3.3
$(OUTPUTDIR)/lwjgl-3.3.3.jar: $(CLASSES)
	@set -e
	@echo "Creating $@"
	@mkdir -p $(OUTPUTDIR)/lwjgl33_lib
	@cd $(OUTPUTDIR)/lwjgl33_lib && $(BOOTJDK)/jar -xf "../../../lwjgl.jar" && rm -rf META-INF
	@cd $(OUTPUTDIR)/lwjgl33_lib && find ../../libs/lwjgl -name 'lwjgl*.jar' ! -name 'lwjgl.jar' -exec $(BOOTJDK)/jar -xf {} \; && rm -rf META-INF
	@cd $(OUTPUTDIR)/lwjgl33_lib && $(BOOTJDK)/jar -xf "../../libs/lwjgl/lwjgl.jar" && rm -rf META-INF
	@cp -R $(OUTPUTDIR)/lwjgl/* $(OUTPUTDIR)/lwjgl33_lib/
	@mkdir -p $(OUTPUTDIR)/lwjgl33_lib/com/apple/ios/audio
	@cp -R $(OUTPUTDIR)/launcher/com/apple/ios/audio/*.class $(OUTPUTDIR)/lwjgl33_lib/com/apple/ios/audio/
	@mkdir -p $(OUTPUTDIR)/lwjgl33_lib/META-INF/services
	@cp $(SOURCEDIR)/launcher/META-INF/services/javax.sound.sampled.spi.MixerProvider $(OUTPUTDIR)/lwjgl33_lib/META-INF/services/
	@$(BOOTJDK)/jar -cf $@ -C $(OUTPUTDIR)/lwjgl33_lib .

# Build LWJGL 3.3.6
$(OUTPUTDIR)/lwjgl-3.3.6.jar: $(CLASSES)
	@set -e
	@echo "Creating $@"
	@mkdir -p $(OUTPUTDIR)/lwjgl36_lib
	@cd $(OUTPUTDIR)/lwjgl36_lib && $(BOOTJDK)/jar -xf "../../../lwjgl.jar" && rm -rf META-INF
	@cd $(OUTPUTDIR)/lwjgl36_lib && find ../../libs/lwjgl36 -name 'lwjgl*.jar' ! -name 'lwjgl.jar' -exec $(BOOTJDK)/jar -xf {} \; && rm -rf META-INF
	@cd $(OUTPUTDIR)/lwjgl36_lib && $(BOOTJDK)/jar -xf "../../libs/lwjgl36/lwjgl.jar" && rm -rf META-INF
	@cp -R $(OUTPUTDIR)/lwjgl/* $(OUTPUTDIR)/lwjgl36_lib/
	@mkdir -p $(OUTPUTDIR)/lwjgl36_lib/com/apple/ios/audio
	@cp -R $(OUTPUTDIR)/launcher/com/apple/ios/audio/*.class $(OUTPUTDIR)/lwjgl36_lib/com/apple/ios/audio/
	@mkdir -p $(OUTPUTDIR)/lwjgl36_lib/META-INF/services
	@cp $(SOURCEDIR)/launcher/META-INF/services/javax.sound.sampled.spi.MixerProvider $(OUTPUTDIR)/lwjgl36_lib/META-INF/services/
	@$(BOOTJDK)/jar -cf $@ -C $(OUTPUTDIR)/lwjgl36_lib .

$(OUTPUTDIR)/lwjgl-3.4.1.jar: $(CLASSES)
	@set -e
	@echo "Creating $@"
	@mkdir -p $(OUTPUTDIR)/lwjgl41_lib
	@cd $(OUTPUTDIR)/lwjgl41_lib && $(BOOTJDK)/jar -xf "../../../lwjgl.jar" && rm -rf META-INF
	@cd $(OUTPUTDIR)/lwjgl41_lib && find ../../libs/lwjgl41 -name 'lwjgl*.jar' ! -name 'lwjgl.jar' -exec $(BOOTJDK)/jar -xf {} \; && rm -rf META-INF
	@cd $(OUTPUTDIR)/lwjgl41_lib && $(BOOTJDK)/jar -xf "../../libs/lwjgl41/lwjgl.jar" && rm -rf META-INF
	@cp -R $(OUTPUTDIR)/lwjgl/* $(OUTPUTDIR)/lwjgl41_lib/
	@mkdir -p $(OUTPUTDIR)/lwjgl41_lib/com/apple/ios/audio
	@cp -R $(OUTPUTDIR)/launcher/com/apple/ios/audio/*.class $(OUTPUTDIR)/lwjgl41_lib/com/apple/ios/audio/
	@mkdir -p $(OUTPUTDIR)/lwjgl41_lib/META-INF/services
	@cp $(SOURCEDIR)/launcher/META-INF/services/javax.sound.sampled.spi.MixerProvider $(OUTPUTDIR)/lwjgl41_lib/META-INF/services/
	@$(BOOTJDK)/jar -cf $@ -C $(OUTPUTDIR)/lwjgl41_lib .

# Legacy alias
$(OUTPUTDIR)/lwjgl.jar: $(OUTPUTDIR)/lwjgl-3.3.3.jar
	@cp $< $@

$(OUTPUTDIR)/patchjna_agent.jar: $(CLASSES)
	@set -e
	@mv $(basename $@)/com/sun/jna/Platform.class $(basename $@)/com/sun/jna/Platform.class.patch
	@echo "Creating $@"
	@$(BOOTJDK)/jar -cfm $@ $(SOURCEDIR)/patchjna_agent.txt -C $(basename $@) .

$(OUTPUTDIR)/cacio-init-agent.jar: $(CLASSES)
	@set -e
	@echo "Creating $@"
	@$(BOOTJDK)/jar -cfm $@ $(SOURCEDIR)/cacio_init_agent.txt -C $(basename $@) .

clean:
	rm -rf $(OUTPUTDIR)

.SUFFIXES: .java
.PHONY: all clean
