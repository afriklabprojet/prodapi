<?php

namespace App\Exceptions;

use InvalidArgumentException;

class InvalidAmountException extends InvalidArgumentException
{
    public function __construct(string $message = 'Montant invalide', int $code = 0, ?\Throwable $previous = null)
    {
        parent::__construct($message, $code, $previous);
    }
}
