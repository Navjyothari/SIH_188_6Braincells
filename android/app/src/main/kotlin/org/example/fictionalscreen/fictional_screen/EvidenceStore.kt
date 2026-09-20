package org.example.fictionalscreen.fictional_screen

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.system.Os
import android.system.OsConstants
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.security.KeyStore
import java.util.UUID
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** One authenticated, encrypted envelope per atomic file: image + OCR + result. */
class EvidenceStore(context: Context) {
    private val directory = File(context.noBackupFilesDir, "evidence-v1").apply { check(isDirectory || mkdirs()) }
    private val alias = "fictional-screen-evidence-v1"
    private val ids = Regex("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")
    private val magic = byteArrayOf(70, 83, 69, 49)

    private fun key(create: Boolean): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if (store.containsAlias(alias)) return store.getKey(alias, null) as SecretKey
        check(create && list().isEmpty()) { "Existing evidence key unavailable" }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").run {
            init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256).setRandomizedEncryptionRequired(true).build())
            generateKey()
        }
    }

    @Synchronized fun save(envelope: String): String {
        val payload = envelope.toByteArray(Charsets.UTF_8)
        require(payload.size <= 40 * 1024 * 1024)
        val parsed = JSONObject(envelope)
        require(parsed.getInt("envelopeVersion") == 1 && parsed.getBoolean("synthetic"))
        require(parsed.getJSONObject("original").getString("base64").isNotEmpty())
        require(parsed.getJSONObject("result").getString("governmentVerification") == "NOT_CONFIGURED")
        val id = UUID.randomUUID().toString()
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key(true))
        check(cipher.iv.size == 12)
        cipher.updateAAD("FSE1:$id".toByteArray(Charsets.UTF_8))
        val encrypted = cipher.doFinal(payload)
        val bytes = ByteBuffer.allocate(4 + 12 + encrypted.size).put(magic).put(cipher.iv).put(encrypted).array()
        val file = File(directory, "$id.enc")
        val pending = File(directory, "$id.enc.new")
        try {
            FileOutputStream(pending).use { stream -> stream.write(bytes); stream.fd.sync() }
            // Both paths are in the same private directory/filesystem. Unlike older
            // AtomicFile implementations, no partial final-name file is exposed.
            Os.rename(pending.absolutePath, file.absolutePath)
        } catch (error: Exception) { pending.delete(); throw error }
        check(file.readBytes().contentEquals(bytes)) { "Atomic commit failed" }
        val dirFd = Os.open(directory.absolutePath, OsConstants.O_RDONLY, 0)
        try { Os.fsync(dirFd) } finally { Os.close(dirFd) }
        return id
    }

    @Synchronized fun load(id: String): String {
        require(ids.matches(id))
        val file = File(directory, "$id.enc")
        require(file.length() in 32..(40L * 1024 * 1024 + 32))
        val bytes = file.readBytes()
        require(bytes.copyOfRange(0, 4).contentEquals(magic))
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(false), GCMParameterSpec(128, bytes.copyOfRange(4, 16)))
        cipher.updateAAD("FSE1:$id".toByteArray(Charsets.UTF_8))
        return String(cipher.doFinal(bytes, 16, bytes.size - 16), Charsets.UTF_8)
    }

    @Synchronized fun list(): List<String> = (directory.listFiles() ?: error("Cannot list evidence"))
        .filter { it.isFile && it.extension == "enc" && ids.matches(it.nameWithoutExtension) }
        .sortedByDescending { it.lastModified() }.map { it.nameWithoutExtension }
}
