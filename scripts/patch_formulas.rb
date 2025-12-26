def process_file(path)
  return unless File.exist?(path)
  puts "Processing #{path}..."
  
  lines = File.readlines(path)
  new_lines = []
  
  lines.each do |line|
    # =======================================================
    # 1. 修改 x265: 开启 Alpha，标准动态库
    # =======================================================
    if path.include?("x265")
      if line.include?("class X265 < Formula")
        new_lines << "class X265Alpha < Formula\n"
        next
      end
      
      # 注意：原 x265 可能有 keg_only，我们这里如果遇到要删掉
      # 但最简单的办法是：只要不主动添加 keg_only，它就是标准库
      
      if line.strip.start_with?("args = %W[")
        new_lines << line
        new_lines << "    -DENABLE_ALPHA=ON\n"
        # 移除了 -DENABLE_SHARED=OFF，默认编译为动态库(.dylib)
        new_lines << "    -DENABLE_CLI=OFF\n"
        next
      end
    end

    # =======================================================
    # 2. 修改 FFmpeg: 依赖 x265-alpha
    # =======================================================
    if path.include?("ffmpeg")
      if line.include?("class Ffmpeg < Formula")
        new_lines << "class FfmpegAlpha < Formula\n"
        next
      end

      # 修改依赖：将 "x265" 替换为 "x265-alpha" (普通依赖，非 :build)
      if line.include?('depends_on "x265"')
        new_lines << line.sub('"x265"', '"x265-alpha"')
        next
      end

      # 注入配置：仅开启开关，Homebrew 会自动处理链接
      if line.strip.start_with?('system "./configure"')
        puts "  -> Enabling libx265..."
        new_lines << <<~EOS
          # === [INJECTED] Enable x265 ===
          args << "--enable-libx265"
          # === [END INJECTION] ===

        EOS
        new_lines << line
        next
      end
    end

    new_lines << line
  end

  File.write(path, new_lines.join)
end

process_file("Formula/x265-alpha.rb")
process_file("Formula/ffmpeg-alpha.rb")
puts "✅ Standard dynamic linking patches applied."
