<x-filament-panels::page>
    <div class="max-w-xl mx-auto">
        <div
            class="mb-6 p-4 bg-warning-50 dark:bg-warning-950/50 border border-warning-300 dark:border-warning-700 rounded-xl">
            <div class="flex items-center gap-3">
                <x-heroicon-o-exclamation-triangle class="w-6 h-6 text-warning-600 dark:text-warning-400" />
                <p class="text-sm font-medium text-warning-800 dark:text-warning-200">
                    Vous devez changer votre mot de passe par défaut avant de pouvoir accéder au tableau de bord.
                </p>
            </div>
        </div>

        <x-filament-panels::form wire:submit="save">
            {{ $this->form }}

            <x-filament-panels::form.actions :actions="$this->getFormActions()" />
        </x-filament-panels::form>
    </div>
</x-filament-panels::page>
