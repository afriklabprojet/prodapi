<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Response;

/**
 * Endpoints d'export CSV/PDF pour l'admin.
 */
class ExportController extends Controller
{
    /**
     * Export des commandes en CSV.
     *
     * GET /api/admin/export/orders?from=2024-01-01&to=2024-12-31&status=delivered
     */
    public function orders(Request $request): \Symfony\Component\HttpFoundation\StreamedResponse|JsonResponse
    {
        $request->validate([
            'from' => 'nullable|date',
            'to' => 'nullable|date|after_or_equal:from',
            'status' => 'nullable|string',
            'format' => 'nullable|in:csv',
        ]);

        $query = DB::table('orders')
            ->leftJoin('users', 'orders.customer_id', '=', 'users.id')
            ->leftJoin('pharmacies', 'orders.pharmacy_id', '=', 'pharmacies.id')
            ->select([
                'orders.id',
                'orders.reference',
                'users.name as customer_name',
                'users.phone as customer_phone',
                'pharmacies.name as pharmacy_name',
                'orders.status',
                'orders.total_amount',
                'orders.delivery_fee',
                'orders.payment_status',
                'orders.payment_mode',
                'orders.created_at',
                'orders.updated_at',
            ]);

        if ($request->filled('from')) {
            $query->where('orders.created_at', '>=', $request->input('from'));
        }
        if ($request->filled('to')) {
            $query->where('orders.created_at', '<=', $request->input('to') . ' 23:59:59');
        }
        if ($request->filled('status')) {
            $query->where('orders.status', $request->input('status'));
        }

        $orders = $query->orderByDesc('orders.created_at')->limit(10000)->get();

        return $this->streamCsv($orders, 'orders_export.csv', [
            'ID', 'Référence', 'Client', 'Téléphone', 'Pharmacie', 'Statut',
            'Montant', 'Frais livraison', 'Paiement', 'Méthode', 'Créé le', 'Modifié le',
        ]);
    }

    /**
     * Export des livraisons en CSV.
     */
    public function deliveries(Request $request): \Symfony\Component\HttpFoundation\StreamedResponse|JsonResponse
    {
        $request->validate([
            'from' => 'nullable|date',
            'to' => 'nullable|date|after_or_equal:from',
            'status' => 'nullable|string',
        ]);

        $query = DB::table('deliveries')
            ->leftJoin('couriers', 'deliveries.courier_id', '=', 'couriers.id')
            ->leftJoin('users', 'couriers.user_id', '=', 'users.id')
            ->leftJoin('orders', 'deliveries.order_id', '=', 'orders.id')
            ->select([
                'deliveries.id',
                'orders.reference as order_reference',
                'users.name as courier_name',
                'users.phone as courier_phone',
                'deliveries.status',
                'deliveries.estimated_distance',
                'deliveries.delivery_fee',
                'deliveries.accepted_at',
                'deliveries.picked_up_at',
                'deliveries.delivered_at',
                'deliveries.created_at',
            ]);

        if ($request->filled('from')) {
            $query->where('deliveries.created_at', '>=', $request->input('from'));
        }
        if ($request->filled('to')) {
            $query->where('deliveries.created_at', '<=', $request->input('to') . ' 23:59:59');
        }
        if ($request->filled('status')) {
            $query->where('deliveries.status', $request->input('status'));
        }

        $deliveries = $query->orderByDesc('deliveries.created_at')->limit(10000)->get();

        return $this->streamCsv($deliveries, 'deliveries_export.csv', [
            'ID', 'Commande', 'Livreur', 'Téléphone', 'Statut', 'Distance (km)',
            'Frais', 'Accepté', 'Récupéré', 'Livré', 'Créé le',
        ]);
    }

