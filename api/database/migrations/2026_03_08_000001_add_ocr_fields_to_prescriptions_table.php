<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Ajoute les champs pour l'analyse OCR des ordonnances
     */
    public function up(): void
    {
        Schema::table('prescriptions', function (Blueprint $table) {
            // Données extraites par OCR
            $table->json('extracted_medications')->nullable()->after('images')
                ->comment('Liste des médicaments extraits par OCR');
            
            // Résultats du matching
            $table->json('matched_products')->nullable()->after('extracted_medications')
                ->comment('Produits correspondants trouvés en stock');
            
            // Médicaments non trouvés
            $table->json('unmatched_medications')->nullable()->after('matched_products')
                ->comment('Médicaments non trouvés en stock');
            
            // Score de confiance OCR
            $table->decimal('ocr_confidence', 5, 2)->nullable()->after('unmatched_medications')
                ->comment('Score de confiance de l\'analyse OCR (0-100)');
            
            // Timestamp de l'analyse
            $table->timestamp('analyzed_at')->nullable()->after('ocr_confidence')
                ->comment('Date/heure de l\'analyse OCR');
            
            // Statut de l'analyse
            $table->string('analysis_status', 50)->default('pending')->after('analyzed_at')
                ->comment('pending, analyzing, completed, failed, manual_review');
            
            // Message d'erreur si échec
            $table->text('analysis_error')->nullable()->after('analysis_status')
                ->comment('Message d\'erreur si l\'analyse a échoué');
            
            // Texte brut extrait
            $table->text('ocr_raw_text')->nullable()->after('analysis_error')
                ->comment('Texte brut extrait de l\'ordonnance');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('prescriptions', function (Blueprint $table) {
            $table->dropColumn([
                'extracted_medications',
                'matched_products',
                'unmatched_medications',
                'ocr_confidence',
                'analyzed_at',
                'analysis_status',
                'analysis_error',
                'ocr_raw_text',
            ]);
        });
    }
};
