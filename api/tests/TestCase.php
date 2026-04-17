<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        if (config('database.default') === 'sqlite' || config('database.connections.sqlite.driver') === 'sqlite') {
            try {
                $pdo = $this->app['db']->connection()->getPdo();
                $pdo->sqliteCreateFunction('acos', 'acos', 1);
                $pdo->sqliteCreateFunction('cos', 'cos', 1);
                $pdo->sqliteCreateFunction('radians', 'deg2rad', 1);
                $pdo->sqliteCreateFunction('sin', 'sin', 1);
                $pdo->sqliteCreateFunction('HOUR', function ($datetime) {
                    return $datetime ? (int) date('G', strtotime($datetime)) : null;
                }, 1);
                $pdo->sqliteCreateFunction('GREATEST', function () {
                    $args = func_get_args();
                    return max(array_filter($args, fn ($v) => $v !== null));
                }, -1);
                $pdo->sqliteCreateFunction('LEAST', function () {
                    $args = func_get_args();
                    return min(array_filter($args, fn ($v) => $v !== null));
                }, -1);

                // WAL mode only outside a transaction (RefreshDatabase starts one)
                if (!$pdo->inTransaction()) {
                    $pdo->exec('PRAGMA journal_mode=WAL');
                }
            } catch (\Exception $e) {
                // Functions might already be registered
            }
        }
    }

    protected function tearDown(): void
    {
        // Reset stuck SQLite transactions to prevent cascade failures
        if (config('database.default') === 'sqlite') {
            try {
                $connection = $this->app['db']->connection();
                $pdo = $connection->getPdo();
                // If PDO thinks we're in a transaction but Laravel doesn't, force reset
                if ($pdo && $pdo->inTransaction()) {
                    $pdo->rollBack();
                }
                // Purge connection to get a fresh one for the next test
                $this->app['db']->purge();
            } catch (\Exception $e) {
                // Connection may already be closed
            }
        }

        parent::tearDown();
    }
}
