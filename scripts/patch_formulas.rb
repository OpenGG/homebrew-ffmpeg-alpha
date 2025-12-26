def patch_x265
  path = "Formula/x265-alpha.rb"
  return unless File.exist?(path)
  puts "Patching #{path}..."
  
  content = File.read(path)
  content.gsub!("class X265 < Formula", "class X265Alpha < Formula")
  
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
  content.gsub!('depends_on "x265"', 'depends_on "x265-alpha" => :build')
  
  # === 修复重点 ===
  # 我们现在查找完整的一行： 'system "./configure", *args'
  # 并用包含这一行完整代码的块去替换它
  target_line = 'system "./configure", *args'
  
  patch_logic = <<~EOS
    # === [AUTO-PATCH] Static Link Logic ===
    args << "--enable-libx265"
    args << "--pkg-config-flags=--static"
    
    if Formula["x265-alpha"].any_version_installed?
      x265_path = Formula["x265-alpha"].opt_prefix
      args << "--extra-cflags=-I\#{x265_path}/include"
      args << "--extra-ldflags=-L\#{x265_path}/lib"
    end
    # === [END PATCH] ===

    system "./configure", *args
  EOS
  
  if content.include?(target_line) && !content.include?("[AUTO-PATCH]")
    content.sub!(target_line, patch_logic)
  else
    puts "Warning: Could not find exact configure line or patch already applied."
  end
  
  File.write(path, content)
end

patch_x265
patch_ffmpeg
puts "✅ Patches applied successfully."
