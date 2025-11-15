using GLib;
using Gee;

// Small generic LRU cache backed by Gee.HashMap and an order list.
// Intended for short-lived in-memory caches where simple bounded
// eviction is sufficient. Not optimized for extreme throughput.
public class LruCache<K, V> : GLib.Object {
    private Gee.HashMap<K, V> map;
    private Gee.ArrayList<K> order;
    private int capacity;

    public LruCache(int capacity) {
        GLib.Object();
        if (capacity <= 0) capacity = 128;
        this.capacity = capacity;
        map = new Gee.HashMap<K, V>();
        order = new Gee.ArrayList<K>();
    }

    // Retrieve a value or null if missing. Marks the key as recently used.
    public V? get(K key) {
        try {
            var v = map.get(key);
            if (v != null) {
                // move key to back
                try { order.remove(key); } catch (GLib.Error e) { }
                order.add(key);
            }
            return v;
        } catch (GLib.Error e) {
            return null;
        }
    }

    // Insert or update a value and enforce capacity eviction.
    public void set(K key, V value) {
        try {
            bool exists = false;
            try {
                var tmp = map.get(key);
                if (tmp != null) exists = true;
            } catch (GLib.Error e) { exists = false; }

            map.set(key, value);
            if (exists) {
                try { order.remove(key); } catch (GLib.Error e) { }
                order.add(key);
                return;
            }

            order.add(key);
            // Evict oldest if over capacity
            while (order.size > capacity) {
                K oldest = order.get(0);
                order.remove_at(0);
                try { map.remove(oldest); } catch (GLib.Error e) { }
            }
        } catch (GLib.Error e) {
            // best-effort: ignore cache failures
        }
    }

    // Remove a key from the cache
    public bool remove(K key) {
        bool r = false;
        try {
            try { order.remove(key); } catch (GLib.Error e) { }
            r = map.remove(key);
        } catch (GLib.Error e) { r = false; }
        return r;
    }

    public void clear() {
        try {
            order.clear();
            map.clear();
        } catch (GLib.Error e) { }
    }

    public int size() {
        return map.size;
    }

    public int get_capacity() {
        return capacity;
    }

    public void set_capacity(int c) {
        if (c <= 0) return;
        capacity = c;
        // Trim if necessary
        while (order.size > capacity) {
            K oldest = order.get(0);
            order.remove_at(0);
            try { map.remove(oldest); } catch (GLib.Error e) { }
        }
    }

    // Return a copy of the keys in LRU order (oldest first). Useful for
    // diagnostics; callers should not mutate the returned list expecting
    // it to affect the cache.
    public Gee.ArrayList<K> keys() {
        var copy = new Gee.ArrayList<K>();
        try {
            for (int i = 0; i < order.size; i++) {
                copy.add(order.get(i));
            }
        } catch (GLib.Error e) { }
        return copy;
    }
}
