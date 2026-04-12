<x-filament-panels::page>
    <div class="space-y-6">
        {{-- Header Stats --}}
        @if ($this->getHeaderWidgets())
            <x-filament-widgets::widgets
                :widgets="$this->getHeaderWidgets()"
                :columns="$this->getHeaderWidgetsColumns()"
            />
        @endif
        
        {{-- Info Banner --}}
        <div class="p-4 bg-primary-50 dark:bg-gray-800 rounded-xl border border-primary-200 dark:border-gray-700">
            <div class="flex items-center gap-3">
                <x-heroicon-o-information-circle class="w-6 h-6 text-primary-500" />
                <div>
                    <p class="text-sm font-medium text-primary-700 dark:text-primary-400">
                        Dashboard de dispatch en temps réel
                    </p>
                    <p class="text-xs text-primary-600 dark:text-primary-500">
                        Les données se rafraîchissent automatiquement. Dernière mise à jour: {{ now()->format('H:i:s') }}
                    </p>
                </div>
            </div>
        </div>
        
        {{-- Footer Widgets (Tables) --}}
        @if ($this->getFooterWidgets())
            <x-filament-widgets::widgets
                :widgets="$this->getFooterWidgets()"
                :columns="$this->getFooterWidgetsColumns()"
            />
        @endif
    </div>
</x-filament-panels::page>
