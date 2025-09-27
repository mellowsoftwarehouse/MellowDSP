# MellowDSP v2.0.0

Professional server-side audio processing plugin for Lyrion Music Server (LMS).

## Features

- High-quality SOX-based transcoding and upsampling up to 768 kHz
- Dynamic FIR filter resampling from REW measurements
- Per-player configuration with individual settings
- Advanced phase response control (Linear, Intermediate, Minimum)
- Automatic filter conversion when upsampling changes
- Professional 24-bit WAV output

## Processing Pipeline

Input Audio → SOX Transcoding/Upsampling → Dynamic FIR Filtering → High-Quality Output

## Installation

Add this repository URL to your LMS plugin settings:

https://raw.githubusercontent.com/mellowsoftwarehouse/MellowDSP/main/plugins.xml

## Configuration

- **Player Settings**: Per-player audio processing options
- **Advanced Settings**: Global helper application paths and buffer settings

## Repository

https://github.com/mellowsoftwarehouse/MellowDSP
