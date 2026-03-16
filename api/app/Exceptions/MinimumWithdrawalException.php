<?php

namespace App\Exceptions;

use RuntimeException;

class MinimumWithdrawalException extends RuntimeException
{
    protected float $minimumAmount;

    public function __construct(float $minimumAmount, int $code = 0, ?\Throwable $previous = null)
    {
        $this->minimumAmount = $minimumAmount;
        parent::__construct("Le montant minimum de retrait est de {$minimumAmount} FCFA", $code, $previous);
    }

    public function getMinimumAmount(): float
    {
        return $this->minimumAmount;
    }
}
