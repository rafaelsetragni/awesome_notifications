package me.carda.awesome_notifications_fcm

/**
 * Reconstructs a nested map from an FCM data payload whose keys use dot notation.
 *
 * FCM data messages can only carry a flat `Map<String,String>`, so a server may
 * send the awesome payload flattened, e.g.:
 *
 *   "content.id" = "1", "content.title" = "Hi", "actionButtons.0.key" = "OK"
 *
 * decodes to:
 *
 *   { content: { id: "1", title: "Hi" }, actionButtons: [ { key: "OK" } ] }
 *
 * A numeric path segment turns the parent into a list. Since every value arrives
 * as a string, `"true"` / `"false"` become booleans (the core reads flags with
 * `getBool`, which does not parse strings) and `"null"` drops the key; anything
 * else stays a string (the core parses numeric strings itself).
 */
object JsonFlattener {

    @Suppress("UNCHECKED_CAST")
    fun decode(flat: Map<String, String>): MutableMap<String, Any?> {
        val root = mutableMapOf<String, Any?>()
        for ((key, value) in flat) {
            val coerced = coerce(value) ?: continue
            insert(root, key.split('.'), coerced)
        }
        return normalize(root) as MutableMap<String, Any?>
    }

    /** Typed value of a flattened string, or null to drop the key. */
    fun coerce(value: String): Any? = when (value) {
        "true" -> true
        "false" -> false
        "null" -> null
        else -> value
    }

    @Suppress("UNCHECKED_CAST")
    private fun insert(node: MutableMap<String, Any?>, path: List<String>, value: Any) {
        val head = path.first()
        if (path.size == 1) {
            node[head] = value
            return
        }
        val child = node[head] as? MutableMap<String, Any?> ?: mutableMapOf<String, Any?>().also {
            node[head] = it
        }
        insert(child, path.drop(1), value)
    }

    /**
     * Turns any map whose keys are the contiguous indices 0..n-1 into a list, so
     * `actionButtons.0.*` / `actionButtons.1.*` become a real list.
     */
    @Suppress("UNCHECKED_CAST")
    private fun normalize(value: Any?): Any? = when (value) {
        is MutableMap<*, *> -> {
            val map = value as MutableMap<String, Any?>
            for (k in map.keys.toList()) map[k] = normalize(map[k])
            asListIfIndexed(map) ?: map
        }
        else -> value
    }

    private fun asListIfIndexed(map: Map<String, Any?>): List<Any?>? {
        if (map.isEmpty()) return null
        val indices = map.keys.mapNotNull { it.toIntOrNull() }
        if (indices.size != map.size) return null
        if (indices.sorted() != (0 until map.size).toList()) return null
        return indices.sorted().map { map[it.toString()] }
    }
}
