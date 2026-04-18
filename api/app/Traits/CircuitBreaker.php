<?php

namespace App\Traits;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

/**
 * Circuit Breaker Pattern pour services externes.
 * 
 * Protège l'application contre les cascading failures en cas de
 * défaillance d'un service externe (API météo, trafic, paiement, etc.)
 * 
 * Usage:
 *   use App\Traits\CircuitBreaker;
 *   
 *   class MyService {
 *       use CircuitBreaker;
 *       
 *       protected string $circuitName = 'my-service';
 *       
 *       public function callExternalApi() {
 *           return $this->executeWithCircuitBreaker(fn() => $this->doCall());
 *       }
 *   }
 */
trait CircuitBreaker
{
    /**
     * Nombre d'échecs avant ouverture du circuit.
     */
    protected int $failureThreshold = 5;
    
    /**
     * Durée en secondes avant de réessayer après ouverture.
     */
    protected int $recoveryTimeout = 60;
    
    /**
     * Durée de vie du compteur d'échecs en secondes.
     */
    protected int $failureCounterTtl = 300;

    /**
     * Exécute une opération avec protection circuit breaker.
     *
     * @param callable $operation L'opération à exécuter
     * @param mixed $fallback Valeur de fallback si circuit ouvert ou erreur
     * @return mixed Résultat de l'opération ou fallback
     */
    protected function executeWithCircuitBreaker(callable $operation, mixed $fallback = null): mixed
    {
        $circuitName = $this->getCircuitName();
        
        // Vérifier si le circuit est ouvert
        if ($this->isCircuitOpen($circuitName)) {
            Log::warning("Circuit breaker: Circuit '{$circuitName}' is OPEN, using fallback", [
                'circuit' => $circuitName,
                'fallback_type' => gettype($fallback),
            ]);
            return $fallback;
        }
        
        try {
            $result = $operation();
            
            // Succès: reset le compteur d'échecs
            $this->resetFailureCount($circuitName);
            
            return $result;
            
        } catch (\Throwable $e) {
            // Échec: incrémenter le compteur
            $failureCount = $this->incrementFailureCount($circuitName);
            
            Log::warning("Circuit breaker: Operation failed on '{$circuitName}'", [
                'circuit' => $circuitName,
                'failure_count' => $failureCount,
                'threshold' => $this->failureThreshold,
                'error' => $e->getMessage(),
            ]);
            
            // Ouvrir le circuit si seuil atteint
            if ($failureCount >= $this->failureThreshold) {
                $this->openCircuit($circuitName);
                Log::error("Circuit breaker: Circuit '{$circuitName}' is now OPEN", [
                    'circuit' => $circuitName,
                    'recovery_timeout' => $this->recoveryTimeout,
                ]);
            }
            
            return $fallback;
        }
    }
    
    /**
     * Retourne le nom du circuit pour ce service.
     */
    protected function getCircuitName(): string
    {
        return $this->circuitName ?? class_basename($this);
    }
    
    /**
     * Vérifie si le circuit est ouvert (bloqué).
     */
    protected function isCircuitOpen(string $circuitName): bool
    {
        return Cache::has("circuit:{$circuitName}:open");
    }
    
    /**
     * Ouvre le circuit (bloque les appels).
     */
    protected function openCircuit(string $circuitName): void
    {
        Cache::put(
            "circuit:{$circuitName}:open",
            true,
            now()->addSeconds($this->recoveryTimeout)
        );
    }
    
    /**
     * Ferme le circuit manuellement.
     */
    protected function closeCircuit(string $circuitName): void
    {
        Cache::forget("circuit:{$circuitName}:open");
        $this->resetFailureCount($circuitName);
    }
    
    /**
     * Incrémente le compteur d'échecs.
     */
    protected function incrementFailureCount(string $circuitName): int
    {
        $key = "circuit:{$circuitName}:failures";
        $count = (int) Cache::get($key, 0) + 1;
        Cache::put($key, $count, now()->addSeconds($this->failureCounterTtl));
        return $count;
    }
    
    /**
     * Reset le compteur d'échecs (après un succès).
     */
    protected function resetFailureCount(string $circuitName): void
    {
        Cache::forget("circuit:{$circuitName}:failures");
    }
    
    /**
     * Retourne l'état actuel du circuit.
     */
    public function getCircuitStatus(): array
    {
        $circuitName = $this->getCircuitName();
        $isOpen = $this->isCircuitOpen($circuitName);
        $failureCount = (int) Cache::get("circuit:{$circuitName}:failures", 0);
        
        return [
            'circuit' => $circuitName,
            'status' => $isOpen ? 'OPEN' : 'CLOSED',
            'failure_count' => $failureCount,
            'failure_threshold' => $this->failureThreshold,
            'recovery_timeout' => $this->recoveryTimeout,
        ];
    }
}
