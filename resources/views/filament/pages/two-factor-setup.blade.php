<x-filament-panels::page>
    <div class="max-w-xl mx-auto space-y-6">
        @if ($confirmed)
            <div class="p-4 bg-success-50 dark:bg-success-950/50 border border-success-300 dark:border-success-700 rounded-xl">
                <div class="flex items-center gap-3">
                    <x-heroicon-o-shield-check class="w-6 h-6 text-success-600 dark:text-success-400" />
                    <p class="text-sm font-medium text-success-800 dark:text-success-200">
                        La double authentification est activée sur votre compte.
                    </p>
                </div>
            </div>
            <x-filament::button wire:click="continueToDashboard" icon="heroicon-o-arrow-right">
                Continuer vers le tableau de bord
            </x-filament::button>
        @else
            <div class="p-4 bg-warning-50 dark:bg-warning-950/50 border border-warning-300 dark:border-warning-700 rounded-xl">
                <p class="text-sm text-warning-800 dark:text-warning-200">
                    Pour des raisons de sécurité, l'accès au panel admin requiert l'activation de la
                    double authentification (2FA TOTP). Scannez le QR code ci-dessous avec votre application
                    d'authentification (Google Authenticator, 1Password, Authy...).
                </p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="p-4 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700 rounded-xl flex items-center justify-center">
                    {!! $qrSvg !!}
                </div>
                <div class="space-y-3">
                    <div>
                        <p class="text-xs font-semibold text-gray-500 uppercase">Clé manuelle</p>
                        <code class="block mt-1 p-2 bg-gray-100 dark:bg-gray-800 rounded text-xs break-all">{{ $secret }}</code>
                    </div>
                    <div>
                        <p class="text-xs font-semibold text-gray-500 uppercase">Codes de récupération</p>
                        <p class="text-xs text-gray-600 dark:text-gray-400 mb-1">Conservez-les hors-ligne. Chaque code n'est utilisable qu'une seule fois.</p>
                        <div class="grid grid-cols-2 gap-1">
                            @foreach ($recoveryCodes as $rc)
                                <code class="p-1 bg-gray-100 dark:bg-gray-800 rounded text-xs">{{ $rc }}</code>
                            @endforeach
                        </div>
                    </div>
                </div>
            </div>

            <x-filament-panels::form wire:submit="confirm">
                {{ $this->form }}
                <x-filament-panels::form.actions :actions="$this->getCachedFormActions()" />
            </x-filament-panels::form>
        @endif
    </div>
</x-filament-panels::page>
