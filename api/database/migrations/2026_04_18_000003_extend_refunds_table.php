<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Étend la table `refunds` pour le pack remboursement MVP :
 * - méthode de remboursement (wallet par défaut, payout sortant, manuel…)
 * - lien vers la transaction wallet créée
 * - traçabilité décision admin
 * - notification envoyée
 * - source de la demande (client, auto rejet pharmacien…)
 */
return new class extends Migration {
    public function up(): void
    {
        if (!Schema::hasTable('refunds')) {
            return;
        }

        Schema::table('refunds', function (Blueprint $table) {
            if (!Schema::hasColumn('refunds', 'method')) {
                $table->string('method', 32)->default('wallet')->after('type');
            }
            if (!Schema::hasColumn('refunds', 'source')) {
                $table->string('source', 32)->default('customer_request')->after('method');
            }
            if (!Schema::hasColumn('refunds', 'wallet_transaction_id')) {
                $table->unsignedBigInteger('wallet_transaction_id')->nullable()->after('processed_at');
            }
            if (!Schema::hasColumn('refunds', 'payout_reference')) {
                $table->string('payout_reference', 64)->nullable()->after('wallet_transaction_id');
            }
            if (!Schema::hasColumn('refunds', 'decided_by')) {
                $table->unsignedBigInteger('decided_by')->nullable()->after('payout_reference');
            }
            if (!Schema::hasColumn('refunds', 'decided_at')) {
                $table->timestamp('decided_at')->nullable()->after('decided_by');
            }
            if (!Schema::hasColumn('refunds', 'notified_at')) {
                $table->timestamp('notified_at')->nullable()->after('decided_at');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('refunds')) {
            return;
        }

        Schema::table('refunds', function (Blueprint $table) {
            foreach (['method', 'source', 'wallet_transaction_id', 'payout_reference', 'decided_by', 'decided_at', 'notified_at'] as $col) {
                if (Schema::hasColumn('refunds', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};
