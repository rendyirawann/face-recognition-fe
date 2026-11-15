package id.go.sumutprov.disdik.jargon_kiosk

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Tablet kios berdiri sepanjang jam sekolah. Layar yang tidur
        // berarti siswa pertama setiap pagi harus menyentuhnya dulu, dan
        // itu tidak akan diingat siapa pun.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
