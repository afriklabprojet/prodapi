<?php

namespace Tests\Unit\Exceptions;

use App\Exceptions\InsufficientBalanceException;
use App\Exceptions\InvalidAmountException;
use App\Exceptions\MinimumWithdrawalException;
use PHPUnit\Framework\TestCase;

class ExceptionsTest extends TestCase
{
    public function test_insufficient_balance_default_message(): void
    {
        $exception = new InsufficientBalanceException();
        $this->assertSame('Solde insuffisant', $exception->getMessage());
    }

    public function test_insufficient_balance_custom_message(): void
    {
        $exception = new InsufficientBalanceException('Not enough funds');
        $this->assertSame('Not enough funds', $exception->getMessage());
    }

    public function test_insufficient_balance_extends_runtime_exception(): void
    {
        $exception = new InsufficientBalanceException();
        $this->assertInstanceOf(\RuntimeException::class, $exception);
    }

    public function test_invalid_amount_default_message(): void
    {
        $exception = new InvalidAmountException();
        $this->assertSame('Montant invalide', $exception->getMessage());
    }

    public function test_invalid_amount_custom_message(): void
    {
        $exception = new InvalidAmountException('Amount must be positive');
        $this->assertSame('Amount must be positive', $exception->getMessage());
    }

    public function test_invalid_amount_extends_invalid_argument_exception(): void
    {
        $exception = new InvalidAmountException();
        $this->assertInstanceOf(\InvalidArgumentException::class, $exception);
    }

    public function test_minimum_withdrawal_message_includes_amount(): void
    {
        $exception = new MinimumWithdrawalException(5000);
        $this->assertSame('Le montant minimum de retrait est de 5000 FCFA', $exception->getMessage());
    }

    public function test_minimum_withdrawal_get_minimum_amount(): void
    {
        $exception = new MinimumWithdrawalException(2500.50);
        $this->assertSame(2500.50, $exception->getMinimumAmount());
    }

    public function test_minimum_withdrawal_extends_runtime_exception(): void
    {
        $exception = new MinimumWithdrawalException(1000);
        $this->assertInstanceOf(\RuntimeException::class, $exception);
    }

    public function test_insufficient_balance_with_previous_exception(): void
    {
        $previous = new \Exception('Original error');
        $exception = new InsufficientBalanceException('Custom', 42, $previous);
        $this->assertSame($previous, $exception->getPrevious());
        $this->assertSame(42, $exception->getCode());
    }

    public function test_minimum_withdrawal_with_previous_exception(): void
    {
        $previous = new \Exception('Previous');
        $exception = new MinimumWithdrawalException(1000, 10, $previous);
        $this->assertSame($previous, $exception->getPrevious());
        $this->assertSame(10, $exception->getCode());
    }
}
