# MellowDSP v2.0.3

Professional server-side audio processing plugin for Lyrion Music Server (LMS).

## Features

- High-quality SOX-based transcoding and upsampling up to 768 kHz
- Dynamic FIR filter resampling from REW measurements
- Per-player configuration with individual settings
- Advanced phase response control (Linear, Intermediate, Minimum)
- Automatic filter conversion when upsampling changes
- Professional dithering options (including e-weighted)
- 24-bit WAV output

## Installation

1. Add this repository URL to your LMS plugin settings: https://raw.githubusercontent.com/mellowsoftwarehouse/MellowDSP/main/plugins.xml

2. Install MellowDSP from the plugin list

3. Enable the plugin and restart LMS

## Configuration

### Advanced Settings (Global)

Access via: **Settings → Advanced → MellowDSP**

- **Enable MellowDSP Globally**: Master switch for the system
- **SOX Path**: Path to SOX binary (default: `/usr/bin/sox`)
- **FFMPEG Path**: Path to FFMPEG binary (default: `/usr/bin/ffmpeg`)
- **Buffer Size**: Processing buffer size in KB (default: 8)

### Player Settings (Per-Player)

Access via: **Settings → Player → [Your Player] → MellowDSP**

Each player can have independent settings:

- **Enable MellowDSP**: Enable processing for this specific player
- **Input Formats**: Select which formats to process (AIFF, ALAC, FLAC, WAV)
- **Target Sample Rate**: Upsampling frequency (44.1 kHz to 768 kHz)
- **Phase Response**: Linear, Intermediate, or Minimum phase
- **Output Bit Depth**: 16, 24, or 32-bit output
- **Dithering Type**: None, Triangular, Shaped, Lipshitz, F-weighted, E-weighted
- **Dither Precision**: Target precision for dithering (16-24 bit)
- **FIR Filters**: Room correction filters from REW

## FIR Filter Setup (Room Correction)

### Step 1: Generate FIR Filters with REW

1. Measure your room with REW (Room EQ Wizard)
2. Create room correction filters
3. Export filters as **WAV files** (one for left channel, one for right)
4. Note the sample rate of the exported files (e.g., 96 kHz)

### Step 2: Upload FIR Files to Server

Upload your FIR WAV files to your Lyrion Music Server via SFTP/SCP:
```bash
scp left_channel_fir.wav root@[SERVER_IP]:/tmp/fir/
scp right_channel_fir.wav root@[SERVER_IP]:/tmp/fir/

Or use any SFTP client (FileZilla, WinSCP, Cyberduck, etc.)
Recommended location: /tmp/fir/ or /var/daphile/mediaserver/fir/
Step 3: Configure FIR in Player Settings
1. Go to Settings → Player → [Your Player] → MellowDSP
2. Check Enable FIR Filtering
3. Enter full paths to your uploaded files:
    * Left Channel: /tmp/fir/left_channel_fir.wav
    * Right Channel: /tmp/fir/right_channel_fir.wav
4. Click Apply
Step 4: Automatic Processing
MellowDSP automatically:
1. Stores master files at original REW frequency (e.g., 96 kHz)
2. Converts filters to match your target sample rate (e.g., 176.4 kHz)
3. Re-converts automatically when you change upsampling settings
4. Applies filters in the processing chain
Example: If you have 96 kHz FIR filters and set target to 352.8 kHz, MellowDSP:
* Keeps original 96 kHz files as masters
* Converts them to 352.8 kHz for processing
* If you later change to 768 kHz, reconverts from 96 kHz masters to 768 kHz
Processing Pipeline
Input Audio 
  ↓
Format Detection & Decoding
  ↓
SOX Transcoding
  ↓
Upsampling (with selected phase response)
  ↓
FIR Filtering (if enabled, at target sample rate)
  ↓
Dithering (if configured)
  ↓
Output (24-bit WAV uncompressed)

Troubleshooting
Plugin doesn't appear in player settings
* Restart LMS after installation
* Check that plugin is enabled in Settings → Plugins
* Verify Lyrion Music Server version ≥ 7.8
FIR filters not working
* Verify file paths are correct and accessible
* Check SOX is installed: /usr/bin/sox --version
* Check server logs: /var/daphile/mediaserver/log/server.log
* Ensure FIR files are valid WAV format
No audio output
* Verify input format is selected in player settings
* Check that player is enabled for MellowDSP
* Verify SOX path in Advanced settings
* Check buffer size (try increasing to 16 or 32)
Performance issues
* Reduce upsampling rate
* Increase buffer size
* Disable FIR filtering temporarily
* Check server CPU usage
Technical Details
* SOX: Used for high-quality resampling and format conversion
* Phase Response: Affects pre-ringing/post-ringing characteristics
* FIR Resampling: Automatic conversion maintains filter accuracy
* Dithering: Applied only when reducing bit depth
* Master Files: Original FIR files stored separately for resampling
Support
* GitHub Issues: https://github.com/mellowsoftwarehouse/MellowDSP/issues
* Documentation: This README
License
Professional audio processing plugin for home audio enthusiasts.
