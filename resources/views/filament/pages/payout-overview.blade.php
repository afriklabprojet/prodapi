<x-filament-panels::page>
    <x-filament::tabs>
        <x-filament::tabs.item
            :active="$activeTab === 'pharmacies'"
            wire:click="switchTab('pharmacies')"
            icon="heroicon-o-building-storefront"
        >
            Pharmacies
            <x-slot name="badge">
                {{ \App\Models\Wallet::where('walletable_type', 'App\Models\Pharmacy')->where('balance', '>', 0)->count() }}
            </x-slot>
        </x-filament::tabs.item>

        <x-filament::tabs.item
            :active="$activeTab === 'couriers'"
            wire:click="switchTab('couriers')"
            icon="heroicon-o-truck"
        >
            Livreurs
            <x-slot name="badge">
                {{ \App\Models\Wallet::where('walletable_type', 'App\Models\Courier')->where('balance', '>', 0)->count() }}
            </x-slot>
        </x-filament::tabs.item>
    </x-filament::tabs>

    {{ $this->table }}
</x-filament-panels::page>
