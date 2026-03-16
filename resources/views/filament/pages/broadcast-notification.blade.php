<x-filament-panels::page>
    <form wire:submit="send">
        {{ $this->form }}

        <div class="mt-6 flex items-center gap-4">
            <x-filament::button type="submit" wire:loading.attr="disabled">
                <span wire:loading.remove>📤 Envoyer la notification</span>
                <span wire:loading>⏳ Envoi en cours...</span>
            </x-filament::button>

            <p class="text-sm text-gray-500 dark:text-gray-400">
                La notification sera envoyée immédiatement à tous les utilisateurs du groupe ciblé.
            </p>
        </div>
    </form>
</x-filament-panels::page>
