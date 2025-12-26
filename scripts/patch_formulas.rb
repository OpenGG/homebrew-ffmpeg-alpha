# 注意：这里不需要 require homebrew 的内部库，我们使用标准 Ruby IO 操作

def patch_x265
  path = "Formula/x265-alpha.rb"
  return unless File.exist?(path)
  puts "Patching #{path}..."
  
  content = File.read(path)
  
  # 修改类名
  content.gsub!("class X265 < Formula", "class X265Alpha < Formula")
  
  # 插入 Alpha 编译参数
  if content.include?('args = %W[')
    patch_args = <<~EOS
      -DENABLE_ALPHA=ON
          -DENABLE_SHARED=OFF
          -DENABLE_CLI=OFF
    EOS
    # 避免重复 patch
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
  
  # 修改类名
  content.gsub!("class Ffmpeg < Formula", "class FfmpegAlpha < Formula")
  
  # 修改依赖
  content.gsub!('depends_on "x265"', 'depends_on "x265-alpha"')
  
  # 注入追加参数逻辑
  patch_logic = <<~EOS
    # === [AUTO-PATCH] User Custom Args ===
    args << "--enable-libx265"
    args << "--pkg-config-flags=--static"
    
    if Formula["x265-alpha"].any_version_installed?
      x265_path = Formula["x265-alpha"].opt_prefix
      args << "--extra-cflags=-I#{x265_path}/include"
      args << "--extra-ldflags=-L#{x265_path}/lib"
    end
    # === [END PATCH] ===

    system "./configure"
  EOS
  
  # 在 ./configure 之前插入代码
  unless content.include?("[AUTO-PATCH]")
    content.sub!('system "./configure"', patch_logic)
  end
  
  File.write(path, content)
end

# 执行 Patch
patch_x265
patch_ffmpeg
puts "✅ All patches applied successfully."
