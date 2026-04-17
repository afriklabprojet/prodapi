<x-filament-panels::page>
    <div class="space-y-6">
        {{-- Filtres de date --}}
        <div class="flex items-end gap-4 p-4 bg-white dark:bg-gray-800 rounded-xl shadow-sm">
            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Date début</label>
                <input type="date" wire:model.live.debounce.500ms="dateFrom"
                    class="rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700 shadow-sm text-sm">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Date fin</label>
                <input type="date" wire:model.live.debounce.500ms="dateTo"
                    class="rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700 shadow-sm text-sm">
            </div>
        </div>

        {{-- KPIs --}}
        @php $kpis = $this->getKpis(); @endphp
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
            <div class="p-4 bg-white dark:bg-gray-800 rounded-xl shadow-sm text-center">
                <div class="text-2xl font-bold text-primary-600">{{ $kpis['total_couriers'] }}</div>
                <div class="text-xs text-gray-500 mt-1">Livreurs vérifiés</div>
            </div>
            <div class="p-4 bg-white dark:bg-gray-800 rounded-xl shadow-sm text-center">
                <div class="text-2xl font-bold text-success-600">{{ $kpis['active_couriers'] }}</div>
                <div class="text-xs text-gray-500 mt-1">Actifs (période)</div>
            </div>
            <div class="p-4 bg-white dark:bg-gray-800 rounded-xl shadow-sm text-center">
                <div class="text-2xl font-bold text-info-600">{{ $kpis['total_deliveries'] }}</div>
                <div class="text-xs text-gray-500 mt-1">Total livraisons</div>
            </div>
            <div class="p-4 bg-white dark:bg-gray-800 rounded-xl shadow-sm text-center">
                <div class="text-2xl font-bold text-success-600">{{ $kpis['completed_deliveries'] }}</div>
                <div class="text-xs text-gray-500 mt-1">Complétées</div>
            </div>
            <div class="p-4 bg-white dark:bg-gray-800 rounded-xl shadow-sm text-center">
                <div class="text-2xl font-bold text-warning-600">{{ $kpis['avg_acceptance_rate'] }}%</div>
                <div class="text-xs text-gray-500 mt-1">Moy. acceptation</div>
            </div>
            <div class="p-4 bg-white dark:bg-gray-800 rounded-xl shadow-sm text-center">
                <div class="text-2xl font-bold text-primary-600">{{ $kpis['avg_reliability'] }}</div>
                <div class="text-xs text-gray-500 mt-1">Moy. fiabilité</div>
            </div>
        </div>

        {{-- Table --}}
        <div>
            {{ $this->table }}
        </div>
    </div>
</x-filament-panels::page>
