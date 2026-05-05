<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;

class ClearLogsCommand extends Command
{
    protected $signature = 'log:clear';
    protected $description = 'Clear all application log files from storage/logs';

    public function handle(): int
    {
        $logPath = storage_path('logs');
        $files = File::glob("{$logPath}/*.log");

        if (empty($files)) {
            $this->info('No log files found.');
            return self::SUCCESS;
        }

        foreach ($files as $file) {
            File::put($file, '');
        }

        $this->info('Log files cleared: ' . count($files));

        return self::SUCCESS;
    }
}
