# Nucleus Audio Architecture

Target engine: Godot 4.7.x.

## Goal

Audio provides application-wide bus preferences, persistent music, and
non-positional one-shot playback without replacing Godot's native audio system.

```text
NucleusSettings
      ▲
      │ volume / mute preferences
      │
 NucleusAudioService
      │
      ├── OneShotPool
      └── MusicService
              │
              ▼
        AudioStreamPlayer
              │
              ▼
          AudioServer
```

## Why `NucleusAudio` is an Autoload

Music and UI audio must survive scene changes, and bus preferences apply to the
whole application. This is application-lifetime infrastructure, so a single
Audio Autoload is justified.

There are not separate AudioManager, MusicManager, and SoundPool Autoloads.

## Buses

Nucleus keeps the existing robust bus layout:

```text
Master
├── Music
├── SFX
├── EchoSFX
├── Voice
├── UI
└── Ambient
```

`EchoSFX` follows the SFX volume preference but keeps its own reverb routing.

## Settings

```text
audio/muted
audio/master_volume
audio/music_volume
audio/sfx_volume
audio/voice_volume
audio/ui_volume
audio/ambient_volume
```

All sliders use linear values. Conversion to decibels happens only at the
AudioServer boundary.

Muting only toggles the Master bus. It never destroys per-bus mute state or
saved volume values.

## One-shot playback

```gdscript
NucleusAudio.play_one_shot(
    hit_stream,
    NucleusAudioBuses.SFX,
)
```

For reusable data:

```gdscript
NucleusAudio.play_cue(hit_cue)
```

`NucleusAudioCue` intentionally stays small. If variation is needed, assign an
`AudioStreamRandomizer` as its stream instead of rebuilding random sample and
pitch logic in Nucleus.

The pool grows dynamically and resets pitch, volume, stream, pause state and bus
when a player is reused. If the configured maximum is reached, the oldest
one-shot is recycled.

## Music

```gdscript
NucleusAudio.music.play(track_stream, 0.75)
NucleusAudio.music.pause()
NucleusAudio.music.resume()
NucleusAudio.music.stop(0.5)
```

Two players provide interruptible crossfades.

Player volume fades from `-80 dB` to `0 dB`. Bus volume is not copied into the
player volume, avoiding double attenuation.

The service accepts any `AudioStream`, so native Godot resources remain usable:

```text
AudioStreamPlaylist
AudioStreamRandomizer
AudioStreamInteractive
AudioStreamSynchronized
```

Nucleus does not maintain a custom music bank or playlist model.

## Barebone code salvaged

Retained:

- Named audio buses.
- One-shot pooling.
- Two-player music crossfades.
- Linear user volume controls.

Redesigned or removed:

- Three Acoustic Autoloads became one composed service.
- Focus loss no longer force-mutes every bus.
- One-shot pitch state is always reset.
- Crossfades no longer target bus dB and double-attenuate output.
- Paused music resumes with `stream_paused = false` instead of restarting.
- Custom music bank/playlist state is replaced by native Godot AudioStreams.
