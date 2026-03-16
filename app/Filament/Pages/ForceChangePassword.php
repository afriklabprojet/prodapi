<?php

namespace App\Filament\Pages;

use Filament\Actions\Action;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

/**
 * Force password change page for admin users on their first login.
 *
 * This page is displayed when a user has `must_change_password = true`.
 * They cannot navigate away until they set a new password.
 */
class ForceChangePassword extends Page implements Forms\Contracts\HasForms
{
    use Forms\Concerns\InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-key';
    protected static string $view = 'filament.pages.force-change-password';
    protected static ?string $title = 'Changement de mot de passe obligatoire';
    protected static ?string $slug = 'force-change-password';

    // Hide from navigation — only accessed via redirect
    protected static bool $shouldRegisterNavigation = false;

    public ?string $new_password = '';
    public ?string $new_password_confirmation = '';

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Nouveau mot de passe')
                    ->description('Pour des raisons de sécurité, vous devez changer votre mot de passe par défaut avant de continuer.')
                    ->icon('heroicon-o-shield-check')
                    ->schema([
                        Forms\Components\TextInput::make('new_password')
                            ->label('Nouveau mot de passe')
                            ->password()
                            ->revealable()
                            ->required()
                            ->minLength(8)
                            ->rule(Password::defaults())
                            ->helperText('Minimum 8 caractères. Utilisez des lettres, chiffres et symboles.'),

                        Forms\Components\TextInput::make('new_password_confirmation')
                            ->label('Confirmer le mot de passe')
                            ->password()
                            ->revealable()
                            ->required()
                            ->same('new_password'),
                    ]),
            ]);
    }

    public function save(): void
    {
        $data = $this->form->getState();

        $user = Auth::user();

        // Ensure the new password is different from the current one
        if (Hash::check($data['new_password'], $user->password)) {
            Notification::make()
                ->title('Erreur')
                ->body('Le nouveau mot de passe doit être différent de l\'ancien.')
                ->danger()
                ->send();
            return;
        }

        $user->forceFill([
            'password' => Hash::make($data['new_password']),
            'must_change_password' => false,
        ])->save();

        Notification::make()
            ->title('Mot de passe modifié')
            ->body('Votre mot de passe a été changé avec succès. Bienvenue !')
            ->success()
            ->send();

        $this->redirect('/admin');
    }

    protected function getFormActions(): array
    {
        return [
            Action::make('save')
                ->label('Changer le mot de passe')
                ->submit('save')
                ->icon('heroicon-o-check-circle'),
        ];
    }
}
