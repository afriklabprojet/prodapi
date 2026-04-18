<?php

namespace App\Filament\Resources\OrderResource\RelationManagers;

use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class ItemsRelationManager extends RelationManager
{
    protected static string $relationship = 'items';

    protected static ?string $title = 'Articles';

    protected static ?string $recordTitleAttribute = 'product_name';

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('product_name')
                    ->label('Produit')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::make('product_sku')
                    ->label('SKU')
                    ->maxLength(255),
                Forms\Components\TextInput::make('quantity')
                    ->label('Quantité')
                    ->numeric()
                    ->required()
                    ->minValue(1),
                Forms\Components\TextInput::make('unit_price')
                    ->label('Prix unitaire (FCFA)')
                    ->numeric()
                    ->required(),
                Forms\Components\TextInput::make('total_price')
                    ->label('Prix total (FCFA)')
                    ->numeric()
                    ->required(),
                Forms\Components\Textarea::make('notes')
                    ->label('Notes')
                    ->rows(2)
                    ->columnSpanFull(),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('product_name')
                    ->label('Produit')
                    ->searchable(),
                Tables\Columns\TextColumn::make('product_sku')
                    ->label('SKU'),
                Tables\Columns\TextColumn::make('quantity')
                    ->label('Qté')
                    ->alignCenter(),
                Tables\Columns\TextColumn::make('unit_price')
                    ->label('Prix unitaire')
                    ->money('XOF'),
                Tables\Columns\TextColumn::make('total_price')
                    ->label('Total')
                    ->money('XOF'),
            ])
            ->filters([])
            ->headerActions([
                Tables\Actions\CreateAction::make(),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }
}
