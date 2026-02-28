package com.example.new_quotes

import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import android.os.Bundle
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterActivity() {
  private val channelName = "new_quotes/media"
  private val premiumChannelName = "new_quotes/premium_db"

  private var pendingResult: MethodChannel.Result? = null
  private var premiumDb: SQLiteDatabase? = null

  private val pickImageLauncher = registerForActivityResult(
    ActivityResultContracts.OpenDocument()
  ) { uri: Uri? ->
    val result = pendingResult
    pendingResult = null
    if (result == null) return@registerForActivityResult
    if (uri == null) {
      result.success(null)
      return@registerForActivityResult
    }
    try {
      contentResolver.takePersistableUriPermission(
        uri,
        Intent.FLAG_GRANT_READ_URI_PERMISSION
      )
    } catch (_: Exception) {
      // ignore
    }
    try {
      val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
      result.success(bytes)
    } catch (e: Exception) {
      result.error("PICK_IMAGE_FAILED", e.message, null)
    }
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
      when (call.method) {
        "pickImageBytes" -> {
          if (pendingResult != null) {
            result.error("BUSY", "Another pick operation is in progress", null)
            return@setMethodCallHandler
          }
          pendingResult = result
          pickImageLauncher.launch(arrayOf("image/*"))
        }
        "shareText" -> {
          val text = (call.argument<String>("text") ?: "").trim()
          if (text.isEmpty()) {
            result.success(false)
            return@setMethodCallHandler
          }
          shareText(text)
          result.success(true)
        }
        "sharePngBytes" -> {
          val bytes = call.argument<ByteArray>("bytes")
          val filename = (call.argument<String>("filename") ?: "quote.png")
          if (bytes == null || bytes.isEmpty()) {
            result.success(false)
            return@setMethodCallHandler
          }
          val ok = sharePng(bytes, filename)
          result.success(ok)
        }
        else -> result.notImplemented()
      }
    }

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, premiumChannelName).setMethodCallHandler { call, result ->
      when (call.method) {
        "hasDb" -> {
          result.success(hasPremiumDb())
        }
        "downloadDb" -> {
          val url = (call.argument<String>("url") ?: "").trim()
          if (url.isEmpty()) {
            result.success(false)
            return@setMethodCallHandler
          }
          Thread {
            val ok = downloadPremiumDb(url)
            runOnUiThread { result.success(ok) }
          }.start()
        }
        "getCategories" -> {
          try {
            val db = openPremiumDb() ?: run {
              result.success(emptyList<Any>())
              return@setMethodCallHandler
            }
            result.success(queryCategories(db))
          } catch (e: Exception) {
            result.error("DB_QUERY_FAILED", e.message, null)
          }
        }
        "getQuotesPage" -> {
          try {
            val limit = (call.argument<Int>("limit") ?: 50).coerceIn(1, 200)
            val offset = (call.argument<Int>("offset") ?: 0).coerceAtLeast(0)
            val db = openPremiumDb() ?: run {
              result.success(emptyList<Any>())
              return@setMethodCallHandler
            }
            result.success(queryQuotesPage(db, limit, offset))
          } catch (e: Exception) {
            result.error("DB_QUERY_FAILED", e.message, null)
          }
        }
        "getQuotesByCategory" -> {
          try {
            val categoryId = (call.argument<String>("categoryId") ?: "").trim()
            val limit = (call.argument<Int>("limit") ?: 50).coerceIn(1, 200)
            val offset = (call.argument<Int>("offset") ?: 0).coerceAtLeast(0)
            val db = openPremiumDb() ?: run {
              result.success(emptyList<Any>())
              return@setMethodCallHandler
            }
            result.success(queryQuotesByCategory(db, categoryId, limit, offset))
          } catch (e: Exception) {
            result.error("DB_QUERY_FAILED", e.message, null)
          }
        }
        else -> result.notImplemented()
      }
    }
  }

  private fun shareText(text: String) {
    val intent = Intent(Intent.ACTION_SEND).apply {
      type = "text/plain"
      putExtra(Intent.EXTRA_TEXT, text)
    }
    startActivity(Intent.createChooser(intent, "Share"))
  }

  private fun sharePng(bytes: ByteArray, filename: String): Boolean {
    return try {
      val file = File(cacheDir, filename)
      file.writeBytes(bytes)
      val uri = FileProvider.getUriForFile(
        this,
        "${applicationContext.packageName}.fileprovider",
        file
      )
      val intent = Intent(Intent.ACTION_SEND).apply {
        type = "image/png"
        putExtra(Intent.EXTRA_STREAM, uri)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
      }
      startActivity(Intent.createChooser(intent, "Share image"))
      true
    } catch (_: Exception) {
      false
    }
  }

  private fun premiumDbFile(): File {
    return File(filesDir, "quotes_premium.db")
  }

  private fun hasPremiumDb(): Boolean {
    return premiumDbFile().exists()
  }

  private fun openPremiumDb(): SQLiteDatabase? {
    val existing = premiumDb
    if (existing != null && existing.isOpen) return existing
    val file = premiumDbFile()
    if (!file.exists()) return null
    val db = SQLiteDatabase.openDatabase(file.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
    premiumDb = db
    return db
  }

  private fun downloadPremiumDb(urlString: String): Boolean {
    return try {
      val url = URL(urlString)
      val conn = (url.openConnection() as HttpURLConnection).apply {
        connectTimeout = 15000
        readTimeout = 30000
        instanceFollowRedirects = true
      }
      conn.connect()
      if (conn.responseCode != 200) return false
      val tmp = File(filesDir, "quotes_premium.db.tmp")
      conn.inputStream.use { input ->
        tmp.outputStream().use { output ->
          input.copyTo(output)
        }
      }
      val dest = premiumDbFile()
      if (dest.exists()) dest.delete()
      tmp.renameTo(dest)
      premiumDb?.close()
      premiumDb = null
      true
    } catch (_: Exception) {
      false
    }
  }

  private fun queryCategories(db: SQLiteDatabase): List<Map<String, Any?>> {
    val out = ArrayList<Map<String, Any?>>()
    val cursor = db.rawQuery("SELECT id, name FROM categories ORDER BY name", null)
    cursor.use {
      val idIdx = it.getColumnIndex("id")
      val nameIdx = it.getColumnIndex("name")
      while (it.moveToNext()) {
        val row = HashMap<String, Any?>()
        row["id"] = if (idIdx >= 0) it.getString(idIdx) else ""
        row["name"] = if (nameIdx >= 0) it.getString(nameIdx) else ""
        out.add(row)
      }
    }
    return out
  }

  private fun queryQuotesPage(db: SQLiteDatabase, limit: Int, offset: Int): List<Map<String, Any?>> {
    val out = ArrayList<Map<String, Any?>>()
    val cursor = db.rawQuery(
      "SELECT text as quote, author, category_id as category, tags, is_premium, created_at FROM quotes ORDER BY id LIMIT ? OFFSET ?",
      arrayOf(limit.toString(), offset.toString())
    )
    cursor.use {
      val quoteIdx = it.getColumnIndex("quote")
      val authorIdx = it.getColumnIndex("author")
      val catIdx = it.getColumnIndex("category")
      while (it.moveToNext()) {
        val row = HashMap<String, Any?>()
        row["quote"] = if (quoteIdx >= 0) it.getString(quoteIdx) else ""
        row["author"] = if (authorIdx >= 0) it.getString(authorIdx) else ""
        row["category"] = if (catIdx >= 0) it.getString(catIdx) else ""
        out.add(row)
      }
    }
    return out
  }

  private fun queryQuotesByCategory(db: SQLiteDatabase, categoryId: String, limit: Int, offset: Int): List<Map<String, Any?>> {
    val out = ArrayList<Map<String, Any?>>()
    val cursor = db.rawQuery(
      "SELECT text as quote, author, category_id as category, tags, is_premium, created_at FROM quotes WHERE category_id = ? ORDER BY id LIMIT ? OFFSET ?",
      arrayOf(categoryId, limit.toString(), offset.toString())
    )
    cursor.use {
      val quoteIdx = it.getColumnIndex("quote")
      val authorIdx = it.getColumnIndex("author")
      val catIdx = it.getColumnIndex("category")
      while (it.moveToNext()) {
        val row = HashMap<String, Any?>()
        row["quote"] = if (quoteIdx >= 0) it.getString(quoteIdx) else ""
        row["author"] = if (authorIdx >= 0) it.getString(authorIdx) else ""
        row["category"] = if (catIdx >= 0) it.getString(catIdx) else ""
        out.add(row)
      }
    }
    return out
  }
}
