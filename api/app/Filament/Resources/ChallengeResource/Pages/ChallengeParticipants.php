<?php

namespace App\Filament\Resources\ChallengeResource\Pages;

use App\Filament\Resources\ChallengeResource;
use App\Models\Challenge;
use Filament\Resources\Pages\Page;
use Filament\Tables;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;

class ChallengeParticipants extends Page implements HasTable
{
    use InteractsWithTable;
    
    protected static string $resource = ChallengeResource::class;

    protected static string $view = 'filament.resources.challenge-resource.pages.challenge-participants';
    
    public Challenge $record;
    
    public function mount(Challenge $record): void
    {
        $this->record = $record;
    }
    
    public function getTitle(): string
    {
        return "Participants: {$this->record->title}";
    }
    
    protected function getTableQuery()
    {
        return $this->record->couriers()->getQuery();
    }
    
    protected function getTableColumns(): array
    {
        return [
            Tables\Columns\TextColumn::make('id')
                ->label('#'),
                
            Tables\Columns\TextColumn::make('user.name')
                ->label('Nom')
                ->searchable(),
                
            Tables\Columns\TextColumn::make('user.phone')
                ->label('Téléphone'),
                
            Tables\Columns\TextColumn::make('pivot.current_progress')
                ->label('Progression')
                ->formatStateUsing(fn ($state) => "{$state}/{$this->record->target_value}")
                ->badge()
                ->color(fn ($state) => $state >= $this->record->target_value ? 'success' : 'warning'),
                
            Tables\Columns\TextColumn::make('pivot.status')
                ->label('Statut')
                ->badge()
                ->formatStateUsing(fn ($state) => match ($state) {
                    'active' => 'En cours',
                    'completed' => 'Complété',
                    'claimed' => 'Réclamé',
                    default => $state,
                })
                ->color(fn ($state) => match ($state) {
                    'active' => 'warning',
                    'completed' => 'success',
                    'claimed' => 'info',
                    default => 'gray',
                }),
                
            Tables\Columns\TextColumn::make('pivot.completed_at')
                ->label('Complété le')
                ->dateTime('d/m/Y H:i')
                ->placeholder('-'),
                
            Tables\Columns\TextColumn::make('pivot.rewarded_at')
                ->label('Récompensé le')
                ->dateTime('d/m/Y H:i')
                ->placeholder('-'),
        ];
    }
    
    protected function getHeaderActions(): array
    {
        return [
            \Filament\Actions\Action::make('back')
                ->label('Retour')
                ->url(ChallengeResource::getUrl('index'))
                ->color('gray'),
        ];
    }
}
