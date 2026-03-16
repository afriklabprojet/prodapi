<?php

namespace App\Filament\Pages;

use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FcmNotification;

class BroadcastNotification extends Page implements HasForms
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-megaphone';

    protected static ?string $navigationLabel = 'Notifications Push';

    protected static ?string $title = 'Envoyer une notification push';

    protected static ?string $navigationGroup = 'Support';

    protected static ?int $navigationSort = 5;

    protected static string $view = 'filament.pages.broadcast-notification';

    public ?string $target = 'all';
    public ?string $notification_title = '';
    public ?string $body = '';
    public ?array $data = [];

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Ciblage')
                    ->schema([
                        Forms\Components\Select::make('target')
                            ->label('Destinataires')
                            ->options([
                                'all' => '📢 Tous les utilisateurs',
                                'customer' => '👤 Clients uniquement',
                                'pharmacy' => '💊 Pharmacies uniquement',
                                'courier' => '🚴 Coursiers uniquement',
                            ])
                            ->required()
                            ->default('all')
                            ->native(false)
                            ->helperText('Sélectionnez le groupe cible'),
                    ]),

                Forms\Components\Section::make('Contenu de la notification')
                    ->schema([
                        Forms\Components\TextInput::make('notification_title')
                            ->label('Titre')
                            ->required()
                            ->maxLength(100)
                            ->placeholder('Ex: 🎉 Promotion spéciale !'),
                        Forms\Components\Textarea::make('body')
                            ->label('Message')
                            ->required()
                            ->rows(3)
                            ->maxLength(500)
                            ->placeholder('Le contenu de la notification...'),
                        Forms\Components\KeyValue::make('data')
                            ->label('Données supplémentaires (optionnel)')
                            ->keyLabel('Clé')
                            ->valueLabel('Valeur')
                            ->helperText('Données JSON envoyées avec la notification (ex: screen, promo_id)'),
                    ]),
            ]);
    }

    public function send(): void
    {
        $this->validate([
            'notification_title' => 'required|string|max:100',
            'body' => 'required|string|max:500',
            'target' => 'required|in:all,customer,pharmacy,courier',
        ]);

        try {
            $query = User::whereNotNull('fcm_token')->where('fcm_token', '!=', '');

            if ($this->target !== 'all') {
                $query->where('role', $this->target);
            }

            $tokens = $query->pluck('fcm_token')->toArray();

            if (empty($tokens)) {
                Notification::make()
                    ->title('Aucun destinataire')
                    ->body('Aucun utilisateur avec un token FCM trouvé pour ce groupe.')
                    ->warning()
                    ->send();
                return;
            }

            /** @var Messaging $messaging */
            $messaging = app(Messaging::class);

            $notification = FcmNotification::create(
                $this->notification_title,
                $this->body
            );

            $dataPayload = array_merge($this->data ?? [], [
                'type' => 'broadcast',
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ]);

            // Envoyer par lots de 500 (limite FCM)
            $chunks = array_chunk($tokens, 500);
            $successCount = 0;
            $failureCount = 0;

            foreach ($chunks as $chunk) {
                $message = CloudMessage::new()
                    ->withNotification($notification)
                    ->withData($dataPayload);

                $report = $messaging->sendMulticast($message, $chunk);
                $successCount += $report->successes()->count();
                $failureCount += $report->failures()->count();
            }

            // Sauvegarder en base aussi (notifications table)
            $users = User::whereNotNull('fcm_token')->where('fcm_token', '!=', '');
            if ($this->target !== 'all') {
                $users->where('role', $this->target);
            }
            foreach ($users->cursor() as $user) {
                $user->notifications()->create([
                    'id' => \Illuminate\Support\Str::uuid(),
                    'type' => 'App\\Notifications\\BroadcastPushNotification',
                    'data' => [
                        'type' => 'broadcast',
                        'title' => $this->notification_title,
                        'body' => $this->body,
                        'data' => $this->data,
                    ],
                ]);
            }

            Log::info('Broadcast notification sent', [
                'target' => $this->target,
                'success' => $successCount,
                'failures' => $failureCount,
                'title' => $this->notification_title,
            ]);

            Notification::make()
                ->title('Notification envoyée !')
                ->body("✅ {$successCount} envoyées, ❌ {$failureCount} échouées sur " . count($tokens) . " destinataires.")
                ->success()
                ->send();

            // Reset form
            $this->notification_title = '';
            $this->body = '';
            $this->data = [];

        } catch (\Exception $e) {
            Log::error('Broadcast notification failed', [
                'error' => $e->getMessage(),
                'target' => $this->target,
            ]);

            Notification::make()
                ->title('Erreur')
                ->body('Échec de l\'envoi : ' . $e->getMessage())
                ->danger()
                ->send();
        }
    }

    protected function getFormStatePath(): ?string
    {
        return null;
    }
}
