<x-filament-panels::page>
    <div class="max-w-md mx-auto space-y-6">
        <div class="p-4 bg-info-50 dark:bg-info-950/50 border border-info-300 dark:border-info-700 rounded-xl">
            <div class="flex items-center gap-3">
                <x-heroicon-o-lock-closed class="w-6 h-6 text-info-600 dark:text-info-400" />
                <p class="text-sm font-medium text-info-800 dark:text-info-200">
                    Saisissez le code à 6 chiffres généré par votre application d'authentification,
                    ou un code de récupération.
                </p>
            </div>
        </div>

        <x-filament-panels::form wire:submit="submitChallenge">
            {{ $this->form }}
            <x-filament-panels::form.actions :actions="$this->getCachedFormActions()" />
        </x-filament-panels::form>
    </div>
</x-filament-panels::page>
