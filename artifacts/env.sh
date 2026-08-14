export W=/Users/crimsonknight/open_source_coding_projects/asset_pipeline/.claude/worktrees/android-validation
export CRYSTAL=crystal-alpha
export ANDROID_NDK_HOME=/opt/homebrew/share/android-commandlinetools/ndk/28.2.13676358
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export ANDROID_SDK_ROOT=/opt/homebrew/share/android-commandlinetools
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
# NOTE: do NOT export BUILD_DIR here. cross_compile_deps.sh uses BUILD_DIR as the
# cross-deps output ROOT, while build_android.sh uses the SAME variable name as
# its artifact output dir. Exporting it (as CROSS_COMPILE.md's "Custom build
# directory" section instructs) silently redirects the .so and breaks
# build_crystal_lib.sh's hardcoded cp from <repo>/build/android-arm64/.
# Pass BUILD_DIR inline to cross_compile_deps.sh only.
export CROSS_DEPS_ROOT="$W/build/cross-deps"
export CRYSTAL_CROSS_DEPS="$W/build/cross-deps"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
