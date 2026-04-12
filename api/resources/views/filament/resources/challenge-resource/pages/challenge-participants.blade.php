<x-filament-panels::page>
    <div class="mb-6">
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <x-filament::section>
                <div class="text-center">
                    <div class="text-sm text-gray-500 dark:text-gray-400">Objectif</div>
                    <div class="text-2xl font-bold text-primary-600">{{ $record->target_value }}</div>
                    <div class="text-xs text-gray-400">{{ $record->metric }}</div>
                </div>
            </x-filament::section>
            
            <x-filament::section>
                <div class="text-center">
                    <div class="text-sm text-gray-500 dark:text-gray-400">Récompense</div>
                    <div class="text-2xl font-bold text-success-600">{{ number_format($record->reward_amount, 0, ',', ' ') }} FCFA</div>
                </div>
            </x-filament::section>
            
            <x-filament::section>
                <div class="text-center">
                    <div class="text-sm text-gray-500 dark:text-gray-400">Participants</div>
                    <div class="text-2xl font-bold text-info-600">{{ $record->couriers()->count() }}</div>
                    <div class="text-xs text-gray-400">{{ $record->couriers()->wherePivot('status', 'completed')->orWherePivot('status', 'claimed')->count() }} terminés</div>
                </div>
            </x-filament::section>
        </div>
    </div>
    
    {{ $this->table }}
</x-filament-panels::page>
