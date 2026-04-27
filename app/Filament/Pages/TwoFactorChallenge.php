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
 * Challenge 2FA après login. Vérifie un code TOTP ou un code de récupération.
 */
class TwoFactorChallenge extends Page implements Forms\Contracts\HasForms
{
    use Forms\Concerns\InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-lock-closed';
    protected static string $view = 'filament.pages.two-factor-challenge';
    protected static ?string $title = 'Vérification en deux étapes';
    protected static ?string $slug = 'two-factor/challenge';
    protected static bool $shouldRegisterNavigation = false;

    public ?string $code = '';

    public function mount(): void
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();
        if (! $user->hasTwoFactorEnabled()) {
            $this->redirect('/admin/two-factor/setup');
            return;
        }
        if (request()->session()->get('two_factor_passed')) {
            $this->redirect('/admin');
        }
    }

    public function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('code')
                ->label('Code 2FA ou code de récupération')
                ->placeholder('123456 ou abcde-fghij')
                ->required()
                ->autocomplete('one-time-code')
                ->extraInputAttributes(['inputmode' => 'text']),
        ]);
    }

    public function submitChallenge(TwoFactorService $service): void
    {
        $data = $this->form->getState();
        /** @var \App\Models\User $user */
        $user = Auth::user();

        if (! $service->verify($user, $data['code'])) {
            Notification::make()
                ->title('Code incorrect')
                ->body('Le code fourni est invalide ou expiré.')
                ->danger()
                ->send();
            return;
        }

        request()->session()->put('two_factor_passed', true);
        $this->redirect('/admin');
    }

    protected function getFormActions(): array
    {
        return [
            Action::make('submit')
                ->label('Valider')
                ->submit('submitChallenge')
                ->icon('heroicon-o-check-circle'),
        ];
    }
}
