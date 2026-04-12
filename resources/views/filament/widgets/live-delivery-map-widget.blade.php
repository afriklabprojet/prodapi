<div wire:poll.10s>
    @php
        $deliveries = $this->getActiveDeliveries();
        $couriers = $this->getAvailableCouriers();
        $stats = $this->getMapStats();
    @endphp

    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden">
        {{-- Header --}}
        <div class="p-4 border-b dark:border-gray-700 flex items-center justify-between">
            <div class="flex items-center gap-3">
                <h3 class="text-lg font-semibold">🗺️ Carte temps réel</h3>
                <span class="inline-flex items-center gap-1 px-2 py-0.5 bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300 rounded-full text-xs">
                    <span class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
                    Live
                </span>
            </div>
            <div class="flex items-center gap-4 text-sm">
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

        {{-- Map Placeholder + Data Grid --}}
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-0">
            {{-- Map area --}}
            <div class="lg:col-span-2 bg-gray-100 dark:bg-gray-900 p-6 min-h-[400px] relative">
                <div class="absolute inset-0 flex items-center justify-center text-gray-400">
                    <div class="text-center">
                        <div class="text-6xl mb-2">🗺️</div>
                        <p class="text-sm">Carte interactive</p>
                        <p class="text-xs text-gray-500 mt-1">Intégration Google Maps / Leaflet à venir</p>
                        <p class="text-xs text-gray-500">{{ count($deliveries) + count($couriers) }} marqueurs prêts</p>
                    </div>
                </div>
            </div>

            {{-- Sidebar: active deliveries list --}}
            <div class="border-l dark:border-gray-700 overflow-y-auto max-h-[500px]">
                <div class="p-3 border-b dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
                    <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300">Livraisons actives</h4>
                </div>

                @forelse ($deliveries as $delivery)
                    <div class="p-3 border-b dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-750 transition">
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

                {{-- Available couriers --}}
                <div class="p-3 border-b border-t dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
                    <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300">Livreurs disponibles</h4>
                </div>

                @forelse ($couriers as $courier)
                    <div class="p-3 border-b dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-750 transition">
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
