# Homebrew FFmpeg Alpha

## 1. Background

**FFmpeg** is the multimedia standard, but official releases often lag behind the rapid pace of development. **Homebrew FFmpeg Alpha** is a specialized Homebrew Tap designed specifically for developers and power users who need the absolute latest, bleeding-edge capabilities of FFmpeg on macOS.

## 2. The Problem

Standard Homebrew installations limit you to "Stable" releases. This creates a gap for users who need **Alpha-level features**—access to new codecs, filters, or API changes that have been committed to the source code recently but are not yet available in the stable version.

## 3. The Solution

This Tap provides **pre-built Alpha binaries** of FFmpeg. It bridges the gap between source code commits and stable releases, offering a convenient way to install and manage unstable/development versions directly via Homebrew.

## 4. Quick Start

### Prerequisites

* macOS
* Homebrew installed

### Installation

We recommend unlinking any existing FFmpeg installation to avoid conflicts.

```bash
# 1. Register the Alpha Tap
brew tap OpenGG/ffmpeg-alpha

# 2. Unlink existing stable ffmpeg (Harmless if not currently installed)
brew unlink ffmpeg

# 3. Install the Alpha version
brew install ffmpeg-alpha

```

## 5. Verification

Run these 3 commands to verify that the installation is working and supports complex rendering with Alpha channels (transparency):

```bash
# 1. Generate a transparent PNG sequence with a moving pattern
ffmpeg -f lavfi -i "color=c=black@0.0:size=1280x720:d=2[bg]; testsrc=size=400x400[fg]; [bg][fg]overlay=x=t*300:y=(H-h)/2" -frames:v 60 -c:v png frame_%03d.png

# 2. Encode to HEVC video, preserving the transparency
ffmpeg -framerate 30 -i frame_%03d.png -c:v libx265 -tag:v hvc1 -pix_fmt yuva420p output_alpha.mp4

# 3. Cleanup the temporary PNG files
rm frame_*.png

```

### What is happening here?

1. **Generation:** We create a strictly transparent background (`color=c=black@0.0`) and overlay a moving `testsrc` box on top of it. This ensures the source content actually has transparency.
2. **Encoding:** We encode the sequence using `libx265` (HEVC) with the pixel format `yuva420p`. The `a` in `yuva` stands for the Alpha channel, ensuring transparency is preserved in the video file.
3. **Cleanup:** Removes the intermediate image files.

### Playback Note

Open `output_alpha.mp4` to check the result.

> **⚠️ Important Note on Playback:**
> When verifying alpha builds on macOS, be aware of a known **pre-multiplication bug in Chrome on macOS** which may cause rendering artifacts or color issues (especially around the edges of transparent objects).
> Please use **Safari (macOS or iOS)** or **QuickTime Player** to verify the video output accuracy. Do not rely on Chrome for visual verification of Alpha builds.
