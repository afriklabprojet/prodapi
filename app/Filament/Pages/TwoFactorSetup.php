<?php

namespace App\Filament\Pages;

use App\Services\TwoFactorService;
use Filament\Actions\Action;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Auth;

/**
 * Page d'enrôlement 2FA TOTP.
 *
 * Affiche le QR code à scanner + champ de confirmation. Tant que l'utilisateur
 * n'a pas activé sa 2FA, le middleware EnsureTwoFactorChallenge le redirige ici.
 */
class TwoFactorSetup extends Page implements Forms\Contracts\HasForms
{
    use Forms\Concerns\InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-shield-check';
    protected static string $view = 'filament.pages.two-factor-setup';
    protected static ?string $title = 'Activer la double authentification';
    protected static ?string $slug = 'two-factor/setup';
    protected static bool $shouldRegisterNavigation = false;

    public ?string $code = '';
    public ?string $qrSvg = null;
    public ?string $secret = null;
    /** @var array<int, string> */
    public array $recoveryCodes = [];
    public bool $confirmed = false;

    public function mount(TwoFactorService $service): void
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();
        if ($user->hasTwoFactorEnabled()) {
            $this->confirmed = true;
            return;
        }
        $payload = $service->enroll($user);
        $this->qrSvg = $payload['qr_svg'];
        $this->secret = $payload['secret'];
        $this->recoveryCodes = $payload['recovery_codes'];
    }

    public function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('code')
                ->label('Code à 6 chiffres')
                ->placeholder('123 456')
                ->required()
                ->length(6)
                ->numeric()
                ->autocomplete('one-time-code')
                ->extraInputAttributes(['inputmode' => 'numeric']),
        ]);
    }

    public function confirm(TwoFactorService $service): void
    {
        $data = $this->form->getState();
        /** @var \App\Models\User $user */
        $user = Auth::user();

        if (! $service->confirm($user, $data['code'])) {
            Notification::make()
                ->title('Code invalide')
                ->body('Vérifiez l\'heure de votre téléphone et réessayez.')
                ->danger()
                ->send();
            return;
        }

        request()->session()->put('two_factor_passed', true);
        $this->confirmed = true;

        Notification::make()
            ->title('2FA activée')
            ->body('Conservez vos codes de récupération en lieu sûr.')
            ->success()
            ->send();
    }

    public function continueToDashboard(): void
    {
        $this->redirect('/admin');
    }

    protected function getFormActions(): array
    {
        return [
            Action::make('confirm')
                ->label('Activer la 2FA')
                ->submit('confirm')
                ->icon('heroicon-o-check-circle'),
        ];
    }
}
