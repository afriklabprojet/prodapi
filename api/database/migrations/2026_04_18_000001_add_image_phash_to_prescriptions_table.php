<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('prescriptions', function (Blueprint $table) {
            // dHash 64-bit stocké en hex (16 caractères) pour détecter les re-photos
            // d'une même ordonnance (angle/lumière différents)
            $table->string('image_phash', 16)->nullable()->after('image_hash')
                ->comment('Perceptual hash dHash 64-bit hex pour détection doublons par similarité');
            $table->index('image_phash');
        });
    }

    public function down(): void
    {
        Schema::table('prescriptions', function (Blueprint $table) {
            $table->dropIndex(['image_phash']);
            $table->dropColumn('image_phash');
        });
    }
};
