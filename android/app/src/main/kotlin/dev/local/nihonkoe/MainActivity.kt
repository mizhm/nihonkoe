package dev.local.nihonkoe

import com.ryanheise.audioservice.AudioServiceFragmentActivity

// Shares audio_service's engine with the playback service; a FragmentActivity because local_auth (app lock) needs one.
class MainActivity : AudioServiceFragmentActivity()
