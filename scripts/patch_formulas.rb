def patch_x265
  path = "Formula/x265-alpha.rb"
  return unless File.exist?(path)
  puts "Patching #{path}..."
  
  content = File.read(path)
  content.gsub!("class X265 < Formula", "class X265Alpha < Formula")
  
  # 确保它是静态编译的 (keg_only 避免链接干扰)
  if content.include?('def install')
    content.sub!('def install', "keg_only \"x265-alpha is build-only\"\n  def install")
  end

  if content.include?('args = %W[')
    patch_args = <<~EOS
      -DENABLE_ALPHA=ON
          -DENABLE_SHARED=OFF
          -DENABLE_CLI=OFF
    EOS
    unless content.include?("-DENABLE_ALPHA=ON")
      content.sub!('args = %W[', "args = %W[\n    #{patch_args}")
    end
  else
    puts "Warning: Could not find args block in x265"
  end
  
  File.write(path, content)
end

def patch_ffmpeg
  path = "Formula/ffmpeg-alpha.rb"
  return unless File.exist?(path)
  puts "Patching #{path}..."
  
  content = File.read(path)
  content.gsub!("class Ffmpeg < Formula", "class FfmpegAlpha < Formula")
  
  # === 核心修改：将 x265 改为 Build-time 依赖 ===
  # 这样用户安装 Bottle 时，Homebrew 就不会去尝试安装 x265-alpha 了！
  content.gsub!('depends_on "x265"', 'depends_on "x265-alpha" => :build')
  
  patch_logic = <<~EOS
    # === [AUTO-PATCH] Static Link Logic ===
    args << "--enable-libx265"
    args << "--pkg-config-flags=--static"
    
    # 只有在编译环境下（有 x265-alpha）才注入路径
    if Formula["x265-alpha"].any_version_installed?
      x265_path = Formula["x265-alpha"].opt_prefix
      args << "--extra-cflags=-I\#{x265_path}/include"
      args << "--extra-ldflags=-L\#{x265_path}/lib"
    end
    # === [END PATCH] ===

    system "./configure"
  EOS
  
  unless content.include?("[AUTO-PATCH]")
    content.sub!('system "./configure"', patch_logic)
  end
  
  File.write(path, content)
end

patch_x265
patch_ffmpeg
puts "✅ Patches applied successfully."
