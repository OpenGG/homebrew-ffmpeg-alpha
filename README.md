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

Follow these steps to generate a transparent video and verify the Alpha channel using a custom HTML viewer.

### Step 1: Generate Video

Run these 3 commands to generate the test file `output_alpha.mp4`:

```bash
# 1. Generate a transparent PNG sequence with a moving pattern
ffmpeg -f lavfi \
  -i "color=c=black@0.0:size=1280x720:d=2[bg]; testsrc=size=400x400[fg]; [bg][fg]overlay=x=t*300:y=(H-h)/2" \
  -frames:v 60 -c:v png frame_%03d.png

# 2. Encode to HEVC video, preserving the transparency
ffmpeg -framerate 30 -i frame_%03d.png -c:v libx265 -tag:v hvc1 \
  -pix_fmt yuva420p output_alpha.mp4

# 3. Cleanup the temporary PNG files
rm frame_*.png

```

### Step 2: Verify in Browser

Run the following command to generate `verify.html`. This player allows you to toggle the background color to visually confirm transparency.

```bash
cat <<EOF > verify.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>FFmpeg Alpha Verification</title>
    <style>
        body { font-family: system-ui, sans-serif; text-align: center; padding: 40px; background: #f0f0f0; }
        .controls { margin-bottom: 20px; }
        button { padding: 10px 20px; font-size: 14px; cursor: pointer; border: 1px solid #ccc; border-radius: 4px; }
        #video-container {
            width: 800px; height: 450px; margin: 0 auto; border: 2px solid #333;
            /* Default Checkerboard Pattern */
            background-image: linear-gradient(45deg, #ccc 25%, transparent 25%), 
                              linear-gradient(-45deg, #ccc 25%, transparent 25%), 
                              linear-gradient(45deg, transparent 75%, #ccc 75%), 
                              linear-gradient(-45deg, transparent 75%, #ccc 75%);
            background-size: 20px 20px;
            background-position: 0 0, 0 10px, 10px -10px, -10px 0px;
            display: flex; align-items: center; justify-content: center;
        }
        video { width: 100%; outline: none; }
    </style>
</head>
<body>
    <div class="controls">
        <strong>Set Background: </strong>
        <button onclick="setBg('checkerboard')">🏁 Checkerboard</button>
        <button onclick="setBg('white')" style="background:white;">White</button>
        <button onclick="setBg('black')" style="background:black; color:white;">Black</button>
        <button onclick="setBg('#00ff00')" style="background:#00ff00;">Green Screen</button>
    </div>
    <div id="video-container">
        <video src="output_alpha.mp4" autoplay loop muted playsinline controls></video>
    </div>
    <script>
        function setBg(color) {
            const container = document.getElementById('video-container');
            container.style.background = (color === 'checkerboard') ? '' : color;
        }
    </script>
</body>
</html>
EOF

```

### Step 3: Playback Note

Open the generated `verify.html` in your browser:

```bash
open verify.html

```

> **⚠️ Important Browser Note:**
> * **Safari (macOS/iOS):** Highly recommended. Safari has native support for HEVC with Alpha.
> * **Chrome/Edge:** May exhibit the "pre-multiplication bug" (dark halos around edges) or fail to play HEVC entirely depending on hardware acceleration. **Do not use Chrome to judge color accuracy for Alpha builds.**
> 
>
