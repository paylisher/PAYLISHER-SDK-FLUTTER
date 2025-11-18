package com.paylisher.flutter

import android.util.Log

/**
 * SnapshotSender – STUB implementation
 *
 * Android Paylisher SDK şu anda session replay (snapshot) özelliği sunmuyor.
 * Bu yüzden Flutter plugin'deki çağrıların derlenmesi için tüm metodlar stub olarak tanımlandı.
 *
 * İleride Android SDK'ya gerçek replay gelirse burası genişletilecek.
 */
class SnapshotSender {

    fun sendMetaEvent(width: Int, height: Int, screen: String) {
        Log.d(
            "PaylisherSnapshot",
            "sendMetaEvent() STUB → width=$width height=$height screen=$screen"
        )
    }

    fun sendFullSnapshot(
        imageBytes: ByteArray,
        id: Int,
        x: Int,
        y: Int
    ) {
        Log.d(
            "PaylisherSnapshot",
            "sendFullSnapshot() STUB → id=$id size=${imageBytes.size} pos=($x,$y)"
        )
    }

    fun sendSnapshot(
        distinctId: String,
        sessionId: String,
        snapshotJson: String
    ) {
        Log.d(
            "PaylisherSnapshot",
            "sendSnapshot() STUB → distinctId=$distinctId sessionId=$sessionId jsonSize=${snapshotJson.length}"
        )
    }
}