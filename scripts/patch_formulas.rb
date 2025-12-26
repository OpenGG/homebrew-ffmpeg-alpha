def process_file(path)
  return unless File.exist?(path)
  puts "Processing #{path}..."
  
  lines = File.readlines(path)
  new_lines = []
  
  lines.each do |line|
    # =======================================================
    # 1. 修改 x265
    # =======================================================
    if path.include?("x265")
      if line.include?("class X265 < Formula")
        new_lines << "class X265Alpha < Formula\n"
        next
      end
      
      if line.strip.start_with?("args = %W[")
        new_lines << line
        new_lines << "    -DENABLE_ALPHA=ON\n"
        new_lines << "    -DENABLE_CLI=OFF\n"
        
        # === 核心修复：禁用 SVE/SVE2 ===
        # 1. 解决 macOS arm64 不支持 SVE 的架构问题
        # 2. 解决 libtool 概率性读取 .o 文件失败的竞态条件问题
        new_lines << "    -DENABLE_SVE=OFF\n"
        new_lines << "    -DENABLE_SVE2=OFF\n"
        # =============================
        
        next
      end
    end

    # =======================================================
    # 2. 修改 FFmpeg
    # =======================================================
    if path.include?("ffmpeg")
      if line.include?("class Ffmpeg < Formula")
        new_lines << "class FfmpegAlpha < Formula\n"
        next
      end

      if line.include?('depends_on "x265"')
        new_lines << line.sub('"x265"', '"x265-alpha"')
        next
      end

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
puts "✅ SVE/SVE2 disabled for stability."
