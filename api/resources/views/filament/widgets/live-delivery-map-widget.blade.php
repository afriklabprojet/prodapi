<div wire:poll.10s>
    @php
        $deliveries = $this->getActiveDeliveries();
        $couriers = $this->getAvailableCouriers();
        $stats = $this->getMapStats();
    @endphp

    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden">
        {{-- Header --}}
        <div class="p-4 border-b dark:border-gray-700 flex items-center justify-between flex-wrap gap-2">
            <div class="flex items-center gap-3">
                <h3 class="text-lg font-semibold">🗺️ Carte temps réel</h3>
                <span class="inline-flex items-center gap-1 px-2 py-0.5 bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300 rounded-full text-xs">
                    <span class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
                    Live
                </span>
            </div>
            <div class="flex items-center gap-4 text-sm flex-wrap">
                <span class="text-primary-600 font-medium">
                    🚴 {{ $stats['active_deliveries'] }} en livraison
                </span>
                <span class="text-success-600 font-medium">
                    ✅ {{ $stats['available_couriers'] }} disponibles
                </span>
                @if($stats['stale_gps'] > 0)
                    <span class="text-warning-600 font-medium">
                        ⚠️ {{ $stats['stale_gps'] }} GPS obsolète
                    </span>
                @endif
            </div>
        </div>

        {{-- Map + Sidebar --}}
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-0">
            {{-- Leaflet Map --}}
            <div class="lg:col-span-2 relative" style="min-height: 500px;" wire:ignore>
                <div id="live-delivery-map" class="absolute inset-0 z-0"></div>

                {{-- Legend overlay --}}
                <div class="absolute bottom-3 left-3 z-[1000] bg-white/90 dark:bg-gray-800/90 backdrop-blur rounded-lg px-3 py-2 text-xs shadow space-y-1">
                    <div class="flex items-center gap-2">
                        <span class="inline-block w-3 h-3 rounded-full bg-blue-500"></span>
                        <span class="dark:text-gray-300">En livraison</span>
                    </div>
                    <div class="flex items-center gap-2">
                        <span class="inline-block w-3 h-3 rounded-full bg-emerald-500"></span>
                        <span class="dark:text-gray-300">Disponible</span>
                    </div>
                    <div class="flex items-center gap-2">
                        <span class="inline-block w-3 h-3 rounded-full bg-amber-400"></span>
                        <span class="dark:text-gray-300">GPS obsolète</span>
                    </div>
                </div>
            </div>

            {{-- Sidebar: deliveries + couriers --}}
            <div class="border-l dark:border-gray-700 overflow-y-auto max-h-[500px]">
                <div class="p-3 border-b dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
                    <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300">Livraisons actives</h4>
                </div>

                @forelse ($deliveries as $delivery)
                    <div
                        class="p-3 border-b dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-750 transition cursor-pointer"
                        onclick="window._liveMapPanTo && window._liveMapPanTo({{ $delivery['position']['latitude'] ?? 'null' }}, {{ $delivery['position']['longitude'] ?? 'null' }})"
                    >
                        <div class="flex items-center justify-between mb-1">
                            <span class="text-sm font-medium">#{{ $delivery['delivery_id'] }}</span>
                            <span class="text-xs px-2 py-0.5 rounded-full
                                {{ $delivery['status'] === 'picked_up' ? 'bg-primary-100 text-primary-700' :
                                   ($delivery['status'] === 'assigned' ? 'bg-yellow-100 text-yellow-700' : 'bg-gray-100 text-gray-700') }}">
                                {{ $delivery['status'] }}
                            </span>
                        </div>
                        <div class="text-xs text-gray-500">
                            {{ $delivery['courier_name'] }} → {{ $delivery['pickup_pharmacy'] }}
                        </div>
                        @if($delivery['position'])
                            <div class="text-[10px] text-gray-400 mt-1 flex items-center gap-2">
                                <span>📍 {{ number_format($delivery['position']['latitude'], 5) }}, {{ number_format($delivery['position']['longitude'], 5) }}</span>
                                @if($delivery['position']['is_stale'])
                                    <span class="text-warning-500">⚠ GPS obsolète</span>
                                @endif
                            </div>
                        @endif
                    </div>
                @empty
                    <div class="p-6 text-center text-gray-400 text-sm">
                        Aucune livraison active
                    </div>
                @endforelse

                <div class="p-3 border-b border-t dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
                    <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300">Livreurs disponibles</h4>
                </div>

                @forelse ($couriers as $courier)
                    <div
                        class="p-3 border-b dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-750 transition cursor-pointer"
                        onclick="window._liveMapPanTo && window._liveMapPanTo({{ $courier['latitude'] }}, {{ $courier['longitude'] }})"
                    >
                        <div class="flex items-center justify-between">
                            <span class="text-sm">{{ $courier['name'] }}</span>
                            <span class="text-[10px] text-gray-400">{{ $courier['updated_at'] }}</span>
                        </div>
                        <div class="text-[10px] text-gray-400 flex items-center gap-2">
                            <span>📍 {{ number_format($courier['latitude'], 5) }}, {{ number_format($courier['longitude'], 5) }}</span>
                            @if($courier['is_stale'])
                                <span class="text-warning-500">⚠ Stale</span>
                            @else
                                <span class="text-success-500">● Actif</span>
                            @endif
                        </div>
                    </div>
                @empty
                    <div class="p-4 text-center text-gray-400 text-sm">
                        Aucun livreur disponible
                    </div>
                @endforelse
            </div>
        </div>
    </div>
