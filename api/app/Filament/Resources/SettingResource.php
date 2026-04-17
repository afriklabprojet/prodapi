<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SettingResource\Pages;
use App\Models\Setting;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class SettingResource extends Resource
{
    protected static ?string $model = Setting::class;

    protected static ?string $navigationIcon = 'heroicon-o-cog-6-tooth';

    protected static ?string $navigationLabel = 'Paramètres';

    protected static ?string $modelLabel = 'Paramètre';

    protected static ?string $pluralModelLabel = 'Paramètres';

    protected static ?string $navigationGroup = 'Configuration';

    protected static ?int $navigationSort = 100;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Paramètre')
                    ->schema([
                        Forms\Components\TextInput::make('key')
                            ->label('Clé')
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->maxLength(255)
                            ->helperText('Identifiant unique du paramètre (ex: app.name, fees.delivery)'),
                        Forms\Components\Select::make('type')
                            ->label('Type')
                            ->options([
                                'string' => 'Texte',
                                'integer' => 'Nombre entier',
                                'float' => 'Nombre décimal',
                                'boolean' => 'Booléen',
                                'json' => 'JSON',
                            ])
                            ->default('string')
                            ->required()
                            ->live(),
                        Forms\Components\TextInput::make('value')
                            ->label('Valeur')
                            ->required()
                            ->visible(fn ($get) => in_array($get('type'), ['string', 'integer', 'float', null])),
                        Forms\Components\Toggle::make('value')
                            ->label('Valeur')
                            ->visible(fn ($get) => $get('type') === 'boolean'),
                        Forms\Components\Textarea::make('value')
                            ->label('Valeur JSON')
                            ->rows(5)
                            ->visible(fn ($get) => $get('type') === 'json')
                            ->helperText('Entrez un JSON valide'),
                        Forms\Components\Textarea::make('description')
                            ->label('Description')
                            ->rows(2)
                            ->columnSpanFull(),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('key')
                    ->label('Clé')
                    ->searchable()
                    ->sortable()
                    ->copyable(),
                Tables\Columns\TextColumn::make('value')
                    ->label('Valeur')
                    ->limit(50)
                    ->searchable(),
                Tables\Columns\TextColumn::make('type')
                    ->label('Type')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'string' => 'info',
                        'integer', 'float' => 'warning',
                        'boolean' => 'success',
                        'json' => 'primary',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('description')
                    ->label('Description')
                    ->limit(30)
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->label('Modifié le')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('type')
                    ->label('Type')
                    ->options([
                        'string' => 'Texte',
                        'integer' => 'Nombre entier',
                        'float' => 'Nombre décimal',
                        'boolean' => 'Booléen',
                        'json' => 'JSON',
                    ]),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->defaultSort('key');
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSettings::route('/'),
            'create' => Pages\CreateSetting::route('/create'),
            'edit' => Pages\EditSetting::route('/{record}/edit'),
        ];
    }
}
