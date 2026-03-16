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

                // Enable WAL mode for better concurrent access and nested transactions
                $pdo->exec('PRAGMA journal_mode=WAL');
            } catch (\Exception $e) {
                // Functions might already be registered
            }
        }
    }
}