</div>

@script
<script>
(function () {
    // ── Load Leaflet CSS ──
    if (!document.querySelector('link[href*="leaflet.css"]')) {
        const css = document.createElement('link');
        css.rel = 'stylesheet';
        css.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
        css.crossOrigin = '';
        document.head.appendChild(css);
    }

    function boot() {
        const el = document.getElementById('live-delivery-map');
        if (!el || el._leafletMap) return;

        const map = L.map(el, {
            zoomControl: true,
            attributionControl: true,
        }).setView([5.36, -4.01], 13);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
        }).addTo(map);

        el._leafletMap = map;
        let markers = [];
        let firstFit = true;

        async function refreshMarkers() {
            try {
                const data = await $wire.getMapData();
                const deliveries = data.deliveries || [];
                const couriers = data.couriers || [];

                markers.forEach(function (m) { m.remove(); });
                markers = [];
                const bounds = [];

                deliveries.forEach(function (d) {
                    if (!d.position || !d.position.latitude) return;
                    var lat = d.position.latitude;
                    var lng = d.position.longitude;
                    bounds.push([lat, lng]);

                    var stale = d.position.is_stale;
                    var icon = L.divIcon({
                        className: '',
                        html: '<div style="width:32px;height:32px;border-radius:50%;'
                            + 'background:' + (stale ? '#f59e0b' : '#3b82f6') + ';'
                            + 'border:3px solid white;box-shadow:0 2px 6px rgba(0,0,0,.35);'
                            + 'display:flex;align-items:center;justify-content:center;'
                            + 'font-size:14px;color:white;">\uD83D\uDEB4</div>',
                        iconSize: [32, 32],
                        iconAnchor: [16, 16],
                    });

                    var popup = '<div style="min-width:160px">'
                        + '<strong>#' + d.delivery_id + '</strong> '
                        + '<span style="display:inline-block;padding:1px 6px;border-radius:9999px;font-size:11px;'
                        + 'background:' + (d.status === 'picked_up' ? '#dbeafe' : '#fef3c7') + ';'
                        + 'color:' + (d.status === 'picked_up' ? '#1d4ed8' : '#92400e') + ';">'
                        + d.status + '</span>'
                        + '<br><span style="font-size:12px;color:#6b7280;">'
                        + d.courier_name + ' \u2192 ' + d.pickup_pharmacy + '</span>'
                        + (stale ? '<br><span style="color:#f59e0b;font-size:11px;">\u26A0 GPS obsol\u00E8te</span>' : '')
                        + '</div>';

                    markers.push(L.marker([lat, lng], { icon: icon }).addTo(map).bindPopup(popup));
                });

                couriers.forEach(function (c) {
                    if (!c.latitude) return;
                    bounds.push([c.latitude, c.longitude]);

                    var icon = L.divIcon({
                        className: '',
                        html: '<div style="width:28px;height:28px;border-radius:50%;'
                            + 'background:' + (c.is_stale ? '#f59e0b' : '#10b981') + ';'
                            + 'border:3px solid white;box-shadow:0 2px 6px rgba(0,0,0,.3);'
                            + 'display:flex;align-items:center;justify-content:center;'
                            + 'font-size:12px;color:white;">\u2713</div>',
                        iconSize: [28, 28],
                        iconAnchor: [14, 14],
                    });

                    var popup = '<div style="min-width:140px">'
                        + '<strong>' + c.name + '</strong>'
                        + '<br><span style="font-size:12px;color:#6b7280;">'
                        + (c.is_stale ? '\u26A0 GPS obsol\u00E8te' : '\u25CF Disponible') + '</span>'
                        + '<br><span style="font-size:11px;color:#9ca3af;">' + c.updated_at + '</span>'
                        + '</div>';

                    markers.push(L.marker([c.latitude, c.longitude], { icon: icon }).addTo(map).bindPopup(popup));
                });

                if (bounds.length > 0 && firstFit) {
                    map.fitBounds(bounds, { padding: [40, 40], maxZoom: 15 });
                    firstFit = false;
                }
            } catch (e) {
                console.warn('[LiveMap] refresh error:', e);
            }
        }

        window._liveMapPanTo = function (lat, lng) {
            if (lat === null || lng === null) return;
            map.flyTo([lat, lng], 16, { duration: 0.8 });
        };

        // Initial load
        setTimeout(function () {
            map.invalidateSize();
            refreshMarkers();
        }, 300);

        // Refresh markers on every Livewire poll cycle
        Livewire.hook('commit', function (payload) {
            payload.succeed(function () {
                refreshMarkers();
            });
        });
    }

    // Load Leaflet JS if needed, then init
    if (window.L) {
        boot();
    } else {
        var js = document.createElement('script');
        js.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
        js.crossOrigin = '';
        js.onload = boot;
        document.head.appendChild(js);
    }
})();
</script>
@endscript