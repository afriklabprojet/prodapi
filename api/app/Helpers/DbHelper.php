<?php

if (!function_exists('db_timestampdiff')) {
    /**
     * Returns a raw SQL expression for TIMESTAMPDIFF compatible with SQLite and MySQL.
     *
     * @param  string  $unit   'MINUTE' or 'SECOND'
     * @param  string  $col1   Start column name
     * @param  string  $col2   End column name
     * @return string
     */
    function db_timestampdiff(string $unit, string $col1, string $col2): string
    {
        $driver = config('database.default');
        $connection = config("database.connections.{$driver}.driver", $driver);

        if ($connection === 'sqlite') {
            $multiplier = strtoupper($unit) === 'SECOND' ? 86400 : 1440;
            return "(julianday({$col2}) - julianday({$col1})) * {$multiplier}";
        }

        return "TIMESTAMPDIFF({$unit}, {$col1}, {$col2})";
    }
}
