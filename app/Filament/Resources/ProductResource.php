<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ProductResource\Pages;
use App\Models\Product;
use App\Models\Category;
use App\Models\Pharmacy;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Str;

class ProductResource extends Resource
{
    protected static ?string $model = Product::class;

    protected static ?string $navigationIcon = 'heroicon-o-cube';

    protected static ?string $navigationLabel = 'Produits';

    protected static ?string $modelLabel = 'Produit';

    protected static ?string $pluralModelLabel = 'Produits';

    protected static ?string $navigationGroup = 'Catalogue';

    protected static ?int $navigationSort = 2;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Group::make()
                    ->schema([
                        Forms\Components\Section::make('Informations générales')
                            ->schema([
                                Forms\Components\TextInput::make('name')
                                    ->label('Nom du produit')
                                    ->required()
                                    ->maxLength(255)
                                    ->live(onBlur: true)
                                    ->afterStateUpdated(function ($state, Forms\Set $set, $record) {
                                        if (!$record) {
                                            $set('slug', Str::slug($state));
                                        }
                                    }),
                                Forms\Components\TextInput::make('slug')
                                    ->label('Slug')
                                    ->required()
                                    ->maxLength(255)
                                    ->unique(ignoreRecord: true),
                                Forms\Components\Select::make('pharmacy_id')
                                    ->label('Pharmacie')
                                    ->relationship('pharmacy', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->required(),
                                Forms\Components\Select::make('category_id')
                                    ->label('Catégorie')
                                    ->relationship('category', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->createOptionForm([
                                        Forms\Components\TextInput::make('name')
                                            ->label('Nom')
                                            ->required(),
                                        Forms\Components\TextInput::make('slug')
                                            ->label('Slug')
                                            ->required(),
                                    ]),
                                Forms\Components\Textarea::make('description')
                                    ->label('Description')
                                    ->rows(4)
                                    ->columnSpanFull(),
                            ])->columns(2),

                        Forms\Components\Section::make('Prix et stock')
                            ->schema([
                                Forms\Components\TextInput::make('price')
                                    ->label('Prix (FCFA)')
                                    ->required()
                                    ->numeric()
                                    ->prefix('FCFA')
                                    ->minValue(0),
                                Forms\Components\TextInput::make('discount_price')
                                    ->label('Prix promotionnel')
                                    ->numeric()
                                    ->prefix('FCFA')
                                    ->minValue(0)
                                    ->lt('price'),
                                Forms\Components\TextInput::make('stock_quantity')
                                    ->label('Quantité en stock')
                                    ->numeric()
                                    ->default(0)
                                    ->minValue(0),
                                Forms\Components\TextInput::make('low_stock_threshold')
                                    ->label('Seuil stock bas')
                                    ->numeric()
                                    ->default(10)
                                    ->minValue(0),
                                Forms\Components\TextInput::make('sku')
                                    ->label('SKU')
                                    ->maxLength(100),
                                Forms\Components\TextInput::make('barcode')
                                    ->label('Code-barres')
                                    ->maxLength(100),
                            ])->columns(3),

                        Forms\Components\Section::make('Détails produit')
                            ->schema([
                                Forms\Components\TextInput::make('brand')
                                    ->label('Marque')
                                    ->maxLength(255),
                                Forms\Components\TextInput::make('manufacturer')
                                    ->label('Fabricant')
                                    ->maxLength(255),
                                Forms\Components\TextInput::make('active_ingredient')
                                    ->label('Principe actif')
                                    ->maxLength(255),
                                Forms\Components\TextInput::make('unit')
                                    ->label('Unité')
                                    ->placeholder('comprimé, ml, mg')
                                    ->maxLength(50),
                                Forms\Components\TextInput::make('units_per_pack')
                                    ->label('Unités par boîte')
                                    ->numeric()
                                    ->minValue(1),
                                Forms\Components\DatePicker::make('expiry_date')
                                    ->label('Date d\'expiration'),
                                Forms\Components\Textarea::make('usage_instructions')
                                    ->label('Mode d\'emploi')
                                    ->rows(3)
                                    ->columnSpanFull(),
                                Forms\Components\Textarea::make('side_effects')
                                    ->label('Effets secondaires')
                                    ->rows(3)
                                    ->columnSpanFull(),
                            ])->columns(3),
                    ])->columnSpan(['lg' => 2]),

                Forms\Components\Group::make()
                    ->schema([
                        Forms\Components\Section::make('Images')
                            ->schema([
                                Forms\Components\FileUpload::make('image')
                                    ->label('Image principale')
                                    ->image()
                                    ->directory('products'),
                                Forms\Components\FileUpload::make('images')
                                    ->label('Galerie')
                                    ->image()
                                    ->multiple()
                                    ->directory('products/gallery')
                                    ->maxFiles(5),
                            ]),

                        Forms\Components\Section::make('Options')
                            ->schema([
                                Forms\Components\Toggle::make('is_available')
                                    ->label('Disponible')
                                    ->default(true),
                                Forms\Components\Toggle::make('is_featured')
                                    ->label('Mis en avant')
                                    ->default(false),
                                Forms\Components\Toggle::make('requires_prescription')
                                    ->label('Ordonnance requise')
                                    ->default(false),
                                Forms\Components\Select::make('delivery_option')
                                    ->label('Option de livraison')
                                    ->options([
                                        'all' => 'Toutes options',
                                        'delivery_only' => 'Livraison uniquement',
                                        'pickup_only' => 'Retrait uniquement',
                                    ])
                                    ->default('all'),
                            ]),

                        Forms\Components\Section::make('Tags')
                            ->schema([
                                Forms\Components\TagsInput::make('tags')
                                    ->label('Tags')
                                    ->placeholder('Ajouter un tag'),
                            ]),
                    ])->columnSpan(['lg' => 1]),
            ])->columns(3);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ImageColumn::make('image')
                    ->label('Image')
                    ->circular(),
                Tables\Columns\TextColumn::make('name')
                    ->label('Nom')
                    ->searchable()
                    ->sortable()
                    ->description(fn (Product $record): string => $record->sku ?? ''),
                Tables\Columns\TextColumn::make('pharmacy.name')
                    ->label('Pharmacie')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('category.name')
                    ->label('Catégorie')
                    ->sortable()
                    ->badge()
                    ->color('primary'),
                Tables\Columns\TextColumn::make('price')
                    ->label('Prix')
                    ->money('XOF')
                    ->sortable(),
                Tables\Columns\TextColumn::make('discount_price')
                    ->label('Prix promo')
                    ->money('XOF')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('stock_quantity')
                    ->label('Stock')
                    ->sortable()
                    ->color(fn (Product $record): string => match(true) {
                        $record->stock_quantity <= 0 => 'danger',
                        $record->stock_quantity <= $record->low_stock_threshold => 'warning',
                        default => 'success',
                    }),
                Tables\Columns\IconColumn::make('requires_prescription')
                    ->label('Ordonnance')
                    ->boolean()
                    ->trueIcon('heroicon-o-document-check')
                    ->falseIcon('heroicon-o-x-circle')
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\IconColumn::make('is_available')
                    ->label('Disponible')
                    ->boolean()
                    ->sortable(),
                Tables\Columns\IconColumn::make('is_featured')
                    ->label('Vedette')
                    ->boolean()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Créé le')
                    ->dateTime('d/m/Y')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('pharmacy_id')
                    ->label('Pharmacie')
                    ->relationship('pharmacy', 'name')
                    ->searchable()
                    ->preload(),
                Tables\Filters\SelectFilter::make('category_id')
                    ->label('Catégorie')
                    ->relationship('category', 'name')
                    ->searchable()
                    ->preload(),
                Tables\Filters\TernaryFilter::make('is_available')
                    ->label('Disponibilité'),
                Tables\Filters\TernaryFilter::make('requires_prescription')
                    ->label('Ordonnance requise'),
                Tables\Filters\TernaryFilter::make('is_featured')
                    ->label('Mis en avant'),
                Tables\Filters\Filter::make('low_stock')
                    ->label('Stock bas')
                    ->query(fn (Builder $query): Builder => $query->whereColumn('stock_quantity', '<=', 'low_stock_threshold')->where('stock_quantity', '>', 0)),
                Tables\Filters\Filter::make('out_of_stock')
                    ->label('Rupture de stock')
                    ->query(fn (Builder $query): Builder => $query->where('stock_quantity', '<=', 0)),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListProducts::route('/'),
            'create' => Pages\CreateProduct::route('/create'),
            'edit' => Pages\EditProduct::route('/{record}/edit'),
        ];
    }

    public static function getGloballySearchableAttributes(): array
    {
        return ['name', 'sku', 'barcode', 'brand', 'manufacturer'];
    }
}
