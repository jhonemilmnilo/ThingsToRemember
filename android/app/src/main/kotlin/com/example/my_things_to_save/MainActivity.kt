package com.example.my_things_to_save

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 🛡️ Phase 4: Anti-Screenshot, Anti-Screen Recording & Recent Apps Task Switcher Obfuscation
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
