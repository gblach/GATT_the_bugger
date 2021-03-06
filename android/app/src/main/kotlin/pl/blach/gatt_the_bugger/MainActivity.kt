package pl.blach.gatt_the_bugger

import android.bluetooth.BluetoothAdapter
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "pl.blach.gatt_the_bugger/native"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if(call.method == "btenable") {
                val mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
                result.success(mBluetoothAdapter.enable())
            } else if(call.method == "btdisable") {
                val mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
                result.success(mBluetoothAdapter.disable())
            } else {
                result.notImplemented()
            }
        }
    }
}
