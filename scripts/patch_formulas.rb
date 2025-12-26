def process_file(path)
  return unless File.exist?(path)
  puts "Processing #{path}..."
  
  lines = File.readlines(path)
  new_lines = []
  
  lines.each do |line|
    # =======================================================
    # 1. 修改 x265: 只要开启 Alpha 即可，做成标准包
    # =======================================================
    if path.include?("x265")
      if line.include?("class X265 < Formula")
        new_lines << "class X265Alpha < Formula\n"
        next
      end
      
      # 注意：删掉了 keg_only，让它成为系统标准库
      
      if line.strip.start_with?("args = %W[")
        new_lines << line
        new_lines << "    -DENABLE_ALPHA=ON\n"
        # 删掉了 -DENABLE_SHARED=OFF，我们现在要编译动态库(.dylib)
        new_lines << "    -DENABLE_CLI=OFF\n"
        next
      end
    end

    # =======================================================
    # 2. 修改 FFmpeg: 标准依赖 x265-alpha
    # =======================================================
    if path.include?("ffmpeg")
      if line.include?("class Ffmpeg < Formula")
        new_lines << "class FfmpegAlpha < Formula\n"
        next
      end

      # 修改依赖：直接依赖，不再是 :build
      if line.include?('depends_on "x265"')
        new_lines << line.sub('"x265"', '"x265-alpha"')
        next
      end

      # 注入配置：只需要开启开关，不需要那些疯狂的路径指定了
      if line.strip.start_with?('system "./configure"')
        puts "  -> Enabling libx265..."
        new_lines << <<~EOS
          # === [INJECTED] Enable x265 ===
          args << "--enable-libx265"
          # 注意：这里没有了 --static，也没有了 PKG_CONFIG_PATH
          # Homebrew 会自动处理好动态库链接
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
