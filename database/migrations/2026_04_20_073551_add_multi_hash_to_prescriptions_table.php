<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * 
     * Ajoute aHash (Average Hash) et sHash (Structure Hash) pour améliorer
     * la détection de doublons sur les ordonnances manuscrites au stylo BIC.
     * 
     * Combinaison de 3 hashes :
     * - dHash (existant) : gradient horizontal
     * - aHash : comparaison à la moyenne
     * - sHash : détection zones d'encre
     * 
     * Un doublon est détecté si AU MOINS 2 des 3 hashes correspondent.
     */
    public function up(): void
    {
        Schema::table('prescriptions', function (Blueprint $table) {
            $table->string('image_ahash', 16)->nullable()->after('image_phash')
                ->comment('Average Hash pour détection doublons manuscrits');
            $table->string('image_shash', 16)->nullable()->after('image_ahash')
                ->comment('Structure Hash (zones encre) pour ordonnances BIC');
            
            $table->index('image_ahash');
            $table->index('image_shash');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('prescriptions', function (Blueprint $table) {
            $table->dropIndex(['image_ahash']);
            $table->dropIndex(['image_shash']);
            $table->dropColumn(['image_ahash', 'image_shash']);
        });
    }
};
