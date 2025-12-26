def patch_x265
  path = "Formula/x265-alpha.rb"
  return unless File.exist?(path)
  puts "Patching #{path}..."
  
  content = File.read(path)
  content.gsub!("class X265 < Formula", "class X265Alpha < Formula")
  
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
  content.gsub!('depends_on "x265"', 'depends_on "x265-alpha"')
  
  # === 关键修复在下面 ===
  # 我们在 #{x265_path} 前面加了反斜杠 \
  # 这样 Ruby 就不会报错说找不到 variable 了
  patch_logic = <<~EOS
    # === [AUTO-PATCH] User Custom Args ===
    args << "--enable-libx265"
    args << "--pkg-config-flags=--static"
    
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
