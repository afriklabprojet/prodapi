<x-filament-panels::page>
    <x-filament-panels::form wire:submit="save">
        {{ $this->form }}

        <div class="fi-form-actions">
            <x-filament::button type="submit">
                Enregistrer
            </x-filament::button>
        </div>
    </x-filament-panels::form>
</x-filament-panels::page>
