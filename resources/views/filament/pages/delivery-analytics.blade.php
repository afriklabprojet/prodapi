<x-filament-panels::page>
    <div class="space-y-6" wire:poll.30s>

        {{-- Sélecteur de période --}}
        <div class="flex items-center gap-3 p-4 bg-white dark:bg-gray-800 rounded-xl shadow-sm">
            <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Période :</span>
            @foreach ([['7', '7 jours'], ['14', '14 jours'], ['30', '30 jours'], ['90', '90 jours']] as [$val, $label])
                <button wire:click="$set('period', '{{ $val }}')"
                    class="px-3 py-1.5 text-sm rounded-lg transition {{ $period === $val ? 'bg-primary-500 text-white' : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200' }}">
                    {{ $label }}
                </button>
            @endforeach
        </div>

        {{-- KPIs Overview --}}
        @php $stats = $this->getOverviewStats(); @endphp
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div class="p-5 bg-white dark:bg-gray-800 rounded-xl shadow-sm">
                <div class="text-sm text-gray-500">Total livraisons</div>
                <div class="text-3xl font-bold text-gray-900 dark:text-white">{{ number_format($stats['total']) }}</div>
                <div class="text-xs mt-1 {{ $stats['growth'] >= 0 ? 'text-success-600' : 'text-danger-600' }}">
                    {{ $stats['growth'] >= 0 ? '+' : '' }}{{ $stats['growth'] }}% vs période précédente
                </div>
            </div>
            <div class="p-5 bg-white dark:bg-gray-800 rounded-xl shadow-sm">
                <div class="text-sm text-gray-500">Taux complétion</div>
                <div class="text-3xl font-bold {{ $stats['completion_rate'] >= 85 ? 'text-success-600' : 'text-warning-600' }}">
                    {{ $stats['completion_rate'] }}%
                </div>
                <div class="text-xs text-gray-400 mt-1">{{ $stats['completed'] }} / {{ $stats['total'] }}</div>
            </div>
            <div class="p-5 bg-white dark:bg-gray-800 rounded-xl shadow-sm">
                <div class="text-sm text-gray-500">Durée moyenne</div>
                <div class="text-3xl font-bold text-primary-600">{{ $stats['avg_duration_min'] }}<span class="text-lg">min</span></div>
                <div class="text-xs text-gray-400 mt-1">Assignation → livraison</div>
            </div>
            <div class="p-5 bg-white dark:bg-gray-800 rounded-xl shadow-sm">
                <div class="text-sm text-gray-500">Revenus livraison</div>
                <div class="text-3xl font-bold text-success-600">{{ number_format($stats['total_revenue']) }}</div>
                <div class="text-xs text-gray-400 mt-1">FCFA total</div>
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {{-- Graphique journalier --}}
            @php $chart = $this->getDailyChart(); @endphp
            <div class="p-5 bg-white dark:bg-gray-800 rounded-xl shadow-sm">
                <h3 class="text-lg font-semibold mb-4">Livraisons par jour</h3>
                <div class="space-y-2">
                    @foreach ($chart['labels'] as $i => $label)
                        <div class="flex items-center gap-2 text-sm">
                            <span class="w-12 text-gray-500">{{ $label }}</span>
                            <div class="flex-1 bg-gray-100 dark:bg-gray-700 rounded-full h-5 relative overflow-hidden">
                                @php
                                    $max = max(1, max($chart['total']));
                                    $totalW = ($chart['total'][$i] / $max) * 100;
                                    $completedW = ($chart['completed'][$i] / $max) * 100;
                                @endphp
                                <div class="absolute inset-y-0 left-0 bg-primary-200 dark:bg-primary-800 rounded-full" style="width: {{ $totalW }}%"></div>
                                <div class="absolute inset-y-0 left-0 bg-primary-500 rounded-full" style="width: {{ $completedW }}%"></div>
                            </div>
                            <span class="w-16 text-right text-gray-600 dark:text-gray-400">{{ $chart['total'][$i] }}</span>
                        </div>
                    @endforeach
                </div>
            </div>

            {{-- Distribution horaire --}}
            @php $hourly = $this->getHourlyDistribution(); @endphp
            <div class="p-5 bg-white dark:bg-gray-800 rounded-xl shadow-sm">
                <h3 class="text-lg font-semibold mb-4">Distribution horaire</h3>
                <div class="flex items-end gap-1 h-48">
                    @php $maxH = max(1, max($hourly['data'])); @endphp
                    @foreach ($hourly['data'] as $i => $count)
                        <div class="flex-1 flex flex-col items-center gap-1">
                            <div class="w-full bg-primary-500 rounded-t transition-all"
                                 style="height: {{ ($count / $maxH) * 100 }}%"
                                 title="{{ $hourly['labels'][$i] }}: {{ $count }}">
                            </div>
                            <span class="text-[10px] text-gray-400">{{ substr($hourly['labels'][$i], 0, 2) }}</span>
                        </div>
                    @endforeach
                </div>
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {{-- Funnel offres --}}
            @php $funnel = $this->getOfferFunnel(); @endphp
            <div class="p-5 bg-white dark:bg-gray-800 rounded-xl shadow-sm">
                <h3 class="text-lg font-semibold mb-4">Funnel des offres</h3>
                <div class="space-y-3">
                    @php $funnelMax = max(1, $funnel['created']); @endphp
                    @foreach ([
                        ['label' => 'Créées', 'value' => $funnel['created'], 'color' => 'bg-gray-400'],
                        ['label' => 'Acceptées', 'value' => $funnel['accepted'], 'color' => 'bg-success-500'],
                        ['label' => 'Expirées', 'value' => $funnel['expired'], 'color' => 'bg-warning-500'],
                        ['label' => 'Sans livreur', 'value' => $funnel['no_courier'], 'color' => 'bg-danger-500'],
                    ] as $item)
                        <div>
                            <div class="flex justify-between text-sm mb-1">
                                <span class="text-gray-600 dark:text-gray-400">{{ $item['label'] }}</span>
                                <span class="font-semibold">{{ $item['value'] }}
                                    @if($funnel['created'] > 0)
                                        <span class="text-gray-400 font-normal">({{ round(($item['value'] / $funnel['created']) * 100) }}%)</span>
                                    @endif
                                </span>
                            </div>
                            <div class="w-full bg-gray-100 dark:bg-gray-700 rounded-full h-3">
                                <div class="{{ $item['color'] }} h-3 rounded-full transition-all"
                                     style="width: {{ ($item['value'] / $funnelMax) * 100 }}%"></div>
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>

            {{-- Top pharmacies --}}
            @php $pharmacies = $this->getTopPharmacies(); @endphp
            <div class="p-5 bg-white dark:bg-gray-800 rounded-xl shadow-sm">
                <h3 class="text-lg font-semibold mb-4">Top pharmacies</h3>
                <div class="space-y-2">
                    @forelse ($pharmacies as $i => $pharma)
                        <div class="flex items-center gap-3 p-2 {{ $i < 3 ? 'bg-primary-50 dark:bg-primary-900/20' : '' }} rounded-lg">
                            <span class="w-6 h-6 flex items-center justify-center text-xs font-bold rounded-full
                                {{ $i === 0 ? 'bg-yellow-400 text-white' : ($i === 1 ? 'bg-gray-300 text-gray-700' : ($i === 2 ? 'bg-orange-400 text-white' : 'bg-gray-100 text-gray-500')) }}">
                                {{ $i + 1 }}
                            </span>
                            <div class="flex-1 min-w-0">
                                <div class="text-sm font-medium truncate">{{ $pharma['name'] }}</div>
                            </div>
                            <div class="text-right">
                                <div class="text-sm font-bold">{{ $pharma['delivery_count'] }}</div>
                                <div class="text-xs text-gray-400">{{ number_format($pharma['avg_fee']) }} FCFA/moy</div>
                            </div>
                        </div>
                    @empty
                        <div class="text-center text-gray-400 py-4">Aucune donnée</div>
                    @endforelse
                </div>
            </div>
        </div>

        {{-- Stats note client --}}
        <div class="p-5 bg-white dark:bg-gray-800 rounded-xl shadow-sm">
            <div class="flex items-center gap-3">
                <div class="text-4xl">⭐</div>
                <div>
                    <div class="text-sm text-gray-500">Note client moyenne</div>
                    <div class="text-2xl font-bold">{{ $stats['avg_rating'] }} / 5</div>
                </div>
                <div class="ml-auto text-sm text-gray-400">
                    {{ $stats['cancelled'] }} annulation{{ $stats['cancelled'] > 1 ? 's' : '' }} sur la période
                </div>
            </div>
        </div>
    </div>
</x-filament-panels::page>
