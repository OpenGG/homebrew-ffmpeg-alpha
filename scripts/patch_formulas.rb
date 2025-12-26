require 'utils/inreplace'

# === Helper to create patching logic ===
def patch_x265
  path = "Formula/x265-alpha.rb"
  return unless File.exist?(path)
  puts "Patching #{path}..."
  
  content = File.read(path)
  content.gsub!("class X265 < Formula", "class X265Alpha < Formula")
  
  # 插入 Alpha 编译参数
  if content.include?('args = %W[')
    patch_args = <<~EOS
      -DENABLE_ALPHA=ON
          -DENABLE_SHARED=OFF
          -DENABLE_CLI=OFF
    EOS
    content.sub!('args = %W[', "args = %W[\n    #{patch_args}")
  end
  
  File.write(path, content)
end

def patch_ffmpeg
  path = "Formula/ffmpeg-alpha.rb"
  return unless File.exist?(path)
  puts "Patching #{path}..."
  
  content = File.read(path)
  content.gsub!("class Ffmpeg < Formula", "class FfmpegAlpha < Formula")
  
  # 修改依赖
  content.gsub!('depends_on "x265"', 'depends_on "x265-alpha"')
  
  # 注入追加参数逻辑 (Append Args)
  patch_logic = <<~EOS
    # === [AUTO-PATCH] User Custom Args ===
    args << "--enable-libx265"
    args << "--pkg-config-flags=--static"
    
    # 指向 x265-alpha 静态库
    if Formula["x265-alpha"].any_version_installed?
      x265_path = Formula["x265-alpha"].opt_prefix
      args << "--extra-cflags=-I#{x265_path}/include"
      args << "--extra-ldflags=-L#{x265_path}/lib"
    end
    # === [END PATCH] ===

    system "./configure"
  EOS
  
  # 在 ./configure 之前插入代码
  content.sub!('system "./configure"', patch_logic)
  
  File.write(path, content)
end

patch_x265
patch_ffmpeg
puts "All patches applied successfully."
