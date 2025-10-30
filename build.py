import os
import subprocess

#after first clone
#git submodule update --init --recursive

#to update submodules
#git submodule update --recursive --remote

#Build Godot_CPP
#os.chdir("godot-cpp")
#os.system("scons -j 8 target=template_debug")
#os.system("scons -j 8 target=template_debug")

#build gdextension
os.system("scons platform=macos arch=x86_64 target=template_debug")
#os.system("scons platform=macos arch=x86_64 target=template_release")
#os.system("scons platform=windows target=template_debug")
#os.system("scons platform=windows target=template_release")
#os.system("scons platform=linux target=template_debug")
#os.system("scons platform=linux target=template_release")

#build ffmpeg on macos
#os.chdir('ffmpeg')
#os.system("./configure --arch=arm64 --prefix=/Users/kmt/Documents/Github/2025_GodotFFmpeg/ffmpeg_bin_arm64 --enable-gpl --enable-shared")
#os.system("./configure --arch=x86_64 --prefix=/Users/kmt/Desktop/2025_GodotFFmpeg/demo/bin_FFmpeg_x86_64 --enable-gpl --enable-shared")
#os.system("make")
#os.system("make install")

#combine architectures
    # Example for ffmpeg executable
#os.system("lipo -create -output universal_ffmpeg ffmpeg_bin_x86_64 ffmpeg_bin_arm64")

# Example for a shared library (e.g., libavcodec.dylib)
#os.system("lipo -create -output universal_libavcodec.dylib /Users/kmt/Documents/Github/2025_GodotFFmpeg/ffmpeg_bin_x86/lib/libavcodec.dylib /Users/kmt/Documents/Github/2025_GodotFFmpeg/ffmpeg_bin_arm64/lib/libavcodec.dylib")
