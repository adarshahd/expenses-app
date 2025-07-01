package com.gigathinking.expenses

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Dispatchers.Main
import kotlinx.coroutines.Job
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL = "io.gthink.expenses/file_operations"
    private val PICK_FILE = 2
    private lateinit var pendingResult: MethodChannel.Result

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "copy_files") {
                val arguments = call.arguments as ArrayList<*>
                val sourcePath = arguments[0] as String
                val destinationPath = arguments[1] as String

                Log.i("source", sourcePath)
                Log.i("dest", destinationPath)

                lifecycleScope.launch {
                    val copyResult = copyFile(Uri.parse(sourcePath), Uri.parse(destinationPath))
                    result.success(copyResult)
                }
            } else if (call.method == "pick_file") {
                pickFile(result)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == PICK_FILE && resultCode == Activity.RESULT_OK) {
            val uri = data?.data.toString()
            val contentResolver = applicationContext.contentResolver

            val takeFlags: Int = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION

            contentResolver.takePersistableUriPermission(Uri.parse(uri), takeFlags)

            pendingResult.success(uri)
        } else {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    private fun pickFile(result: MethodChannel.Result) {
        pendingResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
        }

        startActivityForResult(intent, PICK_FILE)
    }

    private suspend fun copyFile(source: Uri, destination: Uri): Int {
        withContext(Dispatchers.IO) {
            val inputStream = context.contentResolver.openInputStream(source)
            val outputStream = context.contentResolver.openOutputStream(destination)
            val buffer = ByteArray(1024)
            var length: Int

            while (inputStream?.read(buffer).also { length = it!! }!! > 0) {
                outputStream?.write(buffer, 0, length)
            }

            inputStream?.close()
            outputStream?.close()
        }

        return 0
    }
}