    /**
     * Export des revenus en CSV.
     */
    public function revenue(Request $request): \Symfony\Component\HttpFoundation\StreamedResponse|JsonResponse
    {
        $request->validate([
            'from' => 'nullable|date',
            'to' => 'nullable|date|after_or_equal:from',
            'group_by' => 'nullable|in:day,week,month',
        ]);

        $groupBy = $request->input('group_by', 'day');
        $driver = DB::getDriverName();

        if ($driver === 'sqlite') {
            $dateExpr = match ($groupBy) {
                'day' => "strftime('%Y-%m-%d', created_at)",
                'week' => "strftime('%Y-W%W', created_at)",
                'month' => "strftime('%Y-%m', created_at)",
            };
        } else {
            $dateFormat = match ($groupBy) {
                'day' => '%Y-%m-%d',
                'week' => '%Y-W%V',
                'month' => '%Y-%m',
            };
            $dateExpr = "DATE_FORMAT(created_at, '{$dateFormat}')";
        }

        $query = DB::table('orders')
            ->selectRaw("{$dateExpr} as period")
            ->selectRaw('COUNT(*) as total_orders')
            ->selectRaw("SUM(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END) as delivered_orders")
            ->selectRaw("SUM(CASE WHEN status = 'delivered' THEN total_amount ELSE 0 END) as revenue")
            ->selectRaw("SUM(CASE WHEN status = 'delivered' THEN delivery_fee ELSE 0 END) as delivery_fees")
            ->selectRaw("SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_orders")
            ->groupByRaw($dateExpr);

        if ($request->filled('from')) {
            $query->where('created_at', '>=', $request->input('from'));
        }
        if ($request->filled('to')) {
            $query->where('created_at', '<=', $request->input('to') . ' 23:59:59');
        }

        $data = $query->orderBy('period')->get();

        return $this->streamCsv($data, "revenue_{$groupBy}_export.csv", [
            'Période', 'Total commandes', 'Livrées', 'Revenu (FCFA)', 'Frais livraison', 'Annulées',
        ]);
    }

    /**
     * Export des pharmacies en CSV.
     */
    public function pharmacies(Request $request): \Symfony\Component\HttpFoundation\StreamedResponse|JsonResponse
    {
        $data = DB::table('pharmacies')
            ->leftJoin('pharmacy_user', 'pharmacies.id', '=', 'pharmacy_user.pharmacy_id')
            ->leftJoin('users', 'pharmacy_user.user_id', '=', 'users.id')
            ->select([
                'pharmacies.id',
                'pharmacies.name',
                'users.name as owner_name',
                'users.phone as phone',
                'users.email as email',
                'pharmacies.status',
                'pharmacies.is_active',
                'pharmacies.is_open',
                'pharmacies.latitude',
                'pharmacies.longitude',
                'pharmacies.created_at',
            ])
            ->orderBy('pharmacies.name')
            ->get();

        return $this->streamCsv($data, 'pharmacies_export.csv', [
            'ID', 'Nom', 'Propriétaire', 'Téléphone', 'Email', 'Statut',
            'Active', 'Ouverte', 'Latitude', 'Longitude', 'Inscrite le',
        ]);
    }

    /**
     * Export des livreurs en CSV.
     */
    public function couriers(Request $request): \Symfony\Component\HttpFoundation\StreamedResponse|JsonResponse
    {
        $data = DB::table('couriers')
            ->leftJoin('users', 'couriers.user_id', '=', 'users.id')
            ->select([
                'couriers.id',
                'users.name',
                'users.phone',
                'users.email',
                'couriers.status',
                'couriers.vehicle_type',
                'couriers.completed_deliveries',
                'couriers.rating',
                'couriers.created_at',
            ])
            ->orderBy('users.name')
            ->get();

        return $this->streamCsv($data, 'couriers_export.csv', [
            'ID', 'Nom', 'Téléphone', 'Email', 'Statut', 'Véhicule',
            'Total livraisons', 'Note', 'Inscrit le',
        ]);
    }

    /**
     * Stream un CSV depuis une collection de données.
     */
    private function streamCsv($data, string $filename, array $headers): \Symfony\Component\HttpFoundation\StreamedResponse
    {
        return Response::streamDownload(function () use ($data, $headers) {
            $handle = fopen('php://output', 'w');

            // BOM UTF-8 pour Excel
            fwrite($handle, "\xEF\xBB\xBF");
            fputcsv($handle, $headers, ';');

            foreach ($data as $row) {
                fputcsv($handle, (array) $row, ';');
            }

            fclose($handle);
        }, $filename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ]);
    }
}
